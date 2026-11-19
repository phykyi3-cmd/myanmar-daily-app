import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_daily_app/data/repositories/backup_repository.dart';
import 'package:myanmar_daily_app/data/repositories/daily_market_repository.dart';
import 'package:myanmar_daily_app/data/repositories/finance_repository.dart';
import 'package:myanmar_daily_app/data/repositories/reminder_repository.dart';
import 'package:myanmar_daily_app/data/repositories/settings_qr_repository.dart';
import 'package:myanmar_daily_app/data/services/asset_data_service.dart';
import 'package:myanmar_daily_app/data/services/backup_service.dart';
import 'package:myanmar_daily_app/data/services/local_db_service.dart';
import 'package:myanmar_daily_app/data/services/market_price_service.dart';
import 'package:myanmar_daily_app/data/services/preferences_service.dart';
import 'package:myanmar_daily_app/domain/models/commodity_price.dart';
import 'package:myanmar_daily_app/domain/models/daily_purchase_record.dart';
import 'package:myanmar_daily_app/domain/models/recipe.dart';
import 'package:myanmar_daily_app/domain/models/shopping_item.dart';
import 'package:myanmar_daily_app/main.dart';
import 'package:myanmar_daily_app/ui/core/utils/formatters.dart';
import 'package:myanmar_daily_app/ui/features/daily_market/view_models/daily_market_view_model.dart';
import 'package:myanmar_daily_app/ui/features/daily_market/views/daily_market_screen.dart';
import 'package:myanmar_daily_app/ui/features/finance_calc/view_models/finance_calc_view_model.dart';
import 'package:myanmar_daily_app/ui/features/home/view_models/home_view_model.dart';
import 'package:myanmar_daily_app/ui/features/reminders_qr/view_models/reminders_qr_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryDbService extends LocalDbService {
  final Map<String, List<Map<String, Object?>>> _tables = {};
  int _nextId = 1;

  List<Map<String, Object?>> _rows(String table) =>
      _tables.putIfAbsent(table, () => <Map<String, Object?>>[]);

  @override
  Future<List<Map<String, Object?>>> queryAll(
    String table, {
    String? orderBy,
  }) async {
    final copy =
        _rows(table).map((row) => Map<String, Object?>.from(row)).toList();
    if (orderBy != null && orderBy.contains('date_key DESC')) {
      copy.sort((a, b) =>
          '${b['date_key'] ?? ''}'.compareTo('${a['date_key'] ?? ''}'));
    } else if (orderBy != null && orderBy.contains('created_at DESC')) {
      copy.sort((a, b) =>
          '${b['created_at'] ?? ''}'.compareTo('${a['created_at'] ?? ''}'));
    }
    return copy;
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    final rows = _rows(table);
    final row = Map<String, Object?>.from(values);
    final id = _nextId++;
    row['id'] = id;
    rows.add(row);
    return id;
  }

  @override
  Future<int> updateById(
    String table,
    int id,
    Map<String, Object?> values,
  ) async {
    var updated = 0;
    for (final row in _rows(table)) {
      if ((row['id'] as num?)?.toInt() == id) {
        row.addAll(values);
        updated++;
      }
    }
    return updated;
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
  }) async {
    final rows = _rows(table);
    if (where == 'is_checked = ?' && whereArgs.isNotEmpty) {
      rows.removeWhere((row) => row['is_checked'] == whereArgs.first);
    } else if (where == 'date_key = ?' && whereArgs.isNotEmpty) {
      rows.removeWhere((row) => row['date_key'] == whereArgs.first);
    }
  }

  @override
  Future<void> clearTable(String table) async {
    _rows(table).clear();
  }
}

class _StubMarketPriceService extends MarketPriceService {
  _StubMarketPriceService();

  @override
  Future<MarketPriceSnapshot> syncLiveMarketPrices({
    int? customUsdMarketMmk,
  }) async {
    return MarketPriceSnapshot(
      usdMarketMmk: 4500,
      thbMarketMmk: 130,
      commodities: MarketPriceSnapshot.defaultCommodities(),
      lastSyncedAt: DateTime(2026, 11, 16, 12, 0),
      isOnlineLive: false,
      sourceNote: 'Test snapshot',
    );
  }
}

