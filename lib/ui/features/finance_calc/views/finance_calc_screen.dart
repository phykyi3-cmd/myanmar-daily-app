import 'package:flutter/material.dart';

import 'package:myanmar_daily_app/domain/models/ledger_entry.dart';
import 'package:myanmar_daily_app/domain/models/loan_rental_item.dart';
import 'package:myanmar_daily_app/ui/core/theme/app_theme.dart';
import 'package:myanmar_daily_app/ui/core/utils/formatters.dart';
import 'package:myanmar_daily_app/ui/core/widgets/category_selector_chips.dart';
import 'package:myanmar_daily_app/ui/core/widgets/empty_state_card.dart';
import '../view_models/finance_calc_view_model.dart';

/// Combined screen for Community Ledgers, Loans/Rentals, and Myanmar Calculators.
class FinanceCalcScreen extends StatefulWidget {
  const FinanceCalcScreen({super.key, required this.viewModel});

  final FinanceCalcViewModel viewModel;

  @override
  State<FinanceCalcScreen> createState() => _FinanceCalcScreenState();
}

class _FinanceCalcScreenState extends State<FinanceCalcScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.viewModel.loadAll();
    });
  }

  Future<void> _showAddLedgerDialog() async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var category = LedgerCategory.donation;
    var isIncome = true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('စာရင်းအသစ် ထည့်ရန်'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CategorySelectorChips<LedgerCategory>(
                  values: LedgerCategory.values,
                  selected: category,
                  labelBuilder: (c) => c.labelMm,
                  onSelected: (v) => setDialogState(() => category = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'ခေါင်းစဉ်'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ပမာဏ (ကျပ်)'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isIncome ? 'ဝင်ငွေ / လက်ခံ' : 'ထွက်ငွေ / ပေးသွင်း'),
                  value: isIncome,
                  onChanged: (v) => setDialogState(() => isIncome = v),
                ),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'မှတ်ချက် (မထည့်လည်းရ)'),
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
                final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
                if (title.isEmpty || amount <= 0) return;
                await widget.viewModel.addLedgerEntry(
                  LedgerEntry(
                    title: title,
                    category: category,
                    amountMmk: amount,
                    isIncome: isIncome,
                    note: noteCtrl.text.trim(),
                    createdAt: DateTime.now(),
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
    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<void> _showAddLoanDialog() async {
    final personCtrl = TextEditingController();
    final itemCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var type = LoanRentalType.lent;
    var dueDate = DateTime.now().add(const Duration(days: 7));

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ငှားရမ်း / ပေးရန်-ရရန် ထည့်ရန်'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CategorySelectorChips<LoanRentalType>(
                  values: LoanRentalType.values,
                  selected: type,
                  labelBuilder: (t) => t.labelMm,
                  onSelected: (v) => setDialogState(() => type = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: personCtrl,
                  decoration: const InputDecoration(labelText: 'လူအမည် / အိမ်ငှား'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: itemCtrl,
                  decoration: const InputDecoration(labelText: 'ပစ္စည်း / အကြောင်းအရာ'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ငွေပမာဏ (ကျပ်)'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('သတ်မှတ်ရက်စွဲ'),
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
                final person = personCtrl.text.trim();
                final item = itemCtrl.text.trim();
                final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
                if (person.isEmpty && item.isEmpty) return;
                await widget.viewModel.addLoanRental(
                  LoanRentalItem(
                    personName: person.isEmpty ? '-' : person,
                    itemName: item.isEmpty ? '-' : item,
                    type: type,
                    amountMmk: amount,
                    dueDate: dueDate,
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

    personCtrl.dispose();
    itemCtrl.dispose();
    amountCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final showFab = vm.activeSection != FinanceSection.calculators;

        return Scaffold(
          appBar: AppBar(title: const Text('စာရင်းနဲ့ တွက်စက်')),
          floatingActionButton: showFab
              ? FloatingActionButton.extended(
                  onPressed: vm.activeSection == FinanceSection.ledger
                      ? _showAddLedgerDialog
                      : _showAddLoanDialog,
                  icon: const Icon(Icons.add),
                  label: Text(
                    vm.activeSection == FinanceSection.ledger
                        ? 'စာရင်းထည့်'
                        : 'မှတ်တမ်းထည့်',
                  ),
                )
              : null,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<FinanceSection>(
                    segments: const [
                      ButtonSegment(
                        value: FinanceSection.ledger,
                        label: Text('အလှူ/စုမဲ'),
                      ),
                      ButtonSegment(
                        value: FinanceSection.loansRentals,
                        label: Text('ငှား/အကြွေး'),
                      ),
                      ButtonSegment(
                        value: FinanceSection.calculators,
                        label: Text('တွက်စက်'),
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
                  FinanceSection.ledger => _LedgerSection(viewModel: vm),
                  FinanceSection.loansRentals => _LoansSection(viewModel: vm),
                  FinanceSection.calculators =>
                    _CalculatorsSection(viewModel: vm),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LedgerSection extends StatelessWidget {
  const _LedgerSection({required this.viewModel});

  final FinanceCalcViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF171E10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppTheme.neonLime600, width: 1.3),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.volunteer_activism_rounded,
              color: AppTheme.neonLime600,
            ),
            title: const Text(
              'စုစုပေါင်း လက်ကျန်',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.white100,
              ),
            ),
            trailing: Text(
              formatMmk(viewModel.netLedgerMmk),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.neonLime600,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (viewModel.ledgerEntries.isEmpty)
          const EmptyStateCard(
            icon: Icons.receipt_long_outlined,
            title: 'အလှူ / စုမဲ စာရင်း မရှိသေးပါ',
            subtitle: 'ညာဘက်အောက် ခလုတ်မှ ဝင်ငွေ/ထွက်ငွေ မှတ်တမ်းထည့်နိုင်ပါသည်။',
          )
        else
          ...viewModel.ledgerEntries.map(
            (entry) => Card(
              child: ListTile(
                title: Text(entry.title),
                subtitle: Text(
                  '${entry.category.labelMm} • ${formatDateShort(entry.createdAt)}'
                  '${entry.note.isEmpty ? '' : ' • ${entry.note}'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entry.isIncome ? '+' : '-'}${formatMmk(entry.amountMmk)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: entry.isIncome
                            ? AppTheme.neonLime600
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: entry.id == null
                          ? null
                          : () => viewModel.deleteLedgerEntry(entry.id!),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LoansSection extends StatelessWidget {
  const _LoansSection({required this.viewModel});

  final FinanceCalcViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF151A22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF38BDF8), width: 1.3),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.handshake_rounded,
              color: Color(0xFF38BDF8),
            ),
            title: const Text(
              'ရရန်ကျန် စုစုပေါင်း',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.white100,
              ),
            ),
            trailing: Text(
              formatMmk(viewModel.pendingToReceiveMmk),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF38BDF8),
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (viewModel.loansRentals.isEmpty)
          const EmptyStateCard(
            icon: Icons.handshake_outlined,
            title: 'ပစ္စည်းငှား / အကြွေးစာရင်း မရှိသေးပါ',
            subtitle: 'ပေးချေး/ငှားထားတာနဲ့ အိမ်လခ ကောက်ရမယ့်ရက်များကို မှတ်ထားနိုင်ပါသည်။',
          )
        else
          ...viewModel.loansRentals.map(
            (item) => Card(
              child: ListTile(
                leading: Checkbox(
                  value: item.isSettled,
                  onChanged: (_) => viewModel.toggleLoanSettled(item),
                ),
                title: Text(
                  '${item.personName} — ${item.itemName}',
                  style: TextStyle(
                    decoration:
                        item.isSettled ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  '${item.type.labelMm} • ${formatDateShort(item.dueDate)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatMmk(item.amountMmk)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: item.id == null
                          ? null
                          : () => viewModel.deleteLoanRental(item.id!),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalculatorsSection extends StatefulWidget {
  const _CalculatorsSection({required this.viewModel});

  final FinanceCalcViewModel viewModel;

  @override
  State<_CalculatorsSection> createState() => _CalculatorsSectionState();
}

class _CalculatorsSectionState extends State<_CalculatorsSection> {
  late final TextEditingController _goldPriceCtrl;
  final _kyatCtrl = TextEditingController(text: '0');
  final _paeCtrl = TextEditingController(text: '4');
  final _ywayCtrl = TextEditingController(text: '0');
  final _wastagePaeCtrl = TextEditingController(text: '1');
  final _makingFeeCtrl = TextEditingController(text: '35000');

  late final TextEditingController _principalCtrl;
  late final TextEditingController _downCtrl;
  final _rateCtrl = TextEditingController(text: '2');
  final _monthsCtrl = TextEditingController(text: '6');

  final _fxAmountCtrl = TextEditingController(text: '100');
  late final TextEditingController _fxRateCtrl;
  bool _toMmk = true;
  DateTime? _lastAppliedSyncTime;

  static const Map<String, String> _currencyLabelsMm = {
    'USD': 'USD ဒေါ်လာ',
    'THB': 'THB ထိုင်းဘတ်',
    'SGD': 'SGD စင်ကာပူ',
    'CNY': 'CNY တရုတ်ယွမ်',
    'MYR': 'MYR မလေးရှား',
    'EUR': 'EUR ယူရို',
    'JPY (100)': 'JPY ဂျပန်ယန်း(100)',
    'KRW (1000)': 'KRW ကိုရီးယားဝမ်(1000)',
  };

  @override
  void initState() {
    super.initState();
    final vm = widget.viewModel;
    _goldPriceCtrl = TextEditingController(
      text: vm.activeGoldPricePerKyatMmk.toString(),
    );
    final phonePrice =
        ((280 * vm.marketSnapshot.usdMarketMmk) / 10000).round() * 10000;
    _principalCtrl = TextEditingController(text: phonePrice.toString());
    _downCtrl =
        TextEditingController(text: (phonePrice * 0.25).round().toString());
    _fxRateCtrl = TextEditingController(
      text: vm.activeCurrencyRateMmk.toString(),
    );
    _lastAppliedSyncTime = vm.marketSnapshot.lastSyncedAt;
  }

  void _syncControllersIfSnapshotUpdated(FinanceCalcViewModel vm) {
    if (_lastAppliedSyncTime == vm.marketSnapshot.lastSyncedAt) return;
    _lastAppliedSyncTime = vm.marketSnapshot.lastSyncedAt;
    _goldPriceCtrl.text = vm.activeGoldPricePerKyatMmk.toString();
    _fxRateCtrl.text = vm.activeCurrencyRateMmk.toString();
    final phonePrice =
        ((280 * vm.marketSnapshot.usdMarketMmk) / 10000).round() * 10000;
    _principalCtrl.text = phonePrice.toString();
    _downCtrl.text = (phonePrice * 0.25).round().toString();
  }

  void _triggerGoldCalculation(FinanceCalcViewModel vm) {
    vm.computeGold(
      kyat: int.tryParse(_kyatCtrl.text.trim()) ?? 0,
      pae: int.tryParse(_paeCtrl.text.trim()) ?? 0,
      yway: double.tryParse(_ywayCtrl.text.trim()) ?? 0,
      pricePerKyat: double.tryParse(_goldPriceCtrl.text.trim()) ?? 0,
      wastagePae: double.tryParse(_wastagePaeCtrl.text.trim()) ?? 0,
      makingFeeMmk: double.tryParse(_makingFeeCtrl.text.trim()) ?? 0,
    );
  }

  void _triggerInstallmentCalculation(FinanceCalcViewModel vm) {
    vm.computeInstallment(
      principal: double.tryParse(_principalCtrl.text.trim()) ?? 0,
      downPayment: double.tryParse(_downCtrl.text.trim()) ?? 0,
      monthlyFlatInterestPercent: double.tryParse(_rateCtrl.text.trim()) ?? 0,
      months: int.tryParse(_monthsCtrl.text.trim()) ?? 1,
    );
  }

  void _triggerCurrencyCalculation(FinanceCalcViewModel vm) {
    vm.computeCurrency(
      amount: double.tryParse(_fxAmountCtrl.text.trim()) ?? 0,
      rateMmkPerUnit: double.tryParse(_fxRateCtrl.text.trim()) ?? 0,
      toMmk: _toMmk,
    );
  }

  Future<void> _showEditMarketRatesDialog(FinanceCalcViewModel vm) async {
    final usdCtrl = TextEditingController(
      text: vm.marketSnapshot.usdMarketMmk.toString(),
    );
    final goldCtrl = TextEditingController(
      text: vm.marketSnapshot.myanmarGold16PaeMmk.toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ရွှေဈေးနှင့် ဒေါ်လာပေါက်ဈေး ချိန်ညှိရန်'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '1 USD ပြင်ပပေါက်ဈေး (ကျပ်)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: goldCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'အခေါက်ရွှေ (၁၆ ပဲရည်) ၁ ကျပ်သား (ကျပ်)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('မလုပ်တော့'),
          ),
          FilledButton(
            onPressed: () async {
              final nextUsd = int.tryParse(usdCtrl.text.trim());
              final nextGold = int.tryParse(goldCtrl.text.trim());
              if (nextUsd != null &&
                  nextUsd > 500 &&
                  nextUsd != vm.marketSnapshot.usdMarketMmk) {
                await vm.updateUsdMarketRate(nextUsd);
              } else if (nextGold != null && nextGold > 100000) {
                await vm.updateMyanmarGold16PaePrice(nextGold);
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('နှုန်းချိန်မည်'),
          ),
        ],
      ),
    );

    usdCtrl.dispose();
    goldCtrl.dispose();
  }

  @override
  void dispose() {
    _goldPriceCtrl.dispose();
    _kyatCtrl.dispose();
    _paeCtrl.dispose();
    _ywayCtrl.dispose();
    _wastagePaeCtrl.dispose();
    _makingFeeCtrl.dispose();
    _principalCtrl.dispose();
    _downCtrl.dispose();
    _rateCtrl.dispose();
    _monthsCtrl.dispose();
    _fxAmountCtrl.dispose();
    _fxRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    _syncControllersIfSnapshotUpdated(vm);
    final snap = vm.marketSnapshot;
    final goldResult = vm.goldResult;
    final installmentResult = vm.installmentResult;

    final phonePrice =
        ((280 * snap.usdMarketMmk) / 10000).round() * 10000;
    final motorbikePrice =
        ((780 * snap.usdMarketMmk) / 50000).round() * 50000;
    final solarPrice =
        ((520 * snap.usdMarketMmk) / 50000).round() * 50000;
    final goldRingPrice =
        ((snap.myanmarGold16PaeMmk * 0.25) / 10000).round() * 10000;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live Online Gold & Foreign Exchange Rate Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF171E10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.neonLime600, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: snap.isOnlineLive
                          ? AppTheme.neonLime600
                          : const Color(0xFFFACC15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          snap.isOnlineLive
                              ? Icons.cloud_done_rounded
                              : Icons.offline_bolt_rounded,
                          size: 13,
                          color: AppTheme.obsidian1000,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          snap.isOnlineLive ? 'ONLINE LIVE' : 'LOCAL RATE',
                          style: const TextStyle(
                            color: AppTheme.obsidian1000,
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
                      snap.sourceNote,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neonLime500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Online ပေါက်ဈေး Sync လုပ်ရန်',
                    onPressed: vm.isSyncingOnline ? null : vm.syncOnlineRates,
                    icon: vm.isSyncingOnline
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            color: AppTheme.neonLime600,
                          ),
                  ),
                  TextButton(
                    onPressed: () => _showEditMarketRatesDialog(vm),
                    child: const Text('ပေါက်ဈေးချိန်ရန်'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: const Color(0xFF282110),
                        side: const BorderSide(color: Color(0xFFFACC15)),
                        label: Text(
                          '၁၆ ပဲရည် (၁ ကျပ်သား): ${formatMmk(snap.myanmarGold16PaeMmk)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFACC15),
                          ),
                        ),
                        onPressed: () => _showEditMarketRatesDialog(vm),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: const Color(0xFF282110),
                        side: const BorderSide(color: Color(0xFFFACC15)),
                        label: Text(
                          '၁၅ ပဲရည်: ${formatMmk(snap.myanmarGold15PaeMmk)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFACC15),
                          ),
                        ),
                        onPressed: () => _showEditMarketRatesDialog(vm),
                      ),
                    ),
                    ...snap.foreignRatesMmk.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          backgroundColor: const Color(0xFF1F2812),
                          side: const BorderSide(color: AppTheme.olive800),
                          label: Text(
                            '1 ${e.key}: ${formatMmk(e.value.round())}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.neonLime500,
                            ),
                          ),
                          onPressed: () {
                            vm.setSelectedCurrencyCode(e.key);
                            _fxRateCtrl.text = e.value.toString();
                            _triggerCurrencyCalculation(vm);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 1. Live Online Gold Calculator
        Card(
          color: const Color(0xFF16181C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF4B6419), width: 1.3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'ရွှေဈေးတွက်စက် (ကျပ် / ပဲ / ရွေး)',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.neonLime600,
                                ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.olive900,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.olive800),
                      ),
                      child: Text(
                        'XAU \$${snap.worldGoldUsdPerOz.toStringAsFixed(0)}/oz',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.neonLime500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(
                        '၁၆ ပဲရည် အခေါက်ရွှေ (${formatMmk(snap.myanmarGold16PaeMmk)})',
                      ),
                      selected: !vm.use15PaeGold,
                      onSelected: (_) {
                        vm.setGoldQuality(use15Pae: false);
                        _goldPriceCtrl.text =
                            snap.myanmarGold16PaeMmk.toString();
                        _triggerGoldCalculation(vm);
                      },
                    ),
                    ChoiceChip(
                      label: Text(
                        '၁၅ ပဲရည် အထည်ရွှေ (${formatMmk(snap.myanmarGold15PaeMmk)})',
                      ),
                      selected: vm.use15PaeGold,
                      onSelected: (_) {
                        vm.setGoldQuality(use15Pae: true);
                        _goldPriceCtrl.text =
                            snap.myanmarGold15PaeMmk.toString();
                        _triggerGoldCalculation(vm);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _goldPriceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '၁ ကျပ်သား ပေါက်ဈေး (ကျပ်) — Online Auto-Sync',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _kyatCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ကျပ်'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _paeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ပဲ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ywayCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'ရွေး'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _wastagePaeCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'အလျော့တွက် (ပဲ)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _makingFeeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'လက်ခ (ကျပ်)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _triggerGoldCalculation(vm),
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('ရွှေတန်ဖိုး တွက်မည်'),
                ),
                if (goldResult != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171E10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.neonLime600),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ရွှေသားတန်ဖိုး: ${formatMmk(goldResult.goldValueMmk)}'),
                        Text(
                          'အလျော့တွက်တန်ဖိုး: ${formatMmk(goldResult.wastageValueMmk)}',
                        ),
                        const Divider(height: 12),
                        Text(
                          'စုစုပေါင်း ကျသင့်ငွေ: ${formatMmk(goldResult.totalMmk)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppTheme.neonLime600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Live Online Market Installment Calculator
        Card(
          color: const Color(0xFF16181C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF2A3A52), width: 1.3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'အရစ်ကျ / အတိုး တွက်စက် (Online ပေါက်ဈေးချိတ်ဆက်)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF38BDF8),
                      ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            '📱 ဖုန်း (${formatMmk(phonePrice)})',
                          ),
                          onPressed: () {
                            _principalCtrl.text = phonePrice.toString();
                            _downCtrl.text =
                                (phonePrice * 0.25).round().toString();
                            _rateCtrl.text = '2';
                            _monthsCtrl.text = '6';
                            _triggerInstallmentCalculation(vm);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            '🛵 ဆိုင်ကယ် (${formatMmk(motorbikePrice)})',
                          ),
                          onPressed: () {
                            _principalCtrl.text = motorbikePrice.toString();
                            _downCtrl.text =
                                (motorbikePrice * 0.3).round().toString();
                            _rateCtrl.text = '2.5';
                            _monthsCtrl.text = '12';
                            _triggerInstallmentCalculation(vm);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            '☀️ ဆိုလာ/အင်ဗာတာ (${formatMmk(solarPrice)})',
                          ),
                          onPressed: () {
                            _principalCtrl.text = solarPrice.toString();
                            _downCtrl.text =
                                (solarPrice * 0.2).round().toString();
                            _rateCtrl.text = '1.8';
                            _monthsCtrl.text = '6';
                            _triggerInstallmentCalculation(vm);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            '💍 ရွှေထည် ၄ ပဲသား (${formatMmk(goldRingPrice)})',
                          ),
                          onPressed: () {
                            _principalCtrl.text = goldRingPrice.toString();
                            _downCtrl.text =
                                (goldRingPrice * 0.3).round().toString();
                            _rateCtrl.text = '2';
                            _monthsCtrl.text = '4';
                            _triggerInstallmentCalculation(vm);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _principalCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'ပစ္စည်းတန်ဖိုး'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _downCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'စရန်ငွေ'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'လစဉ်အတိုး (%)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _monthsCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'လအရေအတွက်'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _triggerInstallmentCalculation(vm),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('လစဉ်သွင်းငွေ တွက်မည်'),
                ),
                if (installmentResult != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B26),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF38BDF8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'တစ်လသွင်းငွေ: ${formatMmk(installmentResult.monthlyPayment)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppTheme.neonLime600,
                          ),
                        ),
                        Text(
                          'ကျန်ရှိ အရင်းငွေ: ${formatMmk(installmentResult.financedAmount)}',
                        ),
                        Text(
                          'စုစုပေါင်းအတိုး: ${formatMmk(installmentResult.totalInterest)}',
                        ),
                        Text(
                          'စရန်အပါ စုစုပေါင်းပေးရငွေ: ${formatMmk(installmentResult.totalPayable)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 3. Live Online Multi-Currency Converter
        Card(
          color: const Color(0xFF16181C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF4B6419), width: 1.3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'နိုင်ငံခြားငွေလဲနှုန်း တွက်စက် (Online Live FX)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.neonLime600,
                      ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: snap.foreignRatesMmk.entries.map((entry) {
                      final label = _currencyLabelsMm[entry.key] ?? entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            '$label (${formatMmk(entry.value.round())})',
                          ),
                          selected: vm.selectedCurrencyCode == entry.key,
                          onSelected: (_) {
                            vm.setSelectedCurrencyCode(entry.key);
                            _fxRateCtrl.text = entry.value.toString();
                            _triggerCurrencyCalculation(vm);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fxAmountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _toMmk
                              ? 'ပမာဏ (${vm.selectedCurrencyCode})'
                              : 'ပမာဏ (ကျပ် MMK)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _fxRateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              '1 ${vm.selectedCurrencyCode} ပေါက်ဈေး (ကျပ်)',
                        ),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _toMmk
                        ? '${vm.selectedCurrencyCode} နိုင်ငံခြားငွေ → မြန်မာကျပ် (MMK)'
                        : 'မြန်မာကျပ် (MMK) → ${vm.selectedCurrencyCode} နိုင်ငံခြားငွေ',
                  ),
                  value: _toMmk,
                  onChanged: (v) {
                    setState(() => _toMmk = v);
                    _triggerCurrencyCalculation(vm);
                  },
                ),
                FilledButton.icon(
                  onPressed: () => _triggerCurrencyCalculation(vm),
                  icon: const Icon(Icons.currency_exchange_rounded),
                  label: const Text('ပြောင်းလဲတွက်မည်'),
                ),
                if (vm.currencyConverted > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171E10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.neonLime600),
                    ),
                    child: Text(
                      _toMmk
                          ? 'ကျသင့်ငွေ: ${formatMmk(vm.currencyConverted.round())}'
                          : 'ရရှိမည့်ပမာဏ: ${vm.currencyConverted.toStringAsFixed(2)} ${vm.selectedCurrencyCode}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.neonLime600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
