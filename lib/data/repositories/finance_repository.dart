import '../../domain/models/donation_su_mae_models.dart';
import '../../domain/models/ledger_entry.dart';
import '../../domain/models/loan_rental_item.dart';
import '../services/local_db_service.dart';

/// Repository managing community ledger entries, group donations, Myanmar Su Mae groups,
/// and loans/rentals in local SQLite / Web storage.
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

  // ---- Community Donation Campaigns (အလှူစာရင်း) ----

  Future<List<DonationCampaign>> getDonationCampaigns() async {
    final rows = await _dbService.queryAll(
      LocalDbService.tableDonationCampaigns,
      orderBy: 'updated_at DESC',
    );
    return rows.map(DonationCampaign.fromMap).toList();
  }

  Future<int> saveDonationCampaign(DonationCampaign campaign) async {
    final now = DateTime.now();
    if (campaign.id == null) {
      return _dbService.insert(
        LocalDbService.tableDonationCampaigns,
        campaign.copyWith(updatedAt: now).toMap(),
      );
    }
    await _dbService.updateById(
      LocalDbService.tableDonationCampaigns,
      campaign.id!,
      campaign.copyWith(updatedAt: now).toMap()..remove('id'),
    );
    return campaign.id!;
  }

  Future<void> deleteDonationCampaign(int id) async {
    await _dbService.deleteById(LocalDbService.tableDonationCampaigns, id);
  }

  // ---- Myanmar Su Mae Groups (စုမဲ / ငွေစုစု) ----

  Future<List<SuMaeGroup>> getSuMaeGroups() async {
    final rows = await _dbService.queryAll(
      LocalDbService.tableSuMaeGroups,
      orderBy: 'updated_at DESC',
    );
    return rows.map(SuMaeGroup.fromMap).toList();
  }

  Future<int> saveSuMaeGroup(SuMaeGroup group) async {
    final now = DateTime.now();
    if (group.id == null) {
      return _dbService.insert(
        LocalDbService.tableSuMaeGroups,
        group.copyWith(updatedAt: now).toMap(),
      );
    }
    await _dbService.updateById(
      LocalDbService.tableSuMaeGroups,
      group.id!,
      group.copyWith(updatedAt: now).toMap()..remove('id'),
    );
    return group.id!;
  }

  Future<void> deleteSuMaeGroup(int id) async {
    await _dbService.deleteById(LocalDbService.tableSuMaeGroups, id);
  }
}
