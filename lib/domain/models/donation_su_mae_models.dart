import 'dart:convert';

import 'package:myanmar_daily_app/ui/core/utils/formatters.dart';

/// Categories of Myanmar community donation campaigns (`အလှူအမျိုးအစား`).
enum DonationType {
  kathina(labelMm: 'ဘုံကထိန်'),
  wasoRobe(labelMm: 'ဝါဆိုသင်္ကန်း'),
  monastery(labelMm: 'ကျောင်း/ဘုရား ပြုပြင်'),
  waterFood(labelMm: 'ရေ/အာဟာရ ဒါန'),
  socialAid(labelMm: 'နာရေး/လူမှုကူညီ'),
  other(labelMm: 'အခြားအလှူ');

  const DonationType({required this.labelMm});
  final String labelMm;

  static DonationType fromName(String? value) {
    return DonationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DonationType.kathina,
    );
  }
}

/// One donor contribution record inside a [DonationCampaign].
class DonorContribution {
  const DonorContribution({
    required this.id,
    required this.donorName,
    required this.amountMmk,
    required this.donatedDate,
    this.paymentMethodMm = 'ငွေသား',
    this.isPaid = true,
    this.note = '',
  });

  final String id;
  final String donorName;
  final int amountMmk;
  final DateTime donatedDate;
  final String paymentMethodMm;
  final bool isPaid;
  final String note;

