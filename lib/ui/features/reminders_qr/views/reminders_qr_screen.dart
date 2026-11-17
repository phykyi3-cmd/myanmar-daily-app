import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:myanmar_daily_app/domain/models/cloud_account_state.dart';
import 'package:myanmar_daily_app/domain/models/emergency_qr_card.dart';
import 'package:myanmar_daily_app/domain/models/renewal_reminder.dart';
import 'package:myanmar_daily_app/ui/core/theme/app_theme.dart';
import 'package:myanmar_daily_app/ui/core/utils/formatters.dart';
import 'package:myanmar_daily_app/ui/core/widgets/category_selector_chips.dart';
import 'package:myanmar_daily_app/ui/features/home/view_models/home_view_model.dart';
import '../view_models/reminders_qr_view_model.dart';

/// Quiet secondary hub grouping Vehicle/Document Reminders, Offline QR Cards, and Backup.
class RemindersQrScreen extends StatefulWidget {
  const RemindersQrScreen({
    super.key,
    required this.viewModel,
    this.homeViewModel,
  });

  final RemindersQrViewModel viewModel;
  final HomeViewModel? homeViewModel;

  @override
  State<RemindersQrScreen> createState() => _RemindersQrScreenState();
}

class _RemindersQrScreenState extends State<RemindersQrScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.viewModel.loadAll();
      widget.homeViewModel?.loadDashboard();
    });
  }

  Future<void> _showAddReminderDialog() async {
    final titleCtrl = TextEditingController();
    final mileageCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var category = ReminderCategory.vehicle;
    var dueDate = DateTime.now().add(const Duration(days: 30));

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('သတိပေးချက် အသစ်ထည့်ရန်'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CategorySelectorChips<ReminderCategory>(
                  values: ReminderCategory.values,
                  selected: category,
                  labelBuilder: (c) => c.labelMm,
                  onSelected: (v) => setDialogState(() => category = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ခေါင်းစဉ် (ဥပမာ - အင်ဂျင်ဝိုင်လဲရန် / Passport)',
                  ),
                ),
                const SizedBox(height: 10),
                if (category == ReminderCategory.vehicle) ...[
                  TextField(
                    controller: mileageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'လဲရမည့် ကီလိုမီတာ (မထည့်လည်းရ)',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'မှတ်ချက်'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('သက်တမ်းကုန် / ပြုလုပ်ရမည့်ရက်'),
                  subtitle: Text(formatDateShort(dueDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() => dueDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('မလုပ်တော့'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                await widget.viewModel.addReminder(
                  RenewalReminder(
                    title: title,
                    category: category,
                    dueDate: dueDate,
                    mileageKm: int.tryParse(mileageCtrl.text.trim()),
                    note: noteCtrl.text.trim(),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('သိမ်းမည်'),
            ),
          ],
        ),
      ),
    );

    titleCtrl.dispose();
    mileageCtrl.dispose();
    noteCtrl.dispose();
  }

  void _toggleSection(ToolsSection section) {
    final vm = widget.viewModel;
    vm.setActiveSection(
      vm.activeSection == section ? ToolsSection.overview : section,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final homeVm = widget.homeViewModel;
    final listenable = homeVm != null
        ? Listenable.merge([vm, homeVm])
        : vm;

    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final activeRemindersCount =
            vm.reminders.where((r) => !r.isCompleted).length;

        return Scaffold(
          appBar: AppBar(title: const Text('အခြား Tools များ')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141812),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF283024)),
                ),
                child: const Text(
                  'အိမ်တွင်းရေး ပင်မမျက်နှာပြင် ရှင်းလင်းစေရန် ယာဉ်/စာရွက်စာတမ်း Reminder၊ Offline QR ကတ်နှင့် Backup တို့ကို ဤနေရာတွင် သီးသန့်စုစည်းထားပါသည်။ လိုအပ်သည့်အပိုင်းကို နှိပ်၍ ဖွင့်ကြည့်နိုင်ပါသည်။',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppTheme.gray200,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _CollapsibleToolCard(
                icon: Icons.directions_car_outlined,
                title: 'ယာဉ်နှင့် စာရွက်စာတမ်း Reminder',
                subtitle: activeRemindersCount == 0
                    ? 'အင်ဂျင်ဝိုင်၊ လိုင်စင်၊ Passport (လက်ရှိ မရှိသေး)'
                    : 'သတိပေးချက် $activeRemindersCount ခု မှတ်သားထားသည်',
                isExpanded: vm.activeSection == ToolsSection.reminders,
                onToggle: () => _toggleSection(ToolsSection.reminders),
                child: _RemindersSection(
                  viewModel: vm,
                  onAddReminder: _showAddReminderDialog,
                ),
              ),
              const SizedBox(height: 10),
              _CollapsibleToolCard(
                icon: Icons.qr_code_2_outlined,
                title: 'Offline QR နှင့် အရေးပေါ်ကတ်',
                subtitle: vm.qrCard.isEmpty
                    ? 'အရေးပေါ်ဖုန်း၊ သွေးအုပ်စုနှင့် Wi-Fi QR ပြင်ဆင်ရန်'
                    : '${vm.qrCard.fullName} • QR ကတ် အသင့်ရှိ',
                isExpanded: vm.activeSection == ToolsSection.qrCard,
                onToggle: () => _toggleSection(ToolsSection.qrCard),
                child: _QrCardSection(viewModel: vm),
              ),
              if (homeVm != null) ...[
                const SizedBox(height: 10),
                _CollapsibleToolCard(
                  icon: Icons.cloud_outlined,
                  title: 'Backup နှင့် Cloud Sync',
                  subtitle: homeVm.cloudAccount.isConnected
                      ? '${homeVm.cloudAccount.provider.labelMm} ချိတ်ဆက်ပြီး'
                      : 'Local JSON Backup • Google Drive / iCloud',
                  isExpanded: vm.activeSection == ToolsSection.backup,
                  onToggle: () => _toggleSection(ToolsSection.backup),
                  child: _BackupSyncSection(homeViewModel: homeVm),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CollapsibleToolCard extends StatelessWidget {
  const _CollapsibleToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151813),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? AppTheme.neonLime600.withValues(alpha: 0.7)
              : const Color(0xFF282E26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20261D),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: AppTheme.neonLime500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.white100,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.gray200,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.gray200,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFF262D22)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

class _RemindersSection extends StatelessWidget {
  const _RemindersSection({
    required this.viewModel,
    required this.onAddReminder,
  });

  final RemindersQrViewModel viewModel;
  final VoidCallback onAddReminder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (viewModel.reminders.isEmpty)
          const Text(
            'ကား/ဆိုင်ကယ် အင်ဂျင်ဝိုင်လဲချိန်၊ လိုင်စင်၊ Passport နဲ့ အိမ်ငှားစာချုပ် သက်တမ်းများကို မှတ်ထားနိုင်ပါသည်။',
            style: TextStyle(fontSize: 12.5, color: AppTheme.gray200),
          )
        else
          ...viewModel.reminders.map((reminder) {
            final days = reminder.daysRemaining();
            final subtitleParts = <String>[
              reminder.category.labelMm,
              formatDateShort(reminder.dueDate),
              if (reminder.mileageKm != null) '${reminder.mileageKm} km',
              if (reminder.note.isNotEmpty) reminder.note,
            ];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                leading: Checkbox(
                  value: reminder.isCompleted,
                  onChanged: (_) => viewModel.toggleCompleted(reminder),
                ),
                title: Text(
                  reminder.title,
                  style: TextStyle(
                    decoration: reminder.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text(subtitleParts.join(' • ')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!reminder.isCompleted)
                      Text(
                        formatDaysRemainingMm(days),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: days <= 7
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: reminder.id == null
                          ? null
                          : () => viewModel.deleteReminder(reminder.id!),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onAddReminder,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('သတိပေးချက် အသစ်ထည့်'),
        ),
      ],
    );
  }
}

class _QrCardSection extends StatefulWidget {
  const _QrCardSection({required this.viewModel});

  final RemindersQrViewModel viewModel;

  @override
  State<_QrCardSection> createState() => _QrCardSectionState();
}

class _QrCardSectionState extends State<_QrCardSection> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();
  final _wifiSsidCtrl = TextEditingController();
  final _wifiPassCtrl = TextEditingController();

  bool _showWifiQr = false;
  bool _syncedInitial = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bloodCtrl.dispose();
    _emergencyCtrl.dispose();
    _addressCtrl.dispose();
    _paymentCtrl.dispose();
    _wifiSsidCtrl.dispose();
    _wifiPassCtrl.dispose();
    super.dispose();
  }

  void _syncControllersIfNeeded(EmergencyQrCard card) {
    if (_syncedInitial) return;
    _nameCtrl.text = card.fullName;
    _phoneCtrl.text = card.phone;
    _bloodCtrl.text = card.bloodType;
    _emergencyCtrl.text = card.emergencyContact;
    _addressCtrl.text = card.addressNote;
    _paymentCtrl.text = card.paymentAccount;
    _wifiSsidCtrl.text = card.wifiSsid;
    _wifiPassCtrl.text = card.wifiPassword;
    _syncedInitial = true;
  }

  Future<void> _saveCard() async {
    final card = EmergencyQrCard(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      bloodType: _bloodCtrl.text.trim(),
      emergencyContact: _emergencyCtrl.text.trim(),
      addressNote: _addressCtrl.text.trim(),
      paymentAccount: _paymentCtrl.text.trim(),
      wifiSsid: _wifiSsidCtrl.text.trim(),
      wifiPassword: _wifiPassCtrl.text.trim(),
    );
    await widget.viewModel.saveQrCard(card);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline QR ကတ် သိမ်းဆည်းပြီးပါပြီ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.viewModel.qrCard;
    _syncControllersIfNeeded(card);

    final wifiPayload = card.toWifiQrPayload();
    final activePayload = (_showWifiQr && wifiPayload.isNotEmpty)
        ? wifiPayload
        : card.toEmergencyQrPayload();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('အရေးပေါ် QR')),
            ButtonSegment(value: true, label: Text('Wi-Fi QR')),
          ],
          selected: {_showWifiQr},
          onSelectionChanged: (set) => setState(() => _showWifiQr = set.first),
        ),
        const SizedBox(height: 14),
        Center(
          child: (_showWifiQr && wifiPayload.isEmpty)
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Wi-Fi SSID နဲ့ Password အောက်မှာ ဖြည့်သွင်းပါ။'),
                )
              : QrImageView(
                  data: activePayload,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: activePayload));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR စာသား Copy ကူးပြီးပါပြီ')),
              );
            }
          },
          icon: const Icon(Icons.copy, size: 17),
          label: const Text('စာသား Copy ကူးမည်'),
        ),
        const SizedBox(height: 10),
        Text(
          'ကိုယ်ရေးအချက်အလက် ပြင်ဆင်ရန်',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'အမည်'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'ဖုန်းနံပါတ်'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _bloodCtrl,
                decoration: const InputDecoration(labelText: 'သွေးအုပ်စု'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emergencyCtrl,
          decoration: const InputDecoration(
            labelText: 'အရေးပေါ် ဆက်သွယ်ရန် ဖုန်း/အမည်',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'နေရပ်လိပ်စာ'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _paymentCtrl,
          decoration: const InputDecoration(
            labelText: 'KPay / WavePay နံပါတ် (မထည့်လည်းရ)',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _wifiSsidCtrl,
                decoration: const InputDecoration(labelText: 'Wi-Fi SSID'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _wifiPassCtrl,
                decoration: const InputDecoration(labelText: 'Wi-Fi Password'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saveCard,
          child: const Text('Offline QR ကတ် သိမ်းမည်'),
        ),
      ],
    );
  }
}

class _BackupSyncSection extends StatelessWidget {
  const _BackupSyncSection({required this.homeViewModel});

  final HomeViewModel homeViewModel;

  Future<void> _showBackupDialog(BuildContext context) async {
    final jsonController = TextEditingController();
    jsonController.text = await homeViewModel.exportBackupJson();
    if (!context.mounted) {
      jsonController.dispose();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Local JSON Backup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ဒေတာအားလုံးကို JSON အဖြစ် Copy ကူးပြီး Google Drive သို့မဟုတ် Notes မှာ သိမ်းနိုင်ပါသည်။',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: jsonController,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Backup JSON Data'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonController.text));
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Backup JSON ကို Copy ကူးပြီးပါပြီ')),
                );
              }
            },
            child: const Text('Copy ကူးမည်'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await homeViewModel.restoreBackupJson(jsonController.text);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup ပြန်သွင်းပြီးပါပြီ')),
                  );
                }
              } catch (_) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('JSON ပုံစံ မှားယွင်းနေပါသည်')),
                  );
                }
              }
            },
            child: const Text('Restore လုပ်မည်'),
          ),
        ],
      ),
    );
    jsonController.dispose();
  }

  Future<void> _showCloudConnectDialog(
    BuildContext context,
    CloudProviderType initialProvider,
  ) async {
    var provider = initialProvider == CloudProviderType.none
        ? CloudProviderType.googleDrive
        : initialProvider;
    final emailCtrl = TextEditingController(
      text: homeViewModel.cloudAccount.accountEmail.isNotEmpty
          ? homeViewModel.cloudAccount.accountEmail
          : (provider == CloudProviderType.googleDrive
              ? 'user@gmail.com'
              : 'user@icloud.com'),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Cloud အကောင့် ချိတ်ဆက်သိမ်းဆည်းရန်'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Google Drive (Gmail)'),
                      selected: provider == CloudProviderType.googleDrive,
                      onSelected: (_) => setDialogState(() {
                        provider = CloudProviderType.googleDrive;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('Apple iCloud'),
                      selected: provider == CloudProviderType.appleICloud,
                      onSelected: (_) => setDialogState(() {
                        provider = CloudProviderType.appleICloud;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: provider == CloudProviderType.googleDrive
                        ? 'Gmail လိပ်စာ'
                        : 'Apple ID လိပ်စာ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (homeViewModel.cloudAccount.isConnected)
              TextButton(
                onPressed: () async {
                  await homeViewModel.disconnectCloudAccount();
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                child: const Text('အကောင့်ဖြုတ်မည်'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('မလုပ်တော့'),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                await homeViewModel.connectCloudAccount(
                  provider: provider,
                  email: email,
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${provider.labelMm} ($email) နှင့် ချိတ်ဆက်ပြီးပါပြီ',
                      ),
                    ),
                  );
                }
              },
              child: const Text('ချိတ်ဆက်သိမ်းမည်'),
            ),
          ],
        ),
      ),
    );
    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = homeViewModel.cloudAccount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          account.isConnected
              ? '${account.provider.labelMm} • ${account.accountEmail}'
              : 'Gmail / Apple ID သို့မဟုတ် Local JSON ဖြင့် ဒေတာများကို လုံခြုံစွာ သိမ်းဆည်းနိုင်ပါသည်။',
          style: const TextStyle(fontSize: 12.5, color: AppTheme.gray200),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showBackupDialog(context),
              icon: const Icon(Icons.save_alt_outlined, size: 17),
              label: const Text('Local JSON Backup'),
            ),
            if (!account.isConnected)
              OutlinedButton.icon(
                onPressed: () =>
                    _showCloudConnectDialog(context, CloudProviderType.googleDrive),
                icon: const Icon(Icons.cloud_upload_outlined, size: 17),
                label: const Text('Cloud ချိတ်ဆက်မည်'),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: homeViewModel.isSyncingCloud
                    ? null
                    : homeViewModel.syncCloudNow,
                icon: const Icon(Icons.sync_rounded, size: 17),
                label: const Text('ယခု Sync လုပ်မည်'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    _showCloudConnectDialog(context, account.provider),
                icon: const Icon(Icons.settings_outlined, size: 17),
                label: const Text('Cloud ပြင်ရန်'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
