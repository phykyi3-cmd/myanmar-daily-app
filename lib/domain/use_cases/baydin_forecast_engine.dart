import 'package:myanmar_daily_app/domain/models/baydin_forecast.dart';
import 'package:myanmar_daily_app/domain/models/baydin_reading.dart';
import 'package:myanmar_daily_app/domain/use_cases/myanmar_baydin_engine.dart';

/// Deterministic offline forecast engine for Weekly (7-day), Monthly (30-day),
/// Daily Auspicious Hours + Nagahle Direction, and 2-Person Myanmar Compatibility.
class BaydinForecastEngine {
  BaydinForecastEngine({MyanmarBaydinEngine? baseEngine})
      : _base = baseEngine ?? MyanmarBaydinEngine();

  final MyanmarBaydinEngine _base;

  static const List<String> _gregorianMonthsMm = [
    'ဇန်နဝါရီ',
    'ဖေဖော်ဝါရီ',
    'မတ်',
    'ဧပြီ',
    'မေ',
    'ဇွန်',
    'ဇူလိုင်',
    'ဩဂုတ်',
    'စက်တင်ဘာ',
    'အောက်တိုဘာ',
    'နိုဝင်ဘာ',
    'ဒီဇင်ဘာ',
  ];

  static const Map<MyanmarWeekday, MyanmarWeekday> _friendPairs = {
    MyanmarWeekday.sunday: MyanmarWeekday.thursday,
    MyanmarWeekday.thursday: MyanmarWeekday.sunday,
    MyanmarWeekday.monday: MyanmarWeekday.wednesday,
    MyanmarWeekday.wednesday: MyanmarWeekday.monday,
    MyanmarWeekday.tuesday: MyanmarWeekday.friday,
    MyanmarWeekday.friday: MyanmarWeekday.tuesday,
    MyanmarWeekday.saturday: MyanmarWeekday.rahu,
    MyanmarWeekday.rahu: MyanmarWeekday.saturday,
  };

  static const Map<MyanmarWeekday, MyanmarWeekday> _spousePairs = {
    MyanmarWeekday.sunday: MyanmarWeekday.friday,
    MyanmarWeekday.friday: MyanmarWeekday.sunday,
    MyanmarWeekday.tuesday: MyanmarWeekday.thursday,
    MyanmarWeekday.thursday: MyanmarWeekday.tuesday,
    MyanmarWeekday.saturday: MyanmarWeekday.wednesday,
    MyanmarWeekday.wednesday: MyanmarWeekday.saturday,
    MyanmarWeekday.monday: MyanmarWeekday.rahu,
    MyanmarWeekday.rahu: MyanmarWeekday.monday,
  };

  static const Map<MyanmarWeekday, MyanmarWeekday> _elementPairs = {
    MyanmarWeekday.saturday: MyanmarWeekday.thursday,
    MyanmarWeekday.thursday: MyanmarWeekday.saturday,
    MyanmarWeekday.friday: MyanmarWeekday.monday,
    MyanmarWeekday.monday: MyanmarWeekday.friday,
    MyanmarWeekday.sunday: MyanmarWeekday.wednesday,
    MyanmarWeekday.wednesday: MyanmarWeekday.sunday,
    MyanmarWeekday.rahu: MyanmarWeekday.tuesday,
    MyanmarWeekday.tuesday: MyanmarWeekday.rahu,
  };

  static const Map<MyanmarWeekday, MyanmarWeekday> _enemyPairs = {
    MyanmarWeekday.sunday: MyanmarWeekday.tuesday,
    MyanmarWeekday.tuesday: MyanmarWeekday.sunday,
    MyanmarWeekday.monday: MyanmarWeekday.thursday,
    MyanmarWeekday.thursday: MyanmarWeekday.monday,
    MyanmarWeekday.friday: MyanmarWeekday.saturday,
    MyanmarWeekday.saturday: MyanmarWeekday.friday,
    MyanmarWeekday.wednesday: MyanmarWeekday.rahu,
    MyanmarWeekday.rahu: MyanmarWeekday.wednesday,
  };

  static const List<MyanmarWeekday> _dayHourCycle = [
    MyanmarWeekday.sunday,
    MyanmarWeekday.monday,
    MyanmarWeekday.tuesday,
    MyanmarWeekday.wednesday,
    MyanmarWeekday.thursday,
    MyanmarWeekday.friday,
    MyanmarWeekday.saturday,
  ];

  static String toMyanmarDigits(int value) {
    const digits = ['၀', '၁', '၂', '၃', '၄', '၅', '၆', '၇', '၈', '၉'];
    return value
        .toString()
        .split('')
        .map((ch) {
          final parsed = int.tryParse(ch);
          return parsed == null ? ch : digits[parsed];
        })
        .join();
  }

  static String formatGregorianDayMm(DateTime d) {
    final monthName = _gregorianMonthsMm[(d.month - 1).clamp(0, 11)];
    return '${toMyanmarDigits(d.day)} $monthName';
  }

  static String formatGregorianMonthYearMm(int year, int month) {
    final monthName = _gregorianMonthsMm[(month - 1).clamp(0, 11)];
    return '$monthName ${toMyanmarDigits(year)}';
  }

  /// Returns the Monday starting the calendar week containing [date].
  DateTime startOfWeekMonday(DateTime date) {
    final clean = DateTime(date.year, date.month, date.day);
    final diff = clean.weekday - DateTime.monday;
    return clean.subtract(Duration(days: diff));
  }

  /// Evaluates a single calendar date against the user's Mahabote / birth weekday / Thet-Yauk.
  DailyTransitOutlook evaluateDay({
    required DateTime date,
    required BaydinReading reading,
  }) {
    final summary = _base.inspectDate(date);
    final dayPlanet = _base.weekdayFromDate(date);
    final birth = reading.birthWeekday;
    final thetYauk = reading.currentThetYaukPlanet;

    var rawScore = 3; // Neutral baseline 1..5
    final tags = <String>[];

    if (summary.isYatyaza) {
      rawScore += 2;
      tags.add('ရက်ရာဇာ');
    }
    if (summary.isSabbath) {
      rawScore += 1;
      tags.add('ဥပုသ်');
    } else if (summary.isSabbathEve) {
      tags.add('အဖိတ်');
    }
    if (summary.isPyathada) {
      rawScore -= 2;
      tags.add('ပြဿဒါး');
    } else if (summary.isAfternoonPyathada) {
      rawScore -= 1;
      tags.add('မွန်းလွဲပြဿဒါး');
    }

    if (dayPlanet == _friendPairs[birth]) {
      rawScore += 2;
      tags.add('မိတ်ဖက်နံ');
    } else if (dayPlanet == reading.tipPlanet) {
      rawScore += 1;
      tags.add('အညွန့်နံ');
    } else if (dayPlanet == _spousePairs[birth]) {
      rawScore += 1;
      tags.add('အိမ်ထောင်ဖက်နံ');
    } else if (dayPlanet == birth) {
      rawScore += 1;
      tags.add('မွေးနံနေ့');
    } else if (dayPlanet == _enemyPairs[birth]) {
      rawScore -= 2;
      tags.add('ရန်ဖက်နံ');
    } else if (dayPlanet == reading.rootPlanet) {
      rawScore -= 1;
      tags.add('အမြစ်နံ');
    }

    if (dayPlanet == thetYauk) {
      rawScore += reading.isBummiYear ? -1 : 1;
    }

    final clampedScore = rawScore.clamp(1, 5);
    final level = clampedScore >= 4
        ? DayEnergyLevel.lucky
        : (clampedScore <= 2 ? DayEnergyLevel.caution : DayEnergyLevel.balanced);

    final relationTag =
        tags.isEmpty ? '${dayPlanet.labelMm}ဓာတ် ပုံမှန်' : tags.take(2).join(' • ');

    final briefNote = _buildDailyBriefNote(
      level: level,
      summary: summary,
      dayPlanet: dayPlanet,
      birth: birth,
      isBummi: reading.isBummiYear,
    );

    final shortMmDate = _extractShortMyanmarDate(summary.myanmarDateFormatted);

    return DailyTransitOutlook(
      date: DateTime(date.year, date.month, date.day),
      myanmarDateShort: shortMmDate,
      weekdayLabelMm: summary.weekdayLabelMm,
      planet: dayPlanet,
      energyLevel: level,
      score: clampedScore,
      isYatyaza: summary.isYatyaza,
      isPyathada: summary.isPyathada,
      isAfternoonPyathada: summary.isAfternoonPyathada,
      isSabbath: summary.isSabbath,
      isSabbathEve: summary.isSabbathEve,
      nagahleMm: summary.nagahleMm,
      relationTagMm: relationTag,
      briefNoteMm: briefNote,
    );
  }

