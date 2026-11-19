import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/commodity_price.dart';

/// Fetches live online Myanmar market USD/MMK rates (via automated 30-min live P2P/market
/// feed on GitHub `fx-data` + direct native Bybit/Bitget P2P orderbooks on mobile),
/// live global cross-rates (USD, THB, MYR, SGD, KRW, JPY, CNY, EUR), and live World Spot Gold (XAU/USD).
class MarketPriceService {
  MarketPriceService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// CORS-enabled live JSON updated every 30 minutes from Bybit P2P, Bitget P2P,
  /// Remitly, Open-ER-API, and Gold-API via `.github/workflows/update-live-fx.yml`.
  static const String liveMyanmarFxFeedUrl =
      'https://raw.githubusercontent.com/phykyi3-cmd/myanmar-daily-app/fx-data/live_fx.json';
  static const String _liveExchangeApiUrl =
      'https://open.er-api.com/v6/latest/USD';
  static const String _liveGoldApiUrl = 'https://api.gold-api.com/price/XAU';
  static const String _bitgetPaxgUrl =
      'https://api.bitget.com/api/v2/spot/market/tickers?symbol=PAXGUSDT';
  static const String _bybitP2pUrl =
      'https://api2.bybit.com/fiat/otc/item/online';
  static const String _bitgetP2pUrl =
      'https://www.bitget.com/v1/p2p/pub/adv/queryAdvList';

  static const String _customOverridesKey = 'user_commodity_overrides_v2';
  static const String _customUsdKey = 'user_usd_market_mmk';
  static const String _customGoldKey = 'user_gold_16pae_mmk';
  static const String _rateTierKey = 'market_rate_tier_v1';
  static const String _goldTierKey = 'gold_rate_tier_v1';

  static const double _kyattharPerTroyOzTraditional = 1.873026; // 31.1034768 / 16.606g
  static const double _kyattharPerTroyOzYgea = 1.90476; // 31.1034768 / 16.3293g
  static const double _yangonPhysicalBullionSpread = 1.015;

  static const int _baselineMarketUsdMmk = 4650;
  static const int _baselineP2pBuyMmk = 5125;
  static const int _baselineP2pSellMmk = 5070;
  static const int _baselineRemitMmk = 3875;
  static const double _baselineThbPerUsd = 34.00;
  static const double _baselineMyrPerUsd = 4.12;
  static const double _baselineSgdPerUsd = 1.29;
  static const double _baselineCnyPerUsd = 6.70;
  static const double _baselineEurPerUsd = 0.91;
  static const double _baselineJpyPerUsd = 159.0;
  static const double _baselineKrwPerUsd = 1335.0;

  /// Fetches live Myanmar market USD/MMK, cross-currency FX, and spot gold online.
  Future<MarketPriceSnapshot> syncLiveMarketPrices({
    int? customUsdMarketMmk,
  }) =>
      _syncInternal(customUsdMarketMmk: customUsdMarketMmk);

