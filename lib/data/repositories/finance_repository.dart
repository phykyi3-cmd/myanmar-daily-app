import '../../domain/models/ledger_entry.dart';
import '../../domain/models/loan_rental_item.dart';
import '../services/local_db_service.dart';

/// Repository managing community ledger entries and loans/rentals in SQLite.
class FinanceRepository {
  FinanceRepository({required LocalDbService dbService})
      : _dbService = dbService;

  final LocalDbService _dbService;

  Future<List<LedgerEntry>> getLedgerEntries() async {
    final rows = await _dbService.queryAll(
      LocalDbService.tableLedger,
      orderBy: 'created_at DESC',
    );
    return rows.map(LedgerEntry.fromMap).toList();
  }

  Future<void> addLedgerEntry(LedgerEntry entry) async {
    await _dbService.insert(
      LocalDbService.tableLedger,
      entry.copyWith(id: null).toMap(),
    );
  }

  Future<void> deleteLedgerEntry(int id) async {
    await _dbService.deleteById(LocalDbService.tableLedger, id);
  }

  Future<List<LoanRentalItem>> getLoansRentals() async {
    final rows = await _dbService.queryAll(
      LocalDbService.tableLoansRentals,
      orderBy: 'is_settled ASC, due_date ASC',
    );
    return rows.map(LoanRentalItem.fromMap).toList();
  }

  Future<void> addLoanRental(LoanRentalItem item) async {
    await _dbService.insert(
      LocalDbService.tableLoansRentals,
      item.copyWith(id: null).toMap(),
    );
  }

  Future<void> toggleLoanSettled(LoanRentalItem item) async {
    final id = item.id;
    if (id == null) return;
    await _dbService.updateById(
      LocalDbService.tableLoansRentals,
      id,
      {'is_settled': item.isSettled ? 0 : 1},
    );
  }

  Future<void> deleteLoanRental(int id) async {
    await _dbService.deleteById(LocalDbService.tableLoansRentals, id);
  }
}