  /// Generates a complete deterministic 7-day weekly horoscope (Monday–Sunday).
  WeeklyBaydinForecast calculateWeeklyForecast({
    required BaydinReading reading,
    DateTime? targetDate,
  }) {
    final anchor = targetDate ?? reading.referenceDate;
    final weekStart = startOfWeekMonday(anchor);
    final weekEnd = weekStart.add(const Duration(days: 6));

    final days = List<DailyTransitOutlook>.generate(
      7,
      (i) => evaluateDay(
        date: weekStart.add(Duration(days: i)),
        reading: reading,
      ),
    );

    final sortedBest = [...days]..sort((a, b) => b.score.compareTo(a.score));
    final bestDays = sortedBest
        .where((d) => d.energyLevel == DayEnergyLevel.lucky)
        .take(3)
        .toList();
    if (bestDays.isEmpty) {
      bestDays.addAll(sortedBest.take(2));
    }

    final cautionDays = days
        .where((d) => d.energyLevel == DayEnergyLevel.caution)
        .toList()
      ..sort((a, b) => a.score.compareTo(b.score));

    final avgDayScore =
        days.fold<int>(0, (sum, d) => sum + d.score) / days.length;
    final houseBonus = switch (reading.mahaboteHouse) {
      MahaboteHouse.adipati || MahaboteHouse.yaza => 7,
      MahaboteHouse.atun || MahaboteHouse.thike => 4,
      MahaboteHouse.puti => 1,
      MahaboteHouse.binga || MahaboteHouse.marana => -5,
    };
    final bummiAdj = reading.isBummiYear ? -6 : 3;
    final weekSeed = _periodSeed(
      year: weekStart.year,
      slot: _isoWeekIndex(weekStart),
      birth: reading.birthWeekday,
      house: reading.mahaboteHouse,
      focus: reading.focus,
    );
    final rawPct = (avgDayScore * 17.5 + houseBonus + bummiAdj + (weekSeed % 7) - 2)
        .round()
        .clamp(48, 96);
    final stars = rawPct >= 86
        ? 5
        : rawPct >= 75
            ? 4
            : rawPct >= 62
                ? 3
                : 2;

    final energyTitle = rawPct >= 82
        ? 'ကံဇာတာ အထူးပွင့်လန်းသော အပတ်'
        : rawPct >= 68
            ? 'တည်ငြိမ်တိုးတက်နိုင်သော အပတ်'
            : 'ဆင်ခြင်ထိန်းညှိသင့်သော အပတ်';

    final bestDaySummary = bestDays
        .map((d) => '${d.weekdayLabelMm} (${formatGregorianDayMm(d.date)})')
        .join(' နှင့် ');
    final cautionDaySummary = cautionDays.isEmpty
        ? 'ကြီးကြီးမားမား အညံ့ရက်မရှိပါ'
        : cautionDays
            .take(2)
            .map((d) => '${d.weekdayLabelMm} (${formatGregorianDayMm(d.date)})')
            .join('၊ ');

    final headline = _pickWeeklyHeadline(
      seed: weekSeed,
      reading: reading,
      bestDaySummary: bestDaySummary,
      rawPct: rawPct,
    );

    final luckyNumbers = _deriveLuckyNumbers(
      birth: reading.birthWeekday,
      target: reading.yadayaTargetPlanet,
      seed: weekSeed,
    );
    final safeDirection = _safeLuckyDirection(
      preferred: reading.yadayaTargetPlanet.directionMm,
      nagahleHead: days[weekStart.weekday % 7].nagahleMm,
    );

    final myanmarSpan =
        '${days.first.myanmarDateShort} – ${days.last.myanmarDateShort}';
    final weekRangeLabel =
        '${formatGregorianDayMm(weekStart)} – ${formatGregorianDayMm(weekEnd)} ${toMyanmarDigits(weekEnd.year)}';

    return WeeklyBaydinForecast(
      weekStart: weekStart,
      weekEnd: weekEnd,
      weekRangeLabelMm: weekRangeLabel,
      myanmarWeekSpanMm: myanmarSpan,
      weekScore: rawPct,
      starRating: stars,
      energyTitleMm: energyTitle,
      headlineMm: headline,
      days: days,
      bestDays: bestDays,
      cautionDays: cautionDays,
      workBusinessMm: _buildWeeklyWork(
        seed: weekSeed,
        reading: reading,
        bestDaySummary: bestDaySummary,
        cautionDaySummary: cautionDaySummary,
      ),
      financeWealthMm: _buildWeeklyFinance(
        seed: weekSeed,
        reading: reading,
        bestDaySummary: bestDaySummary,
        rawPct: rawPct,
      ),
      loveFamilyMm: _buildWeeklyLove(
        seed: weekSeed,
        reading: reading,
        cautionDaySummary: cautionDaySummary,
      ),
      healthTravelMm: _buildWeeklyHealth(
        seed: weekSeed,
        reading: reading,
        safeDirection: safeDirection,
        nagahleExample: days.first.nagahleMm,
      ),
      luckyNumbersMm: luckyNumbers,
      luckyColorLabelMm: reading.prescription.wearOutfitTitleMm,
      luckyColorHex: reading.prescription.wearPrimaryHex,
      luckyDirectionMm: safeDirection,
      weeklyYadayaMm: _buildWeeklyYadaya(
        reading: reading,
        bestDay: bestDays.first,
        seed: weekSeed,
      ),
      weeklyAdviceMm:
          'ယခုအပတ်အတွင်း $bestDaySummary တို့၌ အရေးကြီးကိစ္စ၊ ငွေကြေးစာချုပ်နှင့် ဆုံးဖြတ်ချက်များ ဦးစားပေးဆောင်ရွက်ပြီး ($cautionDaySummary) တွင် စိတ်အေးအေးထား ဆင်ခြင်ပါ။',
    );
  }

