import 'commodity_price.dart';

/// Single ingredient item linked to a Myanmar market commodity unit price.
class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.amount,
    this.commodityId = 'seasoning',
    this.unitQuantity = 1.0,
    this.baseCostMmk = 0,
  });

  final String name;
  final String amount;
  final String commodityId;
  final double unitQuantity;
  final int baseCostMmk;

  /// Computes exact portion cost in MMK from the live [commodities] table.
  int estimatedCostMmk(
    Map<String, CommodityPrice> commodities, {
    double multiplier = 1.0,
  }) {
    final commodity = commodities[commodityId];
    if (commodity != null) {
      return (commodity.currentPriceMmk * unitQuantity * multiplier).round();
    }
    return (baseCostMmk * multiplier).round();
  }

  /// Human-readable unit rate breakdown (e.g. `၁ ပိဿာ 6,000 ကျပ် နှုန်း`).
  String unitRateSummaryMm(
    Map<String, CommodityPrice> commodities, {
    required String Function(int) formatMmk,
  }) {
    final commodity = commodities[commodityId];
    if (commodity == null) return '';
    return '${commodity.unitLabelMm} ${formatMmk(commodity.currentPriceMmk)} နှုန်း';
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: (json['name'] as String?) ?? '',
      amount: (json['amount'] as String?) ?? '',
      commodityId: (json['commodityId'] as String?) ?? 'seasoning',
      unitQuantity: (json['unitQuantity'] as num?)?.toDouble() ?? 1.0,
      baseCostMmk: (json['baseCostMmk'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Offline/online hybrid recipe with dish photo, NBK stat metrics, and live commodity-based cost breakdown.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.category,
    this.ethnicGroup = '',
    required this.prepMinutes,
    required this.ingredients,
    required this.steps,
    this.imageAsset = '',
    this.flavorProfileMm = '',
    this.chefTipMm = '',
    this.ratingScore = 92,
  });

  final String id;
  final String name;
  final String category;
  final String ethnicGroup;
  final int prepMinutes;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final String imageAsset;
  final String flavorProfileMm;
  final String chefTipMm;
  final int ratingScore;

  String get resolvedImageAsset =>
      imageAsset.isNotEmpty ? imageAsset : 'assets/images/dishes/$id.jpg';

  bool get isEthnicDish =>
      category == 'တိုင်းရင်းသားဟင်းလျာများ' || ethnicGroup.isNotEmpty;

  int totalEstimatedCostMmk(
    Map<String, CommodityPrice> commodities, {
    double multiplier = 1.0,
  }) {
    return ingredients.fold(
      0,
      (sum, item) =>
          sum + item.estimatedCostMmk(commodities, multiplier: multiplier),
    );
  }

  String budgetTierLabelMm(Map<String, CommodityPrice> commodities) {
    final total = totalEstimatedCostMmk(commodities);
    if (total <= 5000) return 'ချွေတာရေး';
    if (total <= 13000) return 'ပုံမှန်';
    return 'အထူးဟင်း';
  }

  /// NBK Card Stat: Taste / Authenticity (85 - 98)
  int get tasteStat => ratingScore.clamp(85, 99);

  /// NBK Card Stat: Speed / Ease based on prepMinutes (65 - 96)
  int get speedStat => (100 - (prepMinutes * 0.55)).round().clamp(65, 96);

  /// NBK Card Stat: Nutrition & Balance (78 - 96)
  int get nutritionStat =>
      (78 + (ingredients.length * 4)).clamp(78, 96);

  /// NBK Card Stat: Budget Value based on live cost (68 - 98)
  int valueStat(Map<String, CommodityPrice> commodities) {
    final cost = totalEstimatedCostMmk(commodities);
    if (cost <= 4500) return 96;
    if (cost <= 7500) return 90;
    if (cost <= 12000) return 84;
    if (cost <= 16500) return 78;
    return 72;
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final rawIngredients = (json['ingredients'] as List<dynamic>?) ?? const [];
    final rawSteps = (json['steps'] as List<dynamic>?) ?? const [];
    final id = (json['id'] as String?) ?? '';
    return Recipe(
      id: id,
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      ethnicGroup: (json['ethnicGroup'] as String?) ?? '',
      prepMinutes: (json['prepMinutes'] as num?)?.toInt() ?? 0,
      ingredients: rawIngredients
          .whereType<Map<String, dynamic>>()
          .map(RecipeIngredient.fromJson)
          .toList(),
      steps: rawSteps.whereType<String>().toList(),
      imageAsset: (json['imageAsset'] as String?) ?? 'assets/images/dishes/$id.jpg',
      flavorProfileMm: (json['flavorProfileMm'] as String?) ?? '',
      chefTipMm: (json['chefTipMm'] as String?) ?? '',
      ratingScore: (json['ratingScore'] as num?)?.toInt() ?? 92,
    );
  }
}
