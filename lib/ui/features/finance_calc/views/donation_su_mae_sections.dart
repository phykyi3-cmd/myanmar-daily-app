import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:myanmar_daily_app/domain/models/donation_su_mae_models.dart';
import 'package:myanmar_daily_app/ui/core/theme/app_theme.dart';
import 'package:myanmar_daily_app/ui/core/utils/formatters.dart';
import 'package:myanmar_daily_app/ui/core/widgets/empty_state_card.dart';
import '../view_models/finance_calc_view_model.dart';

/// Unified 'အလှူ/စုမဲ' Hub separating Group Donations, Traditional Myanmar Su Mae,
/// and General Income/Expense Ledger cleanly.
class CommunityHubSection extends StatelessWidget {
  const CommunityHubSection({
    super.key,
    required this.viewModel,
    required this.generalLedgerView,
  });

  final FinanceCalcViewModel viewModel;
  final Widget generalLedgerView;

  @override
  Widget build(BuildContext context) {
    final activeTab = viewModel.activeCommunityTab;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF14171D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF283024)),
            ),
            child: Row(
              children: [
                _SubTabPill(
                  label: 'အလှူစာရင်း (${viewModel.donationCampaigns.length})',
                  selected: activeTab == CommunitySubTab.donations,
                  onTap: () => viewModel
                      .setActiveCommunityTab(CommunitySubTab.donations),
                ),
                _SubTabPill(
                  label: 'စုမဲ (${viewModel.suMaeGroups.length})',
                  selected: activeTab == CommunitySubTab.suMae,
                  onTap: () =>
                      viewModel.setActiveCommunityTab(CommunitySubTab.suMae),
                ),
                _SubTabPill(
                  label: 'အထွေထွေ (${viewModel.ledgerEntries.length})',
                  selected: activeTab == CommunitySubTab.generalLedger,
                  onTap: () => viewModel
                      .setActiveCommunityTab(CommunitySubTab.generalLedger),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: switch (activeTab) {
            CommunitySubTab.donations => _DonationsTab(viewModel: viewModel),
            CommunitySubTab.suMae => _SuMaeTab(viewModel: viewModel),
            CommunitySubTab.generalLedger => generalLedgerView,
          },
        ),
      ],
    );
  }
}

class _SubTabPill extends StatelessWidget {
  const _SubTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppTheme.neonLime600 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? AppTheme.obsidian1000 : AppTheme.gray200,
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the modal dialog to create a new Donation Campaign (`ဘုံကထိန်`, etc.).
Future<void> showCreateDonationCampaignDialog(
  BuildContext context,
  FinanceCalcViewModel vm,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _CreateDonationCampaignDialog(viewModel: vm),
  );
}

/// Opens the modal dialog to create a new Myanmar Su Mae ROSCA Group.
Future<void> showCreateSuMaeGroupDialog(
  BuildContext context,
  FinanceCalcViewModel vm,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _CreateSuMaeGroupDialog(viewModel: vm),
  );
}

// =============================================================================
// 1. GROUP DONATION CAMPAIGNS TAB (အလှူစာရင်း — ဘုံကထိန် / ဝါဆိုသင်္ကန်း / ဒါန)
// =============================================================================

class _DonationsTab extends StatelessWidget {
  const _DonationsTab({required this.viewModel});

  final FinanceCalcViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final campaigns = viewModel.donationCampaigns;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 92),
      children: [
        // Top Summary Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF171E10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.neonLime600, width: 1.3),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.volunteer_activism_rounded,
                color: AppTheme.neonLime600,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'အလှူငွေ စုစုပေါင်း (ကောက်ခံပြီး)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.gray200,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMmk(viewModel.totalDonationsCollectedMmk),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.neonLime500,
                      ),
                    ),
                    Text(
                      'အလှူခေါင်းစဉ် ${campaigns.length} ခု • အလှူရှင် စုစုပေါင်း ${viewModel.totalDonorsCount} ဦး',
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
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () =>
              showCreateDonationCampaignDialog(context, viewModel),
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('အလှူခေါင်းစဉ်အသစ် ဖွင့်မည် (ဥပမာ - ဘုံကထိန်)'),
        ),
        const SizedBox(height: 12),
        if (campaigns.isEmpty)
          const EmptyStateCard(
            icon: Icons.volunteer_activism_outlined,
            title: 'အလှူခေါင်းစဉ် မဖွင့်ရသေးပါ',
            subtitle:
                'ဘုံကထိန်၊ ဝါဆိုသင်္ကန်း စသည့် အလှူခေါင်းစဉ်ဖွင့်ပြီး အလှူရှင်တစ်ဦးချင်းစီ (အမည်၊ ငွေပမာဏ၊ ရက်စွဲ) ကို အချိန်မရွေး ထပ်ဖြည့်မှတ်တမ်းတင်နိုင်ပါသည်။',
          )
        else
          ...campaigns.map(
            (campaign) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DonationCampaignCard(
                campaign: campaign,
                viewModel: viewModel,
              ),
            ),
          ),
      ],
    );
  }
}