  /// Generates a complete deterministic full-month horoscope with 3-phase trends & key dates.
  MonthlyBaydinForecast calculateMonthlyForecast({
    required BaydinReading reading,
    int? year,
    int? month,
  }) {
    final targetYear = year ?? reading.referenceDate.year;
    final targetMonth = month ?? reading.referenceDate.month;
    final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;

    final allDays = List<DailyTransitOutlook>.generate(
      daysInMonth,
      (i) => evaluateDay(
        date: DateTime(targetYear, targetMonth, i + 1),
        reading: reading,
      ),
    );

    final earlyDays = allDays.where((d) => d.date.day <= 10).toList();
    final midDays =
        allDays.where((d) => d.date.day >= 11 && d.date.day <= 20).toList();
    final lateDays = allDays.where((d) => d.date.day >= 21).toList();

    final monthSeed = _periodSeed(
      year: targetYear,
      slot: targetMonth,
      birth: reading.birthWeekday,
      house: reading.mahaboteHouse,
      focus: reading.focus,
    );

    final phases = [
      _buildPhaseOutlook(
        title: 'လဆန်းပိုင်း',
        dayRange: '၁ – ၁၀ ရက်',
        days: earlyDays,
        reading: reading,
        seed: monthSeed + 1,
      ),
      _buildPhaseOutlook(
        title: 'လလယ်ပိုင်း',
        dayRange: '၁၁ – ၂၀ ရက်',
        days: midDays,
        reading: reading,
        seed: monthSeed + 2,
      ),
      _buildPhaseOutlook(
        title: 'လကုန်ပိုင်း',
        dayRange: '၂၁ – ${toMyanmarDigits(daysInMonth)} ရက်',
        days: lateDays,
        reading: reading,
        seed: monthSeed + 3,
      ),
    ];

    final sortedBest = [...allDays]..sort((a, b) {
        final cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
        final yCmp = (b.isYatyaza ? 1 : 0).compareTo(a.isYatyaza ? 1 : 0);
        if (yCmp != 0) return yCmp;
        return a.date.compareTo(b.date);
      });
    final bestDates = sortedBest
        .where((d) => d.energyLevel == DayEnergyLevel.lucky)
        .take(5)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (bestDates.isEmpty) {
      bestDates.addAll(
        sortedBest.take(4).toList()..sort((a, b) => a.date.compareTo(b.date)),
      );
    }

    final cautionDates = allDays
        .where((d) => d.isPyathada || d.energyLevel == DayEnergyLevel.caution)
        .toList()
      ..sort((a, b) => a.score.compareTo(b.score));
    final topCaution = cautionDates.take(4).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final sabbathDates = allDays.where((d) => d.isSabbath).toList();

    final avgScore =
        allDays.fold<int>(0, (sum, d) => sum + d.score) / allDays.length;
    final houseBonus = switch (reading.mahaboteHouse) {
      MahaboteHouse.adipati || MahaboteHouse.yaza => 6,
      MahaboteHouse.atun || MahaboteHouse.thike => 4,
      MahaboteHouse.puti => 1,
      MahaboteHouse.binga || MahaboteHouse.marana => -4,
    };
    final bummiAdj = reading.isBummiYear ? -5 : 3;
    final monthPct = (avgScore * 17.5 + houseBonus + bummiAdj + (monthSeed % 6) - 1)
        .round()
        .clamp(50, 95);
    final stars = monthPct >= 85
        ? 5
        : monthPct >= 74
            ? 4
            : monthPct >= 62
                ? 3
                : 2;

    final energyTitle = monthPct >= 82
        ? 'အခွင့်အလမ်းနှင့် လာဘ်လာဘ တိုးပွားမည့်လ'
        : monthPct >= 68
            ? 'စနစ်တကျ ကြိုးစားလျှင် အောင်မြင်မည့်လ'
            : 'အခြေအနေထိန်းပြီး ပြင်ဆင်သင့်သည့်လ';

    final monthTitle = formatGregorianMonthYearMm(targetYear, targetMonth);
    final mmSpan = _extractMyanmarMonthSpan(
      allDays.first.myanmarDateShort,
      allDays.last.myanmarDateShort,
    );

    final bestShort = bestDates
        .take(3)
        .map((d) => '${toMyanmarDigits(d.date.day)} ရက် (${d.planet.labelMm})')
        .join('၊ ');
    final cautionShort = topCaution.isEmpty
        ? 'ပြဿဒါးရက်များ'
        : topCaution
            .take(3)
            .map((d) => '${toMyanmarDigits(d.date.day)} ရက်')
            .join('၊ ');

    final safeDirection = _safeLuckyDirection(
      preferred: reading.yadayaTargetPlanet.directionMm,
      nagahleHead: allDays[daysInMonth ~/ 2].nagahleMm,
    );

    return MonthlyBaydinForecast(
      year: targetYear,
      month: targetMonth,
      monthTitleMm: monthTitle,
      myanmarMonthSpanMm: mmSpan,
      monthScore: monthPct,
      starRating: stars,
      energyTitleMm: energyTitle,
      headlineMm:
          '$monthTitle ($mmSpan) သည် ${reading.birthWeekday.labelMm}သား/သမီး (${reading.mahaboteHouse.titleMm}) အတွက် ${reading.currentThetYaukPlanet.labelMm}သက်ရောက်နှင့် တွဲဖက်၍ ${monthPct >= 75 ? 'အလုပ်အကိုင်သစ်နှင့် ဝင်ငွေလမ်းကြောင်း ပွင့်လန်းနိုင်သောလ' : 'အလျင်စလိုမလုပ်ဘဲ အခြေခံခိုင်မာအောင် တည်ဆောက်သင့်သောလ'} ဖြစ်ပါသည်။',
      phases: phases,
      bestDates: bestDates,
      cautionDates: topCaution,
      sabbathDates: sabbathDates,
      workBusinessMm: _buildMonthlyWork(
        seed: monthSeed,
        reading: reading,
        bestShort: bestShort,
        cautionShort: cautionShort,
      ),
      financeWealthMm: _buildMonthlyFinance(
        seed: monthSeed,
        reading: reading,
        bestShort: bestShort,
        monthPct: monthPct,
      ),
      loveFamilyMm: _buildMonthlyLove(
        seed: monthSeed,
        reading: reading,
        sabbathCount: sabbathDates.length,
      ),
      healthTravelMm: _buildMonthlyHealth(
        seed: monthSeed,
        reading: reading,
        safeDirection: safeDirection,
        cautionShort: cautionShort,
      ),
      luckyNumbersMm: _deriveLuckyNumbers(
        birth: reading.birthWeekday,
        target: reading.yadayaTargetPlanet,
        seed: monthSeed + 11,
      ),
      luckyColorLabelMm: reading.prescription.wearOutfitTitleMm,
      luckyColorHex: reading.prescription.wearPrimaryHex,
      luckyDirectionMm: safeDirection,
      monthlyYadayaMm:
          'ယခုလအတွင်း ဥပုသ်နေ့ (${sabbathDates.isNotEmpty ? formatGregorianDayMm(sabbathDates.first.date) : bestShort}) သို့မဟုတ် မိမိမွေးနံနေ့ နံနက်ပိုင်းတွင် ${reading.prescription.flowerTitleMm} (${reading.prescription.flowerCountLabelMm}) နှင့် ${reading.prescription.almsTitleMm} တို့ကို ဘုရားရှင်အား ရည်မှန်းကပ်လှူပြီး လိုရာဆုတောင်းပါ။',
    );
  }

