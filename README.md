# မြန်မာနေ့စဉ် (Myanmar Daily App)

Offline-First Flutter Application for Myanmar families at home and abroad — packaged as both an **Installable Progressive Web App (PWA)** and an **Android Release APK**.

- **Live Installable App (PWA):** https://smartmyanmarfonts.com/myanmar-daily-app/
- **Android APK Download (GitHub Releases):** https://github.com/phykyi3-cmd/myanmar-daily-app/releases/latest

## Core Modules (4 Tabs)

1. **`အိမ်တွင်းရေး` (Household Meals, Regional Market & Shopping):**
   - 82 Myanmar & ethnic dishes (`assets/images/dishes/`) with one-tap ingredient sync to Shopping List & dated Purchase History.
   - Automatic IP geolocation & local currency recipe cost estimation strictly for **6 countries**: Myanmar (`MMK`), Thailand (`THB`), Malaysia (`MYR`), Singapore (`SGD`), South Korea (`KRW`), and Japan (`JPY`), with editable per-staple local prices.
2. **`ဗေဒင်/ယတြာ` (Weekly/Monthly Horoscope, Mahabote, Compatibility & Yadayas):**
   - 100% offline **Weekly (7-day)** and **Monthly (3-phase + key dates)** personalized forecasts powered by real Myanmar Calendar transits (`myanmar_calendar_dart`) with week/month navigation.
   - Name-based 7-house Mahabote birth chart, Current-Age Thet-Yauk, Today's Auspicious Hours & Nagahle Direction, Classical 4-verse 2-Person Compatibility, Uposatha/Yatyaza/Pyathada calendar, and 39 studio remedy images (`assets/images/baydin/`).
3. **`စာရင်း/တွက်စက်` (Group Donations, Myanmar Su Mae, Live Gold/FX & Calculators):**
   - **အလှူစာရင်း (Group Donation Campaigns):** Create campaigns (e.g., `ဘုံကထိန်`, `ဝါဆိုသင်္ကန်း`, `ရေ/အာဟာရ`), incrementally add dated donor records (paid vs pledged), view live totals, and copy formatted Burmese lists.
   - **စုမဲ / ငွေစုစု (Traditional Myanmar ROSCA):** Dedicated `မဲနှိုက် စုမဲ`, `လေလံ စုမဲ`, and `ဒိုင်ယူ • အလှည့်ကျ စုမဲ` groups with share support (`0.5 / 1 / 2 မဲ`), round-by-round payment checklists, built-in random draw & auction bid payout math.
   - **Live Yangon Gold & Multi-Currency FX:** 30-min automated live feed (`fx-data/live_fx.json` via Bybit/Bitget P2P + Remitly + Gold-API/PAXG + Open-ER-API), Kyat/Pae/Yway Gold calculator, Loan EMI, and Loan/Rental tracker.
4. **`အခြား` (Utilities, Backup & Security):** Renewal Reminders, Emergency QR Card, JSON Backup/Restore & Account Vault Sync (`cloud_sync_service.dart`).

## Verification

```bash
flutter analyze
flutter test
```
Unit and widget tests cover domain engines, SQLite/Web persistence, 6-country IP geolocation & regional recipe cost calculations, Myanmar numeral normalization, and Backup v2 round-trip flows.
