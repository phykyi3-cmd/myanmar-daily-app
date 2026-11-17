import 'commodity_price.dart';
import 'recipe.dart';

/// Strictly supports ONLY the 6 requested ASEAN & East Asian countries.
enum SupportedMarketCountry {
  mm(
    isoCode: 'MM',
    flag: '🇲🇲',
    nameMm: 'မြန်မာ',
    currencyCode: 'MMK',
    currencyLabelMm: 'ကျပ်',
    decimalPlaces: 0,
    unitBasisNoteMm: '၁ ပိဿာ (1.63 kg) / မြန်မာဈေးနှုန်း',
  ),
  th(
    isoCode: 'TH',
    flag: '🇹🇭',
    nameMm: 'ထိုင်း',
    currencyCode: 'THB',
    currencyLabelMm: 'ဘတ်',
    decimalPlaces: 0,
    unitBasisNoteMm: 'ထိုင်းလက်လီဈေး (၁.၆ kg / ပုံမှန်အစည်း)',
  ),
  my(
    isoCode: 'MY',
    flag: '🇲🇾',
    nameMm: 'မလေးရှား',
    currencyCode: 'MYR',
    currencyLabelMm: 'RM',
    decimalPlaces: 2,
    unitBasisNoteMm: 'မလေးရှားဈေး (၁.၆ kg / ပုံမှန်အစည်း)',
  ),
  sg(
    isoCode: 'SG',
    flag: '🇸🇬',
    nameMm: 'စင်ကာပူ',
    currencyCode: 'SGD',
    currencyLabelMm: 'S\$',
    decimalPlaces: 2,
    unitBasisNoteMm: 'စင်ကာပူဈေး (၁.၆ kg / ပုံမှန်အစည်း)',
  ),
  kr(
    isoCode: 'KR',
    flag: '🇰🇷',
    nameMm: 'ကိုရီးယား',
    currencyCode: 'KRW',
    currencyLabelMm: '₩',
    decimalPlaces: 0,
    unitBasisNoteMm: 'ကိုရီးယား Mart ဈေး (၁.၆ kg / ပုံမှန်အစည်း)',
  ),
  jp(
    isoCode: 'JP',
    flag: '🇯🇵',
    nameMm: 'ဂျပန်',
    currencyCode: 'JPY',
    currencyLabelMm: '¥',
    decimalPlaces: 0,
    unitBasisNoteMm: 'ဂျပန် Super ဈေး (၁.၆ kg / ပုံမှန်အစည်း)',
  );

  const SupportedMarketCountry({
    required this.isoCode,
    required this.flag,
    required this.nameMm,
    required this.currencyCode,
    required this.currencyLabelMm,
    required this.decimalPlaces,
    required this.unitBasisNoteMm,
  });

  final String isoCode;
  final String flag;
  final String nameMm;
  final String currencyCode;
  final String currencyLabelMm;
  final int decimalPlaces;
  final String unitBasisNoteMm;

  /// Returns matching country ONLY for `MM, TH, MY, SG, KR, JP`; `null` for any other country.
  static SupportedMarketCountry? fromIsoCode(String? code) {
    final upper = (code ?? '').trim().toUpperCase();
    for (final c in SupportedMarketCountry.values) {
      if (c.isoCode == upper) return c;
    }
    return null;
  }

  /// Formats a numeric amount cleanly in this country's local currency format.
  String formatAmount(double amount) {
    final isNeg = amount < 0;
    final absVal = amount.abs();
    final prefix = isNeg ? '-' : '';
    if (decimalPlaces > 0) {
      final fixed = absVal.toStringAsFixed(decimalPlaces);
      final parts = fixed.split('.');
      final intPart = _groupThousands(parts[0]);
      final formatted = '$intPart.${parts[1]}';
      return '$prefix$currencyLabelMm $formatted';
    }
    final intStr = _groupThousands(absVal.round().toString());
    return '$prefix$intStr $currencyLabelMm';
  }