class _DonationCampaignCard extends StatelessWidget {
  const _DonationCampaignCard({
    required this.campaign,
    required this.viewModel,
  });

  final DonationCampaign campaign;
  final FinanceCalcViewModel viewModel;

  Future<void> _confirmDeleteCampaign(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('အလှူစာရင်း ဖျက်မည်လား?'),
        content: Text(
          '"${campaign.title}" နှင့် အလှူရှင် (${campaign.donorCount} ဦး) မှတ်တမ်းအားလုံးကို ဖျက်ပစ်မည် ဖြစ်ပါသည်။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('မဖျက်တော့'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ဖျက်မည်'),
          ),
        ],
      ),
    );
    if (ok == true && campaign.id != null) {
      await viewModel.deleteDonationCampaign(campaign.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14181E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334124), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campaign Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.neonLime600.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                    AppTheme.neonLime500.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              campaign.type.labelMm,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.neonLime500,
                              ),
                            ),
                          ),
                          Text(
                            'ရက်စွဲ: ${formatDateShort(campaign.eventDate)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.gray300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        campaign.title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.white100,
                        ),
                      ),
                      if (campaign.note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          campaign.note,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.gray300,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'အလှူစာရင်း Copy ကူးမည်',
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: campaign.formatShareSummaryMm()),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('အလှူရှင်စာရင်း Copy ကူးပြီးပါပြီ'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 19,
                    color: AppTheme.neonLime500,
                  ),
                ),
                IconButton(
                  tooltip: 'အလှူခေါင်းစဉ် ဖျက်မည်',
                  onPressed: () => _confirmDeleteCampaign(context),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Color(0xFFF87171),
                  ),
                ),
              ],
            ),
          ),

          // Optional Target Goal Bar
          if (campaign.targetAmountMmk > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ရည်မှန်းချက်: ${formatMmk(campaign.targetAmountMmk)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.gray200,
                        ),
                      ),
                      Text(
                        '${(campaign.targetProgress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.neonLime500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: campaign.targetProgress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFF232934),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.neonLime500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1, color: Color(0xFF252C36)),

          // Donor List Header + Add Donor Button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Text(
                  'လှူဒါန်းသူ စာရင်း (${campaign.donorCount} ဦး)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.white100,
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _AddDonorDialog(
                      campaign: campaign,
                      viewModel: viewModel,
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text(
                    'အလှူရှင် ထပ်ဖြည့်မည်',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          // Donor Rows
          if (campaign.contributions.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: Text(
                'အလှူရှင် မထည့်ရသေးပါ — "အလှူရှင် ထပ်ဖြည့်မည်" ကိုနှိပ်ပြီး လိုအပ်သလို ထပ်ဖြည့်မှတ်တမ်းတင်နိုင်ပါသည်။',
                style: TextStyle(fontSize: 12, color: AppTheme.gray300),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
              child: Column(
                children: [
                  for (var i = 0; i < campaign.contributions.length; i++)
                    _DonorRowItem(
                      index: i + 1,
                      item: campaign.contributions[i],
                      onTogglePaid: () => viewModel.toggleDonorPaidStatus(
                        campaign,
                        campaign.contributions[i].id,
                      ),
                      onDelete: () => viewModel.deleteDonorContribution(
                        campaign,
                        campaign.contributions[i].id,
                      ),
                    ),
                ],
              ),
            ),

          // Campaign Total Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFF171E10),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(17)),
              border: Border(top: BorderSide(color: Color(0xFF334124))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ပါဝင်လှူဒါန်းသူ: ${campaign.donorCount} ဦး (ပေးပြီး ${campaign.paidDonorCount} ဦး)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gray200,
                        ),
                      ),
                    ),
                    Text(
                      'စုစုပေါင်း: ${formatMmk(campaign.totalCollectedMmk)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.neonLime500,
                      ),
                    ),
                  ],
                ),
                if (campaign.totalPledgedMmk > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    'ကတိပြု ကျန်ငွေ: ${formatMmk(campaign.totalPledgedMmk)} • စုစုပေါင်းတန်ဖိုး: ${formatMmk(campaign.grandTotalMmk)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFACC15),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonorRowItem extends StatelessWidget {
  const _DonorRowItem({
    required this.index,
    required this.item,
    required this.onTogglePaid,
    required this.onDelete,
  });

  final int index;
  final DonorContribution item;
  final VoidCallback onTogglePaid;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        item.isPaid ? const Color(0xFF4ADE80) : const Color(0xFFFACC15);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF29313E)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: badgeColor.withValues(alpha: 0.16),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.donorName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.white100,
                  ),
                ),
                Text(
                  '${formatDateShort(item.donatedDate)} • ${item.paymentMethodMm}'
                  '${item.note.isEmpty ? '' : ' • ${item.note}'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.gray300,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMmk(item.amountMmk),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: item.isPaid
                      ? AppTheme.neonLime500
                      : const Color(0xFFFACC15),
                ),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: onTogglePaid,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.isPaid ? 'ပေးပြီး ✓' : 'ကတိပြု (နှိပ်)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 2),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onDelete,
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppTheme.gray300,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. TRADITIONAL MYANMAR SU MAE TAB (စုမဲ / ငွေစုစု — မဲနှိုက် / လေလံ / အလှည့်ကျ)
// =============================================================================