  /// Calculates Today's real Nagahle head direction and 6 daytime 2-hour auspicious slots.
  DailyAuspiciousGuide calculateDailyAuspiciousGuide({
    required DateTime date,
    MyanmarWeekday? userBirthWeekday,
  }) {
    final summary = _base.inspectDate(date);
    final dayPlanet = _base.weekdayFromDate(date);
    final startIdx = _dayHourCycle.indexOf(dayPlanet).clamp(0, 6);

    const windows = [
      'နံနက် ၀၆:၀၀ – ၀၈:၀၀',
      'နံနက် ၀၈:၀၀ – ၁၀:၀၀',
      'နံနက် ၁၀:၀၀ – ၁၂:၀၀',
      'မွန်းလွဲ ၁၂:၀၀ – ၀၂:၀၀',
      'မွန်းလွဲ ၀၂:၀၀ – ၀၄:၀၀',
      'ညနေ ၀၄:၀၀ – ၀၆:၀၀',
    ];

    final slots = <DailyAuspiciousSlot>[];
    for (var i = 0; i < windows.length; i++) {
      final slotPlanet = _dayHourCycle[(startIdx + i) % _dayHourCycle.length];
      final isUserFriend = userBirthWeekday != null &&
          (_friendPairs[userBirthWeekday] == slotPlanet ||
              _spousePairs[userBirthWeekday] == slotPlanet ||
              userBirthWeekday == slotPlanet);
      final isUserEnemy = userBirthWeekday != null &&
          _enemyPairs[userBirthWeekday] == slotPlanet;
      final isDayEnemy = _enemyPairs[dayPlanet] == slotPlanet;
      final afternoonPenalty = summary.isAfternoonPyathada && i >= 3;

      final isCaution =
          summary.isPyathada || afternoonPenalty || isUserEnemy || isDayEnemy;
      final isGood = !isCaution &&
          (isUserFriend ||
              slotPlanet == _friendPairs[dayPlanet] ||
              slotPlanet == dayPlanet ||
              summary.isYatyaza);

      final quality = isGood
          ? 'အခါကောင်း'
          : (isCaution ? 'သတိပြု/ရှောင်' : 'ပုံမှန်');
      final purpose = isGood
          ? 'အလုပ်စတင်ရန်၊ ခရီးထွက်ရန်၊ ငွေကြေးစကားပြောရန် အထူးကောင်း'
          : (isCaution
              ? 'စာချုပ်လက်မှတ်ထိုးခြင်းနှင့် အရေးကြီးဆုံးဖြတ်ချက် ခေတ္တဆိုင်းငံ့သင့်'
              : 'နေ့စဉ်လုပ်ငန်းဆောင်တာများ ပုံမှန်ဆောင်ရွက်နိုင်');

      slots.add(
        DailyAuspiciousSlot(
          timeWindowMm: windows[i],
          planetLabelMm: '${slotPlanet.labelMm}အခါ',
          qualityLabelMm: quality,
          isGood: isGood,
          isCaution: isCaution,
          purposeMm: purpose,
        ),
      );
    }

    final head = summary.nagahleMm;
    final safeDirs = _safeDirectionsForNagahle(head);

    return DailyAuspiciousGuide(
      date: DateTime(date.year, date.month, date.day),
      myanmarDateFormatted: summary.myanmarDateFormatted,
      nagahleHeadMm: head,
      avoidDirectionMm: '$head အရပ်သို့ ဦးတည်ခရီးစတင်ခြင်း ရှောင်သင့်',
      safeDirectionsMm: safeDirs,
      slots: slots,
    );
  }

