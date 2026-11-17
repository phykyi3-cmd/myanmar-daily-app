import '../../domain/models/commodity_price.dart';
import '../../domain/models/daily_purchase_record.dart';
import '../../domain/models/recipe.dart';
import '../../domain/models/shopping_item.dart';
import '../../ui/core/utils/formatters.dart';
import '../services/asset_data_service.dart';
import '../services/local_db_service.dart';
import '../services/market_price_service.dart';

/// Repository managing bundled Myanmar recipes, live online commodity prices, shopping checklists, and date-based purchase records.
class DailyMarketRepository {
  DailyMarketRepository({
    required LocalDbService dbService,
    required AssetDataService assetDataService,
    required MarketPriceService marketPriceService,
  })  : _dbService = dbService,
        _assetDataService = assetDataService,
        _marketPriceService = marketPriceService;

  final LocalDbService _dbService;
  final AssetDataService _assetDataService;
  final MarketPriceService _marketPriceService;

  Future<List<Recipe>> getRecipes() => _assetDataService.loadRecipes();

  Future<MarketPriceSnapshot> syncLiveMarketPrices({int? customUsdMarketMmk}) =>
      _marketPriceService.syncLiveMarketPrices(
        customUsdMarketMmk: customUsdMarketMmk,
      );

  Future<MarketPriceSnapshot> updateUsdMarketRate(int newUsdMmk) =>
      _marketPriceService.updateUsdMarketRate(newUsdMmk);

  Future<MarketPriceSnapshot> updateSingleCommodityPrice({
    required MarketPriceSnapshot current,
    required String commodityId,
    required int newUnitPriceMmk,
  }) =>
      _marketPriceService.updateSingleCommodityPrice(
        current: current,
        commodityId: commodityId,
        newUnitPriceMmk: newUnitPriceMmk,
      );

  Future<List<ShoppingItem>> getShoppingItems() async {
    final rows = await _dbService.queryAll(
      LocalDbService.tableShopping,
      orderBy: 'is_checked ASC, created_at DESC',
    );
    return rows.map(ShoppingItem.fromMap).toList();
  }

  Future<void> addShoppingItem(ShoppingItem item) async {
    await _dbService.insert(
      LocalDbService.tableShopping,
      item.copyWith(id: null).toMap(),
    );
  }

  Future<void> addIngredientsFromRecipe(
    Recipe recipe,
    Map<String, CommodityPrice> commodities,
  ) async {
    final now = DateTime.now();
    for (final ingredient in recipe.ingredients) {
      await addShoppingItem(
        ShoppingItem(
          name: ingredient.name,
          quantity: ingredient.amount,
          estimatedCostMmk: ingredient.estimatedCostMmk(commodities),
          recipeName: recipe.name,
          createdAt: now,
        ),
      );
    }
  }

  Future<void> toggleShoppingItem(
    ShoppingItem item, {
    DateTime? now,
  }) async {
    final id = item.id;
    if (id == null) return;
    final nextChecked = !item.isChecked;
    await _dbService.updateById(
      LocalDbService.tableShopping,
      id,
      {'is_checked': nextChecked ? 1 : 0},
    );
    if (nextChecked) {
      await recordPurchasedShoppingItem(item, now: now);
    } else {
      await unrecordPurchasedShoppingItem(item, now: now);
    }
  }

  Future<void> deleteShoppingItem(int id) async {
    await _dbService.deleteById(LocalDbService.tableShopping, id);
  }

  Future<void> clearCheckedItems() async {
    await _dbService.deleteWhere(
      LocalDbService.tableShopping,
      where: 'is_checked = ?',
      whereArgs: [1],
    );
  }

  Future<List<DailyPurchaseRecord>> getPurchaseRecords() async {
    final rows = await _dbService.queryAll(
      LocalDbService.tablePurchaseRecords,
      orderBy: 'date_key DESC',
    );
    return rows.map(DailyPurchaseRecord.fromMap).toList();
  }

  Future<void> restorePurchaseRecord(DailyPurchaseRecord record) async {
    await _dbService.insert(
      LocalDbService.tablePurchaseRecords,
      record.copyWith(id: null).toMap(),
    );
  }

