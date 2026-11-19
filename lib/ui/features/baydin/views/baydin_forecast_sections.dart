import 'package:flutter/material.dart';

import 'package:myanmar_daily_app/domain/models/baydin_forecast.dart';
import 'package:myanmar_daily_app/domain/models/baydin_reading.dart';
import 'package:myanmar_daily_app/domain/use_cases/baydin_forecast_engine.dart';
import 'package:myanmar_daily_app/ui/core/theme/app_theme.dart';
import '../view_models/baydin_view_model.dart';

Color _energyColor(DayEnergyLevel level) {
  return switch (level) {
    DayEnergyLevel.lucky => const Color(0xFF4ADE80),
    DayEnergyLevel.balanced => const Color(0xFFFACC15),
    DayEnergyLevel.caution => const Color(0xFFF87171),
  };
}

Color _energyBg(DayEnergyLevel level) {
  return switch (level) {
    DayEnergyLevel.lucky => const Color(0xFF142818),
    DayEnergyLevel.balanced => const Color(0xFF26200D),
    DayEnergyLevel.caution => const Color(0xFF2B1416),
  };
}

/// Prominent 3-period selector bar (Weekly / Monthly / Mahabote+Yadaya).
class BaydinPeriodSwitcherBar extends StatelessWidget {
  const BaydinPeriodSwitcherBar({
    super.key,
    required this.activePeriod,
    required this.onSelected,
    this.weeklyScore,
    this.monthlyScore,
  });

  final BaydinForecastPeriod activePeriod;
  final ValueChanged<BaydinForecastPeriod> onSelected;
  final int? weeklyScore;
  final int? monthlyScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF14171D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B3426), width: 1.2),
      ),
      child: Row(
        children: BaydinForecastPeriod.values.map((period) {
          final isSelected = period == activePeriod;
          final badgeText = switch (period) {
            BaydinForecastPeriod.weekly =>
              weeklyScore != null ? '${BaydinForecastEngine.toMyanmarDigits(weeklyScore!)}%' : '၇ ရက်',
            BaydinForecastPeriod.monthly =>
              monthlyScore != null ? '${BaydinForecastEngine.toMyanmarDigits(monthlyScore!)}%' : '၁ လ',
            BaydinForecastPeriod.mahabote => 'ဇာတာ',
          };

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => onSelected(period),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.neonLime600
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        period == BaydinForecastPeriod.mahabote
                            ? 'မဟာဘုတ်'
                            : period.labelMm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? AppTheme.obsidian1000
                              : AppTheme.white100,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badgeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppTheme.obsidian1000.withValues(alpha: 0.78)
                              : AppTheme.gray300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Compact quick-jump teaser rendered on the Mahabote view so users spot Weekly & Monthly immediately.
class QuickPeriodTeaserBanner extends StatelessWidget {
  const QuickPeriodTeaserBanner({
    super.key,
    required this.weekly,
    required this.monthly,
    required this.onOpenWeekly,
    required this.onOpenMonthly,
  });

  final WeeklyBaydinForecast weekly;
  final MonthlyBaydinForecast monthly;
  final VoidCallback onOpenWeekly;
  final VoidCallback onOpenMonthly;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TeaserTile(
            icon: Icons.date_range_rounded,
            title: 'တစ်ပတ်စာ ဟောစာတမ်း',
            subtitle:
                'ကံဇာတာ ${BaydinForecastEngine.toMyanmarDigits(weekly.weekScore)}/၁၀၀ • ရက်ကောင်း ${BaydinForecastEngine.toMyanmarDigits(weekly.bestDays.length)} ရက်',
            accent: AppTheme.neonLime500,
            onTap: onOpenWeekly,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TeaserTile(
            icon: Icons.calendar_month_rounded,
            title: 'တစ်လစာ ဟောစာတမ်း',
            subtitle:
                'ကံဇာတာ ${BaydinForecastEngine.toMyanmarDigits(monthly.monthScore)}/၁၀၀ • ${monthly.myanmarMonthSpanMm}',
            accent: const Color(0xFFFACC15),
            onTap: onOpenMonthly,
          ),
        ),
      ],
    );
  }
}

class _TeaserTile extends StatelessWidget {
  const _TeaserTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFF151914),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 16, color: accent),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.3,
                color: AppTheme.gray200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Complete 7-day Weekly Horoscope UI with week stepper, daily transit timeline, and weekly Yadaya.
