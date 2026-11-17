import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_daily_app/data/services/backup_service.dart';
import 'package:myanmar_daily_app/domain/models/emergency_qr_card.dart';
import 'package:myanmar_daily_app/domain/models/ledger_entry.dart';
import 'package:myanmar_daily_app/domain/models/loan_rental_item.dart';
import 'package:myanmar_daily_app/domain/models/renewal_reminder.dart';
import 'package:myanmar_daily_app/domain/models/shopping_item.dart';

void main() {
  test('BackupService round-trips snapshot cleanly', () {
    final service = BackupService();
    final now = DateTime(2026, 11, 15, 13, 0);

    final snapshot = BackupSnapshot(
      version: 1,
      exportedAt: now,
      ledgerEntries: [
        LedgerEntry(
          id: 1,
          title: 'ကထိန်အလှူ',
          category: LedgerCategory.donation,
          amountMmk: 50000,
          isIncome: false,
          createdAt: now,
        ),
      ],
      loansRentals: [
        LoanRentalItem(
          id: 2,
          personName: 'ကိုမောင်',
          itemName: 'စက်ဘီး',
          type: LoanRentalType.lent,
          amountMmk: 0,
          dueDate: now.add(const Duration(days: 3)),
        ),
      ],
      shoppingItems: [
        ShoppingItem(
          id: 3,
          name: 'ကြက်သွန်နီ',
          quantity: '၁ ပိဿာ',
          estimatedCostMmk: 4500,
          createdAt: now,
        ),
      ],
      reminders: [
        RenewalReminder(
          id: 4,
          title: 'အင်ဂျင်ဝိုင်လဲရန်',
          category: ReminderCategory.vehicle,
          dueDate: now.add(const Duration(days: 10)),
          mileageKm: 5000,
        ),
      ],
      qrCard: const EmergencyQrCard(
        fullName: 'Sithu',
        phone: '09123456789',
        bloodType: 'O',
      ),
    );

    final encoded = service.encodeBackup(snapshot);
    final decoded = service.decodeBackup(encoded);

    expect(decoded.ledgerEntries.length, 1);
    expect(decoded.ledgerEntries.first.title, 'ကထိန်အလှူ');
    expect(decoded.loansRentals.first.personName, 'ကိုမောင်');
    expect(decoded.shoppingItems.first.estimatedCostMmk, 4500);
    expect(decoded.reminders.first.mileageKm, 5000);
    expect(decoded.qrCard.bloodType, 'O');
  });
}