  static String _groupThousands(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final rev = digits.length - i;
      if (i > 0 && rev % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

/// Result returned from HTTPS IP geolocation + offline timezone/locale detection.
class IpLocationResult {
  const IpLocationResult({
    this.detectedIp = '',
    this.rawCountryCode = 'MM',
    this.rawCountryName = 'Myanmar',
    this.matchedCountry,
    required this.effectiveCountry,
    this.isFromLiveIp = false,
    required this.statusSummaryMm,
  });

  final String detectedIp;
  final String rawCountryCode;
  final String rawCountryName;
  final SupportedMarketCountry? matchedCountry;
  final SupportedMarketCountry effectiveCountry;
  final bool isFromLiveIp;
  final String statusSummaryMm;

  bool get isSupportedIpCountry => matchedCountry != null;
}

/// Calibrated real-world local commodity unit prices (`MMK, THB, MYR, SGD, KRW, JPY`)
/// matched 1:1 with `recipes_mm.json` `commodityId` & `unitQuantity` baselines.
class RegionalMarketCatalog {
  const RegionalMarketCatalog._();

  static const Map<String, double> _thbBaselines = {
    'chicken': 145,
    'pork': 240,
    'beef': 420,
    'mutton': 560,
    'fish_hilsa': 380,
    'fish_general': 180,
    'prawn': 360,
    'seafood_squid': 300,
    'duck_meat': 260,
    'dried_fish': 550,
    'bamboo_shoot': 70,
    'rice_grain': 75,
    'onion': 65,
    'garlic_ginger': 140,
    'potato': 75,
    'tomato': 70,
    'cooking_oil': 105,
    'egg_chicken': 5,
    'egg_duck': 6,
    'leafy_greens': 15,
    'vegetables': 65,
    'lentils_beans': 110,
    'noodles': 55,
    'seasoning': 15,
  };

  static const Map<String, double> _myrBaselines = {
    'chicken': 17.50,
    'pork': 38.00,
    'beef': 45.00,
    'mutton': 62.00,
    'fish_hilsa': 42.00,
    'fish_general': 22.00,
    'prawn': 46.00,
    'seafood_squid': 38.00,
    'duck_meat': 34.00,
    'dried_fish': 65.00,
    'bamboo_shoot': 9.50,
    'rice_grain': 7.00,
    'onion': 7.50,
    'garlic_ginger': 16.00,
    'potato': 8.00,
    'tomato': 8.50,
    'cooking_oil': 13.50,
    'egg_chicken': 0.50,
    'egg_duck': 0.85,
    'leafy_greens': 2.20,
    'vegetables': 7.50,
    'lentils_beans': 14.00,
    'noodles': 6.50,
    'seasoning': 2.00,
  };

  static const Map<String, double> _sgdBaselines = {
    'chicken': 13.50,
    'pork': 22.00,
    'beef': 32.00,
    'mutton': 38.00,
    'fish_hilsa': 28.00,
    'fish_general': 15.50,
    'prawn': 26.00,
    'seafood_squid': 22.00,
    'duck_meat': 20.00,
    'dried_fish': 42.00,
    'bamboo_shoot': 5.80,
    'rice_grain': 5.00,
    'onion': 4.80,
    'garlic_ginger': 10.50,
    'potato': 4.80,
    'tomato': 5.50,
    'cooking_oil': 7.20,
    'egg_chicken': 0.35,
    'egg_duck': 0.55,
    'leafy_greens': 1.60,
    'vegetables': 5.20,
    'lentils_beans': 8.50,
    'noodles': 4.50,
    'seasoning': 1.50,
  };

  static const Map<String, double> _krwBaselines = {
    'chicken': 13000,
    'pork': 26000,
    'beef': 42000,
    'mutton': 38000,
    'fish_hilsa': 30000,
    'fish_general': 18000,
    'prawn': 28000,
    'seafood_squid': 24000,
    'duck_meat': 22000,
    'dried_fish': 45000,
    'bamboo_shoot': 7500,
    'rice_grain': 6500,
    'onion': 4500,
    'garlic_ginger': 13000,
    'potato': 6000,
    'tomato': 7500,
    'cooking_oil': 9500,
    'egg_chicken': 320,
    'egg_duck': 600,
    'leafy_greens': 2000,
    'vegetables': 6500,
    'lentils_beans': 10000,
    'noodles': 5500,
    'seasoning': 1800,
  };

  static const Map<String, double> _jpyBaselines = {
    'chicken': 1480,
    'pork': 2350,
    'beef': 3900,
    'mutton': 3600,
    'fish_hilsa': 2800,
    'fish_general': 1850,
    'prawn': 2900,
    'seafood_squid': 2400,
    'duck_meat': 2500,
    'dried_fish': 4200,
    'bamboo_shoot': 780,
    'rice_grain': 950,
    'onion': 520,
    'garlic_ginger': 1450,
    'potato': 680,
    'tomato': 820,
    'cooking_oil': 920,
    'egg_chicken': 28,
    'egg_duck': 65,
    'leafy_greens': 190,
    'vegetables': 680,
    'lentils_beans': 1050,
    'noodles': 560,
    'seasoning': 180,
  };

  static Map<String, double> baselineUnitPricesFor(
    SupportedMarketCountry country,
    Map<String, CommodityPrice> myanmarCommodities,
  ) {
    switch (country) {
      case SupportedMarketCountry.mm:
        return {
          for (final e in myanmarCommodities.entries)
            e.key: e.value.currentPriceMmk.toDouble(),
        };
      case SupportedMarketCountry.th:
        return Map<String, double>.from(_thbBaselines);
      case SupportedMarketCountry.my:
        return Map<String, double>.from(_myrBaselines);
      case SupportedMarketCountry.sg:
        return Map<String, double>.from(_sgdBaselines);
      case SupportedMarketCountry.kr:
        return Map<String, double>.from(_krwBaselines);
      case SupportedMarketCountry.jp:
        return Map<String, double>.from(_jpyBaselines);
    }
  }

  /// Resolves active local commodity prices combining baseline regional markets with user overrides.
  static Map<String, double> resolveUnitPrices({
    required SupportedMarketCountry country,
    required MarketPriceSnapshot snapshot,
    Map<String, double> regionalOverrides = const {},
  }) {
    final base = baselineUnitPricesFor(country, snapshot.commodities);
    if (country == SupportedMarketCountry.mm) return base;
    for (final e in regionalOverrides.entries) {
      if (e.value > 0) base[e.key] = e.value;
    }
    return base;
  }

  /// MMK value of 1 local currency unit using live FX from [MarketPriceSnapshot].
  static double mmkPerCurrencyUnit(
    SupportedMarketCountry country,
    MarketPriceSnapshot snapshot,
  ) {
    final fx = snapshot.foreignRatesMmk;
    switch (country) {
      case SupportedMarketCountry.mm:
        return 1.0;
      case SupportedMarketCountry.th:
        return fx['THB'] ?? snapshot.thbMarketMmk.toDouble();
      case SupportedMarketCountry.my:
        return fx['MYR'] ?? 1070.0;
      case SupportedMarketCountry.sg:
        return fx['SGD'] ?? 3400.0;
      case SupportedMarketCountry.kr:
        return (fx['KRW (1000)'] ?? 3330.0) / 1000.0;
      case SupportedMarketCountry.jp:
        return (fx['JPY (100)'] ?? 2900.0) / 100.0;
    }
  }

  static double convertMmkToCountry(
    int mmk,
    SupportedMarketCountry country,
    MarketPriceSnapshot snapshot,
  ) {
    if (country == SupportedMarketCountry.mm) return mmk.toDouble();
    final rate = mmkPerCurrencyUnit(country, snapshot);
    if (rate <= 0) return mmk.toDouble();
    return mmk / rate;
  }

  static int convertCountryToMmk(
    double localAmount,
    SupportedMarketCountry country,
    MarketPriceSnapshot snapshot,
  ) {
    if (country == SupportedMarketCountry.mm) return localAmount.round();
    final rate = mmkPerCurrencyUnit(country, snapshot);
    return (localAmount * rate).round();
  }

  static String formatFromMmk(
    int mmk,
    SupportedMarketCountry country,
    MarketPriceSnapshot snapshot,
  ) {
    final local = convertMmkToCountry(mmk, country, snapshot);
    return country.formatAmount(local);
  }

  /// Computes an ingredient's cost directly in the active country's currency.
  static double ingredientCostLocal({
    required RecipeIngredient ingredient,
    required SupportedMarketCountry country,
    required Map<String, double> unitPrices,
    required MarketPriceSnapshot snapshot,
  }) {
    final unitPrice = unitPrices[ingredient.commodityId];
    if (unitPrice != null) {
      return _roundCurrency(unitPrice * ingredient.unitQuantity, country);
    }
    if (country == SupportedMarketCountry.mm) {
      return ingredient.baseCostMmk.toDouble();
    }
    return _roundCurrency(
      convertMmkToCountry(ingredient.baseCostMmk, country, snapshot),
      country,
    );
  }

  /// Computes a dish's total cost directly in the active country's currency.
  static double recipeTotalLocal({
    required Recipe recipe,
    required SupportedMarketCountry country,
    required Map<String, double> unitPrices,
    required MarketPriceSnapshot snapshot,
  }) {
    var sum = 0.0;
    for (final ing in recipe.ingredients) {
      sum += ingredientCostLocal(
        ingredient: ing,
        country: country,
        unitPrices: unitPrices,
        snapshot: snapshot,
      );
    }
    return _roundCurrency(sum, country);
  }

  static String ingredientUnitSummary({
    required RecipeIngredient ingredient,
    required SupportedMarketCountry country,
    required MarketPriceSnapshot snapshot,
    required Map<String, double> unitPrices,
  }) {
    final commodity = snapshot.commodities[ingredient.commodityId];
    final price = unitPrices[ingredient.commodityId];
    if (commodity == null || price == null) return '';
    final unitDesc = country == SupportedMarketCountry.mm
        ? commodity.unitLabelMm
        : _regionalUnitLabel(commodity);
    return '$unitDesc ${country.formatAmount(price)} နှုန်း';
  }

  static String _regionalUnitLabel(CommodityPrice commodity) {
    if (commodity.unitLabelMm == '၁ ပိဿာ') return '~၁.၆ kg (၁ ပိဿာစာ)';
    return commodity.unitLabelMm;
  }

  static double _roundCurrency(double val, SupportedMarketCountry country) {
    if (country.decimalPlaces == 0) return val.roundToDouble();
    return double.parse(val.toStringAsFixed(country.decimalPlaces));
  }
}