  /// Adds or updates a checked-off shopping item inside [now]'s daily record.
  Future<void> recordPurchasedShoppingItem(
    ShoppingItem item, {
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final dateKey = formatDateShort(timestamp);
    final entryKey = item.historyEntryKey;
    final lineItem = PurchasedLineItem(
      entryKey: entryKey,
      name: item.name,
      quantity: item.quantity,
      costMmk: item.estimatedCostMmk,
      recipeName: item.recipeName,
      purchasedAt: timestamp,
    );

    final records = await getPurchaseRecords();
    final existingIdx = records.indexWhere((r) => r.dateKey == dateKey);

    if (existingIdx == -1) {
      final dishes = <String>[
        if (item.recipeName.trim().isNotEmpty) item.recipeName.trim(),
      ];
      final created = DailyPurchaseRecord(
        dateKey: dateKey,
        recordDate: DateTime(timestamp.year, timestamp.month, timestamp.day),
        dishNames: dishes,
        items: [lineItem],
        updatedAt: timestamp,
      );
      await _dbService.insert(
        LocalDbService.tablePurchaseRecords,
        created.toMap(),
      );
      return;
    }

    final existing = records[existingIdx];
    final nextItems = List<PurchasedLineItem>.from(existing.items);
    final dupIdx = nextItems.indexWhere((i) => i.entryKey == entryKey);
    if (dupIdx == -1) {
      nextItems.add(lineItem);
    } else {
      nextItems[dupIdx] = lineItem;
    }

    final nextDishes = _collectDishNames(nextItems);
    final updated = existing.copyWith(
      dishNames: nextDishes,
      items: nextItems,
      updatedAt: timestamp,
    );
    await _saveUpdatedRecord(updated);
  }

  /// Removes a previously auto-recorded shopping item if unchecked today.
  Future<void> unrecordPurchasedShoppingItem(
    ShoppingItem item, {
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final entryKey = item.historyEntryKey;
    final records = await getPurchaseRecords();

    for (final record in records) {
      final contains = record.items.any((i) => i.entryKey == entryKey);
      if (!contains) continue;
      final remaining =
          record.items.where((i) => i.entryKey != entryKey).toList();
      if (remaining.isEmpty) {
        await _deleteRecordRow(record);
      } else {
        await _saveUpdatedRecord(
          record.copyWith(
            dishNames: _collectDishNames(remaining),
            items: remaining,
            updatedAt: timestamp,
          ),
        );
      }
      break;
    }
  }

  /// Removes a single line item from a stored daily purchase record.
  Future<void> deletePurchaseLineItem(
    DailyPurchaseRecord record,
    String entryKey,
  ) async {
    final remaining =
        record.items.where((item) => item.entryKey != entryKey).toList();
    if (remaining.isEmpty) {
      await _deleteRecordRow(record);
      return;
    }
    await _saveUpdatedRecord(
      record.copyWith(
        dishNames: _collectDishNames(remaining),
        items: remaining,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Permanently deletes an entire date's purchase record after user confirmation.
  Future<void> deletePurchaseRecord(DailyPurchaseRecord record) async {
    await _deleteRecordRow(record);
  }

  Future<void> _saveUpdatedRecord(DailyPurchaseRecord record) async {
    if (record.id != null) {
      await _dbService.updateById(
        LocalDbService.tablePurchaseRecords,
        record.id!,
        record.toMap(),
      );
      return;
    }
    await _dbService.deleteWhere(
      LocalDbService.tablePurchaseRecords,
      where: 'date_key = ?',
      whereArgs: [record.dateKey],
    );
    await _dbService.insert(
      LocalDbService.tablePurchaseRecords,
      record.copyWith(id: null).toMap(),
    );
  }

  Future<void> _deleteRecordRow(DailyPurchaseRecord record) async {
    if (record.id != null) {
      await _dbService.deleteById(
        LocalDbService.tablePurchaseRecords,
        record.id!,
      );
      return;
    }
    await _dbService.deleteWhere(
      LocalDbService.tablePurchaseRecords,
      where: 'date_key = ?',
      whereArgs: [record.dateKey],
    );
  }

  List<String> _collectDishNames(List<PurchasedLineItem> items) {
    final seen = <String>[];
    for (final item in items) {
      final name = item.recipeName.trim();
      if (name.isNotEmpty && !seen.contains(name)) {
        seen.add(name);
      }
    }
    return seen;
  }
}
