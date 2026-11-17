import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:myanmar_daily_app/domain/use_cases/maternal_child_engine.dart';
import 'package:myanmar_daily_app/ui/core/theme/app_theme.dart';
import 'package:myanmar_daily_app/ui/core/utils/formatters.dart';
import '../view_models/maternal_child_view_model.dart';

/// Interactive Offline Mindfulness Breathing & Meditation Timer + Mood Logger.
class MaternalWellnessSection extends StatefulWidget {
  const MaternalWellnessSection({
    super.key,
    required this.viewModel,
  });

  final MaternalChildViewModel viewModel;

  @override
  State<MaternalWellnessSection> createState() =>
      _MaternalWellnessSectionState();
}

class _MaternalWellnessSectionState extends State<MaternalWellnessSection> {
  static const List<(String label, int seconds, String guide)> _presets = [
    (
      '၄-၇-၈ စိတ်ငြိမ်အသက်ရှူ (၃ မိနစ်)',
      180,
      '၄ စက္ကန့် နှာခေါင်းမှရှူသွင်း • ၇ စက္ကန့် ခေတ္တအောင့် • ၈ စက္ကန့် ဖြည်းညှင်းစွာ မှုတ်ထုတ်ပါ။',
    ),
    (
      'မေတ္တာဘာဝနာ တရားရှုမှတ် (၅ မိနစ်)',
      300,
      'မျက်လုံးမှိတ်၍ ဝင်လေထွက်လေကို ရှုမှတ်ပြီး မိခင်နှင့်ကလေး ကျန်းမာချမ်းသာပါစေဟု မေတ္တာပို့ပါ။',
    ),
    (
      'အိပ်မပျော်မီ ဖြေလျှော့နည်း (၁၀ မိနစ်)',
      600,
      'ပုခုံးနှင့် ခန္ဓာကိုယ်တစ်ခုလုံး လျှော့ချပြီး နှေးကွေးညင်သာစွာ အသက်ရှူသွင်း/ထုတ် ပြုလုပ်ပါ။',
    ),
  ];

