/// Immutable shopping checklist entry with optional dish source and estimated MMK cost.
class ShoppingItem {
  const ShoppingItem({
    this.id,
    required this.name,
    this.quantity = '',
    this.estimatedCostMmk = 0,
    this.recipeName = '',
    this.isChecked = false,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String quantity;
  final int estimatedCostMmk;
  final String recipeName;
  final bool isChecked;
  final DateTime createdAt;

  /// Stable identifier used when syncing check/uncheck state into daily history records.
  String get historyEntryKey => id != null
      ? 'shop_$id'
      : 'manual_${createdAt.millisecondsSinceEpoch}_$name';

  ShoppingItem copyWith({
    int? id,
    String? name,
    String? quantity,
    int? estimatedCostMmk,
    String? recipeName,
    bool? isChecked,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      estimatedCostMmk: estimatedCostMmk ?? this.estimatedCostMmk,
      recipeName: recipeName ?? this.recipeName,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'quantity': quantity,
        'estimated_cost_mmk': estimatedCostMmk,
        'recipe_name': recipeName,
        'is_checked': isChecked ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory ShoppingItem.fromMap(Map<String, Object?> map) {
    return ShoppingItem(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      quantity: (map['quantity'] as String?) ?? '',
      estimatedCostMmk: (map['estimated_cost_mmk'] as num?)?.toInt() ?? 0,
      recipeName: (map['recipe_name'] as String?) ?? '',
      isChecked: ((map['is_checked'] as num?)?.toInt() ?? 0) == 1,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