  /// Evaluates classical Myanmar 8-planet compatibility between two birth weekdays.
  CompatibilityResult calculateCompatibility({
    required MyanmarWeekday personA,
    required MyanmarWeekday personB,
  }) {
    if (_spousePairs[personA] == personB) {
      final luckyDay = _friendPairs[personA] ?? MyanmarWeekday.thursday;
      return CompatibilityResult(
        personA: personA,
        personB: personB,
        bondTypeMm: 'အိမ်ထောင်ဖက် • ဖူးစာမွန်',
        classicalRhymeMm: 'ဥဿာ – စိန်ပန်း – ဒန်းလှ – ကိုရှာ',
        overallScore: 93,
        loveScore: 96,
        businessScore: 88,
        isHarmonious: true,
        loveAnalysisMm:
            '${personA.labelMm}နှင့် ${personB.labelMm}တို့သည် မြန်မာ့နက္ခတ်ဗေဒင်အရ အလိုက်ဖက်ဆုံး "အိမ်ထောင်ဖက် (ဖူးစာမွန်)" တွဲဖက်မှုဖြစ်ပါသည်။ တစ်ဦးနှင့်တစ်ဦး နားလည်မှုအားကောင်းပြီး ရေရှည်လက်တွဲရာတွင် အိမ်တွင်းရေး သာယာချမ်းမြေ့မည်။',
        businessAnalysisMm:
            'စီးပွားရေးနှင့် အိမ်ထောင်စုစီမံခန့်ခွဲမှုတွင် တစ်ဦးအားနည်းချက်ကို တစ်ဦးက ဖြည့်ဆည်းပေးနိုင်သဖြင့် ပူးပေါင်းလုပ်ကိုင်ပါက စီးပွားတိုးတက်မည်။',
        sharedLuckyDayMm: '${luckyDay.labelMm}နေ့ နှင့် ${personA.labelMm}နေ့',
        harmonizingYadayaMm:
            'နှစ်ဦးအတူ ဥပုသ်နေ့တွင် ဘုရားရှင်အား ${personA.flowerNameMm}နှင့် သောက်ရေချမ်း ကပ်လှူပြီး မေတ္တာပို့ခြင်းဖြင့် ချစ်ခင်မြဲမြံစေမည်။',
      );
    }

    if (_friendPairs[personA] == personB) {
      final luckyDay = _spousePairs[personA] ?? MyanmarWeekday.friday;
      return CompatibilityResult(
        personA: personA,
        personB: personB,
        bondTypeMm: 'မိတ်ဖက် • အကျိုးပေးတွဲဖက်',
        classicalRhymeMm: 'အောင်ပ – ကုလား – ဆွေသား – တော်ရင်း',
        overallScore: 89,
        loveScore: 87,
        businessScore: 92,
        isHarmonious: true,
        loveAnalysisMm:
            '${personA.labelMm}နှင့် ${personB.labelMm}သည် "အတွင်းမိတ်/ဓာတ်မိတ်" ဖြစ်၍ မိတ်ဆွေမှ ချစ်သူဖြစ်လာလျှင်လည်းကောင်း၊ အိမ်ထောင်ပြုလျှင်လည်းကောင်း တစ်ဦးကိုတစ်ဦး ဖေးမကူညီတတ်သော ဆက်ဆံရေးကောင်း ရရှိမည်။',
        businessAnalysisMm:
            'စီးပွားဖက်အဖြစ် ပူးပေါင်းလုပ်ကိုင်ရန် အထူးသင့်တော်ပြီး ငွေကြေးလာဘ်လာဘနှင့် လူမှုရေးအရှိန်အဝါ အတူတကွ တိုးပွားမည်။',
        sharedLuckyDayMm: '${personA.labelMm}နေ့ နှင့် ${luckyDay.labelMm}နေ့',
        harmonizingYadayaMm:
            'နှစ်ဦးအတူ ${personB.labelMm}နေ့ နံနက်ပိုင်းတွင် ဆီမီးပူဇော်ပြီး အလှူဒါနပြုခြင်းဖြင့် လာဘ်ပွင့်အောင်မြင်မည်။',
      );
    }

    if (_elementPairs[personA] == personB) {
      final luckyDay = _friendPairs[personA] ?? MyanmarWeekday.wednesday;
      return CompatibilityResult(
        personA: personA,
        personB: personB,
        bondTypeMm: 'ဓာတ်ဖက် • စီးပွားရေးတိုးတက်',
        classicalRhymeMm: 'ဓမ္မာ – သောက – အင်းဝ – ရာဇာ',
        overallScore: 84,
        loveScore: 81,
        businessScore: 90,
        isHarmonious: true,
        loveAnalysisMm:
            '${personA.labelMm}နှင့် ${personB.labelMm}သည် "ဓာတ်ဖက်" တွဲဖက်ဖြစ်၍ အတွေးအမြင် တူညီတတ်ပြီး တစ်ဦး၏အကြံဉာဏ်ကို တစ်ဦးက လေးစားလက်ခံသည့် ရင့်ကျက်သော အချစ်ရေးဖြစ်ပါသည်။',
        businessAnalysisMm:
            'ရေရှည်စီးပွားရေး၊ ရင်းနှီးမြှုပ်နှံမှုနှင့် အဖွဲ့အစည်းလုပ်ငန်းများတွင် ခိုင်မာသော ရလဒ်ကောင်းများ ဖန်တီးနိုင်မည့် တွဲဖက်မှုဖြစ်သည်။',
        sharedLuckyDayMm: '${luckyDay.labelMm}နေ့',
        harmonizingYadayaMm:
            'အရေးကြီးလုပ်ငန်း စတင်သည့်နေ့တွင် ဘုရားရှင်အား ရွှေ/အဖြူ ပန်းနှင့် ဆွမ်းတော်ကပ်လှူပြီး စတင်ပါ။',
      );
    }

    if (personA == personB) {
      final luckyDay = _friendPairs[personA] ?? MyanmarWeekday.thursday;
      return CompatibilityResult(
        personA: personA,
        personB: personB,
        bondTypeMm: 'မွေးနံတူ • စိတ်သဘောထားတူ',
        classicalRhymeMm: 'တူညီဂြိုဟ်ဓာတ် (မွေးနံတူ တွဲဖက်)',
        overallScore: 78,
        loveScore: 79,
        businessScore: 77,
        isHarmonious: true,
        loveAnalysisMm:
            'နှစ်ဦးလုံး ${personA.labelMm}နံ တူညီသဖြင့် ဝါသနာနှင့် စိတ်ထားခြင်း နားလည်လွယ်သည်။ သို့သော် နှစ်ဦးလုံး မာန/စိတ်ခံစားချက် ပြိုင်တူတက်ချိန်တွင် တစ်ဦးက အလျှော့ပေးညှိနှိုင်းရန် လိုအပ်ပါသည်။',
        businessAnalysisMm:
            'ပန်းတိုင်တူညီသဖြင့် အစပိုင်းတွင် အရှိန်ကောင်းမည်။ ငွေကြေးနှင့် တာဝန်ခွဲဝေမှုကို စာရင်းအတိအကျထား၍ လုပ်ကိုင်ပါက ရေရှည်တည်တံ့မည်။',
        sharedLuckyDayMm: '${luckyDay.labelMm}နေ့',
        harmonizingYadayaMm:
            'မွေးနံတူ အတူတကွ ${luckyDay.labelMm}နေ့တွင် ${luckyDay.flowerNameMm} ကပ်လှူပူဇော်ပါ။',
      );
    }

    if (_enemyPairs[personA] == personB) {
      final bridgePlanet = _friendPairs[personA] ?? MyanmarWeekday.thursday;
      return CompatibilityResult(
        personA: personA,
        personB: personB,
        bondTypeMm: 'ရန်ဖက် • သည်းခံညှိနှိုင်းရန်',
        classicalRhymeMm: 'ဦးညို – ခေမာ – သုတ – ဝေရီ',
        overallScore: 56,
        loveScore: 58,
        businessScore: 54,
        isHarmonious: false,
        loveAnalysisMm:
            '${personA.labelMm}နှင့် ${personB.labelMm}သည် ဂြိုဟ်ဓာတ်အရ "ရန်ဖက်" ကျသဖြင့် စကားအပြောအဆို အမြင်ကွဲလွဲလွယ်တတ်သည်။ သို့သော် မေတ္တာစစ်နှင့် သည်းခံနားလည်မှုထားကာ တစ်ဦးစိတ်တိုချိန် တစ်ဦးက နှုတ်ဆိတ်ပေးလျှင် အေးချမ်းစွာ ကျော်လွှားနိုင်ပါသည်။',
        businessAnalysisMm:
            'စီးပွားရေးပူးပေါင်းရာတွင် နှုတ်ကတိဖြင့်မလုပ်ဘဲ စာချုပ်စာတမ်း၊ ငွေစာရင်း ရှင်းလင်းစွာထားရှိပြီး မိတ်ဖက်ဖြစ်သော ${bridgePlanet.labelMm}သား/သမီးအား ကြားခံညှိနှိုင်းသူအဖြစ် ပါဝင်စေသင့်သည်။',
        sharedLuckyDayMm: '${bridgePlanet.labelMm}နေ့ (ကြားခံမိတ်ဖက်နေ့)',
        harmonizingYadayaMm:
            'အညံ့ဓာတ်ပြေစေရန် နှစ်ဦးအတူ ဥပုသ်နေ့တွင် သံဃာတော်အား သောက်ရေသန့်နှင့် အအေးဒါနပြုကာ ${bridgePlanet.flowerNameMm} ကပ်လှူပူဇော်ပါ။',
      );
    }

    // Neutral (ဥဒါသိန်) pair
    final luckyDay = _friendPairs[personA] ?? MyanmarWeekday.friday;
    return CompatibilityResult(
      personA: personA,
      personB: personB,
      bondTypeMm: 'ဥဒါသိန် • တည်ငြိမ်မျှတ',
      classicalRhymeMm: 'ဥဒါသိန်ဓာတ် (မိတ်မဟုတ် – ရန်မဟုတ် မျှတတွဲဖက်)',
      overallScore: 74,
      loveScore: 75,
      businessScore: 73,
      isHarmonious: true,
      loveAnalysisMm:
          '${personA.labelMm}နှင့် ${personB.labelMm}သည် မိတ်ရန်ကင်းသော "ဥဒါသိန်" တွဲဖက်ဖြစ်သဖြင့် ကြီးကြီးမားမား ပဋိပက္ခမရှိဘဲ အေးချမ်းတည်ငြိမ်သော ဆက်ဆံရေးကို နှစ်ဦးသား ကြိုးစားတည်ဆောက်နိုင်ပါသည်။',
      businessAnalysisMm:
          'ပုံမှန်တိုးတက်မှုရရှိမည့် တွဲဖက်မှုဖြစ်ပြီး ရက်ရာဇာရက်များတွင် အရေးကြီးဆုံးဖြတ်ချက်ချကာ ပွင့်လင်းစွာ ဆွေးနွေးလုပ်ကိုင်ပါက အောင်မြင်မည်။',
      sharedLuckyDayMm: '${luckyDay.labelMm}နေ့',
      harmonizingYadayaMm:
          'နှစ်ဦးအတူ ${luckyDay.labelMm}နေ့တွင် ဘုရားပန်းနှင့် ဆီမီးပူဇော်ပြီး ကုသိုလ်အတူပြုပါ။',
    );
  }