class _SuMaeTab extends StatefulWidget {
  const _SuMaeTab({required this.viewModel});

  final FinanceCalcViewModel viewModel;

  @override
  State<_SuMaeTab> createState() => _SuMaeTabState();
}

class _SuMaeTabState extends State<_SuMaeTab> {
  bool _showGuide = false;

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final groups = vm.suMaeGroups;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 92),
      children: [
        // Top Su Mae Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A170E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFACC15).withValues(alpha: 0.8),
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.savings_rounded,
                color: Color(0xFFFACC15),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'မြန်မာ့ စုမဲ (ငွေစုစု) စုစုပေါင်း မဲငွေပမာဏ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFDE68A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMmk(vm.totalActiveSuMaePotMmk),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFACC15),
                      ),
                    ),
                    Text(
                      'စုမဲအဖွဲ့ ${groups.length} ဖွဲ့ • မဲနှိုက် / လေလံ / ဒိုင်ယူအလှည့်ကျ',
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
        ),
        const SizedBox(height: 8),

        // Collapsible Guide to 3 Authentic Myanmar Su Mae Types
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF14171D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2B313C)),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _showGuide = !_showGuide),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: Color(0xFFFACC15),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'မြန်မာ့ စုမဲ (ငွေစုစု) ၃ မျိုး ပုံစံ ရှင်းလင်းချက်',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.white100,
                          ),
                        ),
                      ),
                      Icon(
                        _showGuide
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.gray300,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showGuide)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: SuMaeStyle.values
                        .map(
                          (style) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '• ${style.labelMm}: ${style.descriptionMm}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.4,
                                color: AppTheme.gray200,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        FilledButton.icon(
          onPressed: () => showCreateSuMaeGroupDialog(context, vm),
          icon: const Icon(Icons.group_add_rounded),
          label: const Text('စုမဲအဖွဲ့အသစ် ဖွင့်မည် (မဲနှိုက် / လေလံ / အလှည့်ကျ)'),
        ),
        const SizedBox(height: 12),

        if (groups.isEmpty)
          const EmptyStateCard(
            icon: Icons.savings_outlined,
            title: 'စုမဲအဖွဲ့ မဖွင့်ရသေးပါ',
            subtitle:
                'ရုံးစုမဲ၊ ဈေးစုမဲ၊ မိသားစုစုမဲများ ဖွင့်ပြီး အဖွဲ့ဝင်အလိုက် အလှည့်ကျငွေကောက်ခံမှု၊ ကျပန်းမဲနှိုက်ခြင်းနှင့် လေလံကြေးတွက်ချက်မှုများကို မှတ်တမ်းတင်နိုင်ပါသည်။',
          )
        else
          ...groups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SuMaeGroupCard(
                key: ValueKey('sumae_${group.id}_${group.rounds.length}'),
                group: group,
                viewModel: vm,
              ),
            ),
          ),
      ],
    );
  }
}

class _SuMaeGroupCard extends StatefulWidget {
  const _SuMaeGroupCard({
    super.key,
    required this.group,
    required this.viewModel,
  });

