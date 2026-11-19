import 'baydin_reading.dart';

/// Time horizon displayed in the Baydin reading area.
enum BaydinForecastPeriod {
  weekly(labelMm: 'တစ်ပတ်စာ', subtitleMm: '၇ ရက် ကံဇာတာ'),
  monthly(labelMm: 'တစ်လစာ', subtitleMm: '၁ လ ဟောစာတမ်း'),
  mahabote(labelMm: 'မဟာဘုတ် • ယတြာ', subtitleMm: 'ဇာတာခွင်နှင့် ယတြာ');

  const BaydinForecastPeriod({
    required this.labelMm,
    required this.subtitleMm,
  });

  final String labelMm;
  final String subtitleMm;
}

/// Daily astrological energy level combining Myanmar calendar flags and birth-planet harmony.
enum DayEnergyLevel {
  lucky(labelMm: 'ကံကောင်း'),
  balanced(labelMm: 'ပုံမှန်'),
  caution(labelMm: 'သတိပြု');

  const DayEnergyLevel({required this.labelMm});
  final String labelMm;
}

/// Astrological transit summary for one specific calendar date tailored to a user's birth chart.
class DailyTransitOutlook {
  const DailyTransitOutlook({
    required this.date,
    required this.myanmarDateShort,
    required this.weekdayLabelMm,
    required this.planet,
    required this.energyLevel,
    required this.score,
    required this.isYatyaza,
    required this.isPyathada,
    required this.isAfternoonPyathada,
    required this.isSabbath,
    required this.isSabbathEve,
    required this.nagahleMm,
    required this.relationTagMm,
    required this.briefNoteMm,
  });

  final DateTime date;
  final String myanmarDateShort;
  final String weekdayLabelMm;
  final MyanmarWeekday planet;
  final DayEnergyLevel energyLevel;
  final int score;
  final bool isYatyaza;
  final bool isPyathada;
  final bool isAfternoonPyathada;
  final bool isSabbath;
  final bool isSabbathEve;
  final String nagahleMm;
  final String relationTagMm;
  final String briefNoteMm;
}

/// Deterministic 7-day weekly Myanmar Baydin forecast derived from calendar transits + Mahabote/Thet-Yauk.
class WeeklyBaydinForecast {
  const WeeklyBaydinForecast({
    required this.weekStart,
    required this.weekEnd,
    required this.weekRangeLabelMm,
    required this.myanmarWeekSpanMm,
    required this.weekScore,
    required this.starRating,
    required this.energyTitleMm,
    required this.headlineMm,
    required this.days,
    required this.bestDays,
    required this.cautionDays,
    required this.workBusinessMm,
    required this.financeWealthMm,
    required this.loveFamilyMm,
    required this.healthTravelMm,
    required this.luckyNumbersMm,
    required this.luckyColorLabelMm,
    required this.luckyColorHex,
    required this.luckyDirectionMm,
    required this.weeklyYadayaMm,
    required this.weeklyAdviceMm,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final String weekRangeLabelMm;
  final String myanmarWeekSpanMm;
  final int weekScore;
  final int starRating;
  final String energyTitleMm;
  final String headlineMm;
  final List<DailyTransitOutlook> days;
  final List<DailyTransitOutlook> bestDays;
  final List<DailyTransitOutlook> cautionDays;
  final String workBusinessMm;
  final String financeWealthMm;
  final String loveFamilyMm;
  final String healthTravelMm;
  final String luckyNumbersMm;
  final String luckyColorLabelMm;
  final int luckyColorHex;
  final String luckyDirectionMm;
  final String weeklyYadayaMm;
  final String weeklyAdviceMm;
}

/// Early, Mid, or Late month trend block inside a monthly forecast.
class MonthlyPhaseOutlook {
  const MonthlyPhaseOutlook({
    required this.phaseTitleMm,
    required this.dayRangeLabelMm,
    required this.energyLevel,
    required this.summaryMm,
  });

  final String phaseTitleMm;
  final String dayRangeLabelMm;
  final DayEnergyLevel energyLevel;
  final String summaryMm;
}

/// Deterministic full-month Myanmar Baydin forecast with 3-phase trends and key calendar dates.
class MonthlyBaydinForecast {
  const MonthlyBaydinForecast({
    required this.year,
    required this.month,
    required this.monthTitleMm,
    required this.myanmarMonthSpanMm,
    required this.monthScore,
    required this.starRating,
    required this.energyTitleMm,
    required this.headlineMm,
    required this.phases,
    required this.bestDates,
    required this.cautionDates,
    required this.sabbathDates,
    required this.workBusinessMm,
    required this.financeWealthMm,
    required this.loveFamilyMm,
    required this.healthTravelMm,
    required this.luckyNumbersMm,
    required this.luckyColorLabelMm,
    required this.luckyColorHex,
    required this.luckyDirectionMm,
    required this.monthlyYadayaMm,
  });

  final int year;
  final int month;
  final String monthTitleMm;
  final String myanmarMonthSpanMm;
  final int monthScore;
  final int starRating;
  final String energyTitleMm;
  final String headlineMm;
  final List<MonthlyPhaseOutlook> phases;
  final List<DailyTransitOutlook> bestDates;
  final List<DailyTransitOutlook> cautionDates;
  final List<DailyTransitOutlook> sabbathDates;
  final String workBusinessMm;
  final String financeWealthMm;
  final String loveFamilyMm;
  final String healthTravelMm;
  final String luckyNumbersMm;
  final String luckyColorLabelMm;
  final int luckyColorHex;
  final String luckyDirectionMm;
  final String monthlyYadayaMm;
}

/// One 2-hour daytime auspicious window (မဟာဘုတ် အခါပေး).
class DailyAuspiciousSlot {
  const DailyAuspiciousSlot({
    required this.timeWindowMm,
    required this.planetLabelMm,
    required this.qualityLabelMm,
    required this.isGood,
    required this.isCaution,
    required this.purposeMm,
  });

  final String timeWindowMm;
  final String planetLabelMm;
  final String qualityLabelMm;
  final bool isGood;
  final bool isCaution;
  final String purposeMm;
}

/// Today's Nagahle direction (နဂါးခေါင်းလှည့်ရာ) and 6 daytime auspicious timing slots.
class DailyAuspiciousGuide {
  const DailyAuspiciousGuide({
    required this.date,
    required this.myanmarDateFormatted,
    required this.nagahleHeadMm,
    required this.avoidDirectionMm,
    required this.safeDirectionsMm,
    required this.slots,
  });

  final DateTime date;
  final String myanmarDateFormatted;
  final String nagahleHeadMm;
  final String avoidDirectionMm;
  final String safeDirectionsMm;
  final List<DailyAuspiciousSlot> slots;
}

/// Classical Myanmar 8-planet compatibility result between two people.
class CompatibilityResult {
  const CompatibilityResult({
    required this.personA,
    required this.personB,
    required this.bondTypeMm,
    required this.classicalRhymeMm,
    required this.overallScore,
    required this.loveScore,
    required this.businessScore,
    required this.isHarmonious,
    required this.loveAnalysisMm,
    required this.businessAnalysisMm,
    required this.sharedLuckyDayMm,
    required this.harmonizingYadayaMm,
  });

  final MyanmarWeekday personA;
  final MyanmarWeekday personB;
  final String bondTypeMm;
  final String classicalRhymeMm;
  final int overallScore;
  final int loveScore;
  final int businessScore;
  final bool isHarmonious;
  final String loveAnalysisMm;
  final String businessAnalysisMm;
  final String sharedLuckyDayMm;
  final String harmonizingYadayaMm;
}