class WeeklyForecastView extends StatelessWidget {
  const WeeklyForecastView({
    super.key,
    required this.reading,
    required this.forecast,
    required this.weekOffset,
    required this.onShiftWeek,
    required this.onResetWeek,
    required this.onAddFlowerToMarket,
  });

  final BaydinReading reading;
  final WeeklyBaydinForecast forecast;
  final int weekOffset;
  final ValueChanged<int> onShiftWeek;
  final VoidCallback onResetWeek;
  final Future<void> Function(BaydinReading) onAddFlowerToMarket;

  @override
  Widget build(BuildContext context) {
    final offsetLabel = weekOffset == 0
        ? 'ယခုအပတ်'
        : weekOffset > 0
            ? 'နောက် ${BaydinForecastEngine.toMyanmarDigits(weekOffset)} ပတ်'
            : 'လွန်ခဲ့သော ${BaydinForecastEngine.toMyanmarDigits(weekOffset.abs())} ပတ်';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Week Navigation Bar
        _PeriodNavigationHeader(
          badgeLabel: offsetLabel,
          title: forecast.weekRangeLabelMm,
          subtitle: 'မြန်မာရက် • ${forecast.myanmarWeekSpanMm}',
          showReset: weekOffset != 0,
          prevTooltip: 'ယခင်အပတ်',
          nextTooltip: 'နောက်အပတ်',
          onPrev: () => onShiftWeek(-1),
          onNext: () => onShiftWeek(1),
          onReset: onResetWeek,
        ),
        const SizedBox(height: 12),

        // 2. Hero Score Card
        _ForecastScoreHeroCard(
          userTitle:
              '${reading.name} (${reading.birthWeekday.labelMm}သား/သမီး • ${reading.mahaboteHouse.titleMm})',
          score: forecast.weekScore,
          stars: forecast.starRating,
          energyTitle: forecast.energyTitleMm,
          headline: forecast.headlineMm,
          accentColor: AppTheme.neonLime500,
        ),
        const SizedBox(height: 12),

        // 3. Best & Caution Quick Summary
        _BestCautionSummaryCard(
          bestTitle: 'ယခုအပတ် အကောင်းဆုံးရက်များ',
          cautionTitle: 'သတိပြုဆင်ခြင်ရမည့်ရက်များ',
          bestDates: forecast.bestDays,
          cautionDates: forecast.cautionDays,
        ),
        const SizedBox(height: 12),

        // 4. 7-Day Daily Transit Breakdown
        _SectionShellCard(
          icon: Icons.view_week_rounded,
          title: 'တစ်ပတ်စာ နေ့ရက်အလိုက် ကံဇာတာ (၇ ရက်)',
          accent: AppTheme.neonLime500,
          child: Column(
            children: forecast.days.map((day) {
              final accent = _energyColor(day.energyLevel);
              final bg = _energyBg(day.energyLevel);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${day.weekdayLabelMm} • ${BaydinForecastEngine.formatGregorianDayMm(day.date)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.white100,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${day.energyLevel.labelMm} • ${BaydinForecastEngine.toMyanmarDigits(day.score)}/၅',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.myanmarDateShort}  |  ${day.relationTagMm}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: accent.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.briefNoteMm,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppTheme.gray200,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // 5. 4-Category Weekly Forecasts
        _FourCategoryForecastCard(
          sectionTitle: 'ယခုအပတ် ကဏ္ဍအလိုက် ဟောစာတမ်း',
          workMm: forecast.workBusinessMm,
          financeMm: forecast.financeWealthMm,
          loveMm: forecast.loveFamilyMm,
          healthMm: forecast.healthTravelMm,
        ),
        const SizedBox(height: 12),

        // 6. Lucky Boosters + Weekly Yadaya
        _LuckyAndYadayaCard(
          title: 'ယခုအပတ် ကံပွင့်အချက်များနှင့် အပတ်စဉ်ယတြာ',
          luckyNumbersMm: forecast.luckyNumbersMm,
          luckyColorLabelMm: forecast.luckyColorLabelMm,
          luckyColorHex: forecast.luckyColorHex,
          luckyDirectionMm: forecast.luckyDirectionMm,
          yadayaTextMm: forecast.weeklyYadayaMm,
          adviceTextMm: forecast.weeklyAdviceMm,
          onAddFlower: () => onAddFlowerToMarket(reading),
        ),
      ],
    );
  }
}

/// Complete full-month Horoscope UI with month stepper, 3-phase trends, key dates & monthly Yadaya.
class MonthlyForecastView extends StatelessWidget {
  const MonthlyForecastView({
    super.key,
    required this.reading,
    required this.forecast,
    required this.monthOffset,
    required this.onShiftMonth,
    required this.onResetMonth,
    required this.onAddFlowerToMarket,
  });

  final BaydinReading reading;
  final MonthlyBaydinForecast forecast;
  final int monthOffset;
  final ValueChanged<int> onShiftMonth;
  final VoidCallback onResetMonth;
  final Future<void> Function(BaydinReading) onAddFlowerToMarket;

  @override
  Widget build(BuildContext context) {
    final offsetLabel = monthOffset == 0
        ? 'ယခုလ'
        : monthOffset > 0
            ? 'နောက် ${BaydinForecastEngine.toMyanmarDigits(monthOffset)} လ'
            : 'လွန်ခဲ့သော ${BaydinForecastEngine.toMyanmarDigits(monthOffset.abs())} လ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Month Navigation Bar
        _PeriodNavigationHeader(
          badgeLabel: offsetLabel,
          title: forecast.monthTitleMm,
          subtitle: 'မြန်မာလ • ${forecast.myanmarMonthSpanMm}',
          showReset: monthOffset != 0,
          prevTooltip: 'ယခင်လ',
          nextTooltip: 'နောက်လ',
          onPrev: () => onShiftMonth(-1),
          onNext: () => onShiftMonth(1),
          onReset: onResetMonth,
        ),
        const SizedBox(height: 12),

        // 2. Hero Score Card
        _ForecastScoreHeroCard(
          userTitle:
              '${reading.name} (${reading.birthWeekday.labelMm}သား/သမီး • ${reading.currentThetYaukPlanet.labelMm}သက်ရောက်)',
          score: forecast.monthScore,
          stars: forecast.starRating,
          energyTitle: forecast.energyTitleMm,
          headline: forecast.headlineMm,
          accentColor: const Color(0xFFFACC15),
        ),
        const SizedBox(height: 12),

        // 3. 3-Phase Monthly Trend (Early / Mid / Late Month)
        _SectionShellCard(
          icon: Icons.timeline_rounded,
          title: 'တစ်လစာ ကံအတက်အကျ (၃ ပိုင်းခွဲ)',
          accent: const Color(0xFFFACC15),
          child: Column(
            children: forecast.phases.map((phase) {
              final accent = _energyColor(phase.energyLevel);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _energyBg(phase.energyLevel),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: 0.42)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${phase.phaseTitleMm} (${phase.dayRangeLabelMm})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.white100,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            phase.energyLevel.labelMm,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      phase.summaryMm,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppTheme.gray200,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // 4. Key Dates of the Month (Best / Sabbath / Caution)
        _BestCautionSummaryCard(
          bestTitle: 'ယခုလ မင်္ဂလာ/အရေးကြီးကိစ္စ အကောင်းဆုံးရက်များ',
          cautionTitle: 'သတိပြု/ရှောင်ရှားသင့်သော ရက်စွဲများ',
          bestDates: forecast.bestDates,
          cautionDates: forecast.cautionDates,
          sabbathDates: forecast.sabbathDates,
        ),
        const SizedBox(height: 12),

        // 5. 4-Category Monthly Forecasts
        _FourCategoryForecastCard(
          sectionTitle: 'ယခုလ ကဏ္ဍအလိုက် ဟောစာတမ်း',
          workMm: forecast.workBusinessMm,
          financeMm: forecast.financeWealthMm,
          loveMm: forecast.loveFamilyMm,
          healthMm: forecast.healthTravelMm,
        ),
        const SizedBox(height: 12),

        // 6. Lucky Boosters + Monthly Special Yadaya
        _LuckyAndYadayaCard(
          title: 'ယခုလ ကံပွင့်အချက်များနှင့် လစဉ်အထူးယတြာ',
          luckyNumbersMm: forecast.luckyNumbersMm,
          luckyColorLabelMm: forecast.luckyColorLabelMm,
          luckyColorHex: forecast.luckyColorHex,
          luckyDirectionMm: forecast.luckyDirectionMm,
          yadayaTextMm: forecast.monthlyYadayaMm,
          onAddFlower: () => onAddFlowerToMarket(reading),
        ),
      ],
    );
  }
}

/// Compact expandable card showing Today's Nagahle Head Direction & 6 Daytime Auspicious Slots.
class DailyAuspiciousExpandableCard extends StatefulWidget {
  const DailyAuspiciousExpandableCard({
    super.key,
    required this.guide,
  });

  final DailyAuspiciousGuide guide;

  @override
  State<DailyAuspiciousExpandableCard> createState() =>
      _DailyAuspiciousExpandableCardState();
}

class _DailyAuspiciousExpandableCardState
    extends State<DailyAuspiciousExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.guide;
    final goodCount = g.slots.where((s) => s.isGood).length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151912),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334124)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    size: 20,
                    color: Color(0xFFFACC15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ယနေ့ အခါပေးနှင့် နဂါးခေါင်းလှည့်ရာ (${g.nagahleHeadMm})',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.white100,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'အခါကောင်း ${BaydinForecastEngine.toMyanmarDigits(goodCount)} ပိုင်း • နှိပ်၍ အချိန်ဇယားကြည့်ပါ',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.gray300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.neonLime500,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFF2B3524), height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1A0E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFACC15).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'နဂါးခေါင်းလှည့်ရာ • ${g.nagahleHeadMm}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFACC15),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '• ရှောင်ရန် - ${g.avoidDirectionMm}\n• ကောင်းမွန် - ${g.safeDirectionsMm}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: AppTheme.gray200,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...g.slots.map((slot) {
                    final color = slot.isGood
                        ? const Color(0xFF4ADE80)
                        : (slot.isCaution
                            ? const Color(0xFFF87171)
                            : const Color(0xFFFACC15));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${slot.timeWindowMm} (${slot.planetLabelMm})',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.white100,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      slot.qualityLabelMm,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  slot.purposeMm,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.gray300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Interactive 2-Person Classical Myanmar Compatibility tab (`နှစ်ဦးသား တိုက်ဆိုင်စစ်`).
class BaydinCompatibilitySection extends StatelessWidget {
  const BaydinCompatibilitySection({
    super.key,
    required this.viewModel,
  });

  final BaydinViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final result = viewModel.compatibilityResult;
    final accent = result.isHarmonious
        ? AppTheme.neonLime500
        : const Color(0xFFF87171);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _SectionShellCard(
          icon: Icons.favorite_rounded,
          title: 'နှစ်ဦးသား မွေးနံတိုက်ဆိုင်စစ် (ချစ်သူ • အိမ်ထောင် • စီးပွားဖက်)',
          accent: AppTheme.neonLime500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'ပထမလူ (မိမိမွေးနံ)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white100,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: viewModel.useMyWeekdayForCompat,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.person_pin_rounded, size: 15),
                    label: Text(
                      'မိမိ (${viewModel.userBirthWeekday.labelMm})',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: MyanmarWeekday.values
                    .map(
                      (wd) => ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(wd.labelMm),
                        selected: viewModel.compatPersonA == wd,
                        onSelected: (_) => viewModel.setCompatPersonA(wd),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              const Text(
                'ဒုတိယလူ (ချစ်သူ / အိမ်ထောင်ဖက် / စီးပွားဖက် မွေးနံ)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.white100,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: MyanmarWeekday.values
                    .map(
                      (wd) => ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(wd.labelMm),
                        selected: viewModel.compatPersonB == wd,
                        onSelected: (_) => viewModel.setCompatPersonB(wd),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Result Hero Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.16),
                const Color(0xFF12151B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.personA.labelMm} + ${result.personB.labelMm}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.bondTypeMm,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.white100,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent),
                    ),
                    child: Text(
                      '${BaydinForecastEngine.toMyanmarDigits(result.overallScore)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1F27),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'မြန်မာ့နက္ခတ်လင်္ကာ • ${result.classicalRhymeMm}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFACC15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ScoreMeterRow(
                label: 'အချစ်ရေး / အိမ်ထောင်ရေး',
                score: result.loveScore,
                color: const Color(0xFFF472B6),
              ),
              const SizedBox(height: 8),
              _ScoreMeterRow(
                label: 'စီးပွားရေး / ပူးပေါင်းဆောင်ရွက်မှု',
                score: result.businessScore,
                color: AppTheme.neonLime500,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _SectionShellCard(
          icon: Icons.auto_awesome_rounded,
          title: 'အသေးစိတ် သုံးသပ်ချက်နှင့် ညှိနှိုင်းယတြာ',
          accent: const Color(0xFFFACC15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryParagraph(
                icon: Icons.favorite_outline_rounded,
                title: 'အချစ်ရေးနှင့် အိမ်ထောင်ရေး',
                body: result.loveAnalysisMm,
                accent: const Color(0xFFF472B6),
              ),
              const SizedBox(height: 10),
              _CategoryParagraph(
                icon: Icons.handshake_outlined,
                title: 'စီးပွားဖက်နှင့် လုပ်ငန်းပူးပေါင်းမှု',
                body: result.businessAnalysisMm,
                accent: AppTheme.neonLime500,
              ),
              const SizedBox(height: 10),
              _CategoryParagraph(
                icon: Icons.event_available_rounded,
                title: 'နှစ်ဦးအတူ ကံကောင်းစေမည့်နေ့',
                body: result.sharedLuckyDayMm,
                accent: const Color(0xFF38BDF8),
              ),
              const SizedBox(height: 10),
              _CategoryParagraph(
                icon: Icons.spa_outlined,
                title: 'ချစ်ခင်ညီညွတ်စေရန် ယတြာ',
                body: result.harmonizingYadayaMm,
                accent: const Color(0xFFFACC15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreMeterRow extends StatelessWidget {
  const _ScoreMeterRow({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray200,
                ),
              ),
            ),
            Text(
              '${BaydinForecastEngine.toMyanmarDigits(score)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (score / 100).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: const Color(0xFF252A34),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _PeriodNavigationHeader extends StatelessWidget {
  const _PeriodNavigationHeader({
    required this.badgeLabel,
    required this.title,
    required this.subtitle,
    required this.showReset,
    required this.prevTooltip,
    required this.nextTooltip,
    required this.onPrev,
    required this.onNext,
    required this.onReset,
  });

  final String badgeLabel;
  final String title;
  final String subtitle;
  final bool showReset;
  final String prevTooltip;
  final String nextTooltip;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF151920),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B3426)),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: prevTooltip,
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.neonLime600.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.neonLime500,
                        ),
                      ),
                    ),
                    if (showReset) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onReset,
                        child: const Text(
                          'ယခုပြန်သွား',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFACC15),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.white100,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.gray300,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: nextTooltip,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _ForecastScoreHeroCard extends StatelessWidget {
  const _ForecastScoreHeroCard({
    required this.userTitle,
    required this.score,
    required this.stars,
    required this.energyTitle,
    required this.headline,
    required this.accentColor,
  });

  final String userTitle;
  final int score;
  final int stars;
  final String energyTitle;
  final String headline;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.16),
            const Color(0xFF12151B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.8), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userTitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      energyTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.white100,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 18,
                          color: const Color(0xFFFACC15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor),
                ),
                child: Column(
                  children: [
                    Text(
                      BaydinForecastEngine.toMyanmarDigits(score),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                    const Text(
                      'ကံရမှတ်',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.gray200,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppTheme.gray200,
            ),
          ),
        ],
      ),
    );
  }
}

class _BestCautionSummaryCard extends StatelessWidget {
  const _BestCautionSummaryCard({
    required this.bestTitle,
    required this.cautionTitle,
    required this.bestDates,
    required this.cautionDates,
    this.sabbathDates = const [],
  });

  final String bestTitle;
  final String cautionTitle;
  final List<DailyTransitOutlook> bestDates;
  final List<DailyTransitOutlook> cautionDates;
  final List<DailyTransitOutlook> sabbathDates;

  @override
  Widget build(BuildContext context) {
    return _SectionShellCard(
      icon: Icons.event_note_rounded,
      title: 'ရက်ကောင်း • ဥပုသ် • သတိပြုရက်များ',
      accent: const Color(0xFF4ADE80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bestTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4ADE80),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: bestDates
                .map(
                  (d) => _DatePillChip(
                    label:
                        '${BaydinForecastEngine.formatGregorianDayMm(d.date)} (${d.planet.labelMm})${d.isYatyaza ? ' ★' : ''}',
                    color: const Color(0xFF4ADE80),
                  ),
                )
                .toList(),
          ),
          if (sabbathDates.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'ဥပုသ်နေ့များ (ကုသိုလ်/ယတြာပြုရန်)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFACC15),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: sabbathDates
                  .map(
                    (d) => _DatePillChip(
                      label:
                          '${BaydinForecastEngine.formatGregorianDayMm(d.date)} • ${d.myanmarDateShort}',
                      color: const Color(0xFFFACC15),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            cautionTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF87171),
            ),
          ),
          const SizedBox(height: 6),
          if (cautionDates.isEmpty)
            const Text(
              'အထူးအညံ့ရက် မတွေ့ရှိပါ (ပုံမှန် ဘေးကင်းကောင်းမွန်)။',
              style: TextStyle(fontSize: 12, color: AppTheme.gray300),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cautionDates
                  .map(
                    (d) => _DatePillChip(
                      label:
                          '${BaydinForecastEngine.formatGregorianDayMm(d.date)} (${d.planet.labelMm})${d.isPyathada ? ' • ပြဿဒါး' : ''}',
                      color: const Color(0xFFF87171),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _DatePillChip extends StatelessWidget {
  const _DatePillChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _FourCategoryForecastCard extends StatelessWidget {
  const _FourCategoryForecastCard({
    required this.sectionTitle,
    required this.workMm,
    required this.financeMm,
    required this.loveMm,
    required this.healthMm,
  });

  final String sectionTitle;
  final String workMm;
  final String financeMm;
  final String loveMm;
  final String healthMm;

  @override
  Widget build(BuildContext context) {
    return _SectionShellCard(
      icon: Icons.auto_stories_rounded,
      title: sectionTitle,
      accent: const Color(0xFF38BDF8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryParagraph(
            icon: Icons.work_outline_rounded,
            title: 'အလုပ်အကိုင်နှင့် စီးပွားရေး',
            body: workMm,
            accent: AppTheme.neonLime500,
          ),
          const SizedBox(height: 10),
          _CategoryParagraph(
            icon: Icons.account_balance_wallet_outlined,
            title: 'ငွေကြေးနှင့် လာဘ်လာဘ',
            body: financeMm,
            accent: const Color(0xFFFACC15),
          ),
          const SizedBox(height: 10),
          _CategoryParagraph(
            icon: Icons.favorite_outline_rounded,
            title: 'အချစ်ရေးနှင့် အိမ်တွင်းရေး',
            body: loveMm,
            accent: const Color(0xFFF472B6),
          ),
          const SizedBox(height: 10),
          _CategoryParagraph(
            icon: Icons.health_and_safety_outlined,
            title: 'ကျန်းမာရေးနှင့် ခရီးသွားလာရေး',
            body: healthMm,
            accent: const Color(0xFF38BDF8),
          ),
        ],
      ),
    );
  }
}

class _LuckyAndYadayaCard extends StatelessWidget {
  const _LuckyAndYadayaCard({
    required this.title,
    required this.luckyNumbersMm,
    required this.luckyColorLabelMm,
    required this.luckyColorHex,
    required this.luckyDirectionMm,
    required this.yadayaTextMm,
    required this.onAddFlower,
    this.adviceTextMm,
  });

  final String title;
  final String luckyNumbersMm;
  final String luckyColorLabelMm;
  final int luckyColorHex;
  final String luckyDirectionMm;
  final String yadayaTextMm;
  final String? adviceTextMm;
  final VoidCallback onAddFlower;

  @override
  Widget build(BuildContext context) {
    return _SectionShellCard(
      icon: Icons.spa_rounded,
      title: title,
      accent: const Color(0xFFFACC15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BoosterBadge(
                label: 'ကံကောင်းဂဏန်း',
                value: luckyNumbersMm,
                dotColor: const Color(0xFFFACC15),
              ),
              _BoosterBadge(
                label: 'လာဘ်ပွင့်အရပ်',
                value: luckyDirectionMm,
                dotColor: const Color(0xFF38BDF8),
              ),
              _BoosterBadge(
                label: 'ကံပွင့်အရောင်',
                value: luckyColorLabelMm,
                dotColor: Color(luckyColorHex),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E15),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppTheme.neonLime600.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ပြုလုပ်သင့်သော ယတြာ',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.neonLime500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  yadayaTextMm,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.48,
                    color: AppTheme.white100,
                  ),
                ),
                if (adviceTextMm != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    adviceTextMm!,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppTheme.gray300,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddFlower,
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
              label: const Text('ယတြာဘုရားပန်း ဈေးဝယ်စာရင်းထည့်မည်'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoosterBadge extends StatelessWidget {
  const _BoosterBadge({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  final String label;
  final String value;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F27),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF2D3340)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.white100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionShellCard extends StatelessWidget {
  const _SectionShellCard({
    required this.icon,
    required this.title,
    required this.accent,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13161C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF262B35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.white100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _CategoryParagraph extends StatelessWidget {
  const _CategoryParagraph({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          body,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.48,
            color: AppTheme.gray200,
          ),
        ),
      ],
    );
  }
}
