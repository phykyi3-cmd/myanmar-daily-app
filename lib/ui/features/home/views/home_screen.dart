import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:myanmar_daily_app/domain/models/app_module.dart';
import 'package:myanmar_daily_app/domain/models/cloud_account_state.dart';
import 'package:myanmar_daily_app/ui/core/theme/app_theme.dart';
import 'package:myanmar_daily_app/ui/core/utils/formatters.dart';
import 'package:myanmar_daily_app/ui/core/widgets/empty_state_card.dart';
import 'package:myanmar_daily_app/ui/core/widgets/section_header.dart';
import 'package:myanmar_daily_app/ui/features/daily_market/view_models/daily_market_view_model.dart';
import 'package:myanmar_daily_app/ui/features/finance_calc/view_models/finance_calc_view_model.dart';
import 'package:myanmar_daily_app/ui/features/reminders_qr/view_models/reminders_qr_view_model.dart';
import '../view_models/home_view_model.dart';

/// Distinct NBK dark + neon accent palette for each module card.
class _ModuleVisualStyle {
  const _ModuleVisualStyle({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
    required this.badgeBackground,
    required this.tags,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;
  final Color badgeBackground;
  final List<String> tags;
}

/// Home Dashboard in NBK Dark + Electric Neon Lime Green UI/UX style.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadDashboard();
  }

  _ModuleVisualStyle _styleForModule(AppModule module) {
    switch (module) {
      case AppModule.calculators:
        return const _ModuleVisualStyle(
          icon: Icons.calculate_rounded,
          backgroundColor: Color(0xFF171C11),
          borderColor: Color(0xFF4B6419),
          accentColor: AppTheme.neonLime600,
          badgeBackground: Color(0xFF253111),
          tags: ['ရွှေဈေး', 'အရစ်ကျ', 'ငွေလဲနှုန်း'],
        );
      case AppModule.ledger:
        return const _ModuleVisualStyle(
          icon: Icons.volunteer_activism_rounded,
          backgroundColor: Color(0xFF16191E),
          borderColor: Color(0xFF3B4D1A),
          accentColor: AppTheme.neonLime500,
          badgeBackground: Color(0xFF232E12),
          tags: ['အလှူ', 'စုမဲ', 'အသင်းအဖွဲ့'],
        );
      case AppModule.loansRentals:
        return const _ModuleVisualStyle(
          icon: Icons.handshake_rounded,
          backgroundColor: Color(0xFF151921),
          borderColor: Color(0xFF1E3A5F),
          accentColor: Color(0xFF38BDF8),
          badgeBackground: Color(0xFF17253B),
          tags: ['ပေးချေး', 'ပစ္စည်းငှား', 'အိမ်လခ'],
        );
      case AppModule.recipesMarket:
        return const _ModuleVisualStyle(
          icon: Icons.restaurant_menu_rounded,
          backgroundColor: Color(0xFF1A1814),
          borderColor: Color(0xFF574115),
          accentColor: Color(0xFFFACC15),
          badgeBackground: Color(0xFF2D2410),
          tags: ['မြန်မာဟင်းလျာ', 'ဈေးဝယ်စာရင်း', 'ဘတ်ဂျက်'],
        );
      case AppModule.reminders:
        return const _ModuleVisualStyle(
          icon: Icons.notifications_active_rounded,
          backgroundColor: Color(0xFF181622),
          borderColor: Color(0xFF43306B),
          accentColor: Color(0xFFC084FC),
          badgeBackground: Color(0xFF271E3D),
          tags: ['အင်ဂျင်ဝိုင်', 'လိုင်စင်', 'Passport'],
        );
      case AppModule.qrCard:
        return const _ModuleVisualStyle(
          icon: Icons.qr_code_2_rounded,
          backgroundColor: Color(0xFF171B16),
          borderColor: Color(0xFF3F571B),
          accentColor: AppTheme.neonLime600,
          badgeBackground: Color(0xFF232F10),
          tags: ['အရေးပေါ်ဖုန်း', 'သွေးအုပ်စု', 'Wi-Fi QR'],
        );
    }
  }

  String _badgeForModule(AppModule module, HomeViewModel vm) {
    switch (module) {
      case AppModule.calculators:
        return 'ကျပ် • ပဲ • ရွေး';
      case AppModule.ledger:
        return 'မှတ်တမ်း ${vm.ledgerCount} ခု';
      case AppModule.loansRentals:
        return 'ရရန်/ပေးရန် ${vm.openLoansRentals.length} ခု';
      case AppModule.recipesMarket:
        return 'ဝယ်ရန် ${vm.uncheckedShoppingCount} မျိုး';
      case AppModule.reminders:
        return 'ရက်နီး ${vm.upcomingReminders.length} ခု';
      case AppModule.qrCard:
        return vm.qrCard.isEmpty ? 'QR ပြင်ဆင်ရန်' : 'QR အသင့်ရှိ';
    }
  }