class _StubAssetDataService extends AssetDataService {
  _StubAssetDataService({this.recipes = const []});

  final List<Recipe> recipes;

  @override
  Future<List<Recipe>> loadRecipes() async => recipes;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'Checking recipe ingredients auto-records by date, preserves history on clearChecked, and deletes cleanly',
    () async {
      final db = _InMemoryDbService();
      final repo = DailyMarketRepository(
        dbService: db,
        assetDataService: _StubAssetDataService(),
        marketPriceService: _StubMarketPriceService(),
      );
      final vm = DailyMarketViewModel(repository: repo);

      const recipe = Recipe(
        id: 'hilsa_braised',
        name: 'ငါးသလောက်ပေါင်း',
        category: 'ငါး/ပုစွန်',
        prepMinutes: 90,
        ingredients: [
          RecipeIngredient(
            name: 'ငါးသလောက်',
            amount: '၅၀ ကျပ်သား',
            commodityId: 'pork',
            unitQuantity: 0.5,
          ),
          RecipeIngredient(
            name: 'ငရုတ်ကောင်း',
            amount: '၁ ထုပ်',
            commodityId: 'garlic',
            unitQuantity: 0.1,
          ),
        ],
        steps: ['ဆီသတ်ပြီး ပေါင်းပါ'],
      );

      await vm.loadAll();
      await vm.addRecipeIngredientsToChecklist(recipe);

      expect(vm.items.length, 2);
      expect(vm.items.first.recipeName, 'ငါးသလောက်ပေါင်း');

      final day1 = DateTime(2026, 11, 16, 10, 30);
      await vm.toggleItem(vm.items[0], now: day1);
      await vm.toggleItem(vm.items[1], now: day1);

      expect(vm.purchaseRecords.length, 1);
      final day1Record = vm.purchaseRecords.first;
      expect(day1Record.dateKey, '2026-11-16');
      expect(day1Record.dishNames, ['ငါးသလောက်ပေါင်း']);
      expect(day1Record.itemCount, 2);
      expect(day1Record.totalCostMmk, vm.totalEstimatedBudgetMmk);

      // Clearing checked items removes active list items ONLY, never purchase history.
      await vm.clearChecked();
      expect(vm.items, isEmpty);
      expect(vm.purchaseRecords.length, 1);

      // Adding & checking an item on another date creates a second record sorted newest first.
      await vm.addItem(
        ShoppingItem(
          name: 'ငါးခူ',
          quantity: '၅၀ ကျပ်သား',
          estimatedCostMmk: 9500,
          recipeName: 'ငါးခူမွှေချက်',
          createdAt: DateTime(2026, 11, 17, 9, 0),
        ),
      );
      await vm.toggleItem(
        vm.items.single,
        now: DateTime(2026, 11, 17, 9, 15),
      );

      expect(vm.purchaseRecords.length, 2);
      expect(vm.purchaseRecords.first.dateKey, '2026-11-17');
      expect(vm.purchaseRecords.last.dateKey, '2026-11-16');

      // Delete line item / delete whole record.
      await vm.deletePurchaseRecord(vm.purchaseRecords.first);
      expect(vm.purchaseRecords.length, 1);
      expect(vm.purchaseRecords.single.dateKey, '2026-11-16');
    },
  );

  test(
    'Unchecking an item removes only its entry from today record',
    () async {
      final db = _InMemoryDbService();
      final repo = DailyMarketRepository(
        dbService: db,
        assetDataService: _StubAssetDataService(),
        marketPriceService: _StubMarketPriceService(),
      );
      final vm = DailyMarketViewModel(repository: repo);
      final day = DateTime(2026, 11, 16, 16, 0);

      await vm.addItem(
        ShoppingItem(
          name: 'ငါးကြင်း',
          quantity: '၅၀ ကျပ်သား',
          estimatedCostMmk: 8000,
          recipeName: 'မုန့်ဟင်းခါး',
          createdAt: day,
        ),
      );
      await vm.toggleItem(vm.items.single, now: day);
      expect(vm.purchaseRecords.length, 1);

      await vm.toggleItem(vm.items.single, now: day);
      expect(vm.purchaseRecords, isEmpty);
    },
  );

  testWidgets(
    'Deleting a purchase record requires explicit confirmation before deleting',
    (tester) async {
      final db = _InMemoryDbService();
      final repo = DailyMarketRepository(
        dbService: db,
        assetDataService: _StubAssetDataService(),
        marketPriceService: _StubMarketPriceService(),
      );
      final vm = DailyMarketViewModel(repository: repo);
      final saturday = DateTime(2026, 11, 14, 10, 0);

      await vm.addItem(
        ShoppingItem(
          name: 'ငရုတ်ကောင်း',
          quantity: '၁ ထုပ်',
          estimatedCostMmk: 1500,
          recipeName: 'ဘူးသီးဟင်းခါး',
          createdAt: saturday,
        ),
      );
      await vm.toggleItem(vm.items.single, now: saturday);

      await tester.pumpWidget(
        MaterialApp(
          home: DailyMarketScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      // ဟင်းချက်အစီအစဉ် is active by default and placed before ဈေးဝယ်စာရင်း.
      expect(vm.activeSection, DailySection.recipes);
      final planFinder = find.textContaining('ဟင်းချက်အစီအစဉ်');
      final shoppingFinder = find.text('ဈေးဝယ်စာရင်း (1)');
      expect(planFinder, findsOneWidget);
      expect(shoppingFinder, findsOneWidget);
      expect(
        tester.getTopLeft(planFinder).dx,
        lessThan(tester.getTopLeft(shoppingFinder).dx),
      );

      // Switch to ဈေးဝယ်စာရင်း tab to inspect purchase history and delete flow.
      await tester.tap(shoppingFinder);
      await tester.pumpAndSettle();
      expect(vm.activeSection, DailySection.shopping);

      // Scroll purchase records cleanly into main view above the FAB.
      await tester.drag(find.byType(ListView).first, const Offset(0, -350));
      await tester.pumpAndSettle();

      // Purchase history header & Saturday record are visible under Shopping List.
      expect(find.textContaining('နေ့စွဲအလိုက် ဈေးဝယ်မှတ်တမ်းများ'),
          findsOneWidget);
      expect(
        find.text(formatBurmeseFullDate(DateTime(2026, 11, 14))),
        findsOneWidget,
      );

      // Tap the Purchase Record card to inspect itemized dishes and daily total.
      await tester.tap(find.text(formatBurmeseFullDate(DateTime(2026, 11, 14))));
      await tester.pumpAndSettle();
      expect(find.text('ထိုနေ့ စုစုပေါင်းသုံးငွေ'), findsOneWidget);
      expect(find.text('ဘူးသီးဟင်းခါး'), findsWidgets);
      expect(find.text('ငရုတ်ကောင်း'), findsWidgets);

      // Close detail sheet before testing Trash confirmation on the record card.
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Tap the trash icon on the Purchase Record card.
      final recordDeleteBtn = find.byTooltip('မှတ်တမ်းဖျက်ရန်');
      await tester.tap(recordDeleteBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog asks Delete or Cancel (must NOT delete immediately!).
      expect(find.text('ဈေးဝယ်မှတ်တမ်း ဖျက်မည်လား?'), findsOneWidget);
      expect(find.text('မဖျက်တော့ပါ (Cancel)'), findsOneWidget);

      // Tapping Cancel keeps record untouched.
      await tester.tap(find.text('မဖျက်တော့ပါ (Cancel)'));
      await tester.pumpAndSettle();
      expect(vm.purchaseRecords.length, 1);

      // Tap Trash again and confirm Delete -> record is removed cleanly.
      await tester.tap(recordDeleteBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ဖျက်မည်'));
      await tester.pumpAndSettle();
      expect(vm.purchaseRecords, isEmpty);
    },
  );

  test('DailyPurchaseRecord preserves JSON map structure round-trip', () {
    final record = DailyPurchaseRecord(
      id: 9,
      dateKey: '2026-11-16',
      recordDate: DateTime(2026, 11, 16),
      dishNames: const ['ထားဝယ် ရိုးရာ မုန့်လက်သုပ်'],
      items: [
        PurchasedLineItem(
          entryKey: 'shop_1',
          name: 'ပအုန်းရည်',
          quantity: '၁ ပုလင်း',
          costMmk: 2500,
          recipeName: 'ထားဝယ် ရိုးရာ မုန့်လက်သုပ်',
          purchasedAt: DateTime(2026, 11, 16, 15, 30),
        ),
      ],
      updatedAt: DateTime(2026, 11, 16, 15, 30),
    );
    final decoded = DailyPurchaseRecord.fromMap(record.toMap());
    expect(decoded.dateKey, '2026-11-16');
    expect(decoded.dishNames, ['ထားဝယ် ရိုးရာ မုန့်လက်သုပ်']);
    expect(decoded.totalCostMmk, 2500);
    expect(decoded.items.single.name, 'ပအုန်းရည်');
  });

  test('DailyMarketViewModel defaults activeSection to recipes first', () {
    final repo = DailyMarketRepository(
      dbService: _InMemoryDbService(),
      assetDataService: _StubAssetDataService(),
      marketPriceService: _StubMarketPriceService(),
    );
    final vm = DailyMarketViewModel(repository: repo);
    expect(vm.activeSection, DailySection.recipes);
    expect(DailySection.values.first, DailySection.recipes);
    expect(DailySection.values.last, DailySection.shopping);
  });

  testWidgets(
    'Recipe grid shows only photo and dish name until tapped to expand NBK UI',
    (tester) async {
      const sampleRecipe = Recipe(
        id: 'dawei_nga_paung_htoke',
        name: 'ထားဝယ် ငါးပေါင်းထုပ်',
        category: 'တိုင်းရင်းသားဟင်းလျာများ',
        ethnicGroup: 'ထားဝယ်ဟင်းလျာ',
        prepMinutes: 45,
        ratingScore: 96,
        flavorProfileMm: 'မွှေးပျံ့ ချိုစိမ့်',
        ingredients: [
          RecipeIngredient(
            name: 'ကကတစ်ငါး',
            amount: '၄၀ ကျပ်သား',
            commodityId: 'fish_general',
            unitQuantity: 0.4,
          ),
        ],
        steps: ['ငှက်ပျောရွက်ဖြင့် ထုပ်၍ ပေါင်းပါ'],
      );
      final repo = DailyMarketRepository(
        dbService: _InMemoryDbService(),
        assetDataService: _StubAssetDataService(recipes: const [sampleRecipe]),
        marketPriceService: _StubMarketPriceService(),
      );
      final vm = DailyMarketViewModel(repository: repo);
      await vm.loadAll();

      await tester.pumpWidget(
        MaterialApp(
          home: DailyMarketScreen(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll slightly so the compact recipe grid card is in view.
      await tester.drag(find.byType(ListView).first, const Offset(0, -320));
      await tester.pumpAndSettle();

      // Outer grid shows dish name (and image/fallback) without detailed card clutter.
      expect(find.text('ထားဝယ် ငါးပေါင်းထုပ်'), findsOneWidget);
      expect(find.text('အရသာ'), findsNothing);
      expect(find.text('လွယ်ကူမှု'), findsNothing);
      expect(find.text('ချွေတာမှု'), findsNothing);
      expect(find.text('ချက်နည်း / ဝယ်ရန်'), findsNothing);

      // Tapping the compact card expands the full NBK UI detail sheet.
      await tester.tap(find.text('ထားဝယ် ငါးပေါင်းထုပ်'));
      await tester.pumpAndSettle();

      expect(find.text('အရသာ'), findsOneWidget);
      expect(find.text('လွယ်ကူမှု'), findsOneWidget);
      expect(find.text('ချွေတာမှု'), findsOneWidget);
      expect(find.textContaining('Est. price'), findsOneWidget);
      expect(find.text('OVR 96'), findsOneWidget);

      // Scroll inside expanded sheet to confirm ingredients and cooking steps.
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.textContaining('ကကတစ်ငါး'), findsOneWidget);
      expect(find.text('ငှက်ပျောရွက်ဖြင့် ထုပ်၍ ပေါင်းပါ'), findsOneWidget);
    },
  );

  testWidgets(
    'App launches on အိမ်တွင်းရေး without ပင်မ tab and groups secondary tools quietly under အခြား',
    (tester) async {
      final db = _InMemoryDbService();
      final prefs = PreferencesService();
      final assetSvc = _StubAssetDataService();
      final priceSvc = _StubMarketPriceService();
      final backupSvc = BackupService();

      final financeRepo = FinanceRepository(dbService: db);
      final dailyRepo = DailyMarketRepository(
        dbService: db,
        assetDataService: assetSvc,
        marketPriceService: priceSvc,
      );
      final reminderRepo = ReminderRepository(dbService: db);
      final settingsQrRepo = SettingsQrRepository(preferencesService: prefs);
      final backupRepo = BackupRepository(
        dbService: db,
        backupService: backupSvc,
        financeRepository: financeRepo,
        dailyMarketRepository: dailyRepo,
        reminderRepository: reminderRepo,
        settingsQrRepository: settingsQrRepo,
      );

      final homeVm = HomeViewModel(
        settingsQrRepository: settingsQrRepo,
        reminderRepository: reminderRepo,
        financeRepository: financeRepo,
        dailyMarketRepository: dailyRepo,
        backupRepository: backupRepo,
      );
      final financeVm = FinanceCalcViewModel(
        financeRepository: financeRepo,
        marketPriceService: priceSvc,
      );
      final dailyVm = DailyMarketViewModel(repository: dailyRepo);
      final toolsVm = RemindersQrViewModel(
        reminderRepository: reminderRepo,
        settingsQrRepository: settingsQrRepo,
      );

      await tester.pumpWidget(
        MyanmarDailyApp(
          homeViewModel: homeVm,
          financeCalcViewModel: financeVm,
          dailyMarketViewModel: dailyVm,
          remindersQrViewModel: toolsVm,
        ),
      );
      await tester.pumpAndSettle();

      // Starts directly on 'အိမ်တွင်းရေး' with strictly 4 nav tabs (no 'ပင်မ' or 'မိခင်/ကလေး').
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text('ပင်မ'), findsNothing);
      expect(find.text('မိခင်/ကလေး'), findsNothing);
      expect(find.text('သတိပေး/QR'), findsNothing);
      expect(find.text('အိမ်တွင်းရေး'), findsWidgets);
      expect(find.text('ဗေဒင်/ယတြာ'), findsOneWidget);
      expect(find.text('စာရင်း/တွက်စက်'), findsWidgets);
      expect(find.text('အခြား'), findsOneWidget);
      expect(find.textContaining('ဟင်းချက်အစီအစဉ်'), findsWidgets);

      // Tapping 'အခြား' shows quiet collapsed sections until explicitly tapped.
      await tester.tap(find.text('အခြား'));
      await tester.pumpAndSettle();

      expect(find.text('အခြား Tools များ'), findsOneWidget);
      expect(find.text('ယာဉ်နှင့် စာရွက်စာတမ်း Reminder'), findsOneWidget);
      expect(find.text('Offline QR နှင့် အရေးပေါ်ကတ်'), findsOneWidget);
      expect(find.text('Backup နှင့် Cloud Sync'), findsOneWidget);
      // Collapsed by default -> action buttons hidden until user taps into them.
      expect(find.text('သတိပေးချက် အသစ်ထည့်'), findsNothing);

      await tester.tap(find.text('ယာဉ်နှင့် စာရွက်စာတမ်း Reminder'));
      await tester.pumpAndSettle();
      expect(find.text('သတိပေးချက် အသစ်ထည့်'), findsOneWidget);
    },
  );
}
