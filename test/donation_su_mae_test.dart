import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_daily_app/data/repositories/finance_repository.dart';
import 'package:myanmar_daily_app/data/services/backup_service.dart';
import 'package:myanmar_daily_app/data/services/local_db_service.dart';
import 'package:myanmar_daily_app/data/services/market_price_service.dart';
import 'package:myanmar_daily_app/domain/models/commodity_price.dart';
import 'package:myanmar_daily_app/domain/models/donation_su_mae_models.dart';
import 'package:myanmar_daily_app/domain/models/emergency_qr_card.dart';
import 'package:myanmar_daily_app/ui/features/finance_calc/view_models/finance_calc_view_model.dart';
import 'package:myanmar_daily_app/ui/features/finance_calc/views/finance_calc_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryCommunityDb extends LocalDbService {
  final Map<String, List<Map<String, Object?>>> _tables = {};
  int _nextId = 1;

  List<Map<String, Object?>> _rows(String table) =>
      _tables.putIfAbsent(table, () => <Map<String, Object?>>[]);

  @override
  Future<List<Map<String, Object?>>> queryAll(
    String table, {
    String? orderBy,
  }) async {
    return _rows(table).map((r) => Map<String, Object?>.from(r)).toList();
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    final row = Map<String, Object?>.from(values);
    final id = _nextId++;
    row['id'] = id;
    _rows(table).add(row);
    return id;
  }

  @override
  Future<int> updateById(
    String table,
    int id,
    Map<String, Object?> values,
  ) async {
    var updated = 0;
    for (final row in _rows(table)) {
      if ((row['id'] as num?)?.toInt() == id) {
        row.addAll(values);
        updated++;
      }
    }
    return updated;
  }

  @override
  Future<int> deleteById(String table, int id) async {
    final rows = _rows(table);
    final before = rows.length;
    rows.removeWhere((row) => (row['id'] as num?)?.toInt() == id);
    return before - rows.length;
  }
}