  int _selectedPresetIdx = 0;
  late int _remainingSeconds = _presets[0].$2;
  bool _isRunning = false;
  Timer? _timer;
  int _selectedMood = 4;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectPreset(int idx) {
    _timer?.cancel();
    setState(() {
      _selectedPresetIdx = idx;
      _remainingSeconds = _presets[idx].$2;
      _isRunning = false;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }
    if (_remainingSeconds <= 0) {
      _remainingSeconds = _presets[_selectedPresetIdx].$2;
    }
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('တရားရှုမှတ်/အသက်ရှူလေ့ကျင့်ခန်း ပြီးဆုံးပါပြီ'),
          ),
        );
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _presets[_selectedPresetIdx].$2;
    });
  }

  String _formatClock(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _breathPhaseLabel(int sec) {
    if (!_isRunning) return 'စတင်ရန် ခလုတ်နှိပ်ပါ';
    final cycle = sec % 12;
    if (cycle >= 8) return 'ဖြည်းညှင်းစွာ ရှူသွင်းပါ...';
    if (cycle >= 4) return 'ခေတ္တ ငြိမ်သက်စွာ ထိန်းထားပါ...';
    return 'စိတ်ဖိစီးမှုများ မှုတ်ထုတ်လိုက်ပါ...';
  }

  @override
  Widget build(BuildContext context) {
    final preset = _presets[_selectedPresetIdx];
    final total = preset.$2;
    final progress = total == 0 ? 0.0 : (_remainingSeconds / total).clamp(0.0, 1.0);
    final profile = widget.viewModel.selectedProfile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF15201A), Color(0xFF101412)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF34D399), width: 1.3),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.self_improvement_rounded,
                      color: Color(0xFF34D399), size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'မိခင် စိတ်အပန်းဖြေ နှင့် တရားရှုမှတ် Timer (Offline)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.white100,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _presets.asMap().entries.map((e) {
                  return ChoiceChip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(e.value.$1),
                    selected: _selectedPresetIdx == e.key,
                    onSelected: (_) => _selectPreset(e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 152,
                    height: 152,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFF222D28),
                      color: const Color(0xFF34D399),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatClock(_remainingSeconds),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.white100,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _breathPhaseLabel(_remainingSeconds),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6EE7B7),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                preset.$3,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppTheme.gray200,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _toggleTimer,
                      icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(_isRunning ? 'ခေတ္တရပ်မည်' : 'စတင်ရှုမှတ်မည်'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('ပြန်စ'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (profile != null)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF151813),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2C3525)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ယနေ့ စိတ်ခံစားချက် မှတ်တမ်းတင်ရန်',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.white100,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    (1, 'ပင်ပန်း/စိတ်ဖိစီး'),
                    (3, 'ပုံမှန်အေးချမ်း'),
                    (4, 'လန်းဆန်း'),
                    (5, 'အထူးပျော်ရွှင်'),
                  ].map((item) {
                    return ChoiceChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(item.$2),
                      selected: _selectedMood == item.$1,
                      onSelected: (_) => setState(() => _selectedMood = item.$1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await widget.viewModel.addGrowthOrVitalLog(
                      moodScore: _selectedMood,
                      symptomsNote: 'စိတ်အပန်းဖြေ မှတ်တမ်း (${preset.$1})',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('စိတ်ခံစားချက် မှတ်တမ်း သိမ်းပြီးပါပြီ'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.favorite_outline_rounded, size: 18),
                  label: const Text('စိတ်ခံစားချက် မှတ်တမ်းသိမ်းမည်'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Phase 2 Telehealth Preparation: SBAR Doctor Summary QR, Copy Note & Local Health PIN Lock.
class MaternalConsultPrepSection extends StatefulWidget {
  const MaternalConsultPrepSection({
    super.key,
    required this.viewModel,
  });

  final MaternalChildViewModel viewModel;

  @override
  State<MaternalConsultPrepSection> createState() =>
      _MaternalConsultPrepSectionState();
}

class _MaternalConsultPrepSectionState
    extends State<MaternalConsultPrepSection> {
  final _concernCtrl = TextEditingController();
  String _urgencyLevel = 'normal';

  @override
  void dispose() {
    _concernCtrl.dispose();
    super.dispose();
  }

  Future<void> _showCloudSetupDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CloudSetupDialog(viewModel: widget.viewModel),
    );
  }

  Future<void> _showPinDialog() async {
    final pinCtrl = TextEditingController();
    final vm = widget.viewModel;
    String? errorMsg;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(vm.hasPinSet
              ? 'ကျန်းမာရေး PIN လော့ခ် စီမံရန်'
              : 'ကျန်းမာရေး PIN လော့ခ် (၄ လုံး) သတ်မှတ်ရန်'),
          content: TextField(
            controller: pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'လျှို့ဝှက်နံပါတ် (ဥပမာ - 1234)',
              errorText: errorMsg,
            ),
          ),
          actions: [
            if (vm.hasPinSet)
              TextButton(
                onPressed: () async {
                  await vm.configurePin(null);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('PIN ဖြုတ်မည်'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('မလုပ်တော့'),
            ),
            FilledButton(
              onPressed: () async {
                final normalized = normalizeAsciiDigits(pinCtrl.text);
                if (normalized.length < 4) {
                  setDialogState(() => errorMsg = 'ဂဏန်း အနည်းဆုံး ၄ လုံး ထည့်ပါ');
                  return;
                }
                await vm.configurePin(normalized);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('သိမ်းမည်'),
            ),
          ],
        ),
      ),
    );
    pinCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final profile = vm.selectedProfile;
    final status = vm.telehealthStatus;
    final summary = profile == null ? '' : vm.buildSbarSummary(_concernCtrl.text);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        // 1. Privacy PIN Security Control Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF151813),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: vm.hasPinSet ? AppTheme.neonLime600 : const Color(0xFF2D3528),
            ),
          ),
          child: Row(
            children: [
              Icon(
                vm.hasPinSet ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: vm.hasPinSet ? AppTheme.neonLime600 : AppTheme.gray200,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ကျန်းမာရေးမှတ်တမ်း ကိုယ်ရေးလုံခြုံမှု (PIN Lock)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.white100,
                      ),
                    ),
                    Text(
                      vm.hasPinSet
                          ? 'PIN လော့ခ် ဖွင့်ထားပြီး (Salted Digest)'
                          : 'မိသားစု ကျန်းမာရေးဒေတာကို ၄ လုံး PIN ဖြင့် ကာကွယ်နိုင်သည်',
                      style: const TextStyle(fontSize: 12, color: AppTheme.gray200),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _showPinDialog,
                child: Text(vm.hasPinSet ? 'ပြင်/ဖြုတ်' : 'PIN ထည့်'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Phase 2 Telehealth Cloud Database & Security Status
        _buildCloudStatusCard(vm, status?.isLiveProviderConfigured ?? false,
            status?.statusLabelMm, status?.requirementsSummaryMm),
        const SizedBox(height: 14),

        // 3. Offline SBAR Doctor Intake Summary + Scannable QR Card
        if (profile != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151813),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.neonLime600),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ဆရာဝန် / ဆေးခန်းသို့ ပြသရန် SBAR အကျဉ်းချုပ် နှင့် QR',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.white100,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _concernCtrl,
                  onChanged: (_) => setState(() {}),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'လက်ရှိ မေးမြန်းလိုသည့် ရောဂါလက္ခဏာ / မေးခွန်း',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('ပုံမှန်တိုင်ပင်'),
                      selected: _urgencyLevel == 'normal',
                      onSelected: (_) => setState(() => _urgencyLevel = 'normal'),
                    ),
                    ChoiceChip(
                      label: const Text('အရေးကြီး / ဦးစားပေး'),
                      selected: _urgencyLevel == 'urgent',
                      onSelected: (_) => setState(() => _urgencyLevel = 'urgent'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: QrImageView(
                      data: summary,
                      version: QrVersions.auto,
                      size: 165,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E120C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    summary,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppTheme.white100,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: summary));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ဆရာဝန်ပြရန် SBAR အကျဉ်းချုပ်ကို Copy ကူးပြီးပါပြီ'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('ဆေးမှတ်တမ်း အကျဉ်းချုပ် Copy ကူးမည်'),
                ),
                if (vm.cloudConfig.isAuthenticated) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: vm.isCloudBusy
                        ? null
                        : () async {
                            final receipt = await vm.submitConsultToCloud(
                              customConcern: _concernCtrl.text,
                              urgencyLevel: _urgencyLevel,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  receipt != null
                                      ? 'Cloud Triage Ticket (${receipt.ticketId}) ပေးပို့ပြီးပါပြီ'
                                      : (vm.cloudErrorMm ?? 'ပေးပို့မှု မအောင်မြင်ပါ'),
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: Text(
                      vm.isCloudBusy
                          ? 'Cloud သို့ ပေးပို့နေပါသည်...'
                          : 'Cloud မှတစ်ဆင့် ဆရာဝန် Queue သို့ ပို့မည်',
                    ),
                  ),
                ],
              ],
            ),
          ),

        if (vm.cloudTickets.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildCloudTicketsCard(vm),
        ],

        const SizedBox(height: 14),
        const Text(
          MaternalChildEngine.medicalDisclaimerMm,
          style: TextStyle(fontSize: 11.5, color: AppTheme.gray200, height: 1.45),
        ),
        const SizedBox(height: 6),
        if (profile != null)
          Text(
            'နောက်ဆုံးပြင်ဆင်မှု: ${formatDateShort(profile.createdAt)}',
            style: const TextStyle(fontSize: 11, color: AppTheme.gray200),
          ),
      ],
    );
  }

  Widget _buildCloudStatusCard(
    MaternalChildViewModel vm,
    bool isLive,
    String? statusLabel,
    String? details,
  ) {
    final accent = isLive ? AppTheme.neonLime600 : const Color(0xFF38BDF8);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFF141D12) : const Color(0xFF131922),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLive ? Icons.cloud_done_rounded : Icons.video_call_rounded,
                color: accent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel ?? 'ဆရာဝန်တိုင်ပင်မှု ကြိုတင်ပြင်ဆင်စနစ်',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.white100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            details ??
                'ဆေးခန်း/ဆရာဝန်ပြရန် SBAR မှတ်တမ်းနှင့် Pre-Consult QR ကို အသင့်ထုတ်ယူနိုင်ပါသည်။',
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppTheme.gray200,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showCloudSetupDialog,
                  icon: const Icon(Icons.settings_ethernet_rounded, size: 17),
                  label: Text(
                    isLive
                        ? 'Cloud Backend ပြင်ဆင်/ဖြုတ်မည်'
                        : 'Cloud Telehealth ချိတ်ဆက်မည်',
                  ),
                ),
              ),
              if (isLive) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Queue အခြေအနေ စစ်ဆေးမည်',
                  onPressed: vm.refreshCloudTickets,
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.neonLime600),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCloudTicketsCard(MaternalChildViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151813),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2D3528)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cloud ဆရာဝန်တိုင်ပင် Queue မှတ်တမ်းများ',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.neonLime500,
            ),
          ),
          const SizedBox(height: 8),
          ...vm.cloudTickets.map((t) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10130F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF262E22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t.profileName} • #${t.ticketId}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white100,
                    ),
                  ),
                  Text(
                    t.statusLabelMm,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.neonLime600,
                    ),
                  ),
                  if (t.doctorNoteMm.isNotEmpty)
                    Text(
                      'ဆရာဝန်မှတ်ချက် (${t.assignedDoctorName}): ${t.doctorNoteMm}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.gray200),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CloudSetupDialog extends StatefulWidget {
  const _CloudSetupDialog({required this.viewModel});

  final MaternalChildViewModel viewModel;

  @override
  State<_CloudSetupDialog> createState() => _CloudSetupDialogState();
}

