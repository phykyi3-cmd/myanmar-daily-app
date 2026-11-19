import 'package:flutter/foundation.dart';

import 'package:myanmar_daily_app/data/repositories/finance_repository.dart';
import 'package:myanmar_daily_app/data/services/market_price_service.dart';
import 'package:myanmar_daily_app/domain/models/commodity_price.dart';
import 'package:myanmar_daily_app/domain/models/ledger_entry.dart';
import 'package:myanmar_daily_app/domain/models/loan_rental_item.dart';
import 'package:myanmar_daily_app/domain/use_cases/myanmar_calculators.dart';

/// Sub-tabs inside the Finance & Calculators screen.
enum FinanceSection { ledger, loansRentals, calculators }

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

  List<LedgerEntry> _ledgerEntries = const [];
  List<LedgerEntry> get ledgerEntries => _ledgerEntries;

  List<LoanRentalItem> _loansRentals = const [];
  List<LoanRentalItem> get loansRentals => _loansRentals;

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
      _marketSnapshot = await _marketPriceService.syncLiveMarketPrices();
      _recomputeDefaultsFromSnapshot();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  void _recomputeDefaultsFromSnapshot() {
    _goldResult = MyanmarCalculators.calculateGoldPrice(
      kyat: 0,
      pae: 4,
      yway: 0,
      pricePerKyat: activeGoldPricePerKyatMmk.toDouble(),
      wastagePae: 1,
      makingFeeMmk: 35000,
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
