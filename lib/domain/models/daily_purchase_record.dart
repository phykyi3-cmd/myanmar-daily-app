import 'dart:convert';

/// Single purchased ingredient or grocery entry logged inside a date record.
class PurchasedLineItem {
  const PurchasedLineItem({
    required this.entryKey,
    required this.name,
    this.quantity = '',
    this.costMmk = 0,
    this.recipeName = '',
    required this.purchasedAt,
  });

  final String entryKey;
  final String name;
  final String quantity;
  final int costMmk;
  final String recipeName;
  final DateTime purchasedAt;

  PurchasedLineItem copyWith({
    String? entryKey,
    String? name,
    String? quantity,
    int? costMmk,
    String? recipeName,
    DateTime? purchasedAt,
  }) {
    return PurchasedLineItem(
      entryKey: entryKey ?? this.entryKey,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      costMmk: costMmk ?? this.costMmk,
      recipeName: recipeName ?? this.recipeName,
      purchasedAt: purchasedAt ?? this.purchasedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'entryKey': entryKey,
        'name': name,
        'quantity': quantity,
        'costMmk': costMmk,
        'recipeName': recipeName,
        'purchasedAt': purchasedAt.toIso8601String(),
      };

  factory PurchasedLineItem.fromJson(Map<String, Object?> map) {
    return PurchasedLineItem(
      entryKey: (map['entryKey'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      quantity: (map['quantity'] as String?) ?? '',
      costMmk: (map['costMmk'] as num?)?.toInt() ?? 0,
      recipeName: (map['recipeName'] as String?) ?? '',
      purchasedAt:
          DateTime.tryParse((map['purchasedAt'] as String?) ?? '') ??
              DateTime.now(),
    );
  }
}

/// Persistent date-grouped record of purchased groceries & planned/cooked dishes.
class DailyPurchaseRecord {
  const DailyPurchaseRecord({
    this.id,
    required this.dateKey,
    required this.recordDate,
    this.dishNames = const [],
    this.items = const [],
    required this.updatedAt,
  });

  final int? id;
  final String dateKey;
  final DateTime recordDate;
  final List<String> dishNames;
  final List<PurchasedLineItem> items;
  final DateTime updatedAt;

  int get totalCostMmk => items.fold(0, (sum, item) => sum + item.costMmk);
  int get itemCount => items.length;

  DailyPurchaseRecord copyWith({
    int? id,
    String? dateKey,
    DateTime? recordDate,
    List<String>? dishNames,
    List<PurchasedLineItem>? items,
    DateTime? updatedAt,
  }) {
    return DailyPurchaseRecord(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      recordDate: recordDate ?? this.recordDate,
      dishNames: dishNames ?? this.dishNames,
      items: items ?? this.items,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date_key': dateKey,
        'record_date': recordDate.toIso8601String(),
        'dish_names_json': jsonEncode(dishNames),
        'items_json': jsonEncode(items.map((e) => e.toJson()).toList()),
        'total_cost_mmk': totalCostMmk,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DailyPurchaseRecord.fromMap(Map<String, Object?> map) {
    final dateKey = (map['date_key'] as String?) ?? '';
    final parsedRecordDate =
        DateTime.tryParse((map['record_date'] as String?) ?? '') ??
            DateTime.tryParse(dateKey) ??
            DateTime.now();

    final dishNames = <String>[];
    final rawDishes = map['dish_names_json'];
    if (rawDishes is String && rawDishes.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDishes);
        if (decoded is List) {
          for (final entry in decoded) {
            final text = entry?.toString().trim() ?? '';
            if (text.isNotEmpty && !dishNames.contains(text)) {
              dishNames.add(text);
            }
          }
        }
      } catch (_) {}
    }

    final items = <PurchasedLineItem>[];
    final rawItems = map['items_json'];
    if (rawItems is String && rawItems.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is List) {
          for (final entry in decoded.whereType<Map<String, dynamic>>()) {
            items.add(PurchasedLineItem.fromJson(entry.cast<String, Object?>()));
          }
        }
      } catch (_) {}
    }

    return DailyPurchaseRecord(
      id: map['id'] as int?,
      dateKey: dateKey,
      recordDate: parsedRecordDate,
      dishNames: dishNames,
      items: items,
      updatedAt: DateTime.tryParse((map['updated_at'] as String?) ?? '') ??
          parsedRecordDate,
    );
  }
}
