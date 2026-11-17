import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myanmar_daily_app/domain/models/maternal_child_models.dart';
import 'package:myanmar_daily_app/domain/models/renewal_reminder.dart';
import 'package:myanmar_daily_app/domain/models/shopping_item.dart';
import 'package:myanmar_daily_app/domain/use_cases/maternal_child_engine.dart';
import 'package:myanmar_daily_app/ui/core/theme/app_theme.dart';
import 'package:myanmar_daily_app/ui/core/utils/formatters.dart';
import 'package:myanmar_daily_app/ui/features/daily_market/view_models/daily_market_view_model.dart';
import 'package:myanmar_daily_app/ui/features/reminders_qr/view_models/reminders_qr_view_model.dart';
import '../view_models/maternal_child_view_model.dart';
import 'wellness_consult_sections.dart';

/// Offline-first Mother & Child Care Hub (MOHS EPI vaccines, WHO growth, pregnancy logs,
/// nutrition meal sync, breathing/meditation timer, PIN security & Phase 2 SBAR summary).
class MaternalChildScreen extends StatefulWidget {
  const MaternalChildScreen({
    super.key,
    required this.viewModel,
  });

  final MaternalChildViewModel viewModel;

  @override
  State<MaternalChildScreen> createState() => _MaternalChildScreenState();
}

