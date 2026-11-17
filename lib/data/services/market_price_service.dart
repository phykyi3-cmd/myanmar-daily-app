import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/commodity_price.dart';

/// Fetches live online exchange rates (USD, THB, SGD, CNY, MYR, EUR, JPY, KRW)
/// and live World Spot Gold (XAU/USD), dynamically computing Myanmar gold
/// (၁၆ ပဲရည် / ၁၅ ပဲရည်) and 24 kitchen commodity prices.
class MarketPriceService {
  static const String _liveExchangeApiUrl =
      'https://open.er-api.com/v6/latest/USD';
  static const String _liveGoldApiUrl = 'https://api.gold-api.com/price/XAU';
  static const String _customOverridesKey = 'user_commodity_overrides_v2';
  static const int _baselineMarketUsdMmk = 4500;
  static const double _baselineThbPerUsd = 34.00;
  static const double _baselineCnyPerUsd = 7.15;

  /// Fetches live currency rates and spot gold online, scaling Myanmar gold, FX, and commodity prices.
  Future<MarketPriceSnapshot> syncLiveMarketPrices({
    int? customUsdMarketMmk,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final overrides = _loadUserOverrides(prefs);

    double? liveXauUsd;
    try {
      final goldResp = await http
          .get(Uri.parse(_liveGoldApiUrl))
          .timeout(const Duration(seconds: 6));
      if (goldResp.statusCode == 200) {
        final gJson = jsonDecode(goldResp.body) as Map<String, dynamic>;
        liveXauUsd = (gJson['price'] as num?)?.toDouble();
      }
    } catch (_) {}

    try {
      final response = await http
          .get(Uri.parse(_liveExchangeApiUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = (decoded['rates'] as Map<String, dynamic>?) ?? const {};
        final thbPerUsd =
            (rates['THB'] as num?)?.toDouble() ?? _baselineThbPerUsd;
        final cnyPerUsd =
            (rates['CNY'] as num?)?.toDouble() ?? _baselineCnyPerUsd;
        final sgdPerUsd = (rates['SGD'] as num?)?.toDouble() ?? 1.32;
        final myrPerUsd = (rates['MYR'] as num?)?.toDouble() ?? 4.20;
        final eurPerUsd = (rates['EUR'] as num?)?.toDouble() ?? 0.91;
        final jpyPerUsd = (rates['JPY'] as num?)?.toDouble() ?? 155.0;
        final krwPerUsd = (rates['KRW'] as num?)?.toDouble() ?? 1350.0;
        final officialMmk = (rates['MMK'] as num?)?.toDouble() ?? 2100.0;

        // Compute live regional trade basket index (THB + CNY movement vs USD).
        final thbDrift = thbPerUsd / _baselineThbPerUsd;
        final cnyDrift = cnyPerUsd / _baselineCnyPerUsd;
        final liveBasketFactor = (thbDrift * 0.6) + (cnyDrift * 0.4);

        final liveDerivedUsdMmk = officialMmk > 3000
            ? officialMmk.round()
            : ((_baselineMarketUsdMmk * liveBasketFactor) / 10).round() * 10;

        final effectiveUsdMmk = customUsdMarketMmk ??
            prefs.getInt('user_usd_market_mmk') ??
            liveDerivedUsdMmk;
        final effectiveThbMmk = (effectiveUsdMmk / thbPerUsd).round();

        final worldGoldUsd = liveXauUsd ?? 3885.0;
        // Myanmar 16-Pae-Yae (အခေါက်ရွှေ ၁ ကျပ်သား) = (World Gold USD/oz / 1.875) * market USD rate
        final computedGold16Pae =
            (((worldGoldUsd / 1.875) * effectiveUsdMmk) / 5000).round() * 5000;
        final effectiveGold16Pae =
            prefs.getInt('user_gold_16pae_mmk') ?? computedGold16Pae;
        final effectiveGold15Pae =
            (((effectiveGold16Pae * 15) / 16) / 5000).round() * 5000;

        final foreignRatesMmk = <String, double>{
          'USD': effectiveUsdMmk.toDouble(),
          'THB': double.parse((effectiveUsdMmk / thbPerUsd).toStringAsFixed(1)),
          'SGD': double.parse((effectiveUsdMmk / sgdPerUsd).toStringAsFixed(0)),
          'CNY': double.parse((effectiveUsdMmk / cnyPerUsd).toStringAsFixed(1)),
          'MYR': double.parse((effectiveUsdMmk / myrPerUsd).toStringAsFixed(1)),
          'EUR': double.parse((effectiveUsdMmk / eurPerUsd).toStringAsFixed(0)),
          'JPY (100)': double.parse(
            ((effectiveUsdMmk / jpyPerUsd) * 100).toStringAsFixed(0),
          ),
          'KRW (1000)': double.parse(
            ((effectiveUsdMmk / krwPerUsd) * 1000).toStringAsFixed(0),
          ),
        };

        final ratio = effectiveUsdMmk / _baselineMarketUsdMmk;
        final defaults = MarketPriceSnapshot.defaultCommodities();
        final updated = <String, CommodityPrice>{};

        for (final entry in defaults.entries) {
          final customPrice = overrides[entry.key];
          if (customPrice != null && customPrice > 0) {
            updated[entry.key] =
                entry.value.copyWith(currentPriceMmk: customPrice);
          } else {
            final step = entry.value.basePriceMmk >= 1000 ? 50 : 10;
            final scaledPrice =
                ((entry.value.basePriceMmk * ratio) / step).round() * step;
            updated[entry.key] = entry.value.copyWith(
              currentPriceMmk:
                  scaledPrice > 0 ? scaledPrice : entry.value.basePriceMmk,
            );
          }
        }

        final snapshot = MarketPriceSnapshot(
          usdMarketMmk: effectiveUsdMmk,
          thbMarketMmk: effectiveThbMmk,
          worldGoldUsdPerOz:
              double.parse(worldGoldUsd.toStringAsFixed(1)),
          myanmarGold16PaeMmk: effectiveGold16Pae,
          myanmarGold15PaeMmk: effectiveGold15Pae,
          foreignRatesMmk: foreignRatesMmk,
          commodities: updated,
          lastSyncedAt: DateTime.now(),
          isOnlineLive: true,
          sourceNote:
              'Online Live (1 USD ≈ $effectiveUsdMmk ကျပ် • 1 THB ≈ $effectiveThbMmk ကျပ် • ကမ္ဘာ့ရွှေ \$${worldGoldUsd.toStringAsFixed(0)}/oz)',
        );
        return snapshot;
      }
    } catch (_) {
      // Fall back to local scaled snapshot when offline.
    }

    final savedUsd = customUsdMarketMmk ??
        prefs.getInt('user_usd_market_mmk') ??
        _baselineMarketUsdMmk;
    final worldGoldUsd = liveXauUsd ?? 3885.0;
    final computedGold16 =
        (((worldGoldUsd / 1.875) * savedUsd) / 5000).round() * 5000;
    final effectiveGold16 = prefs.getInt('user_gold_16pae_mmk') ?? computedGold16;
    final effectiveGold15 =
        (((effectiveGold16 * 15) / 16) / 5000).round() * 5000;

    final ratio = savedUsd / _baselineMarketUsdMmk;
    final defaults = MarketPriceSnapshot.defaultCommodities();
    final fallbackMap = <String, CommodityPrice>{};
    for (final entry in defaults.entries) {
      final customPrice = overrides[entry.key];
      final step = entry.value.basePriceMmk >= 1000 ? 50 : 10;
      final scaledPrice =
          ((entry.value.basePriceMmk * ratio) / step).round() * step;
      fallbackMap[entry.key] = entry.value.copyWith(
        currentPriceMmk: customPrice ?? scaledPrice,
      );
    }

    return MarketPriceSnapshot(
      usdMarketMmk: savedUsd,
      thbMarketMmk: (savedUsd / _baselineThbPerUsd).round(),
      worldGoldUsdPerOz: worldGoldUsd,
      myanmarGold16PaeMmk: effectiveGold16,
      myanmarGold15PaeMmk: effectiveGold15,
      commodities: fallbackMap,
      lastSyncedAt: DateTime.now(),
      isOnlineLive: false,
      sourceNote: 'Offline ခန့်မှန်းပေါက်ဈေး (1 USD ≈ $savedUsd ကျပ်)',
    );
  }

  /// Updates the Myanmar market USD/MMK rate, clears individual overrides so all
  /// commodities and gold prices scale dynamically with the new USD rate, and re-syncs.
  Future<MarketPriceSnapshot> updateUsdMarketRate(int newUsdMmk) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_usd_market_mmk', newUsdMmk);
    await prefs.remove(_customOverridesKey);
    await prefs.remove('user_gold_16pae_mmk');
    return syncLiveMarketPrices(customUsdMarketMmk: newUsdMmk);
  }

  /// Updates the Myanmar 16-Pae-Yae gold price (၁ ကျပ်သား) and recalculates 15-Pae-Yae.
  Future<MarketPriceSnapshot> updateMyanmarGoldPrice(int newGold16PaeMmk) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_gold_16pae_mmk', newGold16PaeMmk);
    return syncLiveMarketPrices();
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
      foreignRatesMmk: current.foreignRatesMmk,
      commodities: updatedMap,
      lastSyncedAt: DateTime.now(),
      isOnlineLive: current.isOnlineLive,
      sourceNote: current.sourceNote,
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
