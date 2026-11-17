# မြန်မာနေ့စဉ် (Myanmar Daily App)

Offline-First & Phase 2 Cloud Telehealth Ready Flutter Application for Myanmar families — packaged as both an **Installable Progressive Web App (PWA)** and an **Android Release APK**.

- **Live Installable App (PWA):** https://phykyi3-cmd.github.io/myanmar-daily-app/
- **Android APK Download (GitHub Releases):** https://github.com/phykyi3-cmd/myanmar-daily-app/releases/latest

## Core Modules (5 Tabs)

1. **`အိမ်တွင်းရေး` (Household Meals & Shopping):** 82 Myanmar dishes (`assets/images/dishes/`) with one-tap ingredient sync to Shopping List & dated Purchase History.
2. **`ဗေဒင်/ယတြာ` (Mahabote Astrology & Yadayas):** Name-based 7-house Mahabote birth chart calculation, Uposatha/Yatyaza/Pyathada Myanmar Calendar lookup, and 39 studio remedy images (`assets/images/baydin/`).
3. **`မိခင်/ကလေး` (Maternal & Child Health Hub):**
   - Official Myanmar MOHS EPI Childhood Immunization Schedule (18 doses) & Maternal ANC/Td tracking with Reminder sync
   - Gestational Week / EDD Calculator, Red-Flag Danger Signs, WHO `0–60 month` Weight-for-Age evaluation (with safe `>60m` boundary & Burmese `၀–၉` numeral support)
   - Mother & Infant Weaning Meals synced to Shopping List
   - Offline `4-7-8` Breathing & Meditation Timer (`03:00` / `05:00` / `10:00`) & Mood log
   - Salted FNV-1a 4-Digit Health PIN Lock, Clinic SBAR Summary + Scannable Pre-Consult QR
   - **Phase 2 Cloud Telehealth (`Firebase Auth + Cloud Firestore`)** via [`FirebaseTelehealthGateway`](lib/data/services/telehealth_gateway.dart) & role-based security rules in [`cloud_backend/`](cloud_backend/CLOUD_SETUP.md).
4. **`စာရင်း/တွက်စက်` (Finance & Calculators):** Kyat/Pae/Yway Gold calculator, Loan EMI, Exchange rate, Ledger & Loan/Rental tracker.
5. **`အခြား` (Utilities, Backup & Security):** Renewal Reminders, Emergency QR Card, JSON Backup/Restore & Account Vault Sync (`cloud_sync_service.dart`).

## Verification

```bash
flutter analyze
flutter test
```
All 26 unit and widget tests cover domain engines, SQLite/Web persistence, salted PIN lock, Backup v2 round-trip, and REST Firebase Telehealth flows.

## Phase 2 Cloud Backend Security Deployment

See [`cloud_backend/CLOUD_SETUP.md`](cloud_backend/CLOUD_SETUP.md) to deploy `firestore.rules` (enforcing `patientUid` ownership and verified Myanmar SAMA doctor custom claims) and composite indexes to Firebase.
