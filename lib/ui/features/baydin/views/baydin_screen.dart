import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myanmar_daily_app/domain/models/baydin_forecast.dart';
import 'package:myanmar_daily_app/domain/models/baydin_reading.dart';
import 'package:myanmar_daily_app/domain/models/shopping_item.dart';
import 'package:myanmar_daily_app/ui/core/theme/app_theme.dart';
import 'package:myanmar_daily_app/ui/core/utils/formatters.dart';
import 'package:myanmar_daily_app/ui/features/daily_market/view_models/daily_market_view_model.dart';
import '../view_models/baydin_view_model.dart';
import 'baydin_forecast_sections.dart';

/// Sayar San Zarni Bo style Mahabote Baydin, Yadaya Flower/Outfit guide, and Myanmar Calendar screen.
class BaydinScreen extends StatefulWidget {
  const BaydinScreen({super.key, required this.viewModel});

  final BaydinViewModel viewModel;

  @override
  State<BaydinScreen> createState() => _BaydinScreenState();
}

class _BaydinScreenState extends State<BaydinScreen> {
  final _nameCtrl = TextEditingController();
  bool _syncedInitialName = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.viewModel.loadAll();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.viewModel.birthDate,
      firstDate: DateTime(1940, 1, 1),
      lastDate: now,
    );
    if (picked != null && mounted) {
      widget.viewModel.updateBirthDate(picked);
    }
  }

  Future<void> _pickCalendarDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.viewModel.selectedCalendarDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null && mounted) {
      widget.viewModel.selectCalendarDate(picked);
    }
  }

  Future<void> _addYadayaFlowerToShopping(BaydinReading reading) async {
    DailyMarketViewModel? marketVm;
    try {
      marketVm = context.read<DailyMarketViewModel>();
    } catch (_) {
      marketVm = null;
    }

    final rx = reading.prescription;
    final target = reading.yadayaTargetPlanet;

    if (marketVm != null) {
      await marketVm.addItem(
        ShoppingItem(
          name: 'ဘုရားပန်း (${rx.flowerTitleMm})',
          quantity: rx.flowerCountLabelMm,
          estimatedCostMmk: 1500,
          recipeName: 'ဗေဒင်/ယတြာ (${target.labelMm})',
          createdAt: DateTime.now(),
        ),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${rx.flowerTitleMm} ကို ဈေးဝယ်စာရင်းထဲ ထည့်ပြီးပါပြီ',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (!_syncedInitialName && vm.nameInput.isNotEmpty) {
          _nameCtrl.text = vm.nameInput;
          _syncedInitialName = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'ဗေဒင်နှင့် ယတြာ',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<BaydinSection>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: BaydinSection.calculator,
                        label: Text(
                          'ဗေဒင် • ယတြာ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ButtonSegment(
                        value: BaydinSection.compatibility,
                        label: Text(
                          'တိုက်ဆိုင်စစ်',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ButtonSegment(
                        value: BaydinSection.calendar,
                        label: Text(
                          'ရက်ရာဇာ • ဥပုသ်',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    selected: {vm.activeSection},
                    onSelectionChanged: (set) =>
                        vm.setActiveSection(set.first),
                  ),
                ),
              ),
              Expanded(
                child: switch (vm.activeSection) {
                  BaydinSection.calculator => _BaydinCalculatorSection(
                      viewModel: vm,
                      nameController: _nameCtrl,
                      onPickBirthDate: _pickBirthDate,
                      onCalculate: () => vm.calculateAndSave(
                        name: _nameCtrl.text,
                      ),
                      onAddFlowerToMarket: _addYadayaFlowerToShopping,
                    ),
                  BaydinSection.compatibility => BaydinCompatibilitySection(
                      viewModel: vm,
                    ),
                  BaydinSection.calendar => _CalendarCheckerSection(
                      viewModel: vm,
                      onPickDate: _pickCalendarDate,
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BaydinCalculatorSection extends StatelessWidget {
  const _BaydinCalculatorSection({
    required this.viewModel,
    required this.nameController,
    required this.onPickBirthDate,
    required this.onCalculate,
    required this.onAddFlowerToMarket,
  });

  final BaydinViewModel viewModel;
  final TextEditingController nameController;
  final VoidCallback onPickBirthDate;
  final VoidCallback onCalculate;
  final Future<void> Function(BaydinReading) onAddFlowerToMarket;

  @override
  Widget build(BuildContext context) {
    final today = viewModel.todaySummary;
    final reading = viewModel.currentReading;
    final birthDate = viewModel.birthDate;
    final isWedBirth = birthDate.weekday == DateTime.wednesday;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (today != null) ...[
          InkWell(
            onTap: () => viewModel.setActiveSection(BaydinSection.calendar),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF171E11),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: today.isYatyaza || today.isSabbath
                      ? AppTheme.neonLime600
                      : const Color(0xFF333D29),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    today.isSabbath
                        ? Icons.brightness_3_rounded
                        : (today.isYatyaza
                            ? Icons.verified_rounded
                            : Icons.calendar_month_rounded),
                    color: AppTheme.neonLime600,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ယနေ့ - ${today.myanmarDateFormatted} (${today.weekdayLabelMm})',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.white100,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${today.primaryStatusTitleMm} • နဂါးလှည့် ${today.nagahleMm}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.neonLime500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.gray200,
                  ),
                ],
              ),
            ),
          ),
          if (viewModel.todayAuspiciousGuide != null) ...[
            const SizedBox(height: 8),
            DailyAuspiciousExpandableCard(
              guide: viewModel.todayAuspiciousGuide!,
            ),
          ],
        ],
        const SizedBox(height: 12),

        // User Input Card (Name + Birth Date + Calculate CTA)
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF151813),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2B3524), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.neonLime600,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ဆရာစံဇာဏီဘို မဟာဘုတ်နှင့် ယတြာ တွက်စက်',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.white100,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                onChanged: viewModel.updateName,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  labelText: 'အမည် ထည့်ပါ (ဥပမာ - မမေသူ / Sithu Min)',
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: onPickBirthDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10130E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2C3427)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cake_outlined,
                        color: AppTheme.neonLime600,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'မွေးသက္ကရာဇ် ရွေးချယ်ရန်',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.gray200,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatDateShort(birthDate),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.white100,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'ပြင်မည်',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.neonLime600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isWedBirth) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('ဗုဒ္ဓဟူး (နံနက်မွေး)'),
                      selected: !viewModel.isWednesdayNightRahu,
                      onSelected: (_) => viewModel.setWednesdayNightRahu(false),
                    ),
                    ChoiceChip(
                      label: const Text('ရာဟု (မွန်းလွဲ/ညမွေး)'),
                      selected: viewModel.isWednesdayNightRahu,
                      onSelected: (_) => viewModel.setWednesdayNightRahu(true),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'ဝတ်စုံ:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.gray200,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ...BaydinGender.values.map(
                    (g) => ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(g.labelMm),
                      selected: viewModel.gender == g,
                      onSelected: (_) => viewModel.setGender(g),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'မေးမြန်းလိုသည့် ယတြာကဏ္ဍ:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.gray200,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: YadayaFocus.values
                    .map(
                      (focus) => ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(focus.labelMm),
                        selected: viewModel.focus == focus,
                        onSelected: (_) => viewModel.setFocus(focus),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              const Text(
                'ဟောကာလ ရွေးချယ်ရန် (တစ်ပတ်စာ / တစ်လစာ / မဟာဘုတ်)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray200,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: BaydinForecastPeriod.values
                    .map(
                      (period) => ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(period.labelMm),
                        selected: viewModel.activePeriod == period,
                        onSelected: (_) => viewModel.setActivePeriod(period),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onCalculate,
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: const Text('ဗေဒင်မေးမည် (တွက်ချက်မည်)'),
                    ),
                  ),
                  if (reading != null) ...[
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'ရလဒ် ခေတ္တပိတ်မည်',
                      onPressed: viewModel.clearReading,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ],
              ),
              if (viewModel.hasSavedProfile) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.bookmark_added_rounded,
                      size: 14,
                      color: AppTheme.neonLime500,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'ပရိုဖိုင် သိမ်းထားပြီး • အပတ်တိုင်း/လတိုင်း တစ်ချက်နှိပ်ရုံဖြင့် ကြည့်နိုင်သည်',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.gray300,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        nameController.clear();
                        viewModel.clearSavedProfile();
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text(
                        'ဖျက်မည်',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: reading == null
              ? const _BaydinPromptPlaceholder(
                  key: ValueKey('baydin-placeholder'),
                )
              : Column(
                  key: ValueKey(
                    '${reading.name}_${reading.birthDate.toIso8601String()}_${reading.focus.name}_${reading.gender.name}_${viewModel.activePeriod.name}_${viewModel.weekOffset}_${viewModel.monthOffset}',
                  ),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BaydinPeriodSwitcherBar(
                      activePeriod: viewModel.activePeriod,
                      onSelected: viewModel.setActivePeriod,
                      weeklyScore: viewModel.weeklyForecast?.weekScore,
                      monthlyScore: viewModel.monthlyForecast?.monthScore,
                    ),
                    const SizedBox(height: 14),
                    if (viewModel.activePeriod == BaydinForecastPeriod.weekly &&
                        viewModel.weeklyForecast != null)
                      WeeklyForecastView(
                        reading: reading,
                        forecast: viewModel.weeklyForecast!,
                        weekOffset: viewModel.weekOffset,
                        onShiftWeek: viewModel.shiftWeek,
                        onResetWeek: viewModel.resetToCurrentWeek,
                        onAddFlowerToMarket: onAddFlowerToMarket,
                      )
                    else if (viewModel.activePeriod ==
                            BaydinForecastPeriod.monthly &&
                        viewModel.monthlyForecast != null)
                      MonthlyForecastView(
                        reading: reading,
                        forecast: viewModel.monthlyForecast!,
                        monthOffset: viewModel.monthOffset,
                        onShiftMonth: viewModel.shiftMonth,
                        onResetMonth: viewModel.resetToCurrentMonth,
                        onAddFlowerToMarket: onAddFlowerToMarket,
                      )
                    else ...[
                      if (viewModel.weeklyForecast != null &&
                          viewModel.monthlyForecast != null) ...[
                        QuickPeriodTeaserBanner(
                          weekly: viewModel.weeklyForecast!,
                          monthly: viewModel.monthlyForecast!,
                          onOpenWeekly: () => viewModel
                              .setActivePeriod(BaydinForecastPeriod.weekly),
                          onOpenMonthly: () => viewModel
                              .setActivePeriod(BaydinForecastPeriod.monthly),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _BaydinReadingView(
                        reading: reading,
                        onAddFlowerToMarket: onAddFlowerToMarket,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _BaydinPromptPlaceholder extends StatelessWidget {
  const _BaydinPromptPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141812),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2B3524)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 36,
            color: AppTheme.neonLime600,
          ),
          SizedBox(height: 10),
          Text(
            'သင့်အမည်နှင့် မွေးသက္ကရာဇ်ကို ထည့်သွင်းပြီး "ဗေဒင်မေးမည်" ကို နှိပ်ပါ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.white100,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'မြန်မာအမည် သို့မဟုတ် English အမည် (ဥပမာ - Sithu Min) ဖြင့် မေးမြန်းနိုင်ပါသည်။ ဗေဒင်မေးလိုက်မှသာ တစ်ပတ်စာ (၇ ရက်)၊ တစ်လစာ (၃၀ ရက်) ဟောစာတမ်းများနှင့် မဟာဘုတ်ဇာတာ၊ ဘုရားပန်း၊ ဆီမီး/ဖယောင်းတိုင် နှင့် ဝတ်စုံဓာတ်ပုံများ ကျဆင်းပေါ်လာပါမည်။',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppTheme.gray200,
            ),
          ),
        ],
      ),
    );
  }
}

