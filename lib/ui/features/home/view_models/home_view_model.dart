import 'package:flutter/foundation.dart';

import 'package:myanmar_daily_app/data/repositories/backup_repository.dart';
import 'package:myanmar_daily_app/data/repositories/daily_market_repository.dart';
import 'package:myanmar_daily_app/data/repositories/finance_repository.dart';
import 'package:myanmar_daily_app/data/repositories/reminder_repository.dart';
import 'package:myanmar_daily_app/data/repositories/settings_qr_repository.dart';
import 'package:myanmar_daily_app/data/services/cloud_sync_service.dart';
import 'package:myanmar_daily_app/domain/models/app_module.dart';
import 'package:myanmar_daily_app/domain/models/cloud_account_state.dart';
import 'package:myanmar_daily_app/domain/models/emergency_qr_card.dart';
import 'package:myanmar_daily_app/domain/models/loan_rental_item.dart';
import 'package:myanmar_daily_app/domain/models/renewal_reminder.dart';

/// ViewModel powering the Home dashboard summary, module toggles, and Google Drive / Apple iCloud backups.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required SettingsQrRepository settingsQrRepository,
    required ReminderRepository reminderRepository,
    required FinanceRepository financeRepository,
    required DailyMarketRepository dailyMarketRepository,
    required BackupRepository backupRepository,
    CloudSyncService? cloudSyncService,
  })  : _settingsQrRepository = settingsQrRepository,
        _reminderRepository = reminderRepository,
        _financeRepository = financeRepository,
        _dailyMarketRepository = dailyMarketRepository,
        _backupRepository = backupRepository,
        _cloudSyncService = cloudSyncService ?? CloudSyncService();

  final SettingsQrRepository _settingsQrRepository;
  final ReminderRepository _reminderRepository;
  final FinanceRepository _financeRepository;
  final DailyMarketRepository _dailyMarketRepository;
  final BackupRepository _backupRepository;
  final CloudSyncService _cloudSyncService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSyncingCloud = false;
  bool get isSyncingCloud => _isSyncingCloud;

  CloudAccountState _cloudAccount = const CloudAccountState();
  CloudAccountState get cloudAccount => _cloudAccount;

  Set<AppModule> _enabledModules = AppModule.values.toSet();
  Set<AppModule> get enabledModules => _enabledModules;

  EmergencyQrCard _qrCard = const EmergencyQrCard();
  EmergencyQrCard get qrCard => _qrCard;

  List<RenewalReminder> _upcomingReminders = const [];
  List<RenewalReminder> get upcomingReminders => _upcomingReminders;

  List<LoanRentalItem> _openLoansRentals = const [];
  List<LoanRentalItem> get openLoansRentals => _openLoansRentals;

  int _uncheckedShoppingCount = 0;
  int get uncheckedShoppingCount => _uncheckedShoppingCount;

  int _ledgerCount = 0;
  int get ledgerCount => _ledgerCount;

  /// Loads dashboard snapshot across local repositories and auto-syncs to Cloud if linked.
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      _enabledModules = await _settingsQrRepository.getEnabledModules();
      _qrCard = await _settingsQrRepository.getQrCard();

      final reminders = await _reminderRepository.getReminders();
      _upcomingReminders = reminders
          .where((r) => !r.isCompleted && r.daysRemaining() <= 14)
          .toList();

      final ledger = await _financeRepository.getLedgerEntries();
      _ledgerCount = ledger.length;

      final loans = await _financeRepository.getLoansRentals();
      _openLoansRentals = loans.where((l) => !l.isSettled).toList();

      final shopping = await _dailyMarketRepository.getShoppingItems();
      _uncheckedShoppingCount = shopping.where((s) => !s.isChecked).length;

      _cloudAccount = await _cloudSyncService.loadAccountState();
      if (_cloudAccount.isConnected && _cloudAccount.autoSyncEnabled) {
        final json = await _backupRepository.exportBackupJson();
        _cloudAccount = await _cloudSyncService.syncToCloud(backupJson: json);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connectCloudAccount({
    required CloudProviderType provider,
    required String email,
  }) async {
    _isSyncingCloud = true;
    notifyListeners();
    try {
      final json = await _backupRepository.exportBackupJson();
      _cloudAccount = await _cloudSyncService.connectAccount(
        provider: provider,
        email: email,
        initialBackupJson: json,
      );
    } finally {
      _isSyncingCloud = false;
      notifyListeners();
    }
  }

  Future<void> syncCloudNow() async {
    if (!_cloudAccount.isConnected) return;
    _isSyncingCloud = true;
    notifyListeners();
    try {
      final json = await _backupRepository.exportBackupJson();
      _cloudAccount = await _cloudSyncService.syncToCloud(backupJson: json);
    } finally {
      _isSyncingCloud = false;
      notifyListeners();
    }
  }

  Future<bool> restoreFromCloud() async {
    if (!_cloudAccount.isConnected) return false;
    _isSyncingCloud = true;
    notifyListeners();
    try {
      final cloudJson = await _cloudSyncService.downloadFromCloud();
      if (cloudJson == null || cloudJson.isEmpty) return false;
      await _backupRepository.restoreBackupJson(cloudJson);
      await loadDashboard();
      return true;
    } finally {
      _isSyncingCloud = false;
      notifyListeners();
    }
  }

  Future<void> toggleCloudAutoSync(bool enabled) async {
    _cloudAccount = await _cloudSyncService.setAutoSync(enabled);
    notifyListeners();
  }

  Future<void> disconnectCloudAccount() async {
    _cloudAccount = await _cloudSyncService.disconnectAccount();
    notifyListeners();
  }

  Future<void> toggleModule(AppModule module, bool enabled) async {
    await _settingsQrRepository.setModuleEnabled(module, enabled);
    final updated = Set<AppModule>.from(_enabledModules);
    if (enabled) {
      updated.add(module);
    } else {
      updated.remove(module);
    }
    _enabledModules = updated;
    notifyListeners();
  }

  Future<String> exportBackupJson() => _backupRepository.exportBackupJson();

  Future<void> restoreBackupJson(String rawJson) async {
    await _backupRepository.restoreBackupJson(rawJson);
    await loadDashboard();
  }
}