  final SuMaeGroup group;
  final FinanceCalcViewModel viewModel;

  @override
  State<_SuMaeGroupCard> createState() => _SuMaeGroupCardState();
}

class _SuMaeGroupCardState extends State<_SuMaeGroupCard> {
  late int _selectedRoundNum;

  @override
  void initState() {
    super.initState();
    final openRound = widget.group.rounds.cast<SuMaeRound?>().firstWhere(
          (r) => r != null && !r.isClosed,
          orElse: () => null,
        );
    _selectedRoundNum = openRound?.roundNumber ??
        (widget.group.rounds.isNotEmpty
            ? widget.group.rounds.last.roundNumber
            : 1);
  }

  @override
  void didUpdateWidget(covariant _SuMaeGroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final exists =
        widget.group.rounds.any((r) => r.roundNumber == _selectedRoundNum);
    if (!exists && widget.group.rounds.isNotEmpty) {
      _selectedRoundNum = widget.group.rounds.last.roundNumber;
    }
  }

  Future<void> _confirmDeleteGroup(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('စုမဲအဖွဲ့ ဖျက်မည်လား?'),
        content: Text(
          '"${widget.group.name}" နှင့် အဖွဲ့ဝင်/အလှည့်မှတ်တမ်းအားလုံးကို ဖျက်ပစ်မည် ဖြစ်ပါသည်။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('မဖျက်တော့'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ဖျက်မည်'),
          ),
        ],
      ),
    );
    if (ok == true && widget.group.id != null) {
      await widget.viewModel.deleteSuMaeGroup(widget.group.id!);
    }
  }

  Future<void> _openSettleWinnerDialog(
    BuildContext context,
    SuMaeRound round, {
    bool randomDraw = false,
  }) async {
    final waiting = widget.group.waitingMembers;
    if (waiting.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('မဲမပေါက်သေးသော အဖွဲ့ဝင် မကျန်တော့ပါ'),
        ),
      );
      return;
    }

    SuMaeMember? initialPick;
    if (randomDraw) {
      initialPick = waiting[Random().nextInt(waiting.length)];
    } else if (widget.group.style == SuMaeStyle.fixedTurn) {
      initialPick = waiting.first;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => _SettleSuMaeWinnerDialog(
        group: widget.group,
        round: round,
        viewModel: widget.viewModel,
        initialWinner: initialPick,
        wasRandomlyDrawn: randomDraw,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final vm = widget.viewModel;
    final activeRound = group.rounds.firstWhere(
      (r) => r.roundNumber == _selectedRoundNum,
      orElse: () => group.rounds.first,
    );
    final expectedTotal = group.expectedTotalForRound(activeRound);
    final collected = activeRound.totalCollectedMmk;
    final remaining = (expectedTotal - collected).clamp(0, expectedTotal);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14181E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFACC15).withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Group Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFACC15)
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFFACC15)
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              '${group.style.labelMm} • ${group.cycle.labelMm}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFACC15),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'ပြီးစီး ${group.completedRoundsCount}/${group.plannedRounds} အလှည့်',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.gray200,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.white100,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '၁ မဲ: ${formatMmk(group.contributionPerShareMmk)}  •  မဲငွေစုစုပေါင်း: ${formatMmk(group.potSizeMmk)}'
                        '${group.organizerName.isEmpty ? '' : '  •  ဒိုင်: ${group.organizerName}'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.neonLime500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'အလှည့်စာရင်း Copy ကူးမည်',
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: group.formatRoundSummaryMm(activeRound),
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('စုမဲအလှည့်စာရင်း Copy ကူးပြီးပါပြီ'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 19,
                    color: Color(0xFFFACC15),
                  ),
                ),
                IconButton(
                  tooltip: 'စုမဲအဖွဲ့ ဖျက်မည်',
                  onPressed: () => _confirmDeleteGroup(context),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Color(0xFFF87171),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF252C36)),

          // Round Switcher Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...group.rounds.map((r) {
                    final selected = r.roundNumber == activeRound.roundNumber;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          'အလှည့် ${r.roundNumber}${r.isClosed ? ' ✓' : ''}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedRoundNum = r.roundNumber),
                      ),
                    );
                  }),
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.add_rounded, size: 15),
                    label: const Text(
                      'အလှည့်သစ်',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    onPressed: () async {
                      await vm.addNextSuMaeRound(group);
                      setState(() {
                        _selectedRoundNum = group.rounds.length + 1;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Active Round Date + Add Member Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'အလှည့် ${activeRound.roundNumber} (${formatDateShort(activeRound.dueDate)}) • အဖွဲ့ဝင် ${group.members.length} ဦး',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white100,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                  ),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _AddSuMaeMemberDialog(
                      group: group,
                      viewModel: vm,
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                  label: const Text(
                    'အဖွဲ့ဝင် ထည့်မည်',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          // Winner Banner (if Round Settled) OR Draw/Assign Controls
          if (activeRound.isClosed)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFF231E0D),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFACC15),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'အလှည့် ${activeRound.roundNumber} မဲပေါက်သူ: ${activeRound.winnerName}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFACC15),
                            ),
                          ),
                          Text(
                            'ထုတ်ပေးငွေ: ${formatMmk(activeRound.netPayoutMmk)}'
                            '${activeRound.auctionBidMmk > 0 ? ' (လေလံကြေး ${formatMmk(activeRound.auctionBidMmk)})' : ''}'
                            '${activeRound.settledAt != null ? ' • ${formatDateShort(activeRound.settledAt!)}' : ''}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.gray200,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'မဲပေါက်သူ ပြန်ပြင်မည်',
                      onPressed: () => vm.undoSuMaeRoundWinner(
                        group: group,
                        roundNumber: activeRound.roundNumber,
                      ),
                      icon: const Icon(
                        Icons.undo_rounded,
                        size: 18,
                        color: AppTheme.gray300,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (group.members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _openSettleWinnerDialog(
                        context,
                        activeRound,
                        randomDraw: true,
                      ),
                      icon: const Icon(Icons.casino_rounded, size: 17),
                      label: const Text(
                        'ကျပန်း မဲနှိုက်မည်',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _openSettleWinnerDialog(
                        context,
                        activeRound,
                        randomDraw: false,
                      ),
                      icon: const Icon(Icons.how_to_reg_rounded, size: 17),
                      label: Text(
                        group.style == SuMaeStyle.auctionBid
                            ? 'လေလံ မဲပေးမည်'
                            : 'မဲပေါက်သူ ရွေးမည်',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Members Payment Checklist for Selected Round
          if (group.members.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 2, 14, 14),
              child: Text(
                'အဖွဲ့ဝင် မထည့်ရသေးပါ — "အဖွဲ့ဝင် ထည့်မည်" ကိုနှိပ်ပြီး စုမဲပါဝင်သူများ (၁ မဲ / မဲဝက် / ၂ မဲ) ထည့်သွင်းပါ။',
                style: TextStyle(fontSize: 12, color: AppTheme.gray300),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: [
                  for (var i = 0; i < group.members.length; i++)
                    _SuMaeMemberPaymentRow(
                      index: i + 1,
                      member: group.members[i],
                      expectedMmk:
                          group.expectedContributionForMember(group.members[i]),
                      payment: activeRound.payments[group.members[i].id],
                      onTogglePaid: () => vm.toggleSuMaeRoundPayment(
                        group: group,
                        roundNumber: activeRound.roundNumber,
                        member: group.members[i],
                      ),
                      onRemove: () =>
                          vm.removeSuMaeMember(group, group.members[i].id),
                    ),
                ],
              ),
            ),

          // Bottom Round Totals Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFF171E10),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(17)),
              border: Border(top: BorderSide(color: Color(0xFF334124))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ပေးပြီး: ${activeRound.paidCount}/${group.members.length} ဦး • ကျန်မဲ: ${group.waitingMembers.length} ဦး',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gray200,
                        ),
                      ),
                      if (remaining > 0)
                        Text(
                          'ကောက်ခံရန်ကျန်: ${formatMmk(remaining)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF87171),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'အလှည့်ကောက်ခံပြီး',
                      style: TextStyle(fontSize: 10.5, color: AppTheme.gray300),
                    ),
                    Text(
                      formatMmk(collected),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.neonLime500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuMaeMemberPaymentRow extends StatelessWidget {
  const _SuMaeMemberPaymentRow({
    required this.index,
    required this.member,
    required this.expectedMmk,
    required this.payment,
    required this.onTogglePaid,
    required this.onRemove,
  });

  final int index;
  final SuMaeMember member;
  final int expectedMmk;
  final SuMaePayment? payment;
  final VoidCallback onTogglePaid;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isPaid = payment != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFF152215) : const Color(0xFF1A1F28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid
              ? const Color(0xFF4ADE80).withValues(alpha: 0.45)
              : const Color(0xFF2A3240),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            visualDensity: VisualDensity.compact,
            value: isPaid,
            onChanged: (_) => onTogglePaid(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$index. ${member.name} (${member.shareLabelMm})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.white100,
                        ),
                      ),
                    ),
                    if (member.hasWon) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFACC15).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'အလှည့် ${member.wonRoundNumber} ပေါက်ပြီး',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFACC15),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  isPaid
                      ? 'ပေးပြီး ✓ • ${formatMmk(payment!.amountMmk)} • ${formatDateShort(payment!.paidAt)}'
                      : 'ထည့်ဝင်ရန်: ${formatMmk(expectedMmk)} • မပေးရသေး',
                  style: TextStyle(
                    fontSize: 11,
                    color: isPaid
                        ? const Color(0xFF4ADE80)
                        : AppTheme.gray300,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppTheme.gray300,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. STATEFUL DIALOGS (Safe TextEditingController lifecycle + Burmese Digits)
// =============================================================================

class _CreateDonationCampaignDialog extends StatefulWidget {
  const _CreateDonationCampaignDialog({required this.viewModel});

  final FinanceCalcViewModel viewModel;

  @override
  State<_CreateDonationCampaignDialog> createState() =>
      _CreateDonationCampaignDialogState();
}

class _CreateDonationCampaignDialogState
    extends State<_CreateDonationCampaignDialog> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DonationType _type = DonationType.kathina;
  DateTime _eventDate = DateTime.now();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('အလှူခေါင်းစဉ်အသစ် ဖွင့်ရန်'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'အလှူအမျိုးအစား ရွေးပါ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: DonationType.values
                  .map(
                    (t) => ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(t.labelMm),
                      selected: _type == t,
                      onSelected: (_) {
                        setState(() {
                          _type = t;
                          if (_titleCtrl.text.trim().isEmpty) {
                            _titleCtrl.text = '${t.labelMm} အလှူ';
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'အလှူခေါင်းစဉ် (ဥပမာ - ၂၀၂၆ ဘုံကထိန်)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ရည်မှန်းငွေ (ကျပ် - မထည့်လည်းရ)',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('အလှူရက်စွဲ'),
              subtitle: Text(formatDateShort(_eventDate)),
              trailing: const Icon(Icons.calendar_today_rounded, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _eventDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null && mounted) {
                  setState(() => _eventDate = picked);
                }
              },
            ),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'မှတ်ချက် (Optional)'),
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
            final title = _titleCtrl.text.trim().isEmpty
                ? '${_type.labelMm} အလှူ'
                : _titleCtrl.text.trim();
            final target =
                int.tryParse(normalizeAsciiDigits(_targetCtrl.text)) ?? 0;
            await widget.viewModel.createDonationCampaign(
              title: title,
              type: _type,
              targetAmountMmk: target,
              eventDate: _eventDate,
              note: _noteCtrl.text,
            );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('အလှူဖွင့်မည်'),
        ),
      ],
    );
  }
}

class _AddDonorDialog extends StatefulWidget {
  const _AddDonorDialog({
    required this.campaign,
    required this.viewModel,
  });

  final DonationCampaign campaign;
  final FinanceCalcViewModel viewModel;

  @override
  State<_AddDonorDialog> createState() => _AddDonorDialogState();
}

class _AddDonorDialogState extends State<_AddDonorDialog> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _donatedDate = DateTime.now();
  String _paymentMethod = 'ငွေသား';
  bool _isPaid = true;

  static const List<String> _methods = [
    'ငွေသား',
    'KBZPay',
    'WavePay',
    'ဘဏ်လွှဲ',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.campaign.title} • အလှူရှင်ထည့်ရန်'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'အလှူရှင် အမည် (ဥပမာ - ဦးအောင်မင်း)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'လှူဒါန်းငွေ (ကျပ်)',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _methods
                  .map(
                    (m) => ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(m),
                      selected: _paymentMethod == m,
                      onSelected: (_) => setState(() => _paymentMethod = m),
                    ),
                  )
                  .toList(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_isPaid ? 'ငွေပေးသွင်းပြီး ✓' : 'ကတိပြုထားဆဲ'),
              value: _isPaid,
              onChanged: (v) => setState(() => _isPaid = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('လှူဒါန်းသည့်ရက်စွဲ'),
              subtitle: Text(formatDateShort(_donatedDate)),
              trailing: const Icon(Icons.calendar_today_rounded, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _donatedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null && mounted) {
                  setState(() => _donatedDate = picked);
                }
              },
            ),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'မှတ်ချက် (Optional)'),
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
            final name = _nameCtrl.text.trim();
            final amount =
                int.tryParse(normalizeAsciiDigits(_amountCtrl.text)) ?? 0;
            if (name.isEmpty || amount <= 0) return;
            await widget.viewModel.addDonorContribution(
              campaign: widget.campaign,
              donorName: name,
              amountMmk: amount,
              donatedDate: _donatedDate,
              paymentMethodMm: _paymentMethod,
              isPaid: _isPaid,
              note: _noteCtrl.text,
            );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('မှတ်တမ်းသိမ်းမည်'),
        ),
      ],
    );
  }
}

