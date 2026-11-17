/// Identifies the six modular offline-first features inside Myanmar Daily App.
enum AppModule {
  calculators(
    key: 'calculators',
    titleMm: 'ရွှေ၊ အရစ်ကျ တွက်စက်',
    subtitleMm: 'ရွှေအလေးချိန်၊ အရစ်ကျနဲ့ ငွေလဲနှုန်း',
    routePath: '/finance',
  ),
  ledger(
    key: 'ledger',
    titleMm: 'အလှူနဲ့ စုမဲစာရင်း',
    subtitleMm: 'အလှူ၊ စုမဲနဲ့ အသင်းအဖွဲ့ ငွေစာရင်း',
    routePath: '/finance',
  ),
  loansRentals(
    key: 'loans_rentals',
    titleMm: 'ငှားရမ်းမှုနဲ့ ပေးရန်-ရရန်',
    subtitleMm: 'ပစ္စည်းငှား၊ အကြွေးနဲ့ အိမ်လခစာရင်း',
    routePath: '/finance',
  ),
  recipesMarket(
    key: 'recipes_market',
    titleMm: 'ဟင်းချက်နဲ့ ဈေးဝယ်စာရင်း',
    subtitleMm: 'နေ့စဉ်ဟင်းအကြံပြုနဲ့ ဘတ်ဂျက် Checklist',
    routePath: '/daily',
  ),
  reminders(
    key: 'reminders',
    titleMm: 'ယာဉ်နဲ့ စာရွက်စာတမ်း Reminder',
    subtitleMm: 'အင်ဂျင်ဝိုင်၊ လိုင်စင်၊ Passport သက်တမ်းတိုး',
    routePath: '/tools',
  ),
  qrCard(
    key: 'qr_card',
    titleMm: 'Offline QR နဲ့ အရေးပေါ် Card',
    subtitleMm: 'ကိုယ်ရေးအရေးပေါ်၊ Wi-Fi နဲ့ Contact QR',
    routePath: '/tools',
  );

  const AppModule({
    required this.key,
    required this.titleMm,
    required this.subtitleMm,
    required this.routePath,
  });

  final String key;
  final String titleMm;
  final String subtitleMm;
  final String routePath;
}
