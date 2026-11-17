import 'package:flutter/foundation.dart';

import 'package:myanmar_daily_app/data/repositories/daily_market_repository.dart';
import 'package:myanmar_daily_app/domain/models/commodity_price.dart';
import 'package:myanmar_daily_app/domain/models/daily_purchase_record.dart';
import 'package:myanmar_daily_app/domain/models/recipe.dart';
import 'package:myanmar_daily_app/domain/models/shopping_item.dart';

/// Sub-tabs inside the Daily Life & Market screen (`ဟင်းချက်အစီအစဉ်` first, then `ဈေးဝယ်စာရင်း`).
enum DailySection { recipes, shopping }

/// ViewModel managing the shopping checklist, budget, purchase records, 82 Myanmar & Ethnic recipes, and live online market prices.
class DailyMarketViewModel extends ChangeNotifier {
  DailyMarketViewModel({required DailyMarketRepository repository})
      : _repository = repository;

  final DailyMarketRepository _repository;

  DailySection _activeSection = DailySection.recipes;
  DailySection get activeSection => _activeSection;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSyncingOnline = false;
  bool get isSyncingOnline => _isSyncingOnline;

  List<ShoppingItem> _items = const [];
  List<ShoppingItem> get items => _items;

  List<DailyPurchaseRecord> _purchaseRecords = const [];
  List<DailyPurchaseRecord> get purchaseRecords => _purchaseRecords;

  List<Recipe> _recipes = const [];
  List<Recipe> get recipes => _recipes;

  MarketPriceSnapshot _marketSnapshot = MarketPriceSnapshot(
    usdMarketMmk: 4500,
    thbMarketMmk: 130,
    commodities: MarketPriceSnapshot.defaultCommodities(),
    lastSyncedAt: DateTime.now(),
    isOnlineLive: false,
    sourceNote: 'ကနဦး စံနှုန်းပေါက်ဈေး',
  );
  MarketPriceSnapshot get marketSnapshot => _marketSnapshot;

  Map<String, CommodityPrice> get commodities => _marketSnapshot.commodities;

  String _selectedCategory = 'အားလုံး';
  String get selectedCategory => _selectedCategory;

  String _selectedEthnicGroup = 'အားလုံး';
  String get selectedEthnicGroup => _selectedEthnicGroup;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<String> get recipeCategories => const [
        'အားလုံး',
        'တိုင်းရင်းသားဟင်းလျာများ',
        'ချွေတာရေး',
        'အသားဟင်း',
        'ငါး/ပုစွန်',
        'အရွက်/ဟင်းရံ',
        'အရည်သောက်',
        'အသုပ်/မြန်မာစာ',
      ];

  List<String> get ethnicGroups => const [
        'အားလုံး',
        'ထားဝယ်ဟင်းလျာ',
        'ရှမ်းဟင်းလျာ',
        'ချင်းဟင်းလျာ',
        'ကချင်ဟင်းလျာ',
        'ရခိုင်ဟင်းလျာ',
        'မွန်/ကရင်/ကယား',
      ];

  bool _matchesSearch(Recipe r) {
    final raw = _searchQuery.trim().toLowerCase();
    if (raw.isEmpty) return true;
    final q = raw
        .replaceAll('ဒဝယ်', 'ထားဝယ်')
        .replaceAll('မုန့်လက်ဆွဲ', 'မုန့်လက်');
    if (r.name.toLowerCase().contains(raw) ||
        r.name.toLowerCase().contains(q) ||
        r.category.toLowerCase().contains(q) ||
        r.ethnicGroup.toLowerCase().contains(q)) {
      return true;
    }
    return r.ingredients.any(
      (i) =>
          i.name.toLowerCase().contains(raw) ||
          i.name.toLowerCase().contains(q),
    );
  }

  /// Non-ethnic general Myanmar dishes matching the current category & search filter.
  List<Recipe> get filteredGeneralRecipes {
    if (_selectedCategory == 'တိုင်းရင်းသားဟင်းလျာများ') {
      return const [];
    }
    return _recipes.where((r) {
      if (r.category == 'တိုင်းရင်းသားဟင်းလျာများ') return false;
      final matchesCategory = _selectedCategory == 'အားလုံး'
          ? true
          : _selectedCategory == 'ချွေတာရေး'
              ? r.totalEstimatedCostMmk(commodities) <= 5500
              : r.category == _selectedCategory;
      if (!matchesCategory) return false;
      return _matchesSearch(r);
    }).toList();
  }