class _CreateSuMaeGroupDialog extends StatefulWidget {
  const _CreateSuMaeGroupDialog({required this.viewModel});

  final FinanceCalcViewModel viewModel;

  @override
  State<_CreateSuMaeGroupDialog> createState() =>
      _CreateSuMaeGroupDialogState();
}

class _CreateSuMaeGroupDialogState extends State<_CreateSuMaeGroupDialog> {
  final _nameCtrl = TextEditingController(text: 'မိသားစု/ရုံး စုမဲ');
  final _contributionCtrl = TextEditingController(text: '100000');
  final _roundsCtrl = TextEditingController(text: '10');
  final _organizerCtrl = TextEditingController();
  final _feeCtrl = TextEditingController(text: '0');
  final _membersCtrl = TextEditingController();

  SuMaeStyle _style = SuMaeStyle.luckyDraw;
  SuMaeCycle _cycle = SuMaeCycle.monthly;
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contributionCtrl.dispose();
    _roundsCtrl.dispose();
    _organizerCtrl.dispose();
    _feeCtrl.dispose();
    _membersCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('စုမဲ (ငွေစုစု) အဖွဲ့အသစ် ဖွင့်ရန်'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'စုမဲအဖွဲ့အမည် (ဥပမာ - ရုံးစုမဲ ၁၀ သိန်း)',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'စုမဲအမျိုးအစား',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: SuMaeStyle.values
                  .map(
                    (s) => ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(s.labelMm),
                      selected: _style == s,
                      onSelected: (_) => setState(() => _style = s),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            Text(
              _style.descriptionMm,
              style: const TextStyle(fontSize: 11, color: AppTheme.gray300),
            ),
            const SizedBox(height: 10),
            const Text(
              'ငွေကောက်ခံမည့် ကာလ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: SuMaeCycle.values
                  .map(
                    (c) => ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(c.labelMm),
                      selected: _cycle == c,
                      onSelected: (_) => setState(() => _cycle = c),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _contributionCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '၁ မဲ ထည့်ငွေ (ကျပ်)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _roundsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'စုစုပေါင်း အလှည့်/မဲ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _organizerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ဒိုင်အမည် (Optional)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _feeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ဒိုင်ခ (ကျပ်)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _membersCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ကနဦး အဖွဲ့ဝင်များ (ကော်မာ သို့မဟုတ် လိုင်းခွဲ)',
                hintText: 'ဥပမာ - မသီတာ, ကိုကျော်, ဒေါ်အေး (နောက်မှလည်း ထပ်ဖြည့်နိုင်)',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('စတင်မည့်ရက်စွဲ'),
              subtitle: Text(formatDateShort(_startDate)),
              trailing: const Icon(Icons.calendar_today_rounded, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null && mounted) {
                  setState(() => _startDate = picked);
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
            final name = _nameCtrl.text.trim();
            final contrib =
                int.tryParse(normalizeAsciiDigits(_contributionCtrl.text)) ??
                    100000;
            final rounds =
                int.tryParse(normalizeAsciiDigits(_roundsCtrl.text)) ?? 10;
            final fee = int.tryParse(normalizeAsciiDigits(_feeCtrl.text)) ?? 0;
            if (name.isEmpty || contrib <= 0) return;

            final rawMembers = _membersCtrl.text
                .split(RegExp(r'[,၊\n]+'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();

            await widget.viewModel.createSuMaeGroup(
              name: name,
              style: _style,
              cycle: _cycle,
              contributionPerShareMmk: contrib,
              plannedRounds: rounds,
              organizerName: _organizerCtrl.text,
              organizerFeeMmk: fee,
              startDate: _startDate,
              initialMemberNames: rawMembers,
            );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('စုမဲဖွင့်မည်'),
        ),
      ],
    );
  }
}

class _AddSuMaeMemberDialog extends StatefulWidget {
  const _AddSuMaeMemberDialog({
    required this.group,
    required this.viewModel,
  });

  final SuMaeGroup group;
  final FinanceCalcViewModel viewModel;

  @override
  State<_AddSuMaeMemberDialog> createState() => _AddSuMaeMemberDialogState();
}

class _AddSuMaeMemberDialogState extends State<_AddSuMaeMemberDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  double _shares = 1.0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.group.name} • အဖွဲ့ဝင်ထည့်ရန်'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'အဖွဲ့ဝင် အမည်'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'ဖုန်းနံပါတ် (Optional)',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'မဲအရေအတွက် ရွေးပါ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: const [
              (0.5, 'မဲဝက် (0.5)'),
              (1.0, '၁ မဲ'),
              (2.0, '၂ မဲ'),
            ]
                .map(
                  (opt) => ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(opt.$2),
                    selected: _shares == opt.$1,
                    onSelected: (_) => setState(() => _shares = opt.$1),
                  ),
                )
                .toList(),
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
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            await widget.viewModel.addSuMaeMember(
              group: widget.group,
              name: name,
              phone: _phoneCtrl.text,
              sharesCount: _shares,
            );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('ထည့်မည်'),
        ),
      ],
    );
  }
}