class _BaydinReadingView extends StatelessWidget {
  const _BaydinReadingView({
    required this.reading,
    required this.onAddFlowerToMarket,
  });

  final BaydinReading reading;
  final Future<void> Function(BaydinReading) onAddFlowerToMarket;

  @override
  Widget build(BuildContext context) {
    final target = reading.yadayaTargetPlanet;
    final rx = reading.prescription;
    final luckyPrimary = Color(rx.wearPrimaryHex);
    final luckySecondary = Color(rx.wearSecondaryHex);
    final avoidPrimary = Color(rx.avoidPrimaryHex);
    final avoidSecondary = Color(rx.avoidSecondaryHex);
    const avoidRedAccent = Color(0xFFF87171);

    final luckyTextOnPrimary =
        ThemeData.estimateBrightnessForColor(luckyPrimary) == Brightness.light
            ? AppTheme.obsidian1000
            : Colors.white;
    final luckyBrightAccent =
        ThemeData.estimateBrightnessForColor(luckyPrimary) == Brightness.dark
            ? Color.lerp(luckyPrimary, Colors.white, 0.35)!
            : luckyPrimary;
    final tintedTopBg = Color.lerp(const Color(0xFF131810), luckyPrimary, 0.22)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 0. Personalized Formula & Lucky Color Cascade Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [tintedTopBg, const Color(0xFF11140E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: luckyPrimary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: luckyPrimary.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ColorSwatchDot(color: luckyPrimary),
                  const SizedBox(width: 8),
                  _ColorSwatchDot(color: luckySecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reading.focus.labelMm} • ${target.labelMm}ဓာတ်အိမ်',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: luckyBrightAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rx.formulaTitleMm,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.white100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                rx.formulaReasonMm,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppTheme.gray200,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 1. Authentic 7-House Birth-Year Mahabote Cross Chart + Zata Details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [tintedTopBg, const Color(0xFF11150E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: luckyPrimary, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${reading.name} ၏ ဇာတာခွင်',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.white100,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: luckyPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      reading.mahaboteHouse.titleMm,
                      style: TextStyle(
                        color: luckyTextOnPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                reading.myanmarBirthDateLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  color: luckyBrightAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _BadgePill(
                    icon: Icons.timelapse_rounded,
                    text:
                        'အသက် (${reading.runningAge}) နှစ် • ${reading.currentThetYaukPlanet.labelMm}သက်ရောက်',
                    highlighted: reading.isBummiYear,
                  ),
                  if (reading.isBummiYear)
                    const _BadgePill(
                      icon: Icons.warning_amber_rounded,
                      text: 'ဘုမ္မိကိန်း (ယတြာဂရုစိုက်ရန်)',
                      highlighted: true,
                    ),
                  _BadgePill(
                    icon: Icons.park_rounded,
                    text: 'အမြစ်: ${reading.rootPlanet.labelMm}',
                  ),
                  _BadgePill(
                    icon: Icons.eco_rounded,
                    text: 'အညွန့်: ${reading.tipPlanet.labelMm}',
                  ),
                  if (reading.nameWeekday != null)
                    _BadgePill(
                      icon: Icons.badge_outlined,
                      text: reading.nameCompatibilityLabelMm,
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // 7-House Birth-Year Mahabote Diagram
              _MahaboteChartCard(
                reading: reading,
                highlightColor: luckyBrightAccent,
              ),
              const SizedBox(height: 14),

              _ForecastLine(
                title: 'နာမည်နေ့နံ စိစစ်ချက် (${reading.nameDetectedScriptMm})',
                body:
                    '${reading.nameLetterChainMm}\n${reading.nameCompatibilityNoteMm}',
                accentColor: luckyBrightAccent,
              ),
              _ForecastLine(
                title: 'ဘာကြောင့် ဤသို့ဖြစ်နေသလဲ (ဇာတာနှင့် သက်ရောက်အကြောင်းရင်း)',
                body: reading.zataPositionReasonMm,
                accentColor: luckyBrightAccent,
              ),
              _ForecastLine(
                title: 'လက်ရှိ စိတ်နေစိတ်ထား',
                body: reading.mindsetProfileMm,
                accentColor: luckyBrightAccent,
              ),
              _ForecastLine(
                title: 'အိမ်တွင်းရေးနှင့် မိသားစု (${reading.mahaboteHouse.houseNameMm})',
                body: reading.householdDetailsMm,
                accentColor: luckyBrightAccent,
              ),
              _ForecastLine(
                title: 'အချစ်ရေး / ရည်းစားရနိုင်ချိန်နှင့် အိမ်ထောင်ဘက်',
                body: reading.loveRomanceForecastMm,
                accentColor: luckyBrightAccent,
              ),
              _ForecastLine(
                title: 'စီးပွားရေးနှင့် အိမ်သုံးဘဏ္ဍာ',
                body: reading.financeForecastMm,
                accentColor: luckyBrightAccent,
              ),
              _ForecastLine(
                title: 'အောင်မြင်မှုလမ်းကြောင်းနှင့် အခွင့်အလမ်း',
                body: reading.opportunitiesPathMm,
                accentColor: luckyBrightAccent,
              ),
              _ForecastLine(
                title: 'ကြုံနိုင်သည့် အန္တရာယ်နှင့် ဆင်ခြင်သတိပြုရန်',
                body: '${reading.risksAndDangersMm}\n${reading.partnerSuggestionMm}။',
                accentColor: luckyBrightAccent,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Offering Flowers Card (Dynamic per Topic x Mahabote x Planet)
        _PhotoGuidanceCard(
          assetPath: rx.flowerAsset,
          fallbackIcon: Icons.local_florist_rounded,
          badgeText: 'ဘုရားကပ်ရန်ပန်း • ${rx.flowerCountLabelMm}',
          title: rx.flowerTitleMm,
          subtitle: rx.flowerInstructionMm,
          accentColor: luckyBrightAccent,
          extraWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => onAddFlowerToMarket(reading),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
                label: Text(
                  '${rx.flowerTitleMm} ကို ဈေးဝယ်စာရင်းထဲ ထည့်မည်',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Buddhist Alms / Food / Water Dāna Yadaya Card
        _PhotoGuidanceCard(
          assetPath: rx.almsAsset,
          fallbackIcon: Icons.rice_bowl_rounded,
          badgeText: 'ယတြာ • ဆွမ်းနှင့် ကုသိုလ်ဒါန',
          title: rx.almsTitleMm,
          subtitle: rx.almsInstructionMm,
          accentColor: const Color(0xFF34D399),
        ),
        const SizedBox(height: 16),

        // 4. Beeswax Candles & Earthen Oil Lamps Card
        _PhotoGuidanceCard(
          assetPath: rx.candleAsset,
          fallbackIcon: Icons.local_fire_department_rounded,
          badgeText: 'ဖယောင်းတိုင်နှင့် ဆီမီးတိုင် ပူဇော်နည်း',
          title: rx.candleTitleMm,
          subtitle: rx.candleInstructionMm,
          accentColor: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 16),

        // 5. Wear Today Outfit Card (Gender & Reading Specific)
        _PhotoGuidanceCard(
          assetPath: rx.wearOutfitAsset,
          fallbackIcon: Icons.checkroom_rounded,
          badgeText: 'ယနေ့ ဝတ်ဆင်ရန် ကံပွင့်ဝတ်စုံ',
          title: rx.wearOutfitTitleMm,
          subtitle: rx.wearOutfitNoteMm,
          accentColor: luckyPrimary,
          extraWidget: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                _ColorSwatchDot(color: luckyPrimary),
                const SizedBox(width: 8),
                _ColorSwatchDot(color: luckySecondary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ယနေ့ ဦးစားပေးဝတ်ဆင်သင့်သည့် အရောင်များ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.white100,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 6. DO NOT WEAR Today Outfit Card ("ဒီနေ့မှာ ဒါမဝတ်ရဘူး")
        _PhotoGuidanceCard(
          assetPath: rx.avoidOutfitAsset,
          fallbackIcon: Icons.do_not_disturb_on_rounded,
          badgeText: 'ယနေ့ မဝတ်ရ • ရှောင်ကြဉ်ရန်ဝတ်စုံ',
          title: rx.avoidOutfitTitleMm,
          subtitle: rx.avoidReasonMm,
          accentColor: avoidRedAccent,
          extraWidget: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                _ColorSwatchDot(color: avoidPrimary),
                const SizedBox(width: 8),
                _ColorSwatchDot(color: avoidSecondary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ယနေ့ ရန်ဓာတ်တိုက်ဆိုင်သဖြင့် ရှောင်ကြဉ်ရန် အရောင်',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: avoidRedAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 5. Yadaya Steps & Recitation Checklist
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151813),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: luckyPrimary.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.volunteer_activism_rounded,
                    color: luckyBrightAccent,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ဆောင်ရွက်ရန် ယတြာနှင့် ကုသိုလ်အစီအစဉ်',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...reading.yadayaStepsMm.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.olive900,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: luckyBrightAccent),
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
                                color: luckyBrightAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppTheme.white100,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2512),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: luckyBrightAccent),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.self_improvement_rounded,
                      color: luckyBrightAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reading.meritCountMm,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: luckyBrightAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoGuidanceCard extends StatelessWidget {
  const _PhotoGuidanceCard({
    required this.assetPath,
    required this.fallbackIcon,
    required this.badgeText,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.extraWidget,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final String badgeText;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Widget? extraWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151813),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.7), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: Stack(
              children: [
                SizedBox(
                  height: 195,
                  width: double.infinity,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    cacheWidth: 640,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF1A2016),
                        child: Center(
                          child: Icon(
                            fallbackIcon,
                            size: 54,
                            color: accentColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accentColor),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: AppTheme.white100,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.white100,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppTheme.gray200,
                  ),
                ),
                if (extraWidget != null) extraWidget!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCheckerSection extends StatelessWidget {
  const _CalendarCheckerSection({
    required this.viewModel,
    required this.onPickDate,
  });

  final BaydinViewModel viewModel;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.selectedDaySummary;
    final days = viewModel.filteredUpcomingDays;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (selected != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2210), Color(0xFF121610)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected.isYatyaza || selected.isSabbath
                    ? AppTheme.neonLime600
                    : const Color(0xFF3E4836),
                width: 1.4,
              ),
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
                            '${formatDateShort(selected.date)} • ${selected.weekdayLabelMm}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.gray200,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selected.myanmarDateFormatted,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.white100,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onPickDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 15),
                      label: const Text('ရက်ရွေးမည်'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected.isPyathada || selected.isAfternoonPyathada
                        ? const Color(0xFF2B1816)
                        : const Color(0xFF212D13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected.isPyathada || selected.isAfternoonPyathada
                          ? const Color(0xFFF87171)
                          : AppTheme.neonLime600,
                    ),
                  ),
                  child: Text(
                    selected.primaryStatusTitleMm,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: selected.isPyathada || selected.isAfternoonPyathada
                          ? const Color(0xFFFCA5A5)
                          : AppTheme.neonLime500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _BadgePill(
                      icon: Icons.explore_outlined,
                      text: 'နဂါးလှည့် - ${selected.nagahleMm}',
                    ),
                    if (selected.isYatyaza)
                      const _BadgePill(
                        icon: Icons.verified_rounded,
                        text: 'ရက်ရာဇာ',
                        highlighted: true,
                      ),
                    if (selected.isSabbath)
                      const _BadgePill(
                        icon: Icons.brightness_3_rounded,
                        text: 'ဥပုသ်နေ့',
                        highlighted: true,
                      ),
                    if (selected.isSabbathEve)
                      const _BadgePill(
                        icon: Icons.wb_twilight_rounded,
                        text: 'အဖိတ်နေ့',
                      ),
                    if (selected.isPyathada || selected.isAfternoonPyathada)
                      _BadgePill(
                        icon: Icons.error_outline_rounded,
                        text: selected.isAfternoonPyathada
                            ? 'မွန်းလွဲပြဿဒါး'
                            : 'ပြဿဒါး',
                      ),
                    ...selected.astrologicalTagsMm.map(
                      (t) => _BadgePill(icon: Icons.star_outline_rounded, text: t),
                    ),
                  ],
                ),
                if (selected.holidaysMm.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'အထိမ်းအမှတ်နေ့ - ${selected.holidaysMm.join(' • ')}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.neonLime500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 14),
        const Text(
          'လာမည့် ရက် (၃၀) ရက်ရာဇာ၊ ပြဿဒါးနှင့် ဥပုသ်နေ့များ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppTheme.white100,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChipItem(
                label: 'အားလုံး',
                selected: viewModel.calendarFilter == CalendarFilter.all,
                onTap: () => viewModel.setCalendarFilter(CalendarFilter.all),
              ),
              _FilterChipItem(
                label: 'ရက်ရာဇာများ',
                selected: viewModel.calendarFilter == CalendarFilter.yatyazaOnly,
                onTap: () =>
                    viewModel.setCalendarFilter(CalendarFilter.yatyazaOnly),
              ),
              _FilterChipItem(
                label: 'ဥပုသ် • အဖိတ်နေ့',
                selected: viewModel.calendarFilter == CalendarFilter.sabbathOnly,
                onTap: () =>
                    viewModel.setCalendarFilter(CalendarFilter.sabbathOnly),
              ),
              _FilterChipItem(
                label: 'ပြဿဒါး (ရှောင်ရန်)',
                selected:
                    viewModel.calendarFilter == CalendarFilter.pyathadaOnly,
                onTap: () =>
                    viewModel.setCalendarFilter(CalendarFilter.pyathadaOnly),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...days.map((day) {
          final isSelected = selected != null &&
              selected.date.year == day.date.year &&
              selected.date.month == day.date.month &&
              selected.date.day == day.date.day;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isSelected
                ? const Color(0xFF1B2412)
                : const Color(0xFF151813),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.neonLime600
                    : const Color(0xFF283024),
              ),
            ),
            child: ListTile(
              onTap: () => viewModel.selectCalendarDate(day.date),
              title: Text(
                '${day.myanmarDateFormatted} • ${day.weekdayLabelMm}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.white100,
                ),
              ),
              subtitle: Text(
                '${formatDateShort(day.date)} • ${day.primaryStatusTitleMm}',
                style: TextStyle(
                  fontSize: 12,
                  color: day.isPyathada || day.isAfternoonPyathada
                      ? const Color(0xFFFCA5A5)
                      : (day.isYatyaza || day.isSabbath
                          ? AppTheme.neonLime500
                          : AppTheme.gray200),
                ),
              ),
              trailing: day.isSabbath
                  ? const Icon(
                      Icons.brightness_3_rounded,
                      color: AppTheme.neonLime600,
                      size: 18,
                    )
                  : (day.isYatyaza
                      ? const Icon(
                          Icons.verified_rounded,
                          color: AppTheme.neonLime600,
                          size: 18,
                        )
                      : null),
            ),
          );
        }),
      ],
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.icon,
    required this.text,
    this.highlighted = false,
  });

  final IconData icon;
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF233210) : const Color(0xFF171B14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted ? AppTheme.neonLime600 : const Color(0xFF313A2A),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: highlighted ? AppTheme.neonLime600 : AppTheme.gray200,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: highlighted ? AppTheme.neonLime500 : AppTheme.white100,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastLine extends StatelessWidget {
  const _ForecastLine({
    required this.title,
    required this.body,
    this.accentColor = AppTheme.neonLime500,
    this.isLast = false,
  });

  final String title;
  final String body;
  final Color accentColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.white100,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatchDot extends StatelessWidget {
  const _ColorSwatchDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white70, width: 1.5),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Visual 7-House Myanmar Mahabote Cross Chart (`အဓိပတိ / ပုတိ-ရာဇ / သိုက်-အထွန်း-မရဏ / ဘင်္ဂ`).
class _MahaboteChartCard extends StatelessWidget {
  const _MahaboteChartCard({
    required this.reading,
    required this.highlightColor,
  });

  final BaydinReading reading;
  final Color highlightColor;

  String _shortDay(MyanmarWeekday? day) {
    if (day == null) return '-';
    return '${day.planetNumber}. ${day.labelMm.split(' ').first}';
  }

  Widget _cell(MahaboteHouse house) {
    final planet = reading.mahaboteChart[house];
    final isMine = reading.mahaboteHouse == house;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: isMine
              ? highlightColor.withValues(alpha: 0.22)
              : const Color(0xFF141812),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMine ? highlightColor : const Color(0xFF2B3524),
            width: isMine ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              house.houseNameMm.replaceAll('အိမ်', ''),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isMine ? FontWeight.w900 : FontWeight.w700,
                color: isMine ? highlightColor : AppTheme.gray200,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _shortDay(planet),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isMine ? AppTheme.white100 : AppTheme.white100,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E120C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF283222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'မြန်မာသက္ကရာဇ် (${reading.myanmarBirthYear}) မဟာဘုတ် ဇာတာခွင် (၇ အိမ်)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: highlightColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Spacer(),
              _cell(MahaboteHouse.adipati),
              const Spacer(),
            ],
          ),
          Row(
            children: [
              _cell(MahaboteHouse.puti),
              const Spacer(),
              _cell(MahaboteHouse.yaza),
            ],
          ),
          Row(
            children: [
              _cell(MahaboteHouse.thike),
              _cell(MahaboteHouse.atun),
              _cell(MahaboteHouse.marana),
            ],
          ),
          Row(
            children: [
              const Spacer(),
              _cell(MahaboteHouse.binga),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}
