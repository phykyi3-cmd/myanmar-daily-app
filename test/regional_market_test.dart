import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myanmar_daily_app/data/repositories/daily_market_repository.dart';
import 'package:myanmar_daily_app/data/services/asset_data_service.dart';
import 'package:myanmar_daily_app/data/services/ip_geolocation_service.dart';
import 'package:myanmar_daily_app/data/services/local_db_service.dart';
import 'package:myanmar_daily_app/data/services/market_price_service.dart';
import 'package:myanmar_daily_app/data/services/preferences_service.dart';
import 'package:myanmar_daily_app/domain/models/commodity_price.dart';
import 'package:myanmar_daily_app/domain/models/recipe.dart';
import 'package:myanmar_daily_app/domain/models/regional_market.dart';
import 'package:myanmar_daily_app/ui/core/utils/formatters.dart';
import 'package:myanmar_daily_app/ui/features/daily_market/view_models/daily_market_view_model.dart';
import 'package:myanmar_daily_app/ui/features/daily_market/views/daily_market_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryRegionalDb extends LocalDbService {
  final Map<String, List<Map<String, Object?>>> _tables = {};
  int _nextId = 1;

  List<Map<String, Object?>> _rows(String table) =>
      _tables.putIfAbsent(table, () => <Map<String, Object?>>[]);

  @override
  Future<List<Map<String, Object?>>> queryAll(
    String table, {
    String? orderBy,
  }) async {
    return _rows(table).map((r) => Map<String, Object?>.from(r)).toList();
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    final row = Map<String, Object?>.from(values);
    final id = _nextId++;
    row['id'] = id;
    _rows(table).add(row);
    return id;
  }

  @override
  Future<int> updateById(
    String table,
    int id,
    Map<String, Object?> values,
  ) async {
    var count = 0;
    for (final row in _rows(table)) {
      if ((row['id'] as num?)?.toInt() == id) {
        row.addAll(values);
        count++;
      }
    }
    return count;
  }

  @override
  Future<int> deleteById(String table, int id) async {
    final rows = _rows(table);
    final before = rows.length;
    rows.removeWhere((row) => (row['id'] as num?)?.toInt() == id);
    return before - rows.length;
  }

  @override
  Future<void> deleteWhere(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {}
}

class _StubMarketService extends MarketPriceService {
  @override
  Future<MarketPriceSnapshot> syncLiveMarketPrices({
    int? customUsdMarketMmk,
  }) async {
    return MarketPriceSnapshot(
      usdMarketMmk: 4500,
      thbMarketMmk: 132,
      commodities: MarketPriceSnapshot.defaultCommodities(),
      lastSyncedAt: DateTime(2026, 11, 17, 12, 0),
      isOnlineLive: false,
      sourceNote: 'Test FX Snapshot',
    );
  }
}

class _StubAssetRecipes extends AssetDataService {
  _StubAssetRecipes(this._recipes);

  final List<Recipe> _recipes;

  @override
  Future<List<Recipe>> loadRecipes() async => _recipes;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Supports strictly ONLY MM, TH, MY, SG, KR, JP and maps IP/fallback accurately', () async {
    expect(
      SupportedMarketCountry.values.map((c) => c.isoCode).toList(),
      ['MM', 'TH', 'MY', 'SG', 'KR', 'JP'],
    );
    expect(SupportedMarketCountry.fromIsoCode('US'), isNull);
    expect(SupportedMarketCountry.fromIsoCode('AU'), isNull);

    // Primary endpoint detects Thailand
    final thService = IpGeolocationService(
      httpClient: MockClient((req) async {
        expect(req.url.host, 'api.country.is');
        return http.Response(jsonEncode({'ip': '203.0.113.5', 'country': 'TH'}), 200);
      }),
    );
    final thRes = await thService.detectCountry();
    expect(thRes.effectiveCountry, SupportedMarketCountry.th);
    expect(thRes.isSupportedIpCountry, isTrue);