  String _extractShortMyanmarDate(String fullFormatted) {
    // Strip leading year prefix like "မြန်မာသက္ကရာဇ် ၁၃၈၈ ခုနှစ်၊ " when present.
    final idx = fullFormatted.indexOf('ခုနှစ်');
    if (idx != -1 && idx + 7 < fullFormatted.length) {
      return fullFormatted
          .substring(idx + 6)
          .replaceFirst(RegExp(r'^[၊,\s]+'), '')
          .trim();
    }
    return fullFormatted.trim();
  }

  String _extractMyanmarMonthSpan(String firstShort, String lastShort) {
    final firstWord = firstShort.split(' ').first;
    final lastWord = lastShort.split(' ').first;
    if (firstWord.isEmpty) return lastShort;
    if (lastWord.isEmpty || firstWord == lastWord) return '$firstWordလ';
    return '$firstWord – $lastWord';
  }

  int _isoWeekIndex(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final diffDays = date.difference(startOfYear).inDays;
    return (diffDays ~/ 7) + 1;
  }

  int _periodSeed({
    required int year,
    required int slot,
    required MyanmarWeekday birth,
    required MahaboteHouse house,
    required YadayaFocus focus,
  }) {
    return (year * 31 +
            slot * 17 +
            birth.planetNumber * 13 +
            house.index * 7 +
            focus.index * 5)
        .abs();
  }

  String _deriveLuckyNumbers({
    required MyanmarWeekday birth,
    required MyanmarWeekday target,
    required int seed,
  }) {
    final a = birth.planetNumber;
    final b = target.planetNumber;
    final c = ((a + b + (seed % 5)) % 9) + 1;
    final set = <int>{a, b, c};
    if (set.length < 3) {
      set.add(((c + 2) % 9) + 1);
    }
    return set.map(toMyanmarDigits).join('၊ ');
  }

  String _safeLuckyDirection({
    required String preferred,
    required String nagahleHead,
  }) {
    if (nagahleHead.isNotEmpty && preferred.contains(nagahleHead)) {
      return switch (nagahleHead) {
        'အရှေ့' => 'အနောက် (သို့) တောင်',
        'အနောက်' => 'အရှေ့ (သို့) မြောက်',
        'တောင်' => 'မြောက် (သို့) အရှေ့',
        'မြောက်' => 'တောင် (သို့) အနောက်',
        _ => 'အရှေ့မြောက်',
      };
    }
    return preferred;
  }

  String _safeDirectionsForNagahle(String head) {
    return switch (head) {
      'အရှေ့' => 'အနောက်၊ တောင်၊ မြောက် အရပ်များ ဘေးကင်းကောင်းမွန်',
      'အနောက်' => 'အရှေ့၊ မြောက်၊ တောင် အရပ်များ ဘေးကင်းကောင်းမွန်',
      'တောင်' => 'မြောက်၊ အရှေ့၊ အနောက် အရပ်များ ဘေးကင်းကောင်းမွန်',
      'မြောက်' => 'တောင်၊ အနောက်၊ အရှေ့ အရပ်များ ဘေးကင်းကောင်းမွန်',
      _ => 'အရှေ့မြောက် နှင့် အနောက်တောင် အရပ်များ ကောင်းမွန်',
    };
  }

  String _buildDailyBriefNote({
    required DayEnergyLevel level,
    required CalendarDaySummary summary,
    required MyanmarWeekday dayPlanet,
    required MyanmarWeekday birth,
    required bool isBummi,
  }) {
    if (summary.isSabbath && summary.isYatyaza) {
      return 'ဥပုသ် + ရက်ရာဇာ အထူးနေ့မြတ် • ကုသိုလ်ပြု၍ ကိစ္စကောင်းစတင်ရန် အကောင်းဆုံး';
    }
    if (level == DayEnergyLevel.lucky) {
      if (summary.isYatyaza) {
        return 'ရက်ရာဇာကျပြီး ${dayPlanet.labelMm}ဓာတ်အားကောင်း • အလုပ်/ငွေကြေး စတင်ရန် သင့်တော်';
      }
      return '${birth.labelMm}နံနှင့် ဓာတ်ညီသောနေ့ • ဆွေးနွေးညှိနှိုင်းမှုနှင့် ဝင်ငွေကောင်း';
    }
    if (level == DayEnergyLevel.caution) {
      if (summary.isPyathada) {
        return 'ပြဿဒါးရက် • အရေးကြီးစာချုပ်၊ ခရီးဝေးနှင့် ငွေအပေးအယူကြီးများ ရှောင်သင့်';
      }
      if (summary.isAfternoonPyathada) {
        return 'မွန်းလွဲပြဿဒါး • အရေးကြီးကိစ္စများ နံနက်ပိုင်းတွင်သာ ပြီးစီးအောင်လုပ်ပါ';
      }
      return isBummi
          ? 'ရန်နံ + ဘုမ္မိအရှိန် • စိတ်အေးအေးထားပြီး အငြင်းပွားမှု ရှောင်ကြဉ်ပါ'
          : 'ဂြိုဟ်ဓာတ်အားနည်းရက် • စကားအပြောအဆိုနှင့် ငွေထွက်မှု သတိပြုပါ';
    }
    if (summary.isSabbath) {
      return 'ဥပုသ်နေ့ • သီလဆောက်တည် မေတ္တာပို့ခြင်းဖြင့် စိတ်အေးချမ်း လာဘ်ပွင့်မည်';
    }
    return 'နေ့စဉ်လုပ်ငန်းများ ပုံမှန်ဆောင်ရွက်နိုင်သော တည်ငြိမ်နေ့';
  }