  Future<MarketPriceSnapshot> _syncInternal({
    int? customUsdMarketMmk,
    MarketRateTier? overrideTier,
    GoldRateTier? overrideGoldTier,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final overrides = _loadUserOverrides(prefs);

    final savedCustomUsd = customUsdMarketMmk ?? prefs.getInt(_customUsdKey);
    final savedTier = overrideTier ??
        (savedCustomUsd != null
            ? MarketRateTier.custom
            : MarketRateTier.fromName(prefs.getString(_rateTierKey)));

    final savedCustomGold = prefs.getInt(_customGoldKey);
    final savedGoldTier = overrideGoldTier ??
        (savedCustomGold != null
            ? GoldRateTier.custom
            : GoldRateTier.fromName(prefs.getString(_goldTierKey)));

    // 1. Fetch live Myanmar FX feed, global FX cross-rates, and World Spot Gold in parallel.
    final results = await Future.wait<dynamic>([
      _fetchMyanmarLiveFeed(),
      _fetchGlobalCrossRates(),
      _fetchWorldGoldUsd(),
    ]);

    final feed = results[0] as _MyanmarFxFeed?;
    final liveGlobal = results[1] as Map<String, double>?;
    final liveGoldUsd = results[2] as double?;

    // 2. On native mobile/desktop (!kIsWeb), if feed is missing or >45 min stale,
    //    query Bybit / Bitget P2P orderbooks directly for second-by-second live rates.
    _LiveP2pQuote? directP2p;
    final feedStale = feed == null ||
        (feed.updatedAtUtc != null &&
            DateTime.now().toUtc().difference(feed.updatedAtUtc!).inMinutes >
                45);
    if (!kIsWeb && feedStale) {
      directP2p = await _fetchDirectNativeP2pQuote();
    }

    final bool hasLiveMmkFeed = feed != null || directP2p != null;
    final bool hasAnyLiveOnline =
        hasLiveMmkFeed || liveGlobal != null || liveGoldUsd != null;

    final int p2pBuy = directP2p?.buyMmk ??
        feed?.usdP2pBuyMmk ??
        _baselineP2pBuyMmk;
    final int p2pSell = directP2p?.sellMmk ??
        feed?.usdP2pSellMmk ??
        _baselineP2pSellMmk;
    final int p2pMid = directP2p?.midMmk ??
        feed?.usdP2pMidMmk ??
        ((p2pBuy + p2pSell) / 2).round();
    final int cashMarketUsd = directP2p != null
        ? ((p2pMid * 0.912) / 5).round() * 5
        : (feed?.usdCashMarketMmk ?? _baselineMarketUsdMmk);
    final int remitUsd = feed?.usdRemitMmk ?? _baselineRemitMmk;

    final MarketRateTier effectiveTier =
        (savedTier == MarketRateTier.custom && savedCustomUsd != null)
            ? MarketRateTier.custom
            : (savedTier == MarketRateTier.custom
                ? MarketRateTier.cashMarket
                : savedTier);

    final int effectiveUsdMmk = switch (effectiveTier) {
      MarketRateTier.cashMarket => cashMarketUsd,
      MarketRateTier.usdtP2p => p2pMid,
      MarketRateTier.bankRemit => remitUsd,
      MarketRateTier.custom => savedCustomUsd ?? cashMarketUsd,
    };

    // Merge global cross-rates (direct Open-ER-API preferred, fallback to feed, then baselines).
    final feedGlobal = feed?.globalRatesPerUsd ?? const <String, double>{};
    double ratePerUsd(String code, double fallback) {
      final liveVal = liveGlobal?[code];
      if (liveVal != null && liveVal > 0) return liveVal;
      final feedVal = feedGlobal[code];
      if (feedVal != null && feedVal > 0) return feedVal;
      return fallback;
    }

    final thbPerUsd = ratePerUsd('THB', _baselineThbPerUsd);
    final myrPerUsd = ratePerUsd('MYR', _baselineMyrPerUsd);
    final sgdPerUsd = ratePerUsd('SGD', _baselineSgdPerUsd);
    final krwPerUsd = ratePerUsd('KRW', _baselineKrwPerUsd);
    final jpyPerUsd = ratePerUsd('JPY', _baselineJpyPerUsd);
    final cnyPerUsd = ratePerUsd('CNY', _baselineCnyPerUsd);
    final eurPerUsd = ratePerUsd('EUR', _baselineEurPerUsd);

    final effectiveThbMmk = (effectiveUsdMmk / thbPerUsd).round();

    final worldGoldUsd = liveGoldUsd ?? feed?.worldGoldUsdPerOz ?? 3728.0;

    // 1) Yangon Real Open-Market 16-Pae Akauk Shwe (16.606g/kyat-thar) priced off live
    //    open-market USD (P2P Mid) + ~1.5% Yangon physical bullion spread.
    //    Recomputes dynamically whenever EITHER XAU/USD OR P2P USD moves live!
    final int openGold16Pae = liveGoldUsd != null || directP2p != null || feed?.goldOpenMarket16PaeMmk == null
        ? ((((worldGoldUsd / _kyattharPerTroyOzTraditional) * p2pMid) *
                    _yangonPhysicalBullionSpread) /
                5000)
            .round() *
            5000
        : feed!.goldOpenMarket16PaeMmk!;
    final int openGold15Pae =
        (((openGold16Pae * 15) / 16) / 5000).round() * 5000;

    // 2) Official YGEA / CSO reference parity (16.3293g/kyat-thar, CBM trade USD ref).
    final int ygeaGold16Pae = feed?.goldYgeaRef16PaeMmk ??
        ((((worldGoldUsd / _kyattharPerTroyOzYgea) * (remitUsd * 0.93)) / 5000)
                .round() *
            5000);
    final int ygeaGold15Pae =
        (((ygeaGold16Pae * 15) / 16) / 5000).round() * 5000;

    final GoldRateTier effectiveGoldTier =
        (savedGoldTier == GoldRateTier.custom && savedCustomGold != null)
            ? GoldRateTier.custom
            : (savedGoldTier == GoldRateTier.custom
                ? GoldRateTier.openMarket
                : savedGoldTier);

    final int effectiveGold16Pae = switch (effectiveGoldTier) {
      GoldRateTier.openMarket => openGold16Pae,
      GoldRateTier.ygeaReference => ygeaGold16Pae,
      GoldRateTier.custom => savedCustomGold ?? openGold16Pae,
    };
    final int effectiveGold15Pae =
        (((effectiveGold16Pae * 15) / 16) / 5000).round() * 5000;

    // Exact 1-unit MMK rates ordered for Myanmar & diaspora users.
    final foreignRatesMmk = <String, double>{
      'USD': effectiveUsdMmk.toDouble(),
      'THB': double.parse((effectiveUsdMmk / thbPerUsd).toStringAsFixed(1)),
      'MYR': double.parse((effectiveUsdMmk / myrPerUsd).toStringAsFixed(1)),
      'SGD': double.parse((effectiveUsdMmk / sgdPerUsd).toStringAsFixed(0)),
      'KRW': double.parse((effectiveUsdMmk / krwPerUsd).toStringAsFixed(2)),
      'JPY': double.parse((effectiveUsdMmk / jpyPerUsd).toStringAsFixed(1)),
      'CNY': double.parse((effectiveUsdMmk / cnyPerUsd).toStringAsFixed(1)),
      'EUR': double.parse((effectiveUsdMmk / eurPerUsd).toStringAsFixed(0)),
    };

    final ratio = effectiveUsdMmk / _baselineMarketUsdMmk;
    final defaults = MarketPriceSnapshot.defaultCommodities();
    final updatedCommodities = <String, CommodityPrice>{};
    for (final entry in defaults.entries) {
      final customPrice = overrides[entry.key];
      if (customPrice != null && customPrice > 0) {
        updatedCommodities[entry.key] =
            entry.value.copyWith(currentPriceMmk: customPrice);
      } else {
        final step = entry.value.basePriceMmk >= 1000 ? 50 : 10;
        final scaledPrice =
            ((entry.value.basePriceMmk * ratio) / step).round() * step;
        updatedCommodities[entry.key] = entry.value.copyWith(
          currentPriceMmk:
              scaledPrice > 0 ? scaledPrice : entry.value.basePriceMmk,
        );
      }
    }

    final liveSources = <String>[
      if (directP2p != null) ...directP2p.sources,
      if (feed != null) ...feed.sources,
      if (liveGlobal != null && !(feed?.sources.contains('Open-ER-API') ?? false))
        'Open-ER-API',
      if (liveGoldUsd != null && !(feed?.sources.contains('Gold-API') ?? false))
        'Gold-API',
    ];

    final tierTag = switch (effectiveTier) {
      MarketRateTier.cashMarket => 'ပြင်ပပေါက်ဈေး Live',
      MarketRateTier.usdtP2p => 'USDT P2P Live (ဝယ် $p2pSell/ရောင်း $p2pBuy)',
      MarketRateTier.bankRemit => 'ဘဏ်/ငွေလွှဲ Live',
      MarketRateTier.custom => 'မိမိသတ်မှတ်နှုန်း',
    };

    final sourceNote = hasAnyLiveOnline
        ? '$tierTag • 1 USD ≈ $effectiveUsdMmk ကျပ် • 1 MYR ≈ ${foreignRatesMmk['MYR']?.round()} ကျပ် • XAU \$${worldGoldUsd.toStringAsFixed(0)}/oz'
        : 'Offline ခန့်မှန်းပေါက်ဈေး (1 USD ≈ $effectiveUsdMmk ကျပ်)';

    return MarketPriceSnapshot(
      usdMarketMmk: effectiveUsdMmk,
      thbMarketMmk: effectiveThbMmk,
      worldGoldUsdPerOz: double.parse(worldGoldUsd.toStringAsFixed(1)),
      myanmarGold16PaeMmk: effectiveGold16Pae,
      myanmarGold15PaeMmk: effectiveGold15Pae,
      goldOpenMarket16PaeMmk: openGold16Pae,
      goldOpenMarket15PaeMmk: openGold15Pae,
      goldYgeaRef16PaeMmk: ygeaGold16Pae,
      goldYgeaRef15PaeMmk: ygeaGold15Pae,
      activeGoldTier: effectiveGoldTier,
      usdCashMarketMmk: cashMarketUsd,
      usdP2pBuyMmk: p2pBuy,
      usdP2pSellMmk: p2pSell,
      usdP2pMidMmk: p2pMid,
      usdRemitMmk: remitUsd,
      activeRateTier: effectiveTier,
      feedUpdatedAtUtc: directP2p != null
          ? DateTime.now().toUtc()
          : feed?.updatedAtUtc,
      liveSources: liveSources,
      foreignRatesMmk: foreignRatesMmk,
      commodities: updatedCommodities,
      lastSyncedAt: DateTime.now(),
      isOnlineLive: hasAnyLiveOnline,
      sourceNote: sourceNote,
    );
  }

  /// Switches between Live Market Cash, Live USDT P2P, and Live Bank/Remit tiers.
  Future<MarketPriceSnapshot> setMarketRateTier(MarketRateTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rateTierKey, tier.name);
    if (tier != MarketRateTier.custom) {
      await prefs.remove(_customUsdKey);
    }
    return _syncInternal(overrideTier: tier);
  }

