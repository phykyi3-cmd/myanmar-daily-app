import '../services/backup_service.dart';
import '../services/local_db_service.dart';
import 'daily_market_repository.dart';
import 'finance_repository.dart';
import 'reminder_repository.dart';
import 'settings_qr_repository.dart';

/// Coordinates full local JSON export and restore without any cloud server.
class BackupRepository {
  BackupRepository({
    required LocalDbService dbService,
    required BackupService backupService,
    required FinanceRepository financeRepository,
    required DailyMarketRepository dailyMarketRepository,
    required ReminderRepository reminderRepository,
    required SettingsQrRepository settingsQrRepository,
  })  : _dbService = dbService,
        _backupService = backupService,
        _financeRepository = financeRepository,
        _dailyMarketRepository = dailyMarketRepository,
        _reminderRepository = reminderRepository,
        _settingsQrRepository = settingsQrRepository;

  final LocalDbService _dbService;
  final BackupService _backupService;
  final FinanceRepository _financeRepository;
  final DailyMarketRepository _dailyMarketRepository;
  final ReminderRepository _reminderRepository;
  final SettingsQrRepository _settingsQrRepository;

  Future<String> exportBackupJson() async {
    final ledger = await _financeRepository.getLedgerEntries();
    final loans = await _financeRepository.getLoansRentals();
    final shopping = await _dailyMarketRepository.getShoppingItems();
    final purchaseRecords = await _dailyMarketRepository.getPurchaseRecords();
    final reminders = await _reminderRepository.getReminders();
    final qrCard = await _settingsQrRepository.getQrCard();

    return _backupService.encodeBackup(
      BackupSnapshot(
        version: BackupService.currentBackupVersion,
        exportedAt: DateTime.now(),
        ledgerEntries: ledger,
        loansRentals: loans,
        shoppingItems: shopping,
        purchaseRecords: purchaseRecords,
        reminders: reminders,
        qrCard: qrCard,
      ),
    );
  }

  /// Replaces local records with the parsed backup snapshot.
  Future<void> restoreBackupJson(String rawJson) async {
    final snapshot = _backupService.decodeBackup(rawJson);

    await _dbService.clearTable(LocalDbService.tableLedger);
    await _dbService.clearTable(LocalDbService.tableLoansRentals);
    await _dbService.clearTable(LocalDbService.tableShopping);
    await _dbService.clearTable(LocalDbService.tablePurchaseRecords);
    await _dbService.clearTable(LocalDbService.tableReminders);

    for (final entry in snapshot.ledgerEntries) {
      await _financeRepository.addLedgerEntry(entry);
    }
    for (final loan in snapshot.loansRentals) {
      await _financeRepository.addLoanRental(loan);
    }
    for (final item in snapshot.shoppingItems) {
      await _dailyMarketRepository.addShoppingItem(item);
    }
    for (final record in snapshot.purchaseRecords) {
      await _dailyMarketRepository.restorePurchaseRecord(record);
    }
    for (final reminder in snapshot.reminders) {
      await _reminderRepository.addReminder(reminder);
    }
    await _settingsQrRepository.saveQrCard(snapshot.qrCard);
  }
}
