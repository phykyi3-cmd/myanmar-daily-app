import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myanmar_daily_app/data/repositories/finance_repository.dart';
import 'package:myanmar_daily_app/data/services/local_db_service.dart';
import 'package:myanmar_daily_app/data/services/market_price_service.dart';
import 'package:myanmar_daily_app/domain/models/commodity_price.dart';
import 'package:myanmar_daily_app/domain/use_cases/myanmar_calculators.dart';
import 'package:myanmar_daily_app/ui/features/finance_calc/view_models/finance_calc_view_model.dart';
import 'package:myanmar_daily_app/ui/features/finance_calc/views/finance_calc_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryFinanceDb extends LocalDbService {
  @override
  Future<List<Map<String, Object?>>> queryAll(
    String table, {
    String? orderBy,
  }) async =>
      const [];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MyanmarCalculators', () {
    test('converts kyat, pae, yway accurately', () {
      final weight = MyanmarCalculators.toKyatWeight(
        kyat: 1,
        pae: 8,
        yway: 4,
      );
      expect(weight, closeTo(1.53125, 0.0001));
    });

    test('calculates gold price with wastage and making fee', () {
      final result = MyanmarCalculators.calculateGoldPrice(
        kyat: 0,
        pae: 8,
        yway: 0,
        pricePerKyat: 6000000,
        wastagePae: 1,
        makingFeeMmk: 50000,
      );

      expect(result.goldValueMmk, 3000000);
      expect(result.wastageValueMmk, 375000);
      expect(result.makingFeeMmk, 50000);
      expect(result.totalMmk, 3425000);
    });

    test('calculates flat installment monthly payment and total payable', () {
      final result = MyanmarCalculators.calculateInstallment(
        principal: 1000000,
        downPayment: 200000,
        monthlyFlatInterestPercent: 2,
        months: 5,
      );

      expect(result.financedAmount, 800000);
      expect(result.totalInterest, 80000);
      expect(result.totalPayable, 880000);
      expect(result.monthlyPayment, 176000);
    });

    test('converts currency both ways safely', () {
      expect(
        MyanmarCalculators.convertCurrency(
          amount: 100,
          rateMmkPerUnit: 4650,
          toMmk: true,
        ),
        465000,
      );
      expect(
        MyanmarCalculators.convertCurrency(
          amount: 465000,
          rateMmkPerUnit: 4650,
          toMmk: false,
        ),
        100,
      );
    });
  });

  group('Live Myanmar Market FX Sync', () {
    MockClient buildLiveFxClient() {
      return MockClient((req) async {
        final url = req.url.toString();
        if (url.contains('live_fx.json')) {
          return http.Response(
            jsonEncode({
              'schemaVersion': 1,
              'updatedAtUtc': DateTime.now().toUtc().toIso8601String(),
              'usdCashMarketMmk': 4650,
              'usdP2pBuyMmk': 5129,
              'usdP2pSellMmk': 5066,
              'usdP2pMidMmk': 5098,
              'usdRemitMmk': 3874,
              'worldGoldUsdPerOz': 3728.0,
              'goldOpenMarket16PaeMmk': 10300000,
              'goldOpenMarket15PaeMmk': 9655000,
              'goldYgeaRef16PaeMmk': 7050000,
              'goldYgeaRef15PaeMmk': 6610000,
              'globalRatesPerUsd': {
                'USD': 1.0,
                'THB': 33.96,
                'MYR': 4.115,
                'SGD': 1.289,
                'KRW': 1332.2,
                'JPY': 159.36,
                'CNY': 6.68,
                'EUR': 0.911,
              },
              'sources': ['Bybit P2P (USDT/MMK)', 'Bitget P2P (USDT/MMK)'],
            }),
            200,
          );
        }
        if (url.contains('open.er-api.com')) {
          return http.Response(
            jsonEncode({
              'rates': {
                'THB': 33.96,
                'MYR': 4.115,
                'SGD': 1.289,
                'KRW': 1332.2,
                'JPY': 159.36,
                'CNY': 6.68,
                'EUR': 0.911,
                'MMK': 2100.0,
              },
            }),
            200,
          );
        }
        if (url.contains('api.gold-api.com')) {
          return http.Response(jsonEncode({'price': 3728.0}), 200);
        }
        return http.Response('not found', 404);
      });
    }

    test('fetches live Myanmar cash/P2P/remit USD rates and switches tiers cleanly', () async {
      final service = MarketPriceService(httpClient: buildLiveFxClient());

      final liveCash = await service.syncLiveMarketPrices();
      expect(liveCash.isOnlineLive, isTrue);
      expect(liveCash.activeRateTier, MarketRateTier.cashMarket);
      expect(liveCash.usdMarketMmk, 4650);
      expect(liveCash.usdP2pBuyMmk, 5129);
      expect(liveCash.usdP2pSellMmk, 5066);
      expect(liveCash.foreignRatesMmk['USD'], 4650.0);
      expect(liveCash.foreignRatesMmk['MYR'], closeTo(1130.0, 2.0));
      expect(liveCash.foreignRatesMmk['JPY'], closeTo(29.2, 0.5));
      expect(liveCash.foreignRatesMmk['KRW'], closeTo(3.49, 0.1));

      final p2p = await service.setMarketRateTier(MarketRateTier.usdtP2p);
      expect(p2p.activeRateTier, MarketRateTier.usdtP2p);
      expect(p2p.usdMarketMmk, 5098);
      expect(p2p.foreignRatesMmk['USD'], 5098.0);

      final custom = await service.updateUsdMarketRate(4720);
      expect(custom.activeRateTier, MarketRateTier.custom);
      expect(custom.usdMarketMmk, 4720);

      final reset = await service.resetToLiveMarketRate();
      expect(reset.activeRateTier, MarketRateTier.cashMarket);
      expect(reset.usdMarketMmk, 4650);

      // Real Yangon open-market 16-Pae gold tracks live XAU/USD * live P2P USD (+1.5% spread)
      expect(liveCash.activeGoldTier, GoldRateTier.openMarket);
      expect(liveCash.goldOpenMarket16PaeMmk, inInclusiveRange(10250000, 10350000));
      expect(liveCash.myanmarGold16PaeMmk, liveCash.goldOpenMarket16PaeMmk);
      expect(liveCash.goldYgeaRef16PaeMmk, 7050000);

      final ygea = await service.setGoldRateTier(GoldRateTier.ygeaReference);
      expect(ygea.activeGoldTier, GoldRateTier.ygeaReference);
      expect(ygea.myanmarGold16PaeMmk, 7050000);

      final customGold = await service.updateMyanmarGoldPrice(10500000);
      expect(customGold.activeGoldTier, GoldRateTier.custom);
      expect(customGold.myanmarGold16PaeMmk, 10500000);

      final resetGold = await service.resetToLiveGoldPrice();
      expect(resetGold.activeGoldTier, GoldRateTier.openMarket);
      expect(resetGold.myanmarGold16PaeMmk, inInclusiveRange(10250000, 10350000));
    });

    test('falls back directly to native Bybit/Bitget P2P when live_fx.json is unavailable', () async {
      final service = MarketPriceService(
        httpClient: MockClient((req) async {
          final url = req.url.toString();
          if (url.contains('api2.bybit.com')) {
            final body = jsonDecode(req.body) as Map<String, dynamic>;
            final price = body['side'] == '1' ? '5120' : '5080';
            return http.Response(
              jsonEncode({
                'result': {
                  'items': [
                    {'price': price},
                  ],
                },
              }),
              200,
            );
          }
          if (url.contains('open.er-api.com')) {
            return http.Response(
              jsonEncode({
                'rates': {'THB': 34.0, 'MYR': 4.12, 'SGD': 1.29, 'MMK': 2100.0},
              }),
              200,
            );
          }
          return http.Response('unavailable', 503);
        }),
      );

      final snap = await service.syncLiveMarketPrices();
      expect(snap.isOnlineLive, isTrue);
      expect(snap.usdP2pBuyMmk, 5120);
      expect(snap.usdP2pSellMmk, 5080);
      expect(snap.usdP2pMidMmk, 5100);
      expect(snap.usdCashMarketMmk, 4650);
    });

    testWidgets('FinanceCalcScreen updates FX conversion live on typing & tier switching', (tester) async {
      final service = MarketPriceService(httpClient: buildLiveFxClient());
      final vm = FinanceCalcViewModel(
        financeRepository: FinanceRepository(dbService: _InMemoryFinanceDb()),
        marketPriceService: service,
      );
      vm.setActiveSection(FinanceSection.calculators);
      await vm.loadAll();

      await tester.pumpWidget(
        MaterialApp(home: FinanceCalcScreen(viewModel: vm)),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('နိုင်ငံခြားငွေလဲနှုန်း တွက်စက်'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.textContaining('ကျသင့်ငွေ:'),
        250,
        scrollable: find.byType(Scrollable).first,
      );

      // Default 100 USD at live cash market 4,650 MMK = 465,000 ကျပ်
      expect(find.textContaining('465,000 ကျပ်'), findsOneWidget);

      // Switch to live USDT P2P (5,098 MMK) -> immediately updates to 509,800 ကျပ်
      await tester.scrollUntilVisible(
        find.textContaining('USDT P2P (5,098 ကျပ်)'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('USDT P2P (5,098 ကျပ်)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('509,800 ကျပ်'), findsOneWidget);

      // Live typing with Burmese digits ("၁၀" = 10 USD) recalculates immediately without tapping button!
      final amountField = find.widgetWithText(TextField, 'ပမာဏ (USD)');
      await tester.ensureVisible(amountField);
      await tester.enterText(amountField, '၁၀');
      await tester.pumpAndSettle();
      expect(find.textContaining('50,980 ကျပ်'), findsOneWidget);

      // Verify Gold Calculator live open-market price & YGEA tier switching
      final ygeaChip = find.textContaining('YGEA ရည်ညွှန်း (7,050,000 ကျပ်)');
      await tester.scrollUntilVisible(
        ygeaChip,
        -350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(ygeaChip);
      await tester.pumpAndSettle();
      expect(find.textContaining('ပြင်ပရွှေပေါက်ဈေး (10,300,000 ကျပ်)'), findsOneWidget);
      expect(ygeaChip, findsOneWidget);

      await tester.tap(ygeaChip);
      await tester.pumpAndSettle();
      expect(vm.marketSnapshot.myanmarGold16PaeMmk, 7050000);
    });
  });
}
