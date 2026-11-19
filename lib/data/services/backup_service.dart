import 'dart:convert';

import '../../domain/models/daily_purchase_record.dart';
import '../../domain/models/donation_su_mae_models.dart';
import '../../domain/models/emergency_qr_card.dart';
import '../../domain/models/ledger_entry.dart';
import '../../domain/models/loan_rental_item.dart';
import '../../domain/models/renewal_reminder.dart';
import '../../domain/models/shopping_item.dart';

/// Structured offline JSON snapshot of all user-owned local data.
class BackupSnapshot {
  const BackupSnapshot({
    required this.version,
    required this.exportedAt,
    required this.ledgerEntries,
    required this.loansRentals,
    required this.shoppingItems,
    this.purchaseRecords = const [],
    required this.reminders,
    required this.qrCard,
    this.donationCampaigns = const [],
    this.suMaeGroups = const [],
  });

  final int version;
  final DateTime exportedAt;
  final List<LedgerEntry> ledgerEntries;
  final List<LoanRentalItem> loansRentals;
  final List<ShoppingItem> shoppingItems;
  final List<DailyPurchaseRecord> purchaseRecords;
  final List<RenewalReminder> reminders;
  final EmergencyQrCard qrCard;
  final List<DonationCampaign> donationCampaigns;
  final List<SuMaeGroup> suMaeGroups;
}

/// Serializes and parses full offline JSON backups for user-owned storage.
class BackupService {
  static const int currentBackupVersion = 2;

  String encodeBackup(BackupSnapshot snapshot) {
    final payload = <String, dynamic>{
      'version': snapshot.version,
      'exportedAt': snapshot.exportedAt.toIso8601String(),
      'ledgerEntries': snapshot.ledgerEntries.map((e) => e.toMap()).toList(),
      'loansRentals': snapshot.loansRentals.map((e) => e.toMap()).toList(),
      'shoppingItems': snapshot.shoppingItems.map((e) => e.toMap()).toList(),
      'purchaseRecords':
          snapshot.purchaseRecords.map((e) => e.toMap()).toList(),
      'reminders': snapshot.reminders.map((e) => e.toMap()).toList(),
      'qrCard': snapshot.qrCard.toJson(),
      'donationCampaigns':
          snapshot.donationCampaigns.map((e) => e.toMap()).toList(),
      'suMaeGroups': snapshot.suMaeGroups.map((e) => e.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  BackupSnapshot decodeBackup(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup JSON format');
    }

    List<T> parseList<T>(
      String key,
      T Function(Map<String, Object?>) fromMap,
    ) {
      final list = decoded[key];
      if (list is! List) return <T>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => fromMap(item.cast<String, Object?>()))
          .toList();
    }

    final rawQr = decoded['qrCard'];
    final qrCard = rawQr is Map<String, dynamic>
        ? EmergencyQrCard.fromJson(rawQr)
        : const EmergencyQrCard();

    return BackupSnapshot(
      version: (decoded['version'] as num?)?.toInt() ?? currentBackupVersion,
      exportedAt: DateTime.tryParse((decoded['exportedAt'] as String?) ?? '') ??
          DateTime.now(),
      ledgerEntries: parseList('ledgerEntries', LedgerEntry.fromMap),
      loansRentals: parseList('loansRentals', LoanRentalItem.fromMap),
      shoppingItems: parseList('shoppingItems', ShoppingItem.fromMap),
      purchaseRecords: parseList('purchaseRecords', DailyPurchaseRecord.fromMap),
      reminders: parseList('reminders', RenewalReminder.fromMap),
      qrCard: qrCard,
      donationCampaigns:
          parseList('donationCampaigns', DonationCampaign.fromMap),
      suMaeGroups: parseList('suMaeGroups', SuMaeGroup.fromMap),
    );
  }
}