    // Primary fails -> fallback geojs.io detects Singapore
    final sgService = IpGeolocationService(
      httpClient: MockClient((req) async {
        if (req.url.host == 'api.country.is') {
          return http.Response('error', 503);
        }
        return http.Response(
          jsonEncode({'ip': '198.51.100.7', 'country': 'SG', 'name': 'Singapore'}),
          200,
        );
      }),
    );
    final sgRes = await sgService.detectCountry();
    expect(sgRes.effectiveCountry, SupportedMarketCountry.sg);
    expect(sgRes.isFromLiveIp, isTrue);

    // Unsupported IP country (e.g. US) safely falls back to MM without adding US
    final usService = IpGeolocationService(
      httpClient: MockClient((_) async {
        return http.Response(jsonEncode({'ip': '8.8.8.8', 'country': 'US'}), 200);
      }),
    );
    final usRes = await usService.detectCountry();
    expect(usRes.isSupportedIpCountry, isFalse);
    expect(usRes.effectiveCountry, SupportedMarketCountry.mm);

    // Offline network exception -> timezone/locale inference works cleanly
    final offlineService = IpGeolocationService(
      httpClient: MockClient((_) async => throw const SocketException('offline')),
    );
    expect(
      offlineService.inferOfflineCountry(timeZoneOffset: const Duration(minutes: 390)),
      SupportedMarketCountry.mm,
    );
    expect(
      offlineService.inferOfflineCountry(
        timeZoneOffset: const Duration(hours: 9),
        localeCountryCode: '',
        localeLanguageCode: 'ko',
      ),
      SupportedMarketCountry.kr,
    );
    expect(
      offlineService.inferOfflineCountry(
        timeZoneOffset: const Duration(hours: 9),
        localeCountryCode: '',
        localeLanguageCode: 'ja',
      ),
      SupportedMarketCountry.jp,
    );
  });

  test('Calculates local dish and ingredient costs accurately across all 6 countries', () async {
    final snap = await _StubMarketService().syncLiveMarketPrices();
    const dish = Recipe(
      id: 'chicken_curry',
      name: 'ကြက်သားအာလူးချက်',
      category: 'အသားဟင်း',
      prepMinutes: 40,
      ingredients: [
        RecipeIngredient(
          name: 'ကြက်သား',
          amount: '၃၀ ကျပ်သား',
          commodityId: 'chicken',
          unitQuantity: 0.30,
        ),
        RecipeIngredient(
          name: 'အာလူး',
          amount: '၂၀ ကျပ်သား',
          commodityId: 'potato',
          unitQuantity: 0.20,
        ),
        RecipeIngredient(
          name: 'စားဆီ/ဟင်းခတ်',
          amount: '၁ ပွဲစာ',
          commodityId: 'seasoning',
          unitQuantity: 1.0,
        ),
      ],
      steps: ['ချက်ပါ'],
    );

    final mmPrices = RegionalMarketCatalog.resolveUnitPrices(
      country: SupportedMarketCountry.mm,
      snapshot: snap,
    );
    final thPrices = RegionalMarketCatalog.resolveUnitPrices(
      country: SupportedMarketCountry.th,
      snapshot: snap,
    );
    final myPrices = RegionalMarketCatalog.resolveUnitPrices(
      country: SupportedMarketCountry.my,
      snapshot: snap,
    );
    final sgPrices = RegionalMarketCatalog.resolveUnitPrices(
      country: SupportedMarketCountry.sg,
      snapshot: snap,
    );
    final krPrices = RegionalMarketCatalog.resolveUnitPrices(
      country: SupportedMarketCountry.kr,
      snapshot: snap,
    );
    final jpPrices = RegionalMarketCatalog.resolveUnitPrices(
      country: SupportedMarketCountry.jp,
      snapshot: snap,
    );

    final mmTotal = RegionalMarketCatalog.recipeTotalLocal(
      recipe: dish,
      country: SupportedMarketCountry.mm,
      unitPrices: mmPrices,
      snapshot: snap,
    );
    final thTotal = RegionalMarketCatalog.recipeTotalLocal(
      recipe: dish,
      country: SupportedMarketCountry.th,
      unitPrices: thPrices,
      snapshot: snap,
    );
    final myTotal = RegionalMarketCatalog.recipeTotalLocal(
      recipe: dish,
      country: SupportedMarketCountry.my,
      unitPrices: myPrices,
      snapshot: snap,
    );
    final sgTotal = RegionalMarketCatalog.recipeTotalLocal(
      recipe: dish,
      country: SupportedMarketCountry.sg,
      unitPrices: sgPrices,
      snapshot: snap,
    );
    final krTotal = RegionalMarketCatalog.recipeTotalLocal(
      recipe: dish,
      country: SupportedMarketCountry.kr,
      unitPrices: krPrices,
      snapshot: snap,
    );
    final jpTotal = RegionalMarketCatalog.recipeTotalLocal(
      recipe: dish,
      country: SupportedMarketCountry.jp,
      unitPrices: jpPrices,
      snapshot: snap,
    );

    expect(SupportedMarketCountry.mm.formatAmount(mmTotal), contains('ကျပ်'));
    expect(SupportedMarketCountry.th.formatAmount(thTotal), contains('ဘတ်'));
    expect(SupportedMarketCountry.my.formatAmount(myTotal), startsWith('RM '));
    expect(SupportedMarketCountry.sg.formatAmount(sgTotal), startsWith('S\$ '));
    expect(SupportedMarketCountry.kr.formatAmount(krTotal), contains('₩'));
    expect(SupportedMarketCountry.jp.formatAmount(jpTotal), contains('¥'));
    expect(normalizeAsciiDigits(' ၁၇.၅၀, '), '17.50');
    expect(normalizeAsciiDigits('၇,၉၀၀'), '7900');
  });

  testWidgets('DailyMarketScreen auto-detects IP country and switches currencies cleanly', (tester) async {
    const sampleDish = Recipe(
      id: 'chicken_potato_curry',
      name: 'ကြက်သားအာလူးဟင်း',
      category: 'အသားဟင်း',
      prepMinutes: 35,
      ingredients: [
        RecipeIngredient(
          name: 'ကြက်သား',
          amount: '၃၀ ကျပ်သား',
          commodityId: 'chicken',
          unitQuantity: 0.30,
        ),
      ],
      steps: ['ချက်ပါ'],
    );

    final repo = DailyMarketRepository(
      dbService: _InMemoryRegionalDb(),
      assetDataService: _StubAssetRecipes([sampleDish]),
      marketPriceService: _StubMarketService(),
      ipGeolocationService: IpGeolocationService(
        httpClient: MockClient((_) async {
          return http.Response(jsonEncode({'ip': '203.0.113.8', 'country': 'TH'}), 200);
        }),
      ),
      preferencesService: PreferencesService(),
    );
    final vm = DailyMarketViewModel(repository: repo);
    await vm.loadAll();

    expect(vm.activeCountry, SupportedMarketCountry.th);

    await tester.pumpWidget(
      MaterialApp(home: DailyMarketScreen(viewModel: vm)),
    );
    await tester.pumpAndSettle();

    // Auto IP detected Thailand -> displays THB staples and strictly 6 countries
    expect(find.textContaining('THB'), findsWidgets);
    expect(find.textContaining('ဘတ်'), findsWidgets);
    expect(find.textContaining('မလေးရှား (MYR)'), findsOneWidget);
    expect(find.textContaining('စင်ကာပူ (SGD)'), findsOneWidget);
    expect(find.textContaining('ကိုရီးယား (KRW)'), findsOneWidget);
    expect(find.textContaining('ဂျပန် (JPY)'), findsOneWidget);

    // Switch manually to Malaysia -> costs recalculate in RM
    final myChip = find.textContaining('မလေးရှား (MYR)');
    await tester.ensureVisible(myChip);
    await tester.tap(myChip);
    await tester.pumpAndSettle();

    expect(vm.activeCountry, SupportedMarketCountry.my);
    expect(find.textContaining('RM 17.50'), findsOneWidget);
  });
}
