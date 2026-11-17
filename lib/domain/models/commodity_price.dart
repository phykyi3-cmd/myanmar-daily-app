/// Standard unit commodity price in Myanmar markets (e.g., 1 Viss / ၁ ပိဿာ).
class CommodityPrice {
  const CommodityPrice({
    required this.id,
    required this.nameMm,
    required this.unitLabelMm,
    required this.basePriceMmk,
    required this.currentPriceMmk,
  });

  final String id;
  final String nameMm;
  final String unitLabelMm;
  final int basePriceMmk;
  final int currentPriceMmk;

  CommodityPrice copyWith({int? currentPriceMmk}) {
    return CommodityPrice(
      id: id,
      nameMm: nameMm,
      unitLabelMm: unitLabelMm,
      basePriceMmk: basePriceMmk,
      currentPriceMmk: currentPriceMmk ?? this.currentPriceMmk,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'currentPriceMmk': currentPriceMmk,
      };
}

/// Snapshot of online-synced Myanmar currency, gold (XAU & 16/15 Pae Yae), and commodity unit prices.
class MarketPriceSnapshot {
  const MarketPriceSnapshot({
    required this.usdMarketMmk,
    required this.thbMarketMmk,
    this.worldGoldUsdPerOz = 3885.0,
    this.myanmarGold16PaeMmk = 6850000,
    this.myanmarGold15PaeMmk = 6420000,
    this.foreignRatesMmk = const {
      'USD': 4500,
      'THB': 133,
      'SGD': 3490,
      'CNY': 670,
      'MYR': 1100,
      'EUR': 4950,
      'JPY (100)': 2820,
      'KRW (1000)': 3360,
    },
    required this.commodities,
    required this.lastSyncedAt,
    required this.isOnlineLive,
    required this.sourceNote,
  });

  final int usdMarketMmk;
  final int thbMarketMmk;
  final double worldGoldUsdPerOz;
  final int myanmarGold16PaeMmk;
  final int myanmarGold15PaeMmk;
  final Map<String, double> foreignRatesMmk;
  final Map<String, CommodityPrice> commodities;
  final DateTime lastSyncedAt;
  final bool isOnlineLive;
  final String sourceNote;

  /// Baseline Myanmar market unit prices (at reference USD = 4,500 MMK).
  static Map<String, CommodityPrice> defaultCommodities() {
    const items = <CommodityPrice>[
      CommodityPrice(
        id: 'chicken',
        nameMm: 'ကြက်သား',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 24000,
        currentPriceMmk: 24000,
      ),
      CommodityPrice(
        id: 'pork',
        nameMm: 'ဝက်သား',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 28000,
        currentPriceMmk: 28000,
      ),
      CommodityPrice(
        id: 'beef',
        nameMm: 'အမဲသား',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 26000,
        currentPriceMmk: 26000,
      ),
      CommodityPrice(
        id: 'mutton',
        nameMm: 'ဆိတ်သား',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 38000,
        currentPriceMmk: 38000,
      ),
      CommodityPrice(
        id: 'fish_hilsa',
        nameMm: 'ငါးသလောက်',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 30000,
        currentPriceMmk: 30000,
      ),
      CommodityPrice(
        id: 'fish_general',
        nameMm: 'ငါးခူ / ငါးကြင်း / ငါးဖယ်',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 20000,
        currentPriceMmk: 20000,
      ),
      CommodityPrice(
        id: 'prawn',
        nameMm: 'ပုစွန်လတ်',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 32000,
        currentPriceMmk: 32000,
      ),
      CommodityPrice(
        id: 'seafood_squid',
        nameMm: 'ကင်းမွန် / ရေဘဝဲ / ပင်လယ်ငါး',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 28000,
        currentPriceMmk: 28000,
      ),
      CommodityPrice(
        id: 'duck_meat',
        nameMm: 'ဘဲသား',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 25000,
        currentPriceMmk: 25000,
      ),
      CommodityPrice(
        id: 'dried_fish',
        nameMm: 'ငါးခြောက် / ပုစွန်ခြောက်',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 55000,
        currentPriceMmk: 55000,
      ),
      CommodityPrice(
        id: 'bamboo_shoot',
        nameMm: 'မျှစ် / မျှစ်ချဉ် / မုန်ညင်းချဉ်',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 6000,
        currentPriceMmk: 6000,
      ),
      CommodityPrice(
        id: 'rice_grain',
        nameMm: 'ဆန် / ကောက်ညှင်း / ပြောင်းဖူးစေ့',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 5000,
        currentPriceMmk: 5000,
      ),
      CommodityPrice(
        id: 'onion',
        nameMm: 'ကြက်သွန်နီ',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 6000,
        currentPriceMmk: 6000,
      ),
      CommodityPrice(
        id: 'garlic_ginger',
        nameMm: 'ကြက်သွန်ဖြူ / ဂျင်း',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 14000,
        currentPriceMmk: 14000,
      ),
      CommodityPrice(
        id: 'potato',
        nameMm: 'အာလူး',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 6500,
        currentPriceMmk: 6500,
      ),
      CommodityPrice(
        id: 'tomato',
        nameMm: 'ခရမ်းချဉ်သီး',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 5500,
        currentPriceMmk: 5500,
      ),
      CommodityPrice(
        id: 'cooking_oil',
        nameMm: 'စားဆီ (ပဲဆီ/နေကြာဆီ)',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 16000,
        currentPriceMmk: 16000,
      ),
      CommodityPrice(
        id: 'egg_chicken',
        nameMm: 'ကြက်ဥ',
        unitLabelMm: '၁ လုံး',
        basePriceMmk: 550,
        currentPriceMmk: 550,
      ),
      CommodityPrice(
        id: 'egg_duck',
        nameMm: 'ဘဲဥ',
        unitLabelMm: '၁ လုံး',
        basePriceMmk: 650,
        currentPriceMmk: 650,
      ),
      CommodityPrice(
        id: 'leafy_greens',
        nameMm: 'ချဉ်ပေါင် / ကန်စွန်း / ဟင်းရွက်',
        unitLabelMm: '၁ စည်း',
        basePriceMmk: 500,
        currentPriceMmk: 500,
      ),
      CommodityPrice(
        id: 'vegetables',
        nameMm: 'ဘူးသီး / ခရမ်းသီး / ဂေါ်ဖီ / အသီးအနှံ',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 4500,
        currentPriceMmk: 4500,
      ),
      CommodityPrice(
        id: 'lentils_beans',
        nameMm: 'ပဲနီလေး / ကုလားပဲ / တို့ဟူး',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 11000,
        currentPriceMmk: 11000,
      ),
      CommodityPrice(
        id: 'noodles',
        nameMm: 'မုန့်ဖတ် / ခေါက်ဆွဲ / နန်းကြီးဖတ်',
        unitLabelMm: '၁ ပိဿာ',
        basePriceMmk: 4000,
        currentPriceMmk: 4000,
      ),
      CommodityPrice(
        id: 'seasoning',
        nameMm: 'မဆလာ / ငါးပိ / ငံပြာရည် / ဟင်းခတ်',
        unitLabelMm: '၁ ပွဲစာ',
        basePriceMmk: 600,
        currentPriceMmk: 600,
      ),
    ];
    return {for (final item in items) item.id: item};
  }
}