  DonorContribution copyWith({
    String? donorName,
    int? amountMmk,
    DateTime? donatedDate,
    String? paymentMethodMm,
    bool? isPaid,
    String? note,
  }) {
    return DonorContribution(
      id: id,
      donorName: donorName ?? this.donorName,
      amountMmk: amountMmk ?? this.amountMmk,
      donatedDate: donatedDate ?? this.donatedDate,
      paymentMethodMm: paymentMethodMm ?? this.paymentMethodMm,
      isPaid: isPaid ?? this.isPaid,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'donorName': donorName,
        'amountMmk': amountMmk,
        'donatedDate': donatedDate.toIso8601String(),
        'paymentMethodMm': paymentMethodMm,
        'isPaid': isPaid,
        'note': note,
      };

  factory DonorContribution.fromJson(Map<String, dynamic> map) {
    return DonorContribution(
      id: (map['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      donorName: (map['donorName'] as String?) ?? '-',
      amountMmk: (map['amountMmk'] as num?)?.round() ?? 0,
      donatedDate:
          DateTime.tryParse((map['donatedDate'] as String?) ?? '') ??
              DateTime.now(),
      paymentMethodMm: (map['paymentMethodMm'] as String?) ?? 'ငွေသား',
      isPaid: (map['isPaid'] as bool?) ?? true,
      note: (map['note'] as String?) ?? '',
    );
  }
}

/// Persistent community donation campaign (e.g., ဘုံကထိန်) with incremental donor records.
class DonationCampaign {
  const DonationCampaign({
    this.id,
    required this.title,
    required this.type,
    this.targetAmountMmk = 0,
    required this.eventDate,
    this.note = '',
    this.contributions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final DonationType type;
  final int targetAmountMmk;
  final DateTime eventDate;
  final String note;
  final List<DonorContribution> contributions;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get donorCount => contributions.length;

  int get paidDonorCount => contributions.where((c) => c.isPaid).length;

  int get totalCollectedMmk => contributions
      .where((c) => c.isPaid)
      .fold<int>(0, (sum, c) => sum + c.amountMmk);

  int get totalPledgedMmk => contributions
      .where((c) => !c.isPaid)
      .fold<int>(0, (sum, c) => sum + c.amountMmk);

  int get grandTotalMmk => totalCollectedMmk + totalPledgedMmk;

  double get targetProgress => targetAmountMmk > 0
      ? (totalCollectedMmk / targetAmountMmk).clamp(0.0, 1.0)
      : 0.0;

  DonationCampaign copyWith({
    int? id,
    String? title,
    DonationType? type,
    int? targetAmountMmk,
    DateTime? eventDate,
    String? note,
    List<DonorContribution>? contributions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DonationCampaign(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      targetAmountMmk: targetAmountMmk ?? this.targetAmountMmk,
      eventDate: eventDate ?? this.eventDate,
      note: note ?? this.note,
      contributions: contributions ?? this.contributions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Generates a ready-to-share Burmese donation list for Viber / Messenger / Facebook.
  String formatShareSummaryMm() {
    final buf = StringBuffer()
      ..writeln('🙏 $title (${type.labelMm})')
      ..writeln('ရက်စွဲ: ${formatDateShort(eventDate)}')
      ..writeln('──────────────');
    if (contributions.isEmpty) {
      buf.writeln('(အလှူရှင်စာရင်း မထည့်ရသေးပါ)');
    } else {
      for (var i = 0; i < contributions.length; i++) {
        final c = contributions[i];
        final status = c.isPaid ? '✓' : '(ကတိပြု)';
        buf.writeln(
          '${i + 1}. ${c.donorName} — ${formatMmk(c.amountMmk)} $status (${formatDateShort(c.donatedDate)})',
        );
      }
    }
    buf
      ..writeln('──────────────')
      ..writeln('အလှူရှင် စုစုပေါင်း: $donorCount ဦး (ပေးပြီး $paidDonorCount ဦး)')
      ..writeln('ကောက်ခံရရှိငွေ: ${formatMmk(totalCollectedMmk)}');
    if (totalPledgedMmk > 0) {
      buf.writeln('ကတိပြု ကျန်ငွေ: ${formatMmk(totalPledgedMmk)}');
      buf.writeln('စုစုပေါင်းတန်ဖိုး: ${formatMmk(grandTotalMmk)}');
    }
    return buf.toString().trim();
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'type': type.name,
        'target_amount_mmk': targetAmountMmk,
        'event_date': eventDate.toIso8601String(),
        'note': note,
        'contributions_json':
            jsonEncode(contributions.map((c) => c.toJson()).toList()),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DonationCampaign.fromMap(Map<String, Object?> map) {
    final rawList = map['contributions_json'] as String?;
    var parsed = <DonorContribution>[];
    if (rawList != null && rawList.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawList);
        if (decoded is List) {
          parsed = decoded
              .whereType<Map<String, dynamic>>()
              .map(DonorContribution.fromJson)
              .toList();
        }
      } catch (_) {}
    }

    final created =
        DateTime.tryParse((map['created_at'] as String?) ?? '') ??
            DateTime.now();
    return DonationCampaign(
      id: (map['id'] as num?)?.toInt(),
      title: (map['title'] as String?) ?? 'အလှူစာရင်း',
      type: DonationType.fromName(map['type'] as String?),
      targetAmountMmk: (map['target_amount_mmk'] as num?)?.toInt() ?? 0,
      eventDate: DateTime.tryParse((map['event_date'] as String?) ?? '') ??
          created,
      note: (map['note'] as String?) ?? '',
      contributions: parsed,
      createdAt: created,
      updatedAt:
          DateTime.tryParse((map['updated_at'] as String?) ?? '') ?? created,
    );
  }
}

/// Traditional Myanmar rotating money-saving styles (`မြန်မာ့ စုမဲ ၃ မျိုး`).
enum SuMaeStyle {
  luckyDraw(
    labelMm: 'မဲနှိုက် စုမဲ',
    descriptionMm:
        'အလှည့်တိုင်း တူညီသောငွေထည့်ပြီး မပေါက်သေးသူများထဲမှ မဲနှိုက်၍ မဲငွေအပြည့် ထုတ်ယူသည်။',
  ),
  auctionBid(
    labelMm: 'လေလံ စုမဲ',
    descriptionMm:
        'ငွေအမြန်လိုသူက အတိုး/လေလံကြေး အများဆုံးပေး၍ ထုတ်ယူပြီး လေလံကြေးကို မပေါက်သေးသူများထံ ခွဲဝေ/လျှော့ပေးသည်။',
  ),
  fixedTurn(
    labelMm: 'ဒိုင်ယူ • အလှည့်ကျ စုမဲ',
    descriptionMm:
        'ဒိုင် (ဦးဆောင်သူ) က ပထမအလှည့်ယူပြီး ကျန်အဖွဲ့ဝင်များ အမှတ်စဉ်အတိုင်း အလှည့်ကျ ထုတ်ယူသည်။',
  );

  const SuMaeStyle({
    required this.labelMm,
    required this.descriptionMm,
  });

  final String labelMm;
  final String descriptionMm;

  static SuMaeStyle fromName(String? value) {
    return SuMaeStyle.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SuMaeStyle.luckyDraw,
    );
  }
}

/// Collection cycle interval for a Myanmar Su Mae group.
enum SuMaeCycle {
  monthly(labelMm: 'လစဉ်', approxDays: 30),
  biweekly(labelMm: '၁၅ ရက်တစ်ကြိမ်', approxDays: 15),
  weekly(labelMm: 'အပတ်စဉ်', approxDays: 7),
  daily(labelMm: 'နေ့စဉ် (ဈေးစုမဲ)', approxDays: 1);

  const SuMaeCycle({
    required this.labelMm,
    required this.approxDays,
  });

  final String labelMm;
  final int approxDays;

  DateTime dateForRound(DateTime startDate, int roundNumber) {
    final offset = (roundNumber - 1).clamp(0, 500);
    if (this == SuMaeCycle.monthly) {
      return DateTime(startDate.year, startDate.month + offset, startDate.day);
    }
    return startDate.add(Duration(days: offset * approxDays));
  }

  static SuMaeCycle fromName(String? value) {
    return SuMaeCycle.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SuMaeCycle.monthly,
    );
  }
}

/// One member slot inside a [SuMaeGroup] (supports 0.5 / 1.0 / 2.0 shares).
class SuMaeMember {
  const SuMaeMember({
    required this.id,
    required this.name,
    this.phone = '',
    this.sharesCount = 1.0,
    this.wonRoundNumber,
    this.wonDate,
    this.wonPayoutMmk,
    this.note = '',
  });

  final String id;
  final String name;
  final String phone;
  final double sharesCount;
  final int? wonRoundNumber;
  final DateTime? wonDate;
  final int? wonPayoutMmk;
  final String note;

  bool get hasWon => wonRoundNumber != null;

  String get shareLabelMm {
    if (sharesCount == 0.5) return 'မဲဝက် (0.5)';
    if (sharesCount == sharesCount.roundToDouble()) {
      return '${sharesCount.round()} မဲ';
    }
    return '$sharesCount မဲ';
  }

  SuMaeMember copyWith({
    String? name,
    String? phone,
    double? sharesCount,
    int? wonRoundNumber,
    bool clearWon = false,
    DateTime? wonDate,
    int? wonPayoutMmk,
    String? note,
  }) {
    return SuMaeMember(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      sharesCount: sharesCount ?? this.sharesCount,
      wonRoundNumber: clearWon ? null : (wonRoundNumber ?? this.wonRoundNumber),
      wonDate: clearWon ? null : (wonDate ?? this.wonDate),
      wonPayoutMmk: clearWon ? null : (wonPayoutMmk ?? this.wonPayoutMmk),
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'sharesCount': sharesCount,
        'wonRoundNumber': wonRoundNumber,
        'wonDate': wonDate?.toIso8601String(),
        'wonPayoutMmk': wonPayoutMmk,
        'note': note,
      };

  factory SuMaeMember.fromJson(Map<String, dynamic> map) {
    return SuMaeMember(
      id: (map['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: (map['name'] as String?) ?? '-',
      phone: (map['phone'] as String?) ?? '',
      sharesCount: (map['sharesCount'] as num?)?.toDouble() ?? 1.0,
      wonRoundNumber: (map['wonRoundNumber'] as num?)?.toInt(),
      wonDate: DateTime.tryParse((map['wonDate'] as String?) ?? ''),
      wonPayoutMmk: (map['wonPayoutMmk'] as num?)?.toInt(),
      note: (map['note'] as String?) ?? '',
    );
  }
}

/// Individual member payment record for one Su Mae round.
class SuMaePayment {
  const SuMaePayment({
    required this.memberId,
    required this.amountMmk,
    required this.paidAt,
    this.paymentMethodMm = 'ငွေသား',
  });

  final String memberId;
  final int amountMmk;
  final DateTime paidAt;
  final String paymentMethodMm;

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'amountMmk': amountMmk,
        'paidAt': paidAt.toIso8601String(),
        'paymentMethodMm': paymentMethodMm,
      };

  factory SuMaePayment.fromJson(Map<String, dynamic> map) {
    return SuMaePayment(
      memberId: (map['memberId'] as String?) ?? '',
      amountMmk: (map['amountMmk'] as num?)?.round() ?? 0,
      paidAt: DateTime.tryParse((map['paidAt'] as String?) ?? '') ??
          DateTime.now(),
      paymentMethodMm: (map['paymentMethodMm'] as String?) ?? 'ငွေသား',
    );
  }
}

/// One collection & payout round (`အလှည့်`) inside a [SuMaeGroup].
class SuMaeRound {
  const SuMaeRound({
    required this.roundNumber,
    required this.dueDate,
    this.payments = const {},
    this.winnerMemberId,
    this.winnerName,
    this.auctionBidMmk = 0,
    this.organizerFeeMmk = 0,
    this.netPayoutMmk = 0,
    this.settledAt,
    this.note = '',
  });

  final int roundNumber;
  final DateTime dueDate;
  final Map<String, SuMaePayment> payments;
  final String? winnerMemberId;
  final String? winnerName;
  final int auctionBidMmk;
  final int organizerFeeMmk;
  final int netPayoutMmk;
  final DateTime? settledAt;
  final String note;

  bool get isClosed => winnerMemberId != null && winnerMemberId!.isNotEmpty;

  int get totalCollectedMmk =>
      payments.values.fold<int>(0, (sum, p) => sum + p.amountMmk);

  int get paidCount => payments.length;

  SuMaeRound copyWith({
    DateTime? dueDate,
    Map<String, SuMaePayment>? payments,
    String? winnerMemberId,
    String? winnerName,
    int? auctionBidMmk,
    int? organizerFeeMmk,
    int? netPayoutMmk,
    DateTime? settledAt,
    bool clearWinner = false,
    String? note,
  }) {
    return SuMaeRound(
      roundNumber: roundNumber,
      dueDate: dueDate ?? this.dueDate,
      payments: payments ?? this.payments,
      winnerMemberId:
          clearWinner ? null : (winnerMemberId ?? this.winnerMemberId),
      winnerName: clearWinner ? null : (winnerName ?? this.winnerName),
      auctionBidMmk: clearWinner ? 0 : (auctionBidMmk ?? this.auctionBidMmk),
      organizerFeeMmk:
          clearWinner ? 0 : (organizerFeeMmk ?? this.organizerFeeMmk),
      netPayoutMmk: clearWinner ? 0 : (netPayoutMmk ?? this.netPayoutMmk),
      settledAt: clearWinner ? null : (settledAt ?? this.settledAt),
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'dueDate': dueDate.toIso8601String(),
        'payments': {
          for (final entry in payments.entries) entry.key: entry.value.toJson(),
        },
        'winnerMemberId': winnerMemberId,
        'winnerName': winnerName,
        'auctionBidMmk': auctionBidMmk,
        'organizerFeeMmk': organizerFeeMmk,
        'netPayoutMmk': netPayoutMmk,
        'settledAt': settledAt?.toIso8601String(),
        'note': note,
      };

  factory SuMaeRound.fromJson(Map<String, dynamic> map) {
    final rawPayments = map['payments'];
    final paymentMap = <String, SuMaePayment>{};
    if (rawPayments is Map<String, dynamic>) {
      for (final entry in rawPayments.entries) {
        if (entry.value is Map<String, dynamic>) {
          paymentMap[entry.key] =
              SuMaePayment.fromJson(entry.value as Map<String, dynamic>);
        }
      }
    }
    return SuMaeRound(
      roundNumber: (map['roundNumber'] as num?)?.toInt() ?? 1,
      dueDate: DateTime.tryParse((map['dueDate'] as String?) ?? '') ??
          DateTime.now(),
      payments: paymentMap,
      winnerMemberId: map['winnerMemberId'] as String?,
      winnerName: map['winnerName'] as String?,
      auctionBidMmk: (map['auctionBidMmk'] as num?)?.toInt() ?? 0,
      organizerFeeMmk: (map['organizerFeeMmk'] as num?)?.toInt() ?? 0,
      netPayoutMmk: (map['netPayoutMmk'] as num?)?.toInt() ?? 0,
      settledAt: DateTime.tryParse((map['settledAt'] as String?) ?? ''),
      note: (map['note'] as String?) ?? '',
    );
  }
}

/// Complete Myanmar Rotating Savings Group (`စုမဲ / ငွေစုစု`) record.
class SuMaeGroup {
  const SuMaeGroup({
    this.id,
    required this.name,
    required this.style,
    required this.cycle,
    required this.contributionPerShareMmk,
    required this.plannedRounds,
    this.organizerName = '',
    this.organizerFeeMmk = 0,
    required this.startDate,
    this.members = const [],
    this.rounds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final SuMaeStyle style;
  final SuMaeCycle cycle;
  final int contributionPerShareMmk;
  final int plannedRounds;
  final String organizerName;
  final int organizerFeeMmk;
  final DateTime startDate;
  final List<SuMaeMember> members;
  final List<SuMaeRound> rounds;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get totalMemberShares =>
      members.fold<double>(0, (sum, m) => sum + m.sharesCount);

  /// Active pot size: uses registered shares when populated, else planned rounds.
  int get potSizeMmk {
    final effectiveShares =
        totalMemberShares > 0 ? totalMemberShares : plannedRounds.toDouble();
    return (contributionPerShareMmk * effectiveShares).round();
  }

  List<SuMaeMember> get waitingMembers =>
      members.where((m) => !m.hasWon).toList();

  int get completedRoundsCount => rounds.where((r) => r.isClosed).length;

  int expectedContributionForMember(SuMaeMember member) =>
      (contributionPerShareMmk * member.sharesCount).round();

  int expectedTotalForRound(SuMaeRound round) {
    if (members.isEmpty) return potSizeMmk;
    return members.fold<int>(
      0,
      (sum, m) => sum + expectedContributionForMember(m),
    );
  }

  /// Calculates actual payout to winner = Pot - Auction Bid (if auction) - Organizer Fee.
  int computeNetPayout({int auctionBidMmk = 0}) {
    final gross = potSizeMmk;
    final net = gross - auctionBidMmk - organizerFeeMmk;
    return net > 0 ? net : 0;
  }

  /// Dividend per waiting share when Auction Su Mae has a positive bid.
  int computeAuctionDividendPerShare(int auctionBidMmk) {
    if (style != SuMaeStyle.auctionBid || auctionBidMmk <= 0) return 0;
    final eligibleShares =
        waitingMembers.fold<double>(0, (sum, m) => sum + m.sharesCount);
    final divisor = eligibleShares > 1 ? (eligibleShares - 1) : 1.0;
    return (auctionBidMmk / divisor).round();
  }

  SuMaeGroup copyWith({
    int? id,
    String? name,
    SuMaeStyle? style,
    SuMaeCycle? cycle,
    int? contributionPerShareMmk,
    int? plannedRounds,
    String? organizerName,
    int? organizerFeeMmk,
    DateTime? startDate,
    List<SuMaeMember>? members,
    List<SuMaeRound>? rounds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SuMaeGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      style: style ?? this.style,
      cycle: cycle ?? this.cycle,
      contributionPerShareMmk:
          contributionPerShareMmk ?? this.contributionPerShareMmk,
      plannedRounds: plannedRounds ?? this.plannedRounds,
      organizerName: organizerName ?? this.organizerName,
      organizerFeeMmk: organizerFeeMmk ?? this.organizerFeeMmk,
      startDate: startDate ?? this.startDate,
      members: members ?? this.members,
      rounds: rounds ?? this.rounds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Formats a ready-to-share Burmese Su Mae round sheet for Viber / Messenger.
  String formatRoundSummaryMm(SuMaeRound round) {
    final buf = StringBuffer()
      ..writeln('💰 $name (${style.labelMm} • ${cycle.labelMm})')
      ..writeln(
        'အလှည့် ${round.roundNumber}/$plannedRounds • ရက်စွဲ: ${formatDateShort(round.dueDate)}',
      )
      ..writeln(
        '၁ မဲ: ${formatMmk(contributionPerShareMmk)} | စုစုပေါင်းမဲငွေ: ${formatMmk(potSizeMmk)}',
      )
      ..writeln('──────────────');
    if (members.isEmpty) {
      buf.writeln('(အဖွဲ့ဝင် မထည့်ရသေးပါ)');
    } else {
      for (var i = 0; i < members.length; i++) {
        final m = members[i];
        final pay = round.payments[m.id];
        final paidTag = pay != null
            ? 'ပေးပြီး ✓ (${formatMmk(pay.amountMmk)}, ${formatDateShort(pay.paidAt)})'
            : 'မပေးရသေး (${formatMmk(expectedContributionForMember(m))})';
        final wonTag = m.hasWon ? ' [အလှည့် ${m.wonRoundNumber} ပေါက်ပြီး]' : '';
        buf.writeln('${i + 1}. ${m.name} (${m.shareLabelMm}) — $paidTag$wonTag');
      }
    }
    final expected = expectedTotalForRound(round);
    final collected = round.totalCollectedMmk;
    final remaining = (expected - collected).clamp(0, expected);
    buf
      ..writeln('──────────────')
      ..writeln(
        'ကောက်ခံပြီး: ${formatMmk(collected)} (${round.paidCount}/${members.length} ဦး)',
      )
      ..writeln('ကောက်ခံရန်ကျန်: ${formatMmk(remaining)}');
    if (round.isClosed) {
      buf.writeln(
        '🏆 အလှည့် ${round.roundNumber} မဲပေါက်သူ: ${round.winnerName} — ထုတ်ပေးငွေ: ${formatMmk(round.netPayoutMmk)}',
      );
      if (round.auctionBidMmk > 0) {
        buf.writeln('လေလံကြေး: ${formatMmk(round.auctionBidMmk)}');
      }
    }
    return buf.toString().trim();
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'style': style.name,
        'cycle': cycle.name,
        'contribution_per_share_mmk': contributionPerShareMmk,
        'planned_rounds': plannedRounds,
        'organizer_name': organizerName,
        'organizer_fee_mmk': organizerFeeMmk,
        'start_date': startDate.toIso8601String(),
        'members_json': jsonEncode(members.map((m) => m.toJson()).toList()),
        'rounds_json': jsonEncode(rounds.map((r) => r.toJson()).toList()),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SuMaeGroup.fromMap(Map<String, Object?> map) {
    var parsedMembers = <SuMaeMember>[];
    final rawMembers = map['members_json'] as String?;
    if (rawMembers != null && rawMembers.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMembers);
        if (decoded is List) {
          parsedMembers = decoded
              .whereType<Map<String, dynamic>>()
              .map(SuMaeMember.fromJson)
              .toList();
        }
      } catch (_) {}
    }

    var parsedRounds = <SuMaeRound>[];
    final rawRounds = map['rounds_json'] as String?;
    if (rawRounds != null && rawRounds.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawRounds);
        if (decoded is List) {
          parsedRounds = decoded
              .whereType<Map<String, dynamic>>()
              .map(SuMaeRound.fromJson)
              .toList();
        }
      } catch (_) {}
    }

    final created =
        DateTime.tryParse((map['created_at'] as String?) ?? '') ??
            DateTime.now();
    final start =
        DateTime.tryParse((map['start_date'] as String?) ?? '') ?? created;
    final cycle = SuMaeCycle.fromName(map['cycle'] as String?);
    if (parsedRounds.isEmpty) {
      parsedRounds = [
        SuMaeRound(
          roundNumber: 1,
          dueDate: cycle.dateForRound(start, 1),
        ),
      ];
    }

    return SuMaeGroup(
      id: (map['id'] as num?)?.toInt(),
      name: (map['name'] as String?) ?? 'စုမဲအဖွဲ့',
      style: SuMaeStyle.fromName(map['style'] as String?),
      cycle: cycle,
      contributionPerShareMmk:
          (map['contribution_per_share_mmk'] as num?)?.toInt() ?? 100000,
      plannedRounds: (map['planned_rounds'] as num?)?.toInt() ?? 10,
      organizerName: (map['organizer_name'] as String?) ?? '',
      organizerFeeMmk: (map['organizer_fee_mmk'] as num?)?.toInt() ?? 0,
      startDate: start,
      members: parsedMembers,
      rounds: parsedRounds,
      createdAt: created,
      updatedAt:
          DateTime.tryParse((map['updated_at'] as String?) ?? '') ?? created,
    );
  }
}