class _MaternalChildScreenState extends State<MaternalChildScreen> {
  final _pinUnlockCtrl = TextEditingController();
  bool _pinError = false;

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
    _pinUnlockCtrl.dispose();
    super.dispose();
  }

  Future<void> _showCreateProfileDialog() async {
    final nameCtrl = TextEditingController();
    final bloodCtrl = TextEditingController();
    final allergyCtrl = TextEditingController();
    var type = HealthProfileType.child;
    var gender = ChildGender.girl;
    var refDate = DateTime.now().subtract(const Duration(days: 120));

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('မိခင် / ကလေး ပရိုဖိုင်အသစ် ထည့်ရန်'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: HealthProfileType.values.map((t) {
                    return ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(t.labelMm),
                      selected: type == t,
                      onSelected: (_) {
                        setDialogState(() {
                          type = t;
                          refDate = t == HealthProfileType.motherPregnancy
                              ? DateTime.now().subtract(const Duration(days: 112))
                              : DateTime.now().subtract(const Duration(days: 120));
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: type == HealthProfileType.motherPregnancy
                        ? 'မိခင်အမည် (ဥပမာ - မမေသူ)'
                        : 'ကလေးအမည် (ဥပမာ - သားသား / မီးမီး)',
                  ),
                ),
                if (type == HealthProfileType.child) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ChildGender.values.map((g) {
                      return ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(g.labelMm),
                        selected: gender == g,
                        onSelected: (_) => setDialogState(() => gender = g),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    type == HealthProfileType.motherPregnancy
                        ? 'နောက်ဆုံးရာသီစသည့်ရက် (LMP)'
                        : 'ကလေးမွေးသက္ကရာဇ်',
                  ),
                  subtitle: Text(formatDateShort(refDate)),
                  trailing: const Icon(Icons.calendar_today_rounded),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: refDate,
                      firstDate: DateTime(2018),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => refDate = picked);
                    }
                  },
                ),
                TextField(
                  controller: bloodCtrl,
                  decoration: const InputDecoration(
                    labelText: 'သွေးအုပ်စု (ဥပမာ - O+ / B+) — မထည့်လည်းရ',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: allergyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ဆေး/အစားအစာ ဓာတ်မတည့်မှု (မထည့်လည်းရ)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('မလုပ်တော့'),
            ),
            FilledButton(
              onPressed: () async {
                final cleanName = nameCtrl.text.trim();
                if (cleanName.isEmpty) return;
                await widget.viewModel.addProfile(
                  name: cleanName,
                  profileType: type,
                  referenceDate: refDate,
                  childGender: gender,
                  bloodType: bloodCtrl.text,
                  allergyNote: allergyCtrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('သိမ်းဆည်းမည်'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    bloodCtrl.dispose();
    allergyCtrl.dispose();
  }

  Future<void> _pushVaccineReminder(
    FamilyHealthProfile profile,
    ImmunizationRecord dose,
  ) async {
    RemindersQrViewModel? remVm;
    try {
      remVm = context.read<RemindersQrViewModel>();
    } catch (_) {
      remVm = null;
    }

    if (remVm != null) {
      await remVm.addReminder(
        RenewalReminder(
          title: '${profile.name} — ${dose.vaccineNameMm}',
          category: ReminderCategory.other,
          dueDate: dose.dueDate,
          note: '${dose.doseLabelMm} • ${dose.protectAgainstMm}',
        ),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${dose.vaccineNameMm} (${formatDateShort(dose.dueDate)}) ကို Reminder စာရင်းထဲ ထည့်ပြီးပါပြီ',
          ),
        ),
      );
    }
  }

  Future<void> _addMealIngredientsToShopping(NutritionGuideMeal meal) async {
    DailyMarketViewModel? marketVm;
    try {
      marketVm = context.read<DailyMarketViewModel>();
    } catch (_) {
      marketVm = null;
    }

    if (marketVm != null) {
      for (final ing in meal.ingredients) {
        await marketVm.addItem(
          ShoppingItem(
            name: ing.nameMm,
            quantity: ing.quantityMm,
            estimatedCostMmk: ing.estimatedCostMmk,
            recipeName: 'မိခင်/ကလေး (${meal.titleMm})',
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${meal.titleMm} ပါဝင်ပစ္စည်း (${meal.ingredients.length}) မျိုး ဈေးဝယ်စာရင်းထဲ ထည့်ပြီးပါပြီ',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteProfile(FamilyHealthProfile profile) async {
    final profileId = profile.id;
    if (profileId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ပရိုဖိုင် ဖျက်ရန် သေချာပါသလား?'),
        content: Text(
          '${profile.name} ၏ ကာကွယ်ဆေးဇယားနှင့် ကြီးထွားမှု မှတ်တမ်းအားလုံးကို ဖျက်ပစ်ပါမည်။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('မဖျက်တော့'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ဖျက်မည်'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.viewModel.deleteProfile(profileId);
    }
  }

  Future<void> _showLogVitalDialog(FamilyHealthProfile profile) async {
    final wtCtrl = TextEditingController();
    final htCtrl = TextEditingController();
    final sysCtrl = TextEditingController();
    final diaCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final isMother = profile.profileType == HealthProfileType.motherPregnancy;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isMother
              ? 'မိခင် ကိုယ်အလေးချိန် / သွေးပေါင် မှတ်တမ်း'
              : 'ကလေး ကြီးထွားမှု (အလေးချိန်/အရပ်) မှတ်တမ်း',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'ကိုယ်အလေးချိန် (kg — ဥပမာ 7.8)',
                ),
              ),
              const SizedBox(height: 8),
              if (!isMother) ...[
                TextField(
                  controller: htCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'အရပ်အမြင့် (cm — မထည့်လည်းရ)',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (isMother) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'အပေါ်သွေး (Sys)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: diaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'အောက်သွေး (Dia)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'မှတ်ချက် / လက္ခဏာ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('မလုပ်တော့'),
          ),
          FilledButton(
            onPressed: () async {
              final wt = double.tryParse(normalizeAsciiDigits(wtCtrl.text));
              final ht = double.tryParse(normalizeAsciiDigits(htCtrl.text));
              final sys = int.tryParse(normalizeAsciiDigits(sysCtrl.text));
              final dia = int.tryParse(normalizeAsciiDigits(diaCtrl.text));
              final note = noteCtrl.text.trim();
              if (wt == null &&
                  ht == null &&
                  sys == null &&
                  dia == null &&
                  note.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'အနည်းဆုံး ကိုယ်အလေးချိန်၊ သွေးပေါင် သို့မဟုတ် မှတ်ချက်တစ်ခု ထည့်ပါ',
                    ),
                  ),
                );
                return;
              }
              await widget.viewModel.addGrowthOrVitalLog(
                weightKg: wt,
                heightCm: ht,
                bpSystolic: sys,
                bpDiastolic: dia,
                symptomsNote: note,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('သိမ်းမည်'),
          ),
        ],
      ),
    );
    wtCtrl.dispose();
    htCtrl.dispose();
    sysCtrl.dispose();
    diaCtrl.dispose();
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.isLocked) {
          return Scaffold(
            appBar: AppBar(title: const Text('မိခင်နှင့် ကလေး ကျန်းမာရေး')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151813),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.neonLime600),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded,
                          size: 40, color: AppTheme.neonLime600),
                      const SizedBox(height: 10),
                      const Text(
                        'ကျန်းမာရေးမှတ်တမ်း လျှို့ဝှက် PIN ရိုက်ထည့်ပါ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.white100,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pinUnlockCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'PIN နံပါတ်',
                          errorText:
                              _pinError ? 'PIN နံပါတ် မှားယွင်းနေပါသည်' : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () async {
                          final ok = await vm.unlockWithPin(
                            normalizeAsciiDigits(_pinUnlockCtrl.text),
                          );
                          setState(() => _pinError = !ok);
                          if (ok) _pinUnlockCtrl.clear();
                        },
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text('ဖွင့်မည်'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final profile = vm.selectedProfile;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'မိခင်နှင့် ကလေး ကျန်းမာရေး',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (profile != null && profile.id != null)
                IconButton(
                  tooltip: 'ပရိုဖိုင် ဖျက်မည်',
                  onPressed: () => _confirmDeleteProfile(profile),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              if (vm.hasPinSet)
                IconButton(
                  tooltip: 'PIN ပြန်ပိတ်မည်',
                  onPressed: vm.lockScreen,
                  icon: const Icon(Icons.lock_outline_rounded),
                ),
              IconButton(
                tooltip: 'မိခင် / ကလေး အသစ်ထည့်',
                onPressed: _showCreateProfileDialog,
                icon: const Icon(Icons.person_add_alt_1_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              // Profile bar + Quick create
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...vm.profiles.map((p) {
                        final selected = p.id == profile?.id;
                        return ChoiceChip(
                          avatar: Icon(
                            p.profileType ==
                                    HealthProfileType.motherPregnancy
                                ? Icons.pregnant_woman_rounded
                                : Icons.child_care_rounded,
                            size: 16,
                          ),
                          label: Text(
                            '${p.name} (${p.ageOrStageSummaryMm()})',
                          ),
                          selected: selected,
                          onSelected: (_) => vm.selectProfile(p),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('ပရိုဖိုင်အသစ်ထည့်'),
                        onPressed: _showCreateProfileDialog,
                      ),
                    ],
                  ),
                ),
              ),

              // 5 Offline/Telehealth Sub-sections
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: MaternalChildSection.values.map((s) {
                    return ChoiceChip(
                      label: Text(s.labelMm),
                      selected: vm.activeSection == s,
                      onSelected: (_) => vm.setActiveSection(s),
                    );
                  }).toList(),
                ),
              ),

              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : profile == null &&
                            vm.activeSection != MaternalChildSection.nutrition &&
                            vm.activeSection != MaternalChildSection.wellness
                        ? _EmptyProfileGuide(
                            onAddProfile: _showCreateProfileDialog,
                          )
                        : _buildSectionContent(vm, profile),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionContent(
    MaternalChildViewModel vm,
    FamilyHealthProfile? profile,
  ) {
    switch (vm.activeSection) {
      case MaternalChildSection.immunization:
        return _ImmunizationTabView(
          profile: profile!,
          records: vm.immunizations,
          onToggle: vm.toggleImmunization,
          onAddReminder: (dose) => _pushVaccineReminder(profile, dose),
        );
      case MaternalChildSection.growthCare:
        return _GrowthCareTabView(
          viewModel: vm,
          profile: profile!,
          onLogVital: () => _showLogVitalDialog(profile),
        );
      case MaternalChildSection.nutrition:
        return _NutritionTabView(
          meals: vm.filteredNutritionMeals(),
          onAddToMarket: _addMealIngredientsToShopping,
        );
      case MaternalChildSection.wellness:
        return MaternalWellnessSection(viewModel: vm);
      case MaternalChildSection.consultPrep:
        return MaternalConsultPrepSection(viewModel: vm);
    }
  }
}

class _EmptyProfileGuide extends StatelessWidget {
  const _EmptyProfileGuide({required this.onAddProfile});

  final VoidCallback onAddProfile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF151813),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.neonLime600),
          ),
          child: Column(
            children: [
              const Icon(Icons.family_restroom_rounded,
                  size: 46, color: AppTheme.neonLime600),
              const SizedBox(height: 10),
              const Text(
                'မိခင် (ကိုယ်ဝန်ဆောင်) သို့မဟုတ် ကလေး ပရိုဖိုင် စတင်ထည့်သွင်းပါ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.white100,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'မြန်မာနိုင်ငံ ကျန်းမာရေးဝန်ကြီးဌာန (EPI) ကာကွယ်ဆေးထိုးရက်ဇယား၊ WHO ကလေးကြီးထွားမှုစံနှုန်း၊ ကိုယ်ဝန်အပတ်စဉ် စောင့်ရှောက်မှုနှင့် အာဟာရချက်ပြုတ်နည်းများကို Offline စစ်ဆေးနိုင်ပါမည်။',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, height: 1.45, color: AppTheme.gray200),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onAddProfile,
                icon: const Icon(Icons.add_rounded),
                label: const Text('မိခင် / ကလေး ပရိုဖိုင် ထည့်မည်'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          MaternalChildEngine.medicalDisclaimerMm,
          style: TextStyle(fontSize: 11.5, color: AppTheme.gray200, height: 1.45),
        ),
      ],
    );
  }
}

class _ImmunizationTabView extends StatelessWidget {
  const _ImmunizationTabView({
    required this.profile,
    required this.records,
    required this.onToggle,
    required this.onAddReminder,
  });

  final FamilyHealthProfile profile;
  final List<ImmunizationRecord> records;
  final Future<void> Function(ImmunizationRecord, bool) onToggle;
  final Future<void> Function(ImmunizationRecord) onAddReminder;

  @override
  Widget build(BuildContext context) {
    final completed = records.where((r) => r.isCompleted).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF171E11),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neonLime600),
          ),
          child: Row(
            children: [
              const Icon(Icons.vaccines_rounded, color: AppTheme.neonLime600),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.profileType == HealthProfileType.motherPregnancy
                          ? 'မိခင် ANC & Td ကာကွယ်ဆေးဇယား'
                          : 'မြန်မာ MOHS EPI ကလေးကာကွယ်ဆေးဇယား',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppTheme.white100,
                      ),
                    ),
                    Text(
                      'ပြီးစီးမှု: $completed / ${records.length} ကြိမ် • ${profile.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neonLime500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...records.map((dose) {
          final daysLeft = dose.daysRemaining();
          final isDueSoonOrOverdue = !dose.isCompleted && daysLeft <= 7;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF151813),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dose.isCompleted
                    ? const Color(0xFF283A22)
                    : (isDueSoonOrOverdue
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF2B3524)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: dose.isCompleted,
                  onChanged: (v) => onToggle(dose, v ?? false),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dose.vaccineNameMm,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          decoration: dose.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: AppTheme.white100,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dose.doseLabelMm} • ထိုးရမည့်ရက်: ${formatDateShort(dose.dueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDueSoonOrOverdue
                              ? const Color(0xFFFBBF24)
                              : AppTheme.neonLime500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'ကာကွယ်ပေးမှု: ${dose.protectAgainstMm}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.gray200,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!dose.isCompleted)
                  IconButton(
                    tooltip: 'Reminder ထည့်မည်',
                    onPressed: () => onAddReminder(dose),
                    icon: const Icon(
                      Icons.notifications_active_outlined,
                      size: 20,
                      color: AppTheme.neonLime600,
                    ),
                  ),
              ],
            ),
          );
        }),
        const Text(
          MaternalChildEngine.medicalDisclaimerMm,
          style: TextStyle(fontSize: 11.5, color: AppTheme.gray200, height: 1.45),
        ),
      ],
    );
  }
}

