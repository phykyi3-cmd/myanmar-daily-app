/// Converts Myanmar numerals (`၀–၉`), commas, and whitespace into plain ASCII digits
/// so numeric health inputs and PINs work identically on Burmese and English keyboards.
String normalizeAsciiDigits(String input) {
  const mmZero = 0x1040;
  final buf = StringBuffer();
  for (final code in input.trim().codeUnits) {
    if (code >= mmZero && code <= mmZero + 9) {
      buf.writeCharCode(0x30 + (code - mmZero));
    } else if (code == 0x2C /* , */ || code == 0x20 /* space */) {
      continue;
    } else {
      buf.writeCharCode(code);
    }
  }
  return buf.toString();
}

/// Distinguishes between expectant/lactating mothers and young children (`0-59 months`).
enum HealthProfileType {
  motherPregnancy(labelMm: 'မိခင် (ကိုယ်ဝန်ဆောင်/မိခင်)'),
  child(labelMm: 'ကလေး (မွေးစ – ၅ နှစ်)');

  const HealthProfileType({required this.labelMm});
  final String labelMm;

  static HealthProfileType fromName(String? value) {
    return HealthProfileType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HealthProfileType.child,
    );
  }
}

/// Sex used for WHO 0-60 month Weight-for-Age median standards.
enum ChildGender {
  boy(labelMm: 'သားလေး'),
  girl(labelMm: 'သမီးလေး');

  const ChildGender({required this.labelMm});
  final String labelMm;

  static ChildGender fromName(String? value) {
    return ChildGender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChildGender.girl,
    );
  }
}

/// Stored family member profile for offline Maternal & Child health tracking.
class FamilyHealthProfile {
  const FamilyHealthProfile({
    this.id,
    required this.name,
    required this.profileType,
    this.childGender = ChildGender.girl,
    required this.referenceDate,
    this.bloodType = '',
    this.allergyNote = '',
    required this.createdAt,
  });

  final int? id;
  final String name;
  final HealthProfileType profileType;
  final ChildGender childGender;

  /// For mothers: LMP (`နောက်ဆုံးရာသီစသည့်ရက်`). For children: Birth date.
  final DateTime referenceDate;
  final String bloodType;
  final String allergyNote;
  final DateTime createdAt;

  /// Expected Delivery Date using Naegele's standard 280-day formula (`LMP + 40 weeks`).
  DateTime get expectedDueDate => referenceDate.add(const Duration(days: 280));

  int gestationalWeekAt([DateTime? now]) {
    final ref = now ?? DateTime.now();
    final days = ref.difference(referenceDate).inDays;
    if (days <= 0) return 1;
    final weeks = (days ~/ 7) + 1;
    return weeks > 42 ? 42 : weeks;
  }

  int trimesterAt([DateTime? now]) {
    final w = gestationalWeekAt(now);
    if (w <= 13) return 1;
    if (w <= 27) return 2;
    return 3;
  }

