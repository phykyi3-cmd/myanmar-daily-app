/// Categories for vehicle maintenance and personal document renewals.
enum ReminderCategory {
  vehicle('ကား / ဆိုင်ကယ်'),
  license('လိုင်စင် / Passport'),
  contract('စာချုပ် / ငှားရမ်းမှု'),
  other('အခြား');

  const ReminderCategory(this.labelMm);
  final String labelMm;

  static ReminderCategory fromName(String? value) {
    return ReminderCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => ReminderCategory.other,
    );
  }
}

/// Immutable vehicle maintenance or document renewal reminder.
class RenewalReminder {
  const RenewalReminder({
    this.id,
    required this.title,
    required this.category,
    required this.dueDate,
    this.mileageKm,
    this.note = '',
    this.isCompleted = false,
  });

  final int? id;
  final String title;
  final ReminderCategory category;
  final DateTime dueDate;
  final int? mileageKm;
  final String note;
  final bool isCompleted;

  /// Number of calendar days remaining from [now] (negative if overdue).
  int daysRemaining([DateTime? now]) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return target.difference(today).inDays;
  }

  RenewalReminder copyWith({
    int? id,
    String? title,
    ReminderCategory? category,
    DateTime? dueDate,
    int? mileageKm,
    String? note,
    bool? isCompleted,
  }) {
    return RenewalReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      mileageKm: mileageKm ?? this.mileageKm,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'category': category.name,
        'due_date': dueDate.toIso8601String(),
        'mileage_km': mileageKm,
        'note': note,
        'is_completed': isCompleted ? 1 : 0,
      };

  factory RenewalReminder.fromMap(Map<String, Object?> map) {
    return RenewalReminder(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      category: ReminderCategory.fromName(map['category'] as String?),
      dueDate: DateTime.tryParse((map['due_date'] as String?) ?? '') ??
          DateTime.now(),
      mileageKm: (map['mileage_km'] as num?)?.toInt(),
      note: (map['note'] as String?) ?? '',
      isCompleted: ((map['is_completed'] as num?)?.toInt() ?? 0) == 1,
    );
  }
}