class _SettleSuMaeWinnerDialog extends StatefulWidget {
  const _SettleSuMaeWinnerDialog({
    required this.group,
    required this.round,
    required this.viewModel,
    this.initialWinner,
    this.wasRandomlyDrawn = false,
  });

  final SuMaeGroup group;
  final SuMaeRound round;
  final FinanceCalcViewModel viewModel;
  final SuMaeMember? initialWinner;
  final bool wasRandomlyDrawn;

  @override
  State<_SettleSuMaeWinnerDialog> createState() =>
      _SettleSuMaeWinnerDialogState();
}

class _SettleSuMaeWinnerDialogState extends State<_SettleSuMaeWinnerDialog> {
  late SuMaeMember _selectedWinner;
  final _bidCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _selectedWinner =
        widget.initialWinner ?? widget.group.waitingMembers.first;
  }

  @override
  void dispose() {
    _bidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waiting = widget.group.waitingMembers;
    final bid = int.tryParse(normalizeAsciiDigits(_bidCtrl.text)) ?? 0;
    final netPayout = widget.group.computeNetPayout(auctionBidMmk: bid);
    final dividend = widget.group.computeAuctionDividendPerShare(bid);

    return AlertDialog(
      title: Text(
        widget.wasRandomlyDrawn
            ? '🎲 အလှည့် ${widget.round.roundNumber} မဲနှိုက်ရလဒ်'
            : 'အလှည့် ${widget.round.roundNumber} မဲပေါက်သူ သတ်မှတ်ရန်',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.wasRandomlyDrawn)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF231E0D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFACC15)),
                ),
                child: Text(
                  '🏆 မဲပေါက်သူ: ${_selectedWinner.name} (${_selectedWinner.shareLabelMm})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFACC15),
                  ),
                ),
              ),
            const Text(
              'မဲမပေါက်သေးသူများထဲမှ ရွေးချယ်ပါ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: waiting
                  .map(
                    (m) => ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(m.name),
                      selected: _selectedWinner.id == m.id,
                      onSelected: (_) => setState(() => _selectedWinner = m),
                    ),
                  )
                  .toList(),
            ),
            if (widget.group.style == SuMaeStyle.auctionBid) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _bidCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'လေလံကြေး / အတိုး (ကျပ်)',
                ),
              ),
              if (dividend > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'မပေါက်သေးသူ ၁ မဲလျှင် ခွဲဝေ/လျှော့ငွေ: ≈ ${formatMmk(dividend)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.neonLime500,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF171E10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.neonLime600),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'မဲငွေစုစုပေါင်း: ${formatMmk(widget.group.potSizeMmk)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (widget.group.organizerFeeMmk > 0)
                    Text(
                      'ဒိုင်ခ: -${formatMmk(widget.group.organizerFeeMmk)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (bid > 0)
                    Text(
                      'လေလံကြေး: -${formatMmk(bid)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    'ထုတ်ပေးရမည့်ငွေ: ${formatMmk(netPayout)}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.neonLime500,
                    ),
                  ),
                ],
              ),
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
            await widget.viewModel.settleSuMaeRoundWinner(
              group: widget.group,
              roundNumber: widget.round.roundNumber,
              winner: _selectedWinner,
              auctionBidMmk: bid,
            );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('အတည်ပြုသိမ်းမည်'),
        ),
      ],
    );
  }
}