  int ageMonthsAt([DateTime? now]) {
    final ref = now ?? DateTime.now();
    var months =
        (ref.year - referenceDate.year) * 12 + (ref.month - referenceDate.month);
    if (ref.day < referenceDate.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  String ageOrStageSummaryMm([DateTime? now]) {
    if (profileType == HealthProfileType.motherPregnancy) {
      final week = gestationalWeekAt(now);
      final tri = trimesterAt(now);
      return 'ကိုယ်ဝန် ($week) ပတ် • Trimester $tri';
    }
    final months = ageMonthsAt(now);
    if (months < 12) return '$months လသား';
    final yrs = months ~/ 12;
    final remM = months % 12;
    if (remM == 0) return '$yrs နှစ်';
    return '$yrs နှစ် $remM လ';
  }

  FamilyHealthProfile copyWith({
    int? id,
    String? name,
    HealthProfileType? profileType,
    ChildGender? childGender,
    DateTime? referenceDate,
    String? bloodType,
    String? allergyNote,
    DateTime? createdAt,
  }) {
    return FamilyHealthProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      profileType: profileType ?? this.profileType,
      childGender: childGender ?? this.childGender,
      referenceDate: referenceDate ?? this.referenceDate,
      bloodType: bloodType ?? this.bloodType,
      allergyNote: allergyNote ?? this.allergyNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'profile_type': profileType.name,
        'child_gender': childGender.name,
        'reference_date': referenceDate.toIso8601String(),
        'blood_type': bloodType,
        'allergy_note': allergyNote,
        'created_at': createdAt.toIso8601String(),
      };

  factory FamilyHealthProfile.fromMap(Map<String, Object?> map) {
    return FamilyHealthProfile(
      id: (map['id'] as num?)?.toInt(),
      name: (map['name'] as String?) ?? '',
      profileType: HealthProfileType.fromName(map['profile_type'] as String?),
      childGender: ChildGender.fromName(map['child_gender'] as String?),
      referenceDate:
          DateTime.tryParse((map['reference_date'] as String?) ?? '') ??
              DateTime.now(),
      bloodType: (map['blood_type'] as String?) ?? '',
      allergyNote: (map['allergy_note'] as String?) ?? '',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

/// Tracked vaccine dose record anchored to a [FamilyHealthProfile].
class ImmunizationRecord {
  const ImmunizationRecord({
    this.id,
    required this.profileId,
    required this.vaccineCode,
    required this.vaccineNameMm,
    required this.doseLabelMm,
    required this.protectAgainstMm,
    required this.dueAgeDays,
    required this.dueDate,
    this.completedDate,
    this.isCompleted = false,
    this.clinicNote = '',
  });

  final int? id;
  final int profileId;
  final String vaccineCode;
  final String vaccineNameMm;
  final String doseLabelMm;
  final String protectAgainstMm;
  final int dueAgeDays;
  final DateTime dueDate;
  final DateTime? completedDate;
  final bool isCompleted;
  final String clinicNote;

  int daysRemaining([DateTime? now]) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return target.difference(today).inDays;
  }

  ImmunizationRecord copyWith({
    int? id,
    int? profileId,
    String? vaccineCode,
    String? vaccineNameMm,
    String? doseLabelMm,
    String? protectAgainstMm,
    int? dueAgeDays,
    DateTime? dueDate,
    DateTime? completedDate,
    bool? isCompleted,
    String? clinicNote,
  }) {
    return ImmunizationRecord(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      vaccineCode: vaccineCode ?? this.vaccineCode,
      vaccineNameMm: vaccineNameMm ?? this.vaccineNameMm,
      doseLabelMm: doseLabelMm ?? this.doseLabelMm,
      protectAgainstMm: protectAgainstMm ?? this.protectAgainstMm,
      dueAgeDays: dueAgeDays ?? this.dueAgeDays,
      dueDate: dueDate ?? this.dueDate,
      completedDate: completedDate ?? this.completedDate,
      isCompleted: isCompleted ?? this.isCompleted,
      clinicNote: clinicNote ?? this.clinicNote,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'profile_id': profileId,
        'vaccine_code': vaccineCode,
        'vaccine_name_mm': vaccineNameMm,
        'dose_label_mm': doseLabelMm,
        'protect_against_mm': protectAgainstMm,
        'due_age_days': dueAgeDays,
        'due_date': dueDate.toIso8601String(),
        'completed_date': completedDate?.toIso8601String(),
        'is_completed': isCompleted ? 1 : 0,
        'clinic_note': clinicNote,
      };

  factory ImmunizationRecord.fromMap(Map<String, Object?> map) {
    final completedRaw = map['completed_date'] as String?;
    return ImmunizationRecord(
      id: (map['id'] as num?)?.toInt(),
      profileId: (map['profile_id'] as num?)?.toInt() ?? 0,
      vaccineCode: (map['vaccine_code'] as String?) ?? '',
      vaccineNameMm: (map['vaccine_name_mm'] as String?) ?? '',
      doseLabelMm: (map['dose_label_mm'] as String?) ?? '',
      protectAgainstMm: (map['protect_against_mm'] as String?) ?? '',
      dueAgeDays: (map['due_age_days'] as num?)?.toInt() ?? 0,
      dueDate: DateTime.tryParse((map['due_date'] as String?) ?? '') ??
          DateTime.now(),
      completedDate:
          completedRaw == null ? null : DateTime.tryParse(completedRaw),
      isCompleted: ((map['is_completed'] as num?)?.toInt() ?? 0) == 1,
      clinicNote: (map['clinic_note'] as String?) ?? '',
    );
  }
}

/// Logged maternal vital/mood entry or child growth measurement.
class HealthGrowthLog {
  const HealthGrowthLog({
    this.id,
    required this.profileId,
    required this.recordedAt,
    this.weightKg,
    this.heightCm,
    this.bpSystolic,
    this.bpDiastolic,
    this.moodScore = 3,
    this.symptomsNote = '',
  });

  final int? id;
  final int profileId;
  final DateTime recordedAt;
  final double? weightKg;
  final double? heightCm;
  final int? bpSystolic;
  final int? bpDiastolic;
  final int moodScore;
  final String symptomsNote;

  bool get hasElevatedBp =>
      (bpSystolic != null && bpSystolic! >= 140) ||
      (bpDiastolic != null && bpDiastolic! >= 90);

  String get moodLabelMm => switch (moodScore) {
        1 => 'ပင်ပန်း / စိတ်ဖိစီး',
        2 => 'အနည်းငယ် နုံး',
        3 => 'ပုံမှန် ကောင်းမွန်',
        4 => 'လန်းဆန်း ပျော်ရွှင်',
        5 => 'အထူး အားအင်ပြည့်',
        _ => 'ပုံမှန်',
      };

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'profile_id': profileId,
        'recorded_at': recordedAt.toIso8601String(),
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'mood_score': moodScore,
        'symptoms_note': symptomsNote,
      };

  factory HealthGrowthLog.fromMap(Map<String, Object?> map) {
    return HealthGrowthLog(
      id: (map['id'] as num?)?.toInt(),
      profileId: (map['profile_id'] as num?)?.toInt() ?? 0,
      recordedAt: DateTime.tryParse((map['recorded_at'] as String?) ?? '') ??
          DateTime.now(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      bpSystolic: (map['bp_systolic'] as num?)?.toInt(),
      bpDiastolic: (map['bp_diastolic'] as num?)?.toInt(),
      moodScore: (map['mood_score'] as num?)?.toInt() ?? 3,
      symptomsNote: (map['symptoms_note'] as String?) ?? '',
    );
  }
}

/// Official WHO / MOHS vaccine dose template.
class EpiVaccineTemplate {
  const EpiVaccineTemplate({
    required this.code,
    required this.nameMm,
    required this.doseLabelMm,
    required this.dueAgeDays,
    required this.protectAgainstMm,
  });

  final String code;
  final String nameMm;
  final String doseLabelMm;
  final int dueAgeDays;
  final String protectAgainstMm;
}

/// Offline ingredient item inside a Mother/Baby nutrition recipe.
class NutritionIngredient {
  const NutritionIngredient({
    required this.nameMm,
    required this.quantityMm,
    required this.estimatedCostMmk,
  });

  final String nameMm;
  final String quantityMm;
  final int estimatedCostMmk;
}

/// Mother or infant weaning nutrition guide syncing directly with Shopping List.
class NutritionGuideMeal {
  const NutritionGuideMeal({
    required this.id,
    required this.titleMm,
    required this.stageLabelMm,
    required this.forMother,
    required this.minChildAgeMonths,
    required this.keyNutrientsMm,
    required this.prepStepsMm,
    required this.ingredients,
  });

  final String id;
  final String titleMm;
  final String stageLabelMm;
  final bool forMother;
  final int minChildAgeMonths;
  final String keyNutrientsMm;
  final String prepStepsMm;
  final List<NutritionIngredient> ingredients;
}

/// Pregnancy trimester care tips and ANC guidance.
class PregnancyTrimesterGuide {
  const PregnancyTrimesterGuide({
    required this.trimester,
    required this.titleMm,
    required this.babyGrowthMm,
    required this.motherCareMm,
    required this.ancVisitReminderMm,
  });

  final int trimester;
  final String titleMm;
  final String babyGrowthMm;
  final String motherCareMm;
  final String ancVisitReminderMm;
}

/// Age-bracket child developmental milestones.
class ChildMilestoneStage {
  const ChildMilestoneStage({
    required this.ageRangeLabelMm,
    required this.minMonths,
    required this.maxMonths,
    required this.milestonesMm,
  });

  final String ageRangeLabelMm;
  final int minMonths;
  final int maxMonths;
  final List<String> milestonesMm;
}