  String _pickWeeklyHeadline({
    required int seed,
    required BaydinReading reading,
    required String bestDaySummary,
    required int rawPct,
  }) {
    final poolHigh = [
      '${reading.birthWeekday.labelMm}သား/သမီးအတွက် ယခုအပတ်သည် ${reading.mahaboteHouse.titleMm}အားဖြင့် အခွင့်အလမ်းသစ်များ ပေါ်ထွက်ပြီး $bestDaySummary တွင် သတင်းကောင်းရနိုင်သော အပတ်ဖြစ်ပါသည်။',
      'ယခုအပတ်အတွင်း ${reading.currentThetYaukPlanet.labelMm}သက်ရောက်နှင့် ဓာတ်ညီနေသဖြင့် ကြိုးစားထားသမျှ ရလဒ်ကောင်းမြင်တွေ့ရမည့် အပတ်ဖြစ်သည်။',
      'မိတ်ဆွေကောင်းအကူအညီနှင့် လာဘ်လာဘပွင့်လန်းမည့် အပတ်ဖြစ်ပြီး $bestDaySummary ကို အကျိုးရှိရှိ အသုံးချသင့်သည်။',
    ];
    final poolMid = [
      'ယခုအပတ်သည် အေးချမ်းတည်ငြိမ်စွာ ရှေ့ဆက်နိုင်မည့်အပတ်ဖြစ်ပြီး $bestDaySummary တွင် အရေးကြီးကိစ္စ ဦးစားပေးလုပ်ဆောင်ပါက အောင်မြင်မည်။',
      '${reading.mahaboteHouse.titleMm}၏ ပံ့ပိုးမှုဖြင့် ပုံမှန်တိုးတက်မှုရမည့်အပတ်ဖြစ်ကာ အသေးအဖွဲ စိတ်ရှုပ်မှုများကို အေးဆေးကျော်လွှားနိုင်မည်။',
    ];
    final poolCare = [
      'ယခုအပတ်တွင် အလျင်စလို ဆုံးဖြတ်ချက်မချဘဲ $bestDaySummary ကိုသာ စောင့်၍ ဆောင်ရွက်ပါက အညံ့ပြေပြီး အဆင်ပြေချောမွေ့မည်။',
      'စိတ်အေးအေးထား၍ အစီအစဉ်စနစ်တကျ ဆောင်ရွက်သင့်သော အပတ်ဖြစ်ပြီး ဘုရားပန်း/မေတ္တာပို့ခြင်းဖြင့် အကာအကွယ်ရမည်။',
    ];

    if (rawPct >= 80) return poolHigh[seed % poolHigh.length];
    if (rawPct >= 66) return poolMid[seed % poolMid.length];
    return poolCare[seed % poolCare.length];
  }

  String _buildWeeklyWork({
    required int seed,
    required BaydinReading reading,
    required String bestDaySummary,
    required String cautionDaySummary,
  }) {
    final variants = [
      'အလုပ်အကိုင်တွင် $bestDaySummary တို့၌ အထက်လူကြီး သို့မဟုတ် မိတ်ဖက်များနှင့် ဆွေးနွေးတင်ပြပါက ထောက်ခံမှုရမည်။ ($cautionDaySummary) တွင် စာရွက်စာတမ်း သေချာစစ်ဆေးပါ။',
      '${reading.birthWeekday.labelMm}နံအတွက် ယခုအပတ်တွင် ကြန့်ကြာနေသော အလုပ်ဟောင်းများ ပြန်လည်လည်ပတ်လာမည်။ အရေးကြီးအရောင်းအဝယ်ကို $bestDaySummary တွင် ဆောင်ရွက်ပါ။',
      'လုပ်ငန်းသစ်စတင်ရန် သို့မဟုတ် အရည်အချင်းပြသရန် $bestDaySummary သည် အကောင်းဆုံးဖြစ်ပြီး တွဲဖက်လုပ်ကိုင်သူများနှင့် ပွင့်လင်းစွာညှိနှိုင်းပါ။',
    ];
    return variants[seed % variants.length];
  }

  String _buildWeeklyFinance({
    required int seed,
    required BaydinReading reading,
    required String bestDaySummary,
    required int rawPct,
  }) {
    if (reading.isBummiYear || rawPct < 65) {
      return 'ယခုအပတ်တွင် မထင်မှတ်သော အိမ်သုံး/လူမှုရေး အပိုစရိတ် ထွက်တတ်သဖြင့် ငွေချေးငှားခြင်းနှင့် အလျင်စလို ရင်းနှီးမြှုပ်နှံမှု ရှောင်ပြီး ဘတ်ဂျက်ထိန်းသိမ်းပါ။';
    }
    final variants = [
      'ဝင်ငွေလမ်းကြောင်း ပုံမှန်ထက်ပိုကောင်းနိုင်ပြီး $bestDaySummary တွင် ငွေဝင်လာဘ်ရွှင်နိုင်သည်။ ဝင်လာသောငွေမှ တစ်စိတ်တစ်ပိုင်း စုဆောင်းထားသင့်သည်။',
      'အရောင်းအဝယ်နှင့် လုပ်ခလစာအပြင် အပိုဝင်ငွေ/လက်ဆောင် ရရှိနိုင်သည့်အပတ်ဖြစ်ပြီး ငွေအပေးအယူကို $bestDaySummary တွင် ပြုလုပ်ပါ။',
    ];
    return variants[(seed + 1) % variants.length];
  }

  String _buildWeeklyLove({
    required int seed,
    required BaydinReading reading,
    required String cautionDaySummary,
  }) {
    final spouse = _spousePairs[reading.birthWeekday] ?? MyanmarWeekday.friday;
    final variants = [
      'ချစ်သူ/အိမ်ထောင်ရှင်များ အချင်းချင်း နားလည်မှုတိုးပွားပြီး အိမ်တွင်းရေးအေးချမ်းမည်။ Single များအတွက် ${spouse.labelMm}နံ သို့မဟုတ် မိတ်ဆွေအသိုင်းအဝိုင်းမှ စိတ်ဝင်စားဖွယ် ဆုံတွေ့မှုရှိနိုင်သည်။',
      'မိသားစုနှင့် ချစ်သူကြားတွင် ($cautionDaySummary) ၌ အသေးအဖွဲ စကားအမြင်မတူမှု မဖြစ်စေရန် နူးညံ့စွာပြောဆိုပါက တစ်ပတ်လုံး ပျော်ရွှင်အေးချမ်းမည်။',
    ];
    return variants[(seed + 2) % variants.length];
  }

  String _buildWeeklyHealth({
    required int seed,
    required BaydinReading reading,
    required String safeDirection,
    required String nagahleExample,
  }) {
    final variants = [
      'ကျန်းမာရေးအနေဖြင့် အိပ်ရေးဝအောင်အိပ်ပြီး ရေများများသောက်ပါ။ ခရီးသွားလာရာတွင် $safeDirection အရပ်သို့ ဦးတည်ပါက ဘေးကင်းချောမွေ့မည် (နဂါးခေါင်းလှည့်ရာ $nagahleExample အရပ်ကို သတိပြုပါ)။',
      'အစားအသောက်နှင့် ခါး/ပခုံး အညောင်းအညာ ဂရုစိုက်ပါ။ မိမိမွေးနံ (${reading.birthWeekday.labelMm}နေ့) တွင် ခရီးတို/မိသားစုအပြင်ထွက်ခြင်းဖြင့် စိတ်လန်းဆန်းမည်။',
    ];
    return variants[(seed + 3) % variants.length];
  }

