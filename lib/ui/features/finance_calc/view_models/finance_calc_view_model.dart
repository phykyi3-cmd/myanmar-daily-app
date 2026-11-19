import 'package:flutter/foundation.dart';

import 'package:myanmar_daily_app/data/repositories/finance_repository.dart';
import 'package:myanmar_daily_app/data/services/market_price_service.dart';
import 'package:myanmar_daily_app/domain/models/commodity_price.dart';
import 'package:myanmar_daily_app/domain/models/donation_su_mae_models.dart';
import 'package:myanmar_daily_app/domain/models/ledger_entry.dart';
import 'package:myanmar_daily_app/domain/models/loan_rental_item.dart';
import 'package:myanmar_daily_app/domain/use_cases/myanmar_calculators.dart';

/// Sub-tabs inside the Finance & Calculators screen.
enum FinanceSection { ledger, loansRentals, calculators }

/// Dedicated sub-views inside the 'အလှူ/စုမဲ' tab so Donations and Myanmar Su Mae stay separate.
enum CommunitySubTab { donations, suMae, generalLedger }

/// ViewModel managing community ledgers, loans/rentals, and Online-Synced Myanmar calculators.
class FinanceCalcViewModel extends ChangeNotifier {
  FinanceCalcViewModel({
    required FinanceRepository financeRepository,
    MarketPriceService? marketPriceService,
  })  : _financeRepository = financeRepository,
        _marketPriceService = marketPriceService ?? MarketPriceService();

  final FinanceRepository _financeRepository;
  final MarketPriceService _marketPriceService;

  FinanceSection _activeSection = FinanceSection.ledger;
  FinanceSection get activeSection => _activeSection;

  CommunitySubTab _activeCommunityTab = CommunitySubTab.donations;
  CommunitySubTab get activeCommunityTab => _activeCommunityTab;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSyncingOnline = false;
  bool get isSyncingOnline => _isSyncingOnline;

  MarketPriceSnapshot _marketSnapshot = MarketPriceSnapshot(
    usdMarketMmk: 4650,
    thbMarketMmk: 137,
    commodities: MarketPriceSnapshot.defaultCommodities(),
    lastSyncedAt: DateTime.now(),
    isOnlineLive: false,
    sourceNote: 'ကနဦး စံနှုန်းပေါက်ဈေး',
  );
  MarketPriceSnapshot get marketSnapshot => _marketSnapshot;

  bool _use15PaeGold = false;
  bool get use15PaeGold => _use15PaeGold;

  String _selectedCurrencyCode = 'USD';
  String get selectedCurrencyCode => _selectedCurrencyCode;

  double _lastFxAmount = 100;
  bool _lastFxToMmk = true;

  int _lastGoldKyat = 0;
  int _lastGoldPae = 4;
  double _lastGoldYway = 0;
  double _lastGoldWastagePae = 1;
  double _lastGoldMakingFeeMmk = 35000;

  List<LedgerEntry> _ledgerEntries = const [];
  List<LedgerEntry> get ledgerEntries => _ledgerEntries;

  List<LoanRentalItem> _loansRentals = const [];
  List<LoanRentalItem> get loansRentals => _loansRentals;

  List<DonationCampaign> _donationCampaigns = const [];
  List<DonationCampaign> get donationCampaigns => _donationCampaigns;

  List<SuMaeGroup> _suMaeGroups = const [];
  List<SuMaeGroup> get suMaeGroups => _suMaeGroups;

  int get totalDonationsCollectedMmk => _donationCampaigns.fold<int>(
        0,
        (sum, c) => sum + c.totalCollectedMmk,
      );

  int get totalDonorsCount =>
      _donationCampaigns.fold<int>(0, (sum, c) => sum + c.donorCount);

  int get totalActiveSuMaePotMmk =>
      _suMaeGroups.fold<int>(0, (sum, g) => sum + g.potSizeMmk);

  GoldCalculationResult? _goldResult;
  GoldCalculationResult? get goldResult => _goldResult;

  InstallmentResult? _installmentResult;
  InstallmentResult? get installmentResult => _installmentResult;

  double _currencyConverted = 0;
  double get currencyConverted => _currencyConverted;

  int get activeGoldPricePerKyatMmk => _use15PaeGold
      ? _marketSnapshot.myanmarGold15PaeMmk
      : _marketSnapshot.myanmarGold16PaeMmk;