  void _openModule(BuildContext context, AppModule module) {
    switch (module) {
      case AppModule.calculators:
        context
            .read<FinanceCalcViewModel>()
            .setActiveSection(FinanceSection.calculators);
        break;
      case AppModule.ledger:
        context
            .read<FinanceCalcViewModel>()
            .setActiveSection(FinanceSection.ledger);
        break;
      case AppModule.loansRentals:
        context
            .read<FinanceCalcViewModel>()
            .setActiveSection(FinanceSection.loansRentals);
        break;
      case AppModule.recipesMarket:
        context
            .read<DailyMarketViewModel>()
            .setActiveSection(DailySection.recipes);
        break;
      case AppModule.reminders:
        context
            .read<RemindersQrViewModel>()
            .setActiveSection(ToolsSection.reminders);
        break;
      case AppModule.qrCard:
        context
            .read<RemindersQrViewModel>()
            .setActiveSection(ToolsSection.qrCard);
        break;
    }
    context.go(module.routePath);
  }

  Future<void> _showQuickQrDialog() async {
    final card = widget.viewModel.qrCard;
    final payload = card.toEmergencyQrPayload();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('အရေးပေါ် / Contact QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              card.isEmpty
                  ? 'သတိပေး/QR Tab ထဲမှာ ကိုယ့်အချက်အလက် ထည့်သွင်းနိုင်ပါတယ်။'
                  : payload,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ပိတ်မည်'),
          ),
        ],
      ),
    );
  }

  Future<void> _showModuleCustomizeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  'Home တွင် ပြသမည့် Module များ ရွေးချယ်ရန်',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...AppModule.values.map(
                  (module) => SwitchListTile(
                    value: widget.viewModel.enabledModules.contains(module),
                    title: Text(module.titleMm),
                    subtitle: Text(module.subtitleMm),
                    onChanged: (val) =>
                        widget.viewModel.toggleModule(module, val),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showBackupDialog() async {
    final jsonController = TextEditingController();
    final exported = await widget.viewModel.exportBackupJson();
    jsonController.text = exported;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Local JSON Backup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cloud server မလိုဘဲ ဒေတာအားလုံးကို JSON အဖြစ် Copy ကူးပြီး Google Drive သို့မဟုတ် Notes မှာ သိမ်းနိုင်ပါတယ်။',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jsonController,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Backup JSON Data',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonController.text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup JSON ကို Copy ကူးပြီးပါပြီ')),
                );
              }
            },
            child: const Text('Copy ကူးမည်'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await widget.viewModel.restoreBackupJson(jsonController.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup ပြန်သွင်းပြီးပါပြီ')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> _showCloudConnectDialog(CloudProviderType initialProvider) async {
    final vm = widget.viewModel;
    var provider = initialProvider == CloudProviderType.none
        ? CloudProviderType.googleDrive
        : initialProvider;
    final emailCtrl = TextEditingController(
      text: vm.cloudAccount.accountEmail.isNotEmpty
          ? vm.cloudAccount.accountEmail
          : (provider == CloudProviderType.googleDrive
              ? 'user@gmail.com'
              : 'user@icloud.com'),
    );

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cloud အကောင့် ချိတ်ဆက်သိမ်းဆည်းရန်'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ကိုယ်ပိုင် Gmail (Google Drive) သို့မဟုတ် Apple ID (iCloud) နှင့် ချိတ်ဆက်ထားပါက အလှူ/စုမဲ၊ ပေးရန်/ရရန်၊ ဈေးဝယ်စာရင်းနှင့် သတိပေးချက်အားလုံးကို သင့်အကောင့်ထဲသို့ အလိုအလျောက် သိမ်းဆည်းပေးပါမည်။',
                  style: TextStyle(fontSize: 13, color: AppTheme.gray200),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Google Drive (Gmail)'),
                      selected: provider == CloudProviderType.googleDrive,
                      onSelected: (_) {
                        setDialogState(() {
                          provider = CloudProviderType.googleDrive;
                          if (emailCtrl.text.endsWith('@icloud.com')) {
                            emailCtrl.text = 'user@gmail.com';
                          }
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Apple iCloud (Apple ID)'),
                      selected: provider == CloudProviderType.appleICloud,
                      onSelected: (_) {
                        setDialogState(() {
                          provider = CloudProviderType.appleICloud;
                          if (emailCtrl.text.endsWith('@gmail.com')) {
                            emailCtrl.text = 'user@icloud.com';
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: provider == CloudProviderType.googleDrive
                        ? 'Gmail လိပ်စာ (ဥပမာ - name@gmail.com)'
                        : 'Apple ID လိပ်စာ (ဥပမာ - name@icloud.com)',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'သိမ်းဆည်းမည့်နေရာ: ${provider.storagePathLabel}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.neonLime600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (vm.cloudAccount.isConnected)
              TextButton(
                onPressed: () async {
                  await vm.disconnectCloudAccount();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('အကောင့်ဖြုတ်မည်'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('မလုပ်တော့'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                await vm.connectCloudAccount(
                  provider: provider,
                  email: email,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${provider.labelMm} ($email) နှင့် ချိတ်ဆက်ပြီး Cloud ပေါ်သို့ သိမ်းဆည်းပြီးပါပြီ',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.cloud_done_rounded, size: 18),
              label: const Text('ချိတ်ဆက်သိမ်းမည်'),
            ),
          ],
        ),
      ),
    );
    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.neonLime600,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: AppTheme.obsidian1000,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'မြန်မာနေ့စဉ်',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.olive900,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.olive800),
              ),
              child: const Text(
                'PRO 6-IN-1',
                style: TextStyle(
                  color: AppTheme.neonLime600,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Quick QR',
            onPressed: _showQuickQrDialog,
            icon: const Icon(Icons.qr_code_2),
          ),
          IconButton(
            tooltip: 'Backup / Restore',
            onPressed: _showBackupDialog,
            icon: const Icon(Icons.save_alt_outlined),
          ),
          IconButton(
            tooltip: 'Module များ ရွေးရန်',
            onPressed: _showModuleCustomizeSheet,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final visibleModules = AppModule.values
              .where((m) => vm.enabledModules.contains(m))
              .toList();

          return RefreshIndicator(
            color: AppTheme.neonLime600,
            backgroundColor: AppTheme.cardSurface,
            onRefresh: vm.loadDashboard,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryRow(
                  upcomingReminderCount: vm.upcomingReminders.length,
                  openLoansCount: vm.openLoansRentals.length,
                  shoppingCount: vm.uncheckedShoppingCount,
                ),
                const SizedBox(height: 14),
                _CloudSyncBannerCard(
                  viewModel: vm,
                  onConnectTap: _showCloudConnectDialog,
                ),
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'နေ့စဉ်သုံး Tools များ',
                  trailing: TextButton.icon(
                    onPressed: _showModuleCustomizeSheet,
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('စိတ်ကြိုက်ရွေး'),
                  ),
                ),
                const SizedBox(height: 10),
                if (visibleModules.isEmpty)
                  const EmptyStateCard(
                    icon: Icons.tune,
                    title: 'Module အားလုံး ပိတ်ထားပါသည်',
                    subtitle: 'ညာဘက်အပေါ် ခလုတ်မှ လိုချင်သော Tool များကို ပြန်ဖွင့်နိုင်ပါသည်။',
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleModules.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisExtent: 176,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final module = visibleModules[index];
                      final style = _styleForModule(module);
                      final badgeText = _badgeForModule(module, vm);

                      return _ColorfulModuleCard(
                        module: module,
                        style: style,
                        badgeText: badgeText,
                        onTap: () => _openModule(context, module),
                      );
                    },
                  ),
                const SizedBox(height: 22),
                const SectionHeader(title: 'ရက်နီးနေသော သတိပေးချက်များ'),
                const SizedBox(height: 8),
                if (vm.upcomingReminders.isEmpty)
                  const EmptyStateCard(
                    icon: Icons.check_circle_outline,
                    title: 'ရက်နီးနေသော သတိပေးချက် မရှိသေးပါ',
                    subtitle: 'ယာဉ်အင်ဂျင်ဝိုင်၊ လိုင်စင်နဲ့ Passport ရက်စွဲများကို ထည့်သွင်းထားနိုင်ပါသည်။',
                  )
                else
                  ...vm.upcomingReminders.take(5).map(
                        (r) => Card(
                          color: const Color(0xFF171A14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: Color(0xFF3E5218)),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.olive900,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.event_note,
                                color: AppTheme.neonLime600,
                              ),
                            ),
                            title: Text(
                              r.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.white100,
                              ),
                            ),
                            subtitle: Text(
                              '${r.category.labelMm} • ${formatDateShort(r.dueDate)}',
                              style: const TextStyle(color: AppTheme.gray200),
                            ),
                            trailing: Text(
                              formatDaysRemainingMm(r.daysRemaining()),
                              style: TextStyle(
                                color: r.daysRemaining() <= 3
                                    ? Theme.of(context).colorScheme.error
                                    : AppTheme.neonLime600,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ColorfulModuleCard extends StatelessWidget {
  const _ColorfulModuleCard({
    required this.module,
    required this.style,
    required this.badgeText,
    required this.onTap,
  });

  final AppModule module;
  final _ModuleVisualStyle style;
  final String badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: style.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: style.borderColor, width: 1.4),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: style.badgeBackground,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: style.borderColor),
                    ),
                    child: Icon(
                      style.icon,
                      color: style.accentColor,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: style.badgeBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: style.borderColor),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: style.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: style.accentColor,
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                module.titleMm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white100,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                module.subtitleMm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray200,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: style.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1013),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: style.borderColor),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: style.accentColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.upcomingReminderCount,
    required this.openLoansCount,
    required this.shoppingCount,
  });

  final int upcomingReminderCount;
  final int openLoansCount;
  final int shoppingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChipCard(
            icon: Icons.notifications_active_outlined,
            label: 'သတိပေးရန်',
            value: '$upcomingReminderCount ခု',
            backgroundColor: const Color(0xFF171B12),
            borderColor: const Color(0xFF3E5218),
            accentColor: AppTheme.neonLime600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChipCard(
            icon: Icons.handshake_outlined,
            label: 'ပေးရန်/ရရန်',
            value: '$openLoansCount ခု',
            backgroundColor: const Color(0xFF151921),
            borderColor: const Color(0xFF233B5E),
            accentColor: const Color(0xFF38BDF8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChipCard(
            icon: Icons.shopping_bag_outlined,
            label: 'ဝယ်ရန်ကျန်',
            value: '$shoppingCount မျိုး',
            backgroundColor: const Color(0xFF1B1812),
            borderColor: const Color(0xFF544014),
            accentColor: const Color(0xFFFACC15),
          ),
        ),
      ],
    );
  }
}

class _StatChipCard extends StatelessWidget {
  const _StatChipCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.3),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.white100,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray200,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CloudSyncBannerCard extends StatelessWidget {
  const _CloudSyncBannerCard({
    required this.viewModel,
    required this.onConnectTap,
  });

  final HomeViewModel viewModel;
  final void Function(CloudProviderType) onConnectTap;

  @override
  Widget build(BuildContext context) {
    final account = viewModel.cloudAccount;
    final isConnected = account.isConnected;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected
              ? const [Color(0xFF1A240E), Color(0xFF131712)]
              : const [Color(0xFF161920), Color(0xFF121418)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? AppTheme.neonLime600 : const Color(0xFF2E3440),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppTheme.neonLime600
                      : const Color(0xFF28303D),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_upload_outlined,
                      size: 13,
                      color: isConnected
                          ? AppTheme.obsidian1000
                          : AppTheme.neonLime500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'CLOUD SYNC ACTIVE' : 'CLOUD BACKUP',
                      style: TextStyle(
                        color: isConnected
                            ? AppTheme.obsidian1000
                            : AppTheme.neonLime500,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isConnected
                      ? '${account.provider.labelMm} • ${account.accountEmail}'
                      : 'Gmail (Google Drive) / Apple ID (iCloud) ချိတ်ဆက်သိမ်းဆည်းရန်',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppTheme.white100,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isConnected)
                TextButton(
                  onPressed: () => onConnectTap(account.provider),
                  child: const Text('ပြင်ရန်'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isConnected
                ? '${account.provider.storagePathLabel} (${account.lastBackupSizeBytes} bytes • အလိုအလျောက် သိမ်းဆည်းပြီး)'
                : 'အလှူ/စုမဲ၊ ပေးရန်/ရရန်၊ ဈေးဝယ်စာရင်းနှင့် သတိပေးချက်အားလုံးကို ကိုယ်ပိုင် Google Drive သို့မဟုတ် Apple iCloud ထဲသို့ အလိုအလျောက် သိမ်းပေးပါသည်။',
            style: const TextStyle(fontSize: 12, color: AppTheme.gray200),
          ),
          const SizedBox(height: 12),
          if (!isConnected)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => onConnectTap(CloudProviderType.googleDrive),
                  icon: const Icon(Icons.add_to_drive_rounded, size: 18),
                  label: const Text('Google Drive (Gmail) ချိတ်မည်'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onConnectTap(CloudProviderType.appleICloud),
                  icon: const Icon(Icons.cloud_circle_outlined, size: 18),
                  label: const Text('Apple ID (iCloud) ချိတ်မည်'),
                ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed:
                      viewModel.isSyncingCloud ? null : viewModel.syncCloudNow,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 17),
                  label: const Text('ယခု Cloud သိမ်းမည်'),
                ),
                OutlinedButton.icon(
                  onPressed: viewModel.isSyncingCloud
                      ? null
                      : () async {
                          final ok = await viewModel.restoreFromCloud();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? '${account.provider.labelMm} မှ ဒေတာအားလုံး ပြန်ယူပြီးပါပြီ'
                                      : 'Cloud ပေါ်တွင် သိမ်းထားသော ဒေတာ မရှိသေးပါ',
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.cloud_download_outlined, size: 17),
                  label: const Text('Cloud မှ ပြန်ယူမည်'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