class _CloudSetupDialogState extends State<_CloudSetupDialog> {
  late final TextEditingController _projectCtrl =
      TextEditingController(text: widget.viewModel.cloudConfig.projectId);
  late final TextEditingController _apiKeyCtrl =
      TextEditingController(text: widget.viewModel.cloudConfig.apiKey);
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _createAccount = true;
  String? _errorMsg;

  @override
  void dispose() {
    _projectCtrl.dispose();
    _apiKeyCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    return AlertDialog(
      title: const Text('Cloud Telehealth Backend ချိတ်ဆက်ရန်'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Firebase Auth + Cloud Firestore Security Rules (`cloud_backend/firestore.rules`) ချိတ်ဆက်ပြီးပါက SBAR မှတ်တမ်းများကို ဆရာဝန်တိုင်ပင် Queue သို့ ပေးပို့နိုင်ပါမည်။',
              style: TextStyle(fontSize: 12, color: AppTheme.gray200),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _projectCtrl,
              decoration: const InputDecoration(labelText: 'Firebase Project ID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyCtrl,
              decoration: const InputDecoration(labelText: 'Firebase Web API Key'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'အီးမေးလ် (Guest အဖြစ်ဝင်လိုပါက ချန်ထားပါ)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'စကားဝှက် (အီးမေးလ်ထည့်မှသာ လိုအပ်)',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('အကောင့်သစ် / Guest'),
                  selected: _createAccount,
                  onSelected: (_) => setState(() => _createAccount = true),
                ),
                ChoiceChip(
                  label: const Text('ရှိပြီးသား Login'),
                  selected: !_createAccount,
                  onSelected: (_) => setState(() => _createAccount = false),
                ),
              ],
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMsg!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFF87171)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (vm.cloudConfig.isAuthenticated)
          TextButton(
            onPressed: () async {
              await vm.disconnectCloudTelehealth();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('ချိတ်ဆက်မှုဖြုတ်မည်'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('မလုပ်တော့'),
        ),
        FilledButton(
          onPressed: () async {
            final pid = _projectCtrl.text.trim();
            final key = _apiKeyCtrl.text.trim();
            if (pid.isEmpty || key.isEmpty) {
              setState(() {
                _errorMsg = 'Project ID နှင့် Web API Key ၂ ခုစလုံး ထည့်ပါ';
              });
              return;
            }
            final ok = await vm.connectCloudTelehealth(
              projectId: pid,
              apiKey: key,
              email: _emailCtrl.text.trim(),
              password: _passCtrl.text,
              createAccount: _createAccount,
            );
            if (!context.mounted) return;
            if (ok) {
              Navigator.pop(context);
            } else {
              setState(() => _errorMsg = vm.cloudErrorMm);
            }
          },
          child: const Text('ချိတ်ဆက်မည်'),
        ),
      ],
    );
  }
}