  /// All ethnic minority dishes grouped under "တိုင်းရင်းသားဟင်းလျာများ".
  List<Recipe> get filteredEthnicRecipes {
    if (_selectedCategory != 'အားလုံး' &&
        _selectedCategory != 'တိုင်းရင်းသားဟင်းလျာများ' &&
        _selectedCategory != 'ချွေတာရေး') {
      return const [];
    }
    return _recipes.where((r) {
      if (!r.isEthnicDish) return false;
      if (_selectedCategory == 'ချွေတာရေး' &&
          r.totalEstimatedCostMmk(commodities) > 5500) {
        return false;
      }
      if (_selectedEthnicGroup != 'အားလုံး' &&
          r.ethnicGroup != _selectedEthnicGroup) {
        return false;
      }
      return _matchesSearch(r);
    }).toList();
  }

  int get totalEthnicRecipeCount =>
      _recipes.where((r) => r.isEthnicDish).length;

  int get totalEstimatedBudgetMmk =>
      _items.fold(0, (sum, item) => sum + item.estimatedCostMmk);

  int get remainingEstimatedBudgetMmk => _items
      .where((item) => !item.isChecked)
      .fold(0, (sum, item) => sum + item.estimatedCostMmk);

  int get checkedItemCount => _items.where((item) => item.isChecked).length;

  int get totalRecordedSpendMmk =>
      _purchaseRecords.fold(0, (sum, record) => sum + record.totalCostMmk);

  void setActiveSection(DailySection section) {
    if (_activeSection == section) return;
    _activeSection = section;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setEthnicGroup(String group) {
    _selectedEthnicGroup = group;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repository.getShoppingItems();
      _purchaseRecords = await _repository.getPurchaseRecords();
      _recipes = await _repository.getRecipes();
      _marketSnapshot = await _repository.syncLiveMarketPrices();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncOnlinePrices() async {
    _isSyncingOnline = true;
    notifyListeners();
    try {
      _marketSnapshot = await _repository.syncLiveMarketPrices();
    } finally {
      _isSyncingOnline = false;
      notifyListeners();
    }
  }

  Future<void> updateUsdMarketRate(int newUsdMmk) async {
    _isSyncingOnline = true;
    notifyListeners();
    try {
      _marketSnapshot = await _repository.updateUsdMarketRate(newUsdMmk);
    } finally {
      _isSyncingOnline = false;
      notifyListeners();
    }
  }

  Future<void> updateCommodityPrice(String commodityId, int newPriceMmk) async {
    _marketSnapshot = await _repository.updateSingleCommodityPrice(
      current: _marketSnapshot,
      commodityId: commodityId,
      newUnitPriceMmk: newPriceMmk,
    );
    notifyListeners();
  }

  Future<void> addItem(ShoppingItem item) async {
    await _repository.addShoppingItem(item);
    _items = await _repository.getShoppingItems();
    notifyListeners();
  }

  Future<void> toggleItem(ShoppingItem item, {DateTime? now}) async {
    await _repository.toggleShoppingItem(item, now: now);
    _items = await _repository.getShoppingItems();
    _purchaseRecords = await _repository.getPurchaseRecords();
    notifyListeners();
  }

  Future<void> deleteItem(int id) async {
    await _repository.deleteShoppingItem(id);
    _items = await _repository.getShoppingItems();
    notifyListeners();
  }

  Future<void> clearChecked() async {
    await _repository.clearCheckedItems();
    _items = await _repository.getShoppingItems();
    notifyListeners();
  }

  Future<void> deletePurchaseRecord(DailyPurchaseRecord record) async {
    await _repository.deletePurchaseRecord(record);
    _purchaseRecords = await _repository.getPurchaseRecords();
    notifyListeners();
  }

  Future<void> deletePurchaseLineItem(
    DailyPurchaseRecord record,
    String entryKey,
  ) async {
    await _repository.deletePurchaseLineItem(record, entryKey);
    _purchaseRecords = await _repository.getPurchaseRecords();
    notifyListeners();
  }

  Future<void> addRecipeIngredientsToChecklist(Recipe recipe) async {
    await _repository.addIngredientsFromRecipe(recipe, commodities);
    _items = await _repository.getShoppingItems();
    notifyListeners();
  }
}
