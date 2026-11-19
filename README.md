# မြန်မာနေ့စဉ် (Myanmar Daily App)

Offline-First Flutter Application for Myanmar families at home and abroad — packaged as both an **Installable Progressive Web App (PWA)** and an **Android Release APK**.

- **Live Installable App (PWA):** https://smartmyanmarfonts.com/myanmar-daily-app/
- **Android APK Download (GitHub Releases):** https://github.com/phykyi3-cmd/myanmar-daily-app/releases/latest

## Core Modules (4 Tabs)

1. **`အိမ်တွင်းရေး` (Household Meals, Regional Market & Shopping):**
   - 82 Myanmar & ethnic dishes (`assets/images/dishes/`) with one-tap ingredient sync to Shopping List & dated Purchase History.
   - Automatic IP geolocation & local currency recipe cost estimation strictly for **6 countries**: Myanmar (`MMK`), Thailand (`THB`), Malaysia (`MYR`), Singapore (`SGD`), South Korea (`KRW`), and Japan (`JPY`), with editable per-staple local prices.
2. **`ဗေဒင်/ယတြာ` (Mahabote Astrology & Yadayas):** Name-based 7-house Mahabote birth chart calculation, Uposatha/Yatyaza/Pyathada Myanmar Calendar lookup, and 39 studio remedy images (`assets/images/baydin/`).
3. **`စာရင်း/တွက်စက်` (Finance & Calculators):** Kyat/Pae/Yway Gold calculator, Loan EMI, Exchange rate, Ledger & Loan/Rental tracker.
4. **`အခြား` (Utilities, Backup & Security):** Renewal Reminders, Emergency QR Card, JSON Backup/Restore & Account Vault Sync (`cloud_sync_service.dart`).

## Verification

```bash
flutter analyze
flutter test
```
Unit and widget tests cover domain engines, SQLite/Web persistence, 6-country IP geolocation & regional recipe cost calculations, Myanmar numeral normalization, and Backup v2 round-trip flows.