  double get activeCurrencyRateMmk =>
      _marketSnapshot.foreignRatesMmk[_selectedCurrencyCode] ??
      _marketSnapshot.usdMarketMmk.toDouble();

  int get netLedgerMmk {
    var total = 0;
    for (final entry in _ledgerEntries) {
      total += entry.isIncome ? entry.amountMmk : -entry.amountMmk;
    }
    return total;
  }

  int get pendingToReceiveMmk {
    var total = 0;
    for (final item in _loansRentals) {
      if (!item.isSettled && item.type != LoanRentalType.borrowed) {
        total += item.amountMmk;
      }
    }
    return total;
  }

  void setActiveSection(FinanceSection section) {
    if (_activeSection == section) return;
    _activeSection = section;
    notifyListeners();
  }

  void setActiveCommunityTab(CommunitySubTab tab) {
    if (_activeCommunityTab == tab) return;
    _activeCommunityTab = tab;
    notifyListeners();
  }

  void setGoldQuality({required bool use15Pae}) {
    _use15PaeGold = use15Pae;
    notifyListeners();
  }

  void setSelectedCurrencyCode(String code) {
    _selectedCurrencyCode = code;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _ledgerEntries = await _financeRepository.getLedgerEntries();
      _loansRentals = await _financeRepository.getLoansRentals();
      _donationCampaigns = await _financeRepository.getDonationCampaigns();
      _suMaeGroups = await _financeRepository.getSuMaeGroups();
      _marketSnapshot = await _marketPriceService.syncLiveMarketPrices();
      _recomputeDefaultsFromSnapshot();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadCommunityData() async {
    _donationCampaigns = await _financeRepository.getDonationCampaigns();
    _suMaeGroups = await _financeRepository.getSuMaeGroups();
    notifyListeners();
  }

  // ---- Group Donation Campaigns (အလှူစာရင်း) ----

  Future<void> createDonationCampaign({
    required String title,
    required DonationType type,
    int targetAmountMmk = 0,
    required DateTime eventDate,
    String note = '',
  }) async {
    final now = DateTime.now();
    await _financeRepository.saveDonationCampaign(
      DonationCampaign(
        title: title.trim(),
        type: type,
        targetAmountMmk: targetAmountMmk,
        eventDate: eventDate,
        note: note.trim(),
        contributions: const [],
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _reloadCommunityData();
  }

  Future<void> addDonorContribution({
    required DonationCampaign campaign,
    required String donorName,
    required int amountMmk,
    required DateTime donatedDate,
    String paymentMethodMm = 'ငွေသား',
    bool isPaid = true,
    String note = '',
  }) async {
    final item = DonorContribution(
      id: '${DateTime.now().microsecondsSinceEpoch}_${campaign.contributions.length}',
      donorName: donorName.trim(),
      amountMmk: amountMmk,
      donatedDate: donatedDate,
      paymentMethodMm: paymentMethodMm,
      isPaid: isPaid,
      note: note.trim(),
    );
    final updated = campaign.copyWith(
      contributions: [...campaign.contributions, item],
      updatedAt: DateTime.now(),
    );
    await _financeRepository.saveDonationCampaign(updated);
    await _reloadCommunityData();
  }

  Future<void> toggleDonorPaidStatus(
    DonationCampaign campaign,
    String contributionId,
  ) async {
    final updatedList = campaign.contributions
        .map(
          (c) => c.id == contributionId ? c.copyWith(isPaid: !c.isPaid) : c,
        )
        .toList();
    await _financeRepository.saveDonationCampaign(
      campaign.copyWith(contributions: updatedList, updatedAt: DateTime.now()),
    );
    await _reloadCommunityData();
  }

  Future<void> deleteDonorContribution(
    DonationCampaign campaign,
    String contributionId,
  ) async {
    final updatedList =
        campaign.contributions.where((c) => c.id != contributionId).toList();
    await _financeRepository.saveDonationCampaign(
      campaign.copyWith(contributions: updatedList, updatedAt: DateTime.now()),
    );
    await _reloadCommunityData();
  }

  Future<void> deleteDonationCampaign(int id) async {
    await _financeRepository.deleteDonationCampaign(id);
    await _reloadCommunityData();
  }

  // ---- Traditional Myanmar Su Mae (စုမဲ / ငွေစုစု ROSCA) ----

  Future<void> createSuMaeGroup({
    required String name,
    required SuMaeStyle style,
    required SuMaeCycle cycle,
    required int contributionPerShareMmk,
    required int plannedRounds,
    String organizerName = '',
    int organizerFeeMmk = 0,
    required DateTime startDate,
    List<String> initialMemberNames = const [],
  }) async {
    final now = DateTime.now();
    final members = <SuMaeMember>[];
    for (var i = 0; i < initialMemberNames.length; i++) {
      final clean = initialMemberNames[i].trim();
      if (clean.isEmpty) continue;
      members.add(
        SuMaeMember(
          id: 'm_${now.microsecondsSinceEpoch}_$i',
          name: clean,
          sharesCount: 1.0,
        ),
      );
    }

    final rounds = [
      SuMaeRound(
        roundNumber: 1,
        dueDate: cycle.dateForRound(startDate, 1),
      ),
    ];

    await _financeRepository.saveSuMaeGroup(
      SuMaeGroup(
        name: name.trim(),
        style: style,
        cycle: cycle,
        contributionPerShareMmk: contributionPerShareMmk,
        plannedRounds: plannedRounds.clamp(2, 120),
        organizerName: organizerName.trim(),
        organizerFeeMmk: organizerFeeMmk,
        startDate: startDate,
        members: members,
        rounds: rounds,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _reloadCommunityData();
  }

  Future<void> addSuMaeMember({
    required SuMaeGroup group,
    required String name,
    String phone = '',
    double sharesCount = 1.0,
    String note = '',
  }) async {
    final newMember = SuMaeMember(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}_${group.members.length}',
      name: name.trim(),
      phone: phone.trim(),
      sharesCount: sharesCount,
      note: note.trim(),
    );
    await _financeRepository.saveSuMaeGroup(
      group.copyWith(
        members: [...group.members, newMember],
        updatedAt: DateTime.now(),
      ),
    );
    await _reloadCommunityData();
  }

  Future<void> removeSuMaeMember(SuMaeGroup group, String memberId) async {
    final updatedMembers =
        group.members.where((m) => m.id != memberId).toList();
    final updatedRounds = group.rounds.map((r) {
      final nextPayments = Map<String, SuMaePayment>.from(r.payments)
        ..remove(memberId);
      final cleared = r.winnerMemberId == memberId;
      return r.copyWith(
        payments: nextPayments,
        clearWinner: cleared,
      );
    }).toList();
    await _financeRepository.saveSuMaeGroup(
      group.copyWith(
        members: updatedMembers,
        rounds: updatedRounds,
        updatedAt: DateTime.now(),
      ),
    );
    await _reloadCommunityData();
  }

  Future<void> toggleSuMaeRoundPayment({
    required SuMaeGroup group,
    required int roundNumber,
    required SuMaeMember member,
    String paymentMethodMm = 'ငွေသား',
  }) async {
    final updatedRounds = group.rounds.map((r) {
      if (r.roundNumber != roundNumber) return r;
      final nextPayments = Map<String, SuMaePayment>.from(r.payments);
      if (nextPayments.containsKey(member.id)) {
        nextPayments.remove(member.id);
      } else {
        nextPayments[member.id] = SuMaePayment(
          memberId: member.id,
          amountMmk: group.expectedContributionForMember(member),
          paidAt: DateTime.now(),
          paymentMethodMm: paymentMethodMm,
        );
      }
      return r.copyWith(payments: nextPayments);
    }).toList();

    await _financeRepository.saveSuMaeGroup(
      group.copyWith(rounds: updatedRounds, updatedAt: DateTime.now()),
    );
    await _reloadCommunityData();
  }

  Future<void> addNextSuMaeRound(SuMaeGroup group) async {
    final nextNum = group.rounds.isEmpty
        ? 1
        : group.rounds
                .map((r) => r.roundNumber)
                .reduce((a, b) => a > b ? a : b) +
            1;
    final nextRound = SuMaeRound(
      roundNumber: nextNum,
      dueDate: group.cycle.dateForRound(group.startDate, nextNum),
    );
    await _financeRepository.saveSuMaeGroup(
      group.copyWith(
        rounds: [...group.rounds, nextRound],
        updatedAt: DateTime.now(),
      ),
    );
    await _reloadCommunityData();
  }

  Future<void> settleSuMaeRoundWinner({
    required SuMaeGroup group,
    required int roundNumber,
    required SuMaeMember winner,
    int auctionBidMmk = 0,
    String note = '',
  }) async {
    final now = DateTime.now();
    final netPayout = group.computeNetPayout(auctionBidMmk: auctionBidMmk);

    final updatedMembers = group.members.map((m) {
      if (m.id == winner.id) {
        return m.copyWith(
          wonRoundNumber: roundNumber,
          wonDate: now,
          wonPayoutMmk: netPayout,
        );
      }
      if (m.wonRoundNumber == roundNumber) {
        return m.copyWith(clearWon: true);
      }
      return m;
    }).toList();

    final updatedRounds = group.rounds.map((r) {
      if (r.roundNumber != roundNumber) return r;
      return r.copyWith(
        winnerMemberId: winner.id,
        winnerName: winner.name,
        auctionBidMmk: auctionBidMmk,
        organizerFeeMmk: group.organizerFeeMmk,
        netPayoutMmk: netPayout,
        settledAt: now,
        note: note.trim(),
      );
    }).toList();

    // Auto-prepare the next round if not yet at plannedRounds and next round doesn't exist.
    final hasNext = updatedRounds.any((r) => r.roundNumber == roundNumber + 1);
    if (!hasNext && roundNumber < group.plannedRounds) {
      updatedRounds.add(
        SuMaeRound(
          roundNumber: roundNumber + 1,
          dueDate: group.cycle.dateForRound(group.startDate, roundNumber + 1),
        ),
      );
    }

    await _financeRepository.saveSuMaeGroup(
      group.copyWith(
        members: updatedMembers,
        rounds: updatedRounds,
        updatedAt: now,
      ),
    );
    await _reloadCommunityData();
  }

  Future<void> undoSuMaeRoundWinner({
    required SuMaeGroup group,
    required int roundNumber,
  }) async {
    final updatedMembers = group.members.map((m) {
      if (m.wonRoundNumber == roundNumber) {
        return m.copyWith(clearWon: true);
      }
      return m;
    }).toList();
    final updatedRounds = group.rounds.map((r) {
      if (r.roundNumber != roundNumber) return r;
      return r.copyWith(clearWinner: true);
    }).toList();

    await _financeRepository.saveSuMaeGroup(
      group.copyWith(
        members: updatedMembers,
        rounds: updatedRounds,
        updatedAt: DateTime.now(),
      ),
    );
    await _reloadCommunityData();
  }

  Future<void> deleteSuMaeGroup(int id) async {
    await _financeRepository.deleteSuMaeGroup(id);
    await _reloadCommunityData();
  }

  Future<void> syncOnlineRates() async {
    _isSyncingOnline = true;
    notifyListeners();
    try {
      _marketSnapshot = await _marketPriceService.syncLiveMarketPrices();
      _recomputeDefaultsFromSnapshot();
    } finally {
      _isSyncingOnline = false;
      notifyListeners();
    }
  }

  Future<void> setMarketRateTier(MarketRateTier tier) async {
    _isSyncingOnline = true;
    notifyListeners();
    try {
      _marketSnapshot = await _marketPriceService.setMarketRateTier(tier);
      _recomputeDefaultsFromSnapshot();
    } finally {
      _isSyncingOnline = false;
      notifyListeners();
    }
  }

  Future<void> resetToLiveMarketRate() async {
    _isSyncingOnline = true;
    notifyListeners();
    try {
      _marketSnapshot = await _marketPriceService.resetToLiveMarketRate();
      _recomputeDefaultsFromSnapshot();
    } finally {
      _isSyncingOnline = false;
      notifyListeners();
    }
  }

  Future<void> updateUsdMarketRate(int newUsdMmk) async {
    _isSyncingOnline = true;
    notifyListeners();
    try {
      _marketSnapshot = await _marketPriceService.updateUsdMarketRate(newUsdMmk);
      _recomputeDefaultsFromSnapshot();
    } finally {
      _isSyncingOnline = false;
      notifyListeners();
    }
  }

  Future<void> updateMyanmarGold16PaePrice(int newGold16PaeMmk) async {
    _isSyncingOnline = true;
    notifyListeners();
    try {
      _marketSnapshot =
          await _marketPriceService.updateMyanmarGoldPrice(newGold16PaeMmk);
      _recomputeDefaultsFromSnapshot();
    } finally {
      _isSyncingOnline = false;
      notifyListeners();
    }
  }

  Future<void> setGoldRateTier(GoldRateTier tier) async {
    _isSyncingOnline = true;
    notifyListeners();
    try {
      _marketSnapshot = await _marketPriceService.setGoldRateTier(tier);
      _recomputeDefaultsFromSnapshot();
    } finally {
      _isSyncingOnline = false;
      notifyListeners();
    }
  }

  Future<void> resetToLiveGoldPrice() async {
    _isSyncingOnline = true;
    notifyListeners();
    try {
      _marketSnapshot = await _marketPriceService.resetToLiveGoldPrice();
      _recomputeDefaultsFromSnapshot();
    } finally {
      _isSyncingOnline = false;
      notifyListeners();
    }
  }

  void _recomputeDefaultsFromSnapshot() {
    _goldResult = MyanmarCalculators.calculateGoldPrice(
      kyat: _lastGoldKyat,
      pae: _lastGoldPae,
      yway: _lastGoldYway,
      pricePerKyat: activeGoldPricePerKyatMmk.toDouble(),
      wastagePae: _lastGoldWastagePae,
      makingFeeMmk: _lastGoldMakingFeeMmk,
    );
    final phonePrice =
        ((280 * _marketSnapshot.usdMarketMmk) / 10000).round() * 10000;
    _installmentResult = MyanmarCalculators.calculateInstallment(
      principal: phonePrice.toDouble(),
      downPayment: (phonePrice * 0.25).roundToDouble(),
      monthlyFlatInterestPercent: 2.0,
      months: 6,
    );
    _currencyConverted = MyanmarCalculators.convertCurrency(
      amount: _lastFxAmount,
      rateMmkPerUnit: activeCurrencyRateMmk,
      toMmk: _lastFxToMmk,
    );
  }

  Future<void> addLedgerEntry(LedgerEntry entry) async {
    await _financeRepository.addLedgerEntry(entry);
    await loadAll();
  }

  Future<void> deleteLedgerEntry(int id) async {
    await _financeRepository.deleteLedgerEntry(id);
    await loadAll();
  }

  Future<void> addLoanRental(LoanRentalItem item) async {
    await _financeRepository.addLoanRental(item);
    await loadAll();
  }

  Future<void> toggleLoanSettled(LoanRentalItem item) async {
    await _financeRepository.toggleLoanSettled(item);
    await loadAll();
  }

  Future<void> deleteLoanRental(int id) async {
    await _financeRepository.deleteLoanRental(id);
    await loadAll();
  }

  void computeGold({
    required int kyat,
    required int pae,
    required double yway,
    required double pricePerKyat,
    double wastagePae = 0,
    double wastageYway = 0,
    double makingFeeMmk = 0,
  }) {
    _lastGoldKyat = kyat;
    _lastGoldPae = pae;
    _lastGoldYway = yway;
    _lastGoldWastagePae = wastagePae;
    _lastGoldMakingFeeMmk = makingFeeMmk;
    _goldResult = MyanmarCalculators.calculateGoldPrice(
      kyat: kyat,
      pae: pae,
      yway: yway,
      pricePerKyat: pricePerKyat,
      wastagePae: wastagePae,
      wastageYway: wastageYway,
      makingFeeMmk: makingFeeMmk,
    );
    notifyListeners();
  }

  void computeInstallment({
    required double principal,
    required double downPayment,
    required double monthlyFlatInterestPercent,
    required int months,
  }) {
    _installmentResult = MyanmarCalculators.calculateInstallment(
      principal: principal,
      downPayment: downPayment,
      monthlyFlatInterestPercent: monthlyFlatInterestPercent,
      months: months,
    );
    notifyListeners();
  }

  void computeCurrency({
    required double amount,
    required double rateMmkPerUnit,
    required bool toMmk,
  }) {
    _lastFxAmount = amount;
    _lastFxToMmk = toMmk;
    _currencyConverted = MyanmarCalculators.convertCurrency(
      amount: amount,
      rateMmkPerUnit: rateMmkPerUnit,
      toMmk: toMmk,
    );
    notifyListeners();
  }
}