class _OfflineMarketStub extends MarketPriceService {
  @override
  Future<MarketPriceSnapshot> syncLiveMarketPrices({
    int? customUsdMarketMmk,
  }) async {
    return MarketPriceSnapshot(
      usdMarketMmk: 4650,
      thbMarketMmk: 137,
      commodities: MarketPriceSnapshot.defaultCommodities(),
      lastSyncedAt: DateTime(2026, 11, 19, 20, 0),
      isOnlineLive: false,
      sourceNote: 'Test Snapshot',
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('DonationCampaign tracks incremental donors, paid vs pledged, totals, and Backup v2 round-trip', () async {
    final db = _InMemoryCommunityDb();
    final vm = FinanceCalcViewModel(
      financeRepository: FinanceRepository(dbService: db),
      marketPriceService: _OfflineMarketStub(),
    );

    await vm.createDonationCampaign(
      title: '၂၀၂၆ ဘုံကထိန် အလှူ',
      type: DonationType.kathina,
      targetAmountMmk: 500000,
      eventDate: DateTime(2026, 11, 25),
    );
    expect(vm.donationCampaigns.length, 1);

    // Incrementally add donors on different dates
    await vm.addDonorContribution(
      campaign: vm.donationCampaigns.first,
      donorName: 'ဦးအောင်မင်း',
      amountMmk: 50000,
      donatedDate: DateTime(2026, 11, 19),
      paymentMethodMm: 'KBZPay',
      isPaid: true,
    );
    await vm.addDonorContribution(
      campaign: vm.donationCampaigns.first,
      donorName: 'ဒေါ်သီတာ',
      amountMmk: 30000,
      donatedDate: DateTime(2026, 11, 20),
      paymentMethodMm: 'ငွေသား',
      isPaid: false,
    );

    var c = vm.donationCampaigns.first;
    expect(c.donorCount, 2);
    expect(c.paidDonorCount, 1);
    expect(c.totalCollectedMmk, 50000);
    expect(c.totalPledgedMmk, 30000);
    expect(c.grandTotalMmk, 80000);
    expect(c.formatShareSummaryMm(), contains('ဦးအောင်မင်း'));
    expect(c.formatShareSummaryMm(), contains('50,000 ကျပ်'));

    // Toggle second donor to paid
    await vm.toggleDonorPaidStatus(c, c.contributions.last.id);
    c = vm.donationCampaigns.first;
    expect(c.paidDonorCount, 2);
    expect(c.totalCollectedMmk, 80000);
    expect(c.totalPledgedMmk, 0);

    // Backup round-trip
    final backupSvc = BackupService();
    final encoded = backupSvc.encodeBackup(
      BackupSnapshot(
        version: 2,
        exportedAt: DateTime(2026, 11, 19),
        ledgerEntries: const [],
        loansRentals: const [],
        shoppingItems: const [],
        reminders: const [],
        qrCard: const EmergencyQrCard(),
        donationCampaigns: [c],
      ),
    );
    final decoded = backupSvc.decodeBackup(encoded);
    expect(decoded.donationCampaigns.length, 1);
    expect(decoded.donationCampaigns.first.donorCount, 2);
    expect(decoded.donationCampaigns.first.totalCollectedMmk, 80000);
  });

  test('SuMaeGroup supports Myanmar ROSCA styles, shares, round checklists, auction payouts & auto-next round', () async {
    final db = _InMemoryCommunityDb();
    final vm = FinanceCalcViewModel(
      financeRepository: FinanceRepository(dbService: db),
      marketPriceService: _OfflineMarketStub(),
    );

    await vm.createSuMaeGroup(
      name: 'ရုံးစုမဲ ၃ သိန်း',
      style: SuMaeStyle.auctionBid,
      cycle: SuMaeCycle.monthly,
      contributionPerShareMmk: 100000,
      plannedRounds: 3,
      organizerName: 'မသီတာ',
      organizerFeeMmk: 5000,
      startDate: DateTime(2026, 11, 1),
      initialMemberNames: ['မသီတာ', 'ကိုကျော်'],
    );
    expect(vm.suMaeGroups.length, 1);

    // Add 3rd member incrementally with 1 share
    await vm.addSuMaeMember(
      group: vm.suMaeGroups.first,
      name: 'ဒေါ်အေး',
      sharesCount: 1.0,
    );
    var group = vm.suMaeGroups.first;
    expect(group.members.length, 3);
    expect(group.potSizeMmk, 300000);

    // Mark first two members paid for Round 1
    await vm.toggleSuMaeRoundPayment(
      group: group,
      roundNumber: 1,
      member: group.members[0],
    );
    await vm.toggleSuMaeRoundPayment(
      group: vm.suMaeGroups.first,
      roundNumber: 1,
      member: vm.suMaeGroups.first.members[1],
    );
    group = vm.suMaeGroups.first;
    expect(group.rounds.first.paidCount, 2);
    expect(group.rounds.first.totalCollectedMmk, 200000);

    // Settle Round 1 winner with 30,000 MMK auction bid & 5,000 MMK organizer fee -> Net = 265,000 MMK
    await vm.settleSuMaeRoundWinner(
      group: group,
      roundNumber: 1,
      winner: group.members[1],
      auctionBidMmk: 30000,
    );
    group = vm.suMaeGroups.first;
    expect(group.completedRoundsCount, 1);
    expect(group.rounds.length, 2); // Auto-created Round 2!
    expect(group.rounds.first.winnerName, 'ကိုကျော်');
    expect(group.rounds.first.netPayoutMmk, 265000);
    expect(group.waitingMembers.length, 2);
    expect(group.formatRoundSummaryMm(group.rounds.first), contains('265,000 ကျပ်'));

    // Undo winner restores member eligibility
    await vm.undoSuMaeRoundWinner(group: group, roundNumber: 1);
    group = vm.suMaeGroups.first;
    expect(group.completedRoundsCount, 0);
    expect(group.waitingMembers.length, 3);
  });

  testWidgets('FinanceCalcScreen manages Kathina donations and Myanmar Su Mae tabs interactively', (tester) async {
    final db = _InMemoryCommunityDb();
    final vm = FinanceCalcViewModel(
      financeRepository: FinanceRepository(dbService: db),
      marketPriceService: _OfflineMarketStub(),
    );
    await vm.loadAll();

    await tester.pumpWidget(
      MaterialApp(home: FinanceCalcScreen(viewModel: vm)),
    );
    await tester.pumpAndSettle();

    // Starts on 'အလှူ/စုမဲ' -> 'အလှူစာရင်း' sub-tab
    expect(find.textContaining('အလှူစာရင်း'), findsWidgets);
    expect(find.textContaining('စုမဲ (0)'), findsOneWidget);

    // Create a Kathina donation campaign via UI button
    await tester.tap(find.textContaining('အလှူခေါင်းစဉ်အသစ် ဖွင့်မည်'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'အလှူခေါင်းစဉ် (ဥပမာ - ၂၀၂၆ ဘုံကထိန်)'),
      'ဘုံကထိန် ၂၀၂၆',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('အလှူဖွင့်မည်'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ဘုံကထိန် ၂၀၂၆'), findsOneWidget);

    // Add donor incrementally via UI dialog (using Burmese numerals!)
    await tester.tap(find.text('အလှူရှင် ထပ်ဖြည့်မည်'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'အလှူရှင် အမည် (ဥပမာ - ဦးအောင်မင်း)'),
      'ကိုမင်းထက်',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'လှူဒါန်းငွေ (ကျပ်)'),
      '၅၀၀၀၀',
    );
    await tester.tap(find.text('မှတ်တမ်းသိမ်းမည်'));
    await tester.pumpAndSettle();

    expect(find.text('ကိုမင်းထက်'), findsOneWidget);
    expect(find.textContaining('စုစုပေါင်း: 50,000 ကျပ်'), findsOneWidget);

    // Switch to 'စုမဲ' sub-tab & create a Myanmar Su Mae group
    await tester.tap(find.text('စုမဲ (0)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('မြန်မာ့ စုမဲ (ငွေစုစု)'), findsWidgets);

    await tester.tap(find.textContaining('စုမဲအဖွဲ့အသစ် ဖွင့်မည်'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'ကနဦး အဖွဲ့ဝင်များ (ကော်မာ သို့မဟုတ် လိုင်းခွဲ)'),
      'မသီတာ, ကိုကျော်, ဒေါ်အေး',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('စုမဲဖွင့်မည်'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('မသီတာ'), findsOneWidget);
    expect(find.textContaining('ကိုကျော်'), findsOneWidget);
    expect(find.textContaining('ဒေါ်အေး'), findsOneWidget);
    expect(find.text('ကျပန်း မဲနှိုက်မည်'), findsOneWidget);
  });
}