  String _buildWeeklyYadaya({
    required BaydinReading reading,
    required DailyTransitOutlook bestDay,
    required int seed,
  }) {
    final planet = reading.yadayaTargetPlanet;
    final offerings = [
      '${bestDay.weekdayLabelMm} (${formatGregorianDayMm(bestDay.date)}) နံနက်ပိုင်းတွင် ဘုရားရှင်အား ${reading.prescription.flowerTitleMm} (${reading.prescription.flowerCountLabelMm}) နှင့် သောက်ရေချမ်း ကပ်လှူပြီး လိုရာဆုတောင်းပါ။',
      'ယခုအပတ် ${planet.labelMm}နေ့တွင် ဘုရားရှင်အား ${reading.prescription.almsTitleMm} ကပ်လှူပြီး မေတ္တာသုတ် (${planet.planetYears > 10 ? 9 : planet.planetYears}) ခေါက် ရွတ်ဖတ်ပူဇော်ပါ။',
    ];
    return offerings[seed % offerings.length];
  }

  MonthlyPhaseOutlook _buildPhaseOutlook({
    required String title,
    required String dayRange,
    required List<DailyTransitOutlook> days,
    required BaydinReading reading,
    required int seed,
  }) {
    final avg = days.isEmpty
        ? 3.0
        : days.fold<int>(0, (sum, d) => sum + d.score) / days.length;
    final yatyazaCount = days.where((d) => d.isYatyaza).length;
    final pyathadaCount = days.where((d) => d.isPyathada).length;

    final level = avg >= 3.45
        ? DayEnergyLevel.lucky
        : (avg <= 2.65 ? DayEnergyLevel.caution : DayEnergyLevel.balanced);

    final summary = switch (level) {
      DayEnergyLevel.lucky =>
        'ရက်ရာဇာ (${toMyanmarDigits(yatyazaCount)}) ရက်ပါဝင်ပြီး ကံဇာတာအားကောင်းသဖြင့် အလုပ်သစ်၊ ငွေကြေးစာချုပ်နှင့် အရေးကြီးအစီအစဉ်များ စတင်ဆောင်ရွက်ရန် အထူးကောင်းမွန်ပါသည်။',
      DayEnergyLevel.caution =>
        'ပြဿဒါး/ဂြိုဟ်အားနည်းရက် (${toMyanmarDigits(pyathadaCount)}) ရက်ရှိနေ၍ အလျင်စလို ငွေထုတ်သုံးခြင်းနှင့် အငြင်းပွားမှုများ ရှောင်ကာ စနစ်တကျ ထိန်းသိမ်းသင့်သည့်အပိုင်း ဖြစ်သည်။',
      DayEnergyLevel.balanced =>
        '${reading.birthWeekday.labelMm}နံအတွက် တည်ငြိမ်မျှတသောကာလဖြစ်ပြီး ပုံမှန်လုပ်ငန်းများ အဆင်ပြေချောမွေ့ကာ ရက်ကောင်းရွေး၍ ရှေ့ဆက်နိုင်မည်။',
    };

    return MonthlyPhaseOutlook(
      phaseTitleMm: title,
      dayRangeLabelMm: dayRange,
      energyLevel: level,
      summaryMm: summary,
    );
  }

  String _buildMonthlyWork({
    required int seed,
    required BaydinReading reading,
    required String bestShort,
    required String cautionShort,
  }) {
    final options = [
      'ယခုလအတွင်း $bestShort ရက်များသည် အလုပ်အကိုင်တိုးတက်ရန်၊ ရာထူး/လစာ ဆွေးနွေးရန်နှင့် လုပ်ငန်းသစ်စတင်ရန် အကောင်းဆုံးရက်များ ဖြစ်ပါသည်။ $cautionShort ရက်များတွင် အရေးကြီးစာချုပ် မချုပ်ဆိုဘဲ စစ်ဆေးပြင်ဆင်ပါ။',
      '${reading.mahaboteHouse.titleMm}အားဖြင့် ယခုလတွင် မိမိ၏အရည်အချင်းကို အသိအမှတ်ပြုခံရမည်။ အရေးကြီးအရောင်းအဝယ်နှင့် ပူးပေါင်းဆောင်ရွက်မှုများကို $bestShort တွင် ဦးစားပေးဆောင်ရွက်ပါ။',
    ];
    return options[seed % options.length];
  }

  String _buildMonthlyFinance({
    required int seed,
    required BaydinReading reading,
    required String bestShort,
    required int monthPct,
  }) {
    if (reading.isBummiYear || monthPct < 66) {
      return 'ယခုလတွင် ရွှေ/မြေ အကြီးစားရင်းနှီးမြှုပ်နှံမှုနှင့် ငွေချေးငှားမှုများ ဆိုင်းငံ့ပြီး ဝင်ငွေ-ထွက်ငွေ စာရင်းစနစ်တကျ မှတ်တမ်းတင်ထိန်းသိမ်းပါက လကုန်တွင် စိတ်အေးရမည်။';
    }
    return 'ဝင်ငွေတိုးပွားနိုင်သောလဖြစ်ပြီး $bestShort ရက်များ၌ ငွေဝင်လမ်းကြောင်း ပွင့်လန်းနိုင်သည်။ လလယ်ပိုင်း အိမ်သုံးစရိတ်ကို မျှတစွာစီမံပါက လကုန်တွင် စုဆောင်းငွေ ကျန်ရှိမည်။';
  }

  String _buildMonthlyLove({
    required int seed,
    required BaydinReading reading,
    required int sabbathCount,
  }) {
    final spouse = _spousePairs[reading.birthWeekday] ?? MyanmarWeekday.friday;
    return 'အိမ်တွင်းရေးနှင့် အချစ်ရေးတွင် ယခုလ ဥပုသ် (${toMyanmarDigits(sabbathCount)}) ရက်၌ မိသားစု/ချစ်သူနှင့်အတူ ကုသိုလ်ပြုခြင်းဖြင့် နားလည်မှုပိုမိုခိုင်မာမည်။ Single များအတွက် ${spouse.labelMm}နံ သို့မဟုတ် လုပ်ငန်းခွင်/မိတ်ဆွေမှတစ်ဆင့် ဆုံတွေ့မှုကောင်း ပေါ်ပေါက်နိုင်သည်။';
  }

  String _buildMonthlyHealth({
    required int seed,
    required BaydinReading reading,
    required String safeDirection,
    required String cautionShort,
  }) {
    return 'ယခုလအတွင်း $cautionShort ရက်များ၌ ညဘက်ခရီးဝေးနှင့် အလုပ်ပင်ပန်းလွန်းခြင်းကို ဆင်ခြင်ပါ။ ခရီးသွားလာခြင်းနှင့် အပြောင်းအလဲများအတွက် $safeDirection အရပ်သည် ဘေးကင်းအကျိုးပေးမည်။';
  }
}
