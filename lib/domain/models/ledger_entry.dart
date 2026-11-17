/// Category for community, donation, and savings group ledger entries.
enum LedgerCategory {
  donation('အလှူ'),
  suuMae('စုမဲ'),
  groupFund('အသင်းအဖွဲ့');

  const LedgerCategory(this.labelMm);
  final String labelMm;

  static LedgerCategory fromName(String? value) {
    return LedgerCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => LedgerCategory.donation,
    );
  }
}

/// Immutable ledger record stored locally in SQLite.
class LedgerEntry {
  const LedgerEntry({
    this.id,
    required this.title,
    required this.category,
    required this.amountMmk,
    required this.isIncome,
    this.note = '',
    required this.createdAt,
  });

  final int? id;
  final String title;
  final LedgerCategory category;
  final int amountMmk;
  final bool isIncome;
  final String note;
  final DateTime createdAt;

  LedgerEntry copyWith({
    int? id,
    String? title,
    LedgerCategory? category,
    int? amountMmk,
    bool? isIncome,
    String? note,
    DateTime? createdAt,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amountMmk: amountMmk ?? this.amountMmk,
      isIncome: isIncome ?? this.isIncome,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'category': category.name,
        'amount_mmk': amountMmk,
        'is_income': isIncome ? 1 : 0,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory LedgerEntry.fromMap(Map<String, Object?> map) {
    return LedgerEntry(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      category: LedgerCategory.fromName(map['category'] as String?),
      amountMmk: (map['amount_mmk'] as num?)?.toInt() ?? 0,
      isIncome: ((map['is_income'] as num?)?.toInt() ?? 0) == 1,
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