class _GrowthCareTabView extends StatelessWidget {
  const _GrowthCareTabView({
    required this.viewModel,
    required this.profile,
    required this.onLogVital,
  });

  final MaternalChildViewModel viewModel;
  final FamilyHealthProfile profile;
  final VoidCallback onLogVital;

  @override
  Widget build(BuildContext context) {
    final isMother = profile.profileType == HealthProfileType.motherPregnancy;
    final eval = isMother ? null : viewModel.evaluateLatestChildWeight();
    final week = isMother ? profile.gestationalWeekAt() : 0;
    final triGuide = isMother ? viewModel.engine.guideForWeek(week) : null;
    final milestoneStage =
        isMother ? null : viewModel.engine.milestoneStageForMonths(profile.ageMonthsAt());
    final whoMedian = isMother
        ? null
        : viewModel.engine.interpolateWhoMedianWeightKg(
            profile.ageMonthsAt(),
            profile.childGender,
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        // Stage / Benchmark Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151A12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.neonLime600),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isMother
                          ? '${profile.name} — ကိုယ်ဝန် ($week) ပတ် (Trimester ${triGuide!.trimester})'
                          : '${profile.name} — ${profile.ageOrStageSummaryMm()}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.white100,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onLogVital,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('မှတ်တမ်းထည့်'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isMother && triGuide != null) ...[
                Text(
                  'ခန့်မှန်းမွေးဖွားရက် (EDD): ${formatDateShort(profile.expectedDueDate)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neonLime500,
                  ),
                ),
                if (DateTime.now().difference(profile.referenceDate).inDays >
                    294) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'သတိ: LMP ရက်စွဲသည် ၄၂ ပတ် ကျော်လွန်နေပါသည် — ကလေးမွေးဖွားပြီးပါက အပေါ် (+) ခလုတ်မှ ကလေးပရိုဖိုင်အသစ် ထည့်သွင်းနိုင်ပါသည်။',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFBBF24),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  triGuide.babyGrowthMm,
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.white100, height: 1.45),
                ),
                const SizedBox(height: 6),
                Text(
                  'မိခင်ဂရုစိုက်မှု: ${triGuide.motherCareMm}',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.gray200, height: 1.45),
                ),
              ],
              if (!isMother && whoMedian != null) ...[
                Text(
                  profile.ageMonthsAt() <= 60
                      ? 'WHO ကြီးထွားမှုစံနှုန်း (${profile.childGender.labelMm} • ${profile.ageMonthsAt()} လ): ပျမ်းမျှကိုယ်အလေးချိန် $whoMedian kg'
                      : 'WHO 0–60 လ (၅ နှစ်) စံနှုန်းထက် ကျော်လွန် (${profile.ageMonthsAt()} လ) — ကျောင်းနေအရွယ် BMI ကို ဆရာဝန်နှင့် စစ်ဆေးပါ',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neonLime500,
                  ),
                ),
                if (eval != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${eval.statusLabelMm}: ${eval.adviceMm}',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: eval.isAlert
                          ? const Color(0xFFFBBF24)
                          : AppTheme.white100,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Milestones or Maternal Red-Flag Emergency Checklist
        if (isMother)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1214),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF87171)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'အရေးပေါ် သတိပြုရန် လက္ခဏာများ (Red-Flag Signs)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFCA5A5),
                  ),
                ),
                const SizedBox(height: 6),
                ...MaternalChildEngine.maternalDangerSignsMm.map(
                  (sign) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $sign',
                      style: const TextStyle(fontSize: 12, color: AppTheme.white100),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (milestoneStage != null)
          Material(
            color: const Color(0xFF151813),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF2B3524)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ဖွံ့ဖြိုးမှု မှတ်တိုင်များ (${milestoneStage.ageRangeLabelMm})',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.neonLime500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...milestoneStage.milestonesMm.map((m) {
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: viewModel.checkedMilestones.contains(m),
                      onChanged: (_) => viewModel.toggleMilestoneChecked(m),
                      title: Text(
                        m,
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.white100),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        const SizedBox(height: 14),
        const Text(
          'မှတ်တမ်းဟောင်းများ',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppTheme.white100,
          ),
        ),
        const SizedBox(height: 8),
        if (viewModel.growthLogs.isEmpty)
          const Text(
            'ကိုယ်အလေးချိန် / သွေးပေါင် မှတ်တမ်း မထည့်ရသေးပါ (အပေါ်မှ "မှတ်တမ်းထည့်" ကို နှိပ်ပါ)။',
            style: TextStyle(fontSize: 12, color: AppTheme.gray200),
          )
        else
          ...viewModel.growthLogs.map((log) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF151813),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: log.hasElevatedBp
                      ? const Color(0xFFF87171)
                      : const Color(0xFF283024),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDateShort(log.recordedAt),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.neonLime500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          [
                            if (log.weightKg != null) 'အလေးချိန်: ${log.weightKg} kg',
                            if (log.heightCm != null) 'အရပ်: ${log.heightCm} cm',
                            if (log.bpSystolic != null && log.bpDiastolic != null)
                              'BP: ${log.bpSystolic}/${log.bpDiastolic}',
                            'စိတ်အခြေအနေ: ${log.moodLabelMm}',
                          ].join(' • '),
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.white100),
                        ),
                        if (log.hasElevatedBp)
                          const Text(
                            'သတိ: သွေးပေါင်မြင့်နေသဖြင့် ဆရာဝန်နှင့် စစ်ဆေးပါ',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFFF87171)),
                          ),
                        if (log.symptomsNote.isNotEmpty)
                          Text(
                            log.symptomsNote,
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.gray200),
                          ),
                      ],
                    ),
                  ),
                  if (log.id != null)
                    IconButton(
                      onPressed: () => viewModel.deleteGrowthLog(log.id!),
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.gray200),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _NutritionTabView extends StatelessWidget {
  const _NutritionTabView({
    required this.meals,
    required this.onAddToMarket,
  });

  final List<NutritionGuideMeal> meals;
  final Future<void> Function(NutritionGuideMeal) onAddToMarket;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        ...meals.map((meal) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF151813),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2B3821)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF223015),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    meal.stageLabelMm,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.neonLime500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  meal.titleMm,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.white100,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'အာဟာရ: ${meal.keyNutrientsMm}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.neonLime600),
                ),
                const SizedBox(height: 8),
                Text(
                  meal.prepStepsMm,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppTheme.gray200,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => onAddToMarket(meal),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
                  label: Text(
                    'ပါဝင်ပစ္စည်း (${meal.ingredients.length}) မျိုး ဈေးဝယ်စာရင်းထဲ ထည့်မည်',
                  ),
                ),
              ],
            ),
          );
        }),
        const Text(
          MaternalChildEngine.medicalDisclaimerMm,
          style: TextStyle(fontSize: 11.5, color: AppTheme.gray200, height: 1.45),
        ),
      ],
    );
  }
}
