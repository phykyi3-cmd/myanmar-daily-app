/// Distinguishes lent money/items, borrowed items, and recurring rent dues.
enum LoanRentalType {
  lent('ပေးချေး / ငှားထား'),
  borrowed('ယူချေး / ငှားထား'),
  rentDue('အိမ်လခ / ဆိုင်ခန်းလခ');

  const LoanRentalType(this.labelMm);
  final String labelMm;

  static LoanRentalType fromName(String? value) {
    return LoanRentalType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => LoanRentalType.lent,
    );
  }
}

/// Immutable record for item rentals, personal IOUs, and rent collection.
class LoanRentalItem {
  const LoanRentalItem({
    this.id,
    required this.personName,
    required this.itemName,
    required this.type,
    required this.amountMmk,
    required this.dueDate,
    this.isSettled = false,
    this.note = '',
  });

  final int? id;
  final String personName;
  final String itemName;
  final LoanRentalType type;
  final int amountMmk;
  final DateTime dueDate;
  final bool isSettled;
  final String note;

  LoanRentalItem copyWith({
    int? id,
    String? personName,
    String? itemName,
    LoanRentalType? type,
    int? amountMmk,
    DateTime? dueDate,
    bool? isSettled,
    String? note,
  }) {
    return LoanRentalItem(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      itemName: itemName ?? this.itemName,
      type: type ?? this.type,
      amountMmk: amountMmk ?? this.amountMmk,
      dueDate: dueDate ?? this.dueDate,
      isSettled: isSettled ?? this.isSettled,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'person_name': personName,
        'item_name': itemName,
        'type': type.name,
        'amount_mmk': amountMmk,
        'due_date': dueDate.toIso8601String(),
        'is_settled': isSettled ? 1 : 0,
        'note': note,
      };

  factory LoanRentalItem.fromMap(Map<String, Object?> map) {
    return LoanRentalItem(
      id: map['id'] as int?,
      personName: (map['person_name'] as String?) ?? '',
      itemName: (map['item_name'] as String?) ?? '',
      type: LoanRentalType.fromName(map['type'] as String?),
      amountMmk: (map['amount_mmk'] as num?)?.toInt() ?? 0,
      dueDate: DateTime.tryParse((map['due_date'] as String?) ?? '') ??
          DateTime.now(),
      isSettled: ((map['is_settled'] as num?)?.toInt() ?? 0) == 1,
      note: (map['note'] as String?) ?? '',
    );
  }
}