  /// Resets any manual custom USD override back to automated live Myanmar market sync.
  Future<MarketPriceSnapshot> resetToLiveMarketRate() async {
    return setMarketRateTier(MarketRateTier.cashMarket);
  }

  /// Switches between Live Yangon Open-Market Gold and Official YGEA Reference Gold.
  Future<MarketPriceSnapshot> setGoldRateTier(GoldRateTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goldTierKey, tier.name);
    if (tier != GoldRateTier.custom) {
      await prefs.remove(_customGoldKey);
    }
    return _syncInternal(overrideGoldTier: tier);
  }

  /// Resets custom gold override back to real-time Yangon open-market live gold sync.
  Future<MarketPriceSnapshot> resetToLiveGoldPrice() async {
    return setGoldRateTier(GoldRateTier.openMarket);
  }

  /// Updates the Myanmar market USD/MMK rate manually, scaling all currencies, commodities, and gold.
  Future<MarketPriceSnapshot> updateUsdMarketRate(int newUsdMmk) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customUsdKey, newUsdMmk);
    await prefs.setString(_rateTierKey, MarketRateTier.custom.name);
    await prefs.remove(_customOverridesKey);
    return _syncInternal(
      customUsdMarketMmk: newUsdMmk,
      overrideTier: MarketRateTier.custom,
    );
  }

  /// Updates the Myanmar 16-Pae-Yae gold price (၁ ကျပ်သား) and recalculates 15-Pae-Yae.
  Future<MarketPriceSnapshot> updateMyanmarGoldPrice(int newGold16PaeMmk) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customGoldKey, newGold16PaeMmk);
    await prefs.setString(_goldTierKey, GoldRateTier.custom.name);
    return _syncInternal(overrideGoldTier: GoldRateTier.custom);
  }

  /// Overrides a single commodity's 1-unit (e.g. ၁ ပိဿာ) market price.
  Future<MarketPriceSnapshot> updateSingleCommodityPrice({
    required MarketPriceSnapshot current,
    required String commodityId,
    required int newUnitPriceMmk,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final overrides = _loadUserOverrides(prefs);
    overrides[commodityId] = newUnitPriceMmk;
    await prefs.setString(_customOverridesKey, jsonEncode(overrides));

    final updatedMap = Map<String, CommodityPrice>.from(current.commodities);
    final existing = updatedMap[commodityId];
    if (existing != null) {
      updatedMap[commodityId] =
          existing.copyWith(currentPriceMmk: newUnitPriceMmk);
    }
    return MarketPriceSnapshot(
      usdMarketMmk: current.usdMarketMmk,
      thbMarketMmk: current.thbMarketMmk,
      worldGoldUsdPerOz: current.worldGoldUsdPerOz,
      myanmarGold16PaeMmk: current.myanmarGold16PaeMmk,
      myanmarGold15PaeMmk: current.myanmarGold15PaeMmk,
      goldOpenMarket16PaeMmk: current.goldOpenMarket16PaeMmk,
      goldOpenMarket15PaeMmk: current.goldOpenMarket15PaeMmk,
      goldYgeaRef16PaeMmk: current.goldYgeaRef16PaeMmk,
      goldYgeaRef15PaeMmk: current.goldYgeaRef15PaeMmk,
      activeGoldTier: current.activeGoldTier,
      usdCashMarketMmk: current.usdCashMarketMmk,
      usdP2pBuyMmk: current.usdP2pBuyMmk,
      usdP2pSellMmk: current.usdP2pSellMmk,
      usdP2pMidMmk: current.usdP2pMidMmk,
      usdRemitMmk: current.usdRemitMmk,
      activeRateTier: current.activeRateTier,
      feedUpdatedAtUtc: current.feedUpdatedAtUtc,
      liveSources: current.liveSources,
      foreignRatesMmk: current.foreignRatesMmk,
      commodities: updatedMap,
      lastSyncedAt: DateTime.now(),
      isOnlineLive: current.isOnlineLive,
      sourceNote: current.sourceNote,
    );
  }

  Future<_MyanmarFxFeed?> _fetchMyanmarLiveFeed() async {
    try {
      final bucket = DateTime.now().millisecondsSinceEpoch ~/ (5 * 60 * 1000);
      final uri = Uri.parse('$liveMyanmarFxFeedUrl?t=$bucket');
      final resp = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 7));
      if (resp.statusCode != 200) return null;

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final cash = (decoded['usdCashMarketMmk'] as num?)?.round();
      final buy = (decoded['usdP2pBuyMmk'] as num?)?.round();
      final sell = (decoded['usdP2pSellMmk'] as num?)?.round();
      final mid = (decoded['usdP2pMidMmk'] as num?)?.round();
      final remit = (decoded['usdRemitMmk'] as num?)?.round();
      if (cash == null || cash < 2500 || cash > 15000) return null;

      final rawGlobal = decoded['globalRatesPerUsd'];
      final globalMap = <String, double>{};
      if (rawGlobal is Map<String, dynamic>) {
        for (final entry in rawGlobal.entries) {
          if (entry.value is num && (entry.value as num) > 0) {
            globalMap[entry.key] = (entry.value as num).toDouble();
          }
        }
      }

      final sourcesRaw = decoded['sources'];
      final sources = sourcesRaw is List
          ? sourcesRaw.whereType<String>().toList()
          : const <String>[];

      return _MyanmarFxFeed(
        usdCashMarketMmk: cash,
        usdP2pBuyMmk: buy ?? _baselineP2pBuyMmk,
        usdP2pSellMmk: sell ?? _baselineP2pSellMmk,
        usdP2pMidMmk: mid ?? ((buy ?? _baselineP2pBuyMmk) + (sell ?? _baselineP2pSellMmk)) ~/ 2,
        usdRemitMmk: remit ?? _baselineRemitMmk,
        worldGoldUsdPerOz: (decoded['worldGoldUsdPerOz'] as num?)?.toDouble(),
        goldOpenMarket16PaeMmk:
            (decoded['goldOpenMarket16PaeMmk'] as num?)?.round(),
        goldYgeaRef16PaeMmk: (decoded['goldYgeaRef16PaeMmk'] as num?)?.round(),
        globalRatesPerUsd: globalMap,
        updatedAtUtc:
            DateTime.tryParse((decoded['updatedAtUtc'] as String?) ?? ''),
        sources: sources,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, double>?> _fetchGlobalCrossRates() async {
    try {
      final resp = await _httpClient
          .get(Uri.parse(_liveExchangeApiUrl))
          .timeout(const Duration(seconds: 7));
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final rates = decoded['rates'];
      if (rates is! Map<String, dynamic>) return null;
      return {
        for (final code in const [
          'THB',
          'MYR',
          'SGD',
          'KRW',
          'JPY',
          'CNY',
          'EUR',
          'MMK',
        ])
          if (rates[code] is num && (rates[code] as num) > 0)
            code: (rates[code] as num).toDouble(),
      };
    } catch (_) {
      return null;
    }
  }

  Future<double?> _fetchWorldGoldUsd() async {
    try {
      final resp = await _httpClient
          .get(Uri.parse(_liveGoldApiUrl))
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final price = (decoded['price'] as num?)?.toDouble();
        if (price != null && price > 1500 && price < 10000) return price;
      }
    } catch (_) {}

    // 24/7 Bitget PAXG/USDT spot fallback on native platforms (trades even on weekends).
    if (!kIsWeb) {
      try {
        final resp = await _httpClient
            .get(Uri.parse(_bitgetPaxgUrl))
            .timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
          final list = decoded['data'];
          if (list is List && list.isNotEmpty && list.first is Map) {
            final price = double.tryParse('${(list.first as Map)['lastPr']}');
            if (price != null && price > 1500 && price < 10000) return price;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<_LiveP2pQuote?> _fetchDirectNativeP2pQuote() async {
    final buys = <double>[];
    final sells = <double>[];
    final sources = <String>[];

    // Query Bybit P2P USDT/MMK Buy (side=1) & Sell (side=0)
    try {
      var foundBybit = false;
      for (final side in const ['1', '0']) {
        final resp = await _httpClient
            .post(
              Uri.parse(_bybitP2pUrl),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'tokenId': 'USDT',
                'currencyId': 'MMK',
                'side': side,
                'size': '5',
                'page': '1',
              }),
            )
            .timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
          final items =
              ((decoded['result'] as Map<String, dynamic>?)?['items'] as List?) ??
                  const [];
          for (final item in items.whereType<Map<String, dynamic>>()) {
            final p = double.tryParse('${item['price']}');
            if (p != null && p >= 2500 && p <= 15000) {
              foundBybit = true;
              if (side == '1') {
                buys.add(p);
              } else {
                sells.add(p);
              }
            }
          }
        }
      }
      if (foundBybit) sources.add('Bybit P2P Direct');
    } catch (_) {}

    // Query Bitget P2P USDT/MMK Buy (side=1) & Sell (side=2)
    try {
      var foundBitget = false;
      for (final side in const [1, 2]) {
        final resp = await _httpClient
            .post(
              Uri.parse(_bitgetP2pUrl),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'side': side,
                'pageNo': 1,
                'pageSize': 5,
                'coinCode': 'USDT',
                'fiatCode': 'MMK',
                'languageType': 0,
              }),
            )
            .timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
          final items =
              ((decoded['data'] as Map<String, dynamic>?)?['dataList'] as List?) ??
                  const [];
          for (final item in items.whereType<Map<String, dynamic>>()) {
            final p = double.tryParse('${item['price']}');
            if (p != null && p >= 2500 && p <= 15000) {
              foundBitget = true;
              if (side == 1) {
                buys.add(p);
              } else {
                sells.add(p);
              }
            }
          }
        }
      }
      if (foundBitget) sources.add('Bitget P2P Direct');
    } catch (_) {}

    if (buys.isEmpty && sells.isEmpty) return null;

    int medianOf(List<double> list) {
      final sorted = [...list]..sort();
      final mid = sorted.length ~/ 2;
      if (sorted.length.isOdd) return sorted[mid].round();
      return ((sorted[mid - 1] + sorted[mid]) / 2).round();
    }

    final buyMed = buys.isNotEmpty ? medianOf(buys) : medianOf(sells);
    final sellMed = sells.isNotEmpty ? medianOf(sells) : medianOf(buys);
    final midVal = ((buyMed + sellMed) / 2).round();

    return _LiveP2pQuote(
      buyMmk: buyMed,
      sellMmk: sellMed,
      midMmk: midVal,
      sources: sources,
    );
  }

  Map<String, int> _loadUserOverrides(SharedPreferences prefs) {
    final raw = prefs.getString(_customOverridesKey);
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          if (entry.value is num) entry.key: (entry.value as num).toInt(),
      };
    } catch (_) {
      return <String, int>{};
    }
  }
}

class _MyanmarFxFeed {
  const _MyanmarFxFeed({
    required this.usdCashMarketMmk,
    required this.usdP2pBuyMmk,
    required this.usdP2pSellMmk,
    required this.usdP2pMidMmk,
    required this.usdRemitMmk,
    required this.worldGoldUsdPerOz,
    this.goldOpenMarket16PaeMmk,
    this.goldYgeaRef16PaeMmk,
    required this.globalRatesPerUsd,
    required this.updatedAtUtc,
    required this.sources,
  });

  final int usdCashMarketMmk;
  final int usdP2pBuyMmk;
  final int usdP2pSellMmk;
  final int usdP2pMidMmk;
  final int usdRemitMmk;
  final double? worldGoldUsdPerOz;
  final int? goldOpenMarket16PaeMmk;
  final int? goldYgeaRef16PaeMmk;
  final Map<String, double> globalRatesPerUsd;
  final DateTime? updatedAtUtc;
  final List<String> sources;
}

class _LiveP2pQuote {
  const _LiveP2pQuote({
    required this.buyMmk,
    required this.sellMmk,
    required this.midMmk,
    required this.sources,
  });

  final int buyMmk;
  final int sellMmk;
  final int midMmk;
  final List<String> sources;
}
