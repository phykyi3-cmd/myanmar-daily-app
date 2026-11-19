import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_daily_app/domain/models/baydin_forecast.dart';
import 'package:myanmar_daily_app/domain/models/baydin_reading.dart';
import 'package:myanmar_daily_app/domain/use_cases/baydin_forecast_engine.dart';
import 'package:myanmar_daily_app/domain/use_cases/myanmar_baydin_engine.dart';
import 'package:myanmar_daily_app/ui/features/baydin/view_models/baydin_view_model.dart';
import 'package:myanmar_daily_app/ui/features/baydin/views/baydin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Extracts Burmese AND English/Romanized Myanmar name weekdays cleanly', () {
    final engine = MyanmarBaydinEngine();

    expect(engine.weekdayFromName('အေးမြ'), MyanmarWeekday.sunday);
    expect(engine.weekdayFromName('ကျော်မင်း'), MyanmarWeekday.monday);
    expect(engine.weekdayFromName('စည်သူ'), MyanmarWeekday.tuesday);
    expect(engine.weekdayFromName('ဝင်းမော်'), MyanmarWeekday.wednesday);
    expect(engine.weekdayFromName('မေသူ'), MyanmarWeekday.thursday);
    expect(engine.weekdayFromName('မာလာ'), MyanmarWeekday.thursday);
    expect(engine.weekdayFromName('မမေသူ'), MyanmarWeekday.thursday);
    expect(engine.weekdayFromName('မအေး'), MyanmarWeekday.sunday);
    expect(engine.weekdayFromName('ကိုစည်သူ'), MyanmarWeekday.tuesday);
    expect(engine.weekdayFromName('သီတာ'), MyanmarWeekday.friday);
    expect(engine.weekdayFromName('တင်ထွန်း'), MyanmarWeekday.saturday);
    expect(engine.weekdayFromName('ရဲမင်း'), MyanmarWeekday.rahu);

    // English / Romanized Burmese names (including digraphs & honorifics)
    expect(engine.weekdayFromName('Sithu Min'), MyanmarWeekday.tuesday);
    expect(engine.weekdayFromName('Si Thu Min'), MyanmarWeekday.tuesday);
    expect(engine.weekdayFromName('Ko Sithu'), MyanmarWeekday.tuesday);
    expect(engine.weekdayFromName('Aung Ko'), MyanmarWeekday.sunday);
    expect(engine.weekdayFromName('Kyaw Zin'), MyanmarWeekday.monday);
    expect(engine.weekdayFromName('Hlaing Hlaing'), MyanmarWeekday.wednesday);
    expect(engine.weekdayFromName('May Thu'), MyanmarWeekday.thursday);
    expect(engine.weekdayFromName('Ma May Thu'), MyanmarWeekday.thursday);
    expect(engine.weekdayFromName('Thura'), MyanmarWeekday.friday);
    expect(engine.weekdayFromName('Htet Aung'), MyanmarWeekday.saturday);
    expect(engine.weekdayFromName('Hnin Wai'), MyanmarWeekday.saturday);
    expect(engine.weekdayFromName('Yan Naing'), MyanmarWeekday.rahu);
    expect(engine.weekdayFromName('Shwe Yee'), MyanmarWeekday.rahu);
  });

  test('Calculates Mahabote 7-house chart, personalized focus Yadayas, male/female Wear & Avoid outfits', () {
    final engine = MyanmarBaydinEngine();
    // 1995-05-10 was a Wednesday. Reference 2026-11-17 is Tuesday.
    final refTue = DateTime(2026, 11, 17);
    final readingGeneral = engine.calculateReading(
      name: 'Sithu Min',
      birthDate: DateTime(1995, 5, 10),
      gender: BaydinGender.male,
      focus: YadayaFocus.generalToday,
      referenceDate: refTue,
    );
    final readingWealth = engine.calculateReading(
      name: 'Sithu Min',
      birthDate: DateTime(1995, 5, 10),
      gender: BaydinGender.male,
      focus: YadayaFocus.wealthBusiness,
      referenceDate: refTue,
    );
    final readingLove = engine.calculateReading(
      name: 'May Thu',
      birthDate: DateTime(1998, 8, 14),
      gender: BaydinGender.female,
      focus: YadayaFocus.loveMarriage,
      referenceDate: refTue,
    );

    expect(readingGeneral.birthWeekday, MyanmarWeekday.wednesday);
    expect(readingGeneral.nameWeekday, MyanmarWeekday.tuesday);
    expect(readingGeneral.runningAge, 32);
    expect(readingGeneral.mahaboteChart.length, 7);
    expect(readingGeneral.mahaboteChart[readingGeneral.mahaboteHouse],
        MyanmarWeekday.wednesday);
    expect(readingGeneral.rootPlanet, MyanmarWeekday.tuesday);
    expect(readingGeneral.tipPlanet, MyanmarWeekday.thursday);

    // Different topics produce genuinely different prescriptions & Dāna assets!
    expect(readingWealth.prescription.almsAsset,
        isNot(equals(readingGeneral.prescription.almsAsset)));
    expect(readingWealth.prescription.flowerTitleMm,
        isNot(equals(readingGeneral.prescription.flowerTitleMm)));
    expect(readingWealth.prescription.wearOutfitAsset,
        contains('outfit_male_'));
    expect(readingLove.prescription.wearOutfitAsset,
        isNot(contains('outfit_male_')));

    // Wear & Avoid Today outfits are never identical.
    expect(readingGeneral.prescription.avoidOutfitAsset,
        isNot(equals(readingGeneral.prescription.wearOutfitAsset)));
    expect(readingWealth.prescription.avoidOutfitAsset,
        isNot(equals(readingWealth.prescription.wearOutfitAsset)));

    // Every weekday defines distinct flower, candle light, and outfit asset paths.
    final flowerAssets =
        MyanmarWeekday.values.map((d) => d.flowerAsset).toSet();
    final lightAssets =
        MyanmarWeekday.values.map((d) => d.lightAsset).toSet();
    final outfitAssets =
        MyanmarWeekday.values.map((d) => d.outfitAsset).toSet();
    expect(flowerAssets.length, MyanmarWeekday.values.length);
    expect(lightAssets.length, MyanmarWeekday.values.length);
    expect(outfitAssets.length, MyanmarWeekday.values.length);
  });

  test('Inspects Myanmar calendar dates for Uposatha Sabbath and Yatyaza/Pyathada', () {
    final engine = MyanmarBaydinEngine();
    final days = engine.upcomingCalendarDays(DateTime(2026, 11, 16), days: 30);

    expect(days.length, 30);
    expect(days.first.myanmarDateFormatted.contains('&'), isFalse);
    expect(days.first.myanmarDateFormatted.contains('၁၃၈၈'), isTrue);
    // Within any 30-day lunar span, there must be at least 3 Sabbath days and multiple Yatyaza/Pyathada days.
    expect(days.where((d) => d.isSabbath).length, greaterThanOrEqualTo(3));
    expect(days.where((d) => d.isYatyaza).length, greaterThanOrEqualTo(4));
    expect(
      days.where((d) => d.isPyathada || d.isAfternoonPyathada).length,
      greaterThanOrEqualTo(4),
    );
  });

  testWidgets('BaydinScreen hides flowers until asked, then reveals English/Burmese fortune & offerings', (tester) async {
    final vm = BaydinViewModel();
    await vm.loadAll(now: DateTime(2026, 11, 16));

    await tester.pumpWidget(
      MaterialApp(
        home: BaydinScreen(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();

    // Flowers, Dāna alms, candle lights & Wear/Avoid outfits stay hidden before asking Baydin.
    expect(find.textContaining('ဘုရားကပ်ရန်ပန်း'), findsNothing);
    expect(find.textContaining('ဆွမ်းနှင့် ကုသိုလ်ဒါန'), findsNothing);
    expect(find.textContaining('ဖယောင်းတိုင်နှင့် ဆီမီးတိုင် ပူဇော်နည်း'), findsNothing);
    expect(find.textContaining('ယနေ့ ဝတ်ဆင်ရန် ကံပွင့်ဝတ်စုံ'), findsNothing);
    expect(find.textContaining('ယနေ့ မဝတ်ရ'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Sithu Min');
    await tester.pump();

    await tester.ensureVisible(find.text('အမျိုးသား'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('အမျိုးသား'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('စီးပွား • လာဘ်ပွင့်'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('စီးပွား • လာဘ်ပွင့်'));
    await tester.pumpAndSettle();

    final calcBtn = find.text('ဗေဒင်မေးမည် (တွက်ချက်မည်)');
    await tester.ensureVisible(calcBtn);
    await tester.pumpAndSettle();
    await tester.tap(calcBtn);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('Sithu Min ၏ ဇာတာခွင်'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Sithu Min ၏ ဇာတာခွင်'), findsOneWidget);
    expect(find.textContaining('မဟာဘုတ် ဇာတာခွင် (၇ အိမ်)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('ဘာကြောင့် ဤသို့ဖြစ်နေသလဲ'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('ဘာကြောင့် ဤသို့ဖြစ်နေသလဲ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('အချစ်ရေး / ရည်းစားရနိုင်ချိန်'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('အချစ်ရေး / ရည်းစားရနိုင်ချိန်'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('ဘုရားကပ်ရန်ပန်း'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('ဘုရားကပ်ရန်ပန်း'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('ဆွမ်းနှင့် ကုသိုလ်ဒါန'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('ဆွမ်းနှင့် ကုသိုလ်ဒါန'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('ဖယောင်းတိုင်နှင့် ဆီမီးတိုင် ပူဇော်နည်း'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('ဖယောင်းတိုင်နှင့် ဆီမီးတိုင် ပူဇော်နည်း'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('ယနေ့ ဝတ်ဆင်ရန် ကံပွင့်ဝတ်စုံ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('ယနေ့ ဝတ်ဆင်ရန် ကံပွင့်ဝတ်စုံ'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('ယနေ့ မဝတ်ရ • ရှောင်ကြဉ်ရန်ဝတ်စုံ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ယနေ့ မဝတ်ရ • ရှောင်ကြဉ်ရန်ဝတ်စုံ'), findsOneWidget);

    await tester.tap(find.text('ရက်ရာဇာ • ဥပုသ်'));
    await tester.pumpAndSettle();

    expect(
      find.text('လာမည့် ရက် (၃၀) ရက်ရာဇာ၊ ပြဿဒါးနှင့် ဥပုသ်နေ့များ'),
      findsOneWidget,
    );
    expect(find.text('ဥပုသ် • အဖိတ်နေ့'), findsOneWidget);
  });

  test('BaydinForecastEngine calculates Weekly, Monthly, Daily Auspicious Guide, and Classical Compatibility', () {
    final base = MyanmarBaydinEngine();
    final forecastEngine = BaydinForecastEngine(baseEngine: base);
    final refDate = DateTime(2026, 11, 19);

    final reading = base.calculateReading(
      name: 'Sithu Min',
      birthDate: DateTime(1995, 5, 10),
      gender: BaydinGender.male,
      focus: YadayaFocus.wealthBusiness,
      referenceDate: refDate,
    );

    // 1. Weekly forecast (Mon..Sun 7 days) + distinct next week
    final thisWeek = forecastEngine.calculateWeeklyForecast(
      reading: reading,
      targetDate: refDate,
    );
    final nextWeek = forecastEngine.calculateWeeklyForecast(
      reading: reading,
      targetDate: refDate.add(const Duration(days: 7)),
    );
    expect(thisWeek.days.length, 7);
    expect(thisWeek.weekStart.weekday, DateTime.monday);
    expect(thisWeek.weekEnd.weekday, DateTime.sunday);
    expect(thisWeek.weekScore, inInclusiveRange(48, 96));
    expect(thisWeek.bestDays, isNotEmpty);
    expect(thisWeek.luckyNumbersMm, isNotEmpty);
    expect(thisWeek.weekRangeLabelMm, isNot(equals(nextWeek.weekRangeLabelMm)));

    // 2. Monthly forecast (Early / Mid / Late 3 phases + best & sabbath dates)
    final nov = forecastEngine.calculateMonthlyForecast(
      reading: reading,
      year: 2026,
      month: 11,
    );
    final dec = forecastEngine.calculateMonthlyForecast(
      reading: reading,
      year: 2026,
      month: 12,
    );
    expect(nov.phases.length, 3);
    expect(nov.phases[0].phaseTitleMm, 'လဆန်းပိုင်း');
    expect(nov.phases[1].phaseTitleMm, 'လလယ်ပိုင်း');
    expect(nov.phases[2].phaseTitleMm, 'လကုန်ပိုင်း');
    expect(nov.bestDates, isNotEmpty);
    expect(nov.sabbathDates.length, greaterThanOrEqualTo(3));
    expect(nov.monthTitleMm, isNot(equals(dec.monthTitleMm)));

    // 3. Daily Auspicious Guide (6 daytime 2-hour windows + Nagahle head)
    final dailyGuide = forecastEngine.calculateDailyAuspiciousGuide(
      date: refDate,
      userBirthWeekday: reading.birthWeekday,
    );
    expect(dailyGuide.slots.length, 6);
    expect(dailyGuide.nagahleHeadMm, isNotEmpty);
    expect(dailyGuide.safeDirectionsMm, isNotEmpty);

    // 4. Classical Myanmar 4-verse compatibility rules
    final spouse = forecastEngine.calculateCompatibility(
      personA: MyanmarWeekday.sunday,
      personB: MyanmarWeekday.friday,
    );
    expect(spouse.bondTypeMm, contains('အိမ်ထောင်ဖက်'));
    expect(spouse.classicalRhymeMm, contains('ဥဿာ'));
    expect(spouse.overallScore, greaterThanOrEqualTo(90));

    final friend = forecastEngine.calculateCompatibility(
      personA: MyanmarWeekday.monday,
      personB: MyanmarWeekday.wednesday,
    );
    expect(friend.bondTypeMm, contains('မိတ်ဖက်'));
    expect(friend.classicalRhymeMm, contains('အောင်ပ'));

    final element = forecastEngine.calculateCompatibility(
      personA: MyanmarWeekday.saturday,
      personB: MyanmarWeekday.thursday,
    );
    expect(element.bondTypeMm, contains('ဓာတ်ဖက်'));
    expect(element.classicalRhymeMm, contains('ဓမ္မာ'));

    final enemy = forecastEngine.calculateCompatibility(
      personA: MyanmarWeekday.sunday,
      personB: MyanmarWeekday.tuesday,
    );
    expect(enemy.bondTypeMm, contains('ရန်ဖက်'));
    expect(enemy.isHarmonious, isFalse);
  });

  testWidgets('BaydinScreen supports Weekly/Monthly horoscopes, week/month stepping, auspicious hours, and Compatibility tab', (tester) async {
    final vm = BaydinViewModel();
    await vm.loadAll(now: DateTime(2026, 11, 19));

    await tester.pumpWidget(
      MaterialApp(
        home: BaydinScreen(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();

    // Expand Today's Auspicious Hours & Nagahle Direction card, then collapse
    await tester.tap(find.textContaining('ယနေ့ အခါပေးနှင့် နဂါးခေါင်းလှည့်ရာ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('နံနက် ၀၆:၀၀ – ၀၈:၀၀'), findsOneWidget);
    await tester.tap(find.textContaining('ယနေ့ အခါပေးနှင့် နဂါးခေါင်းလှည့်ရာ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('နံနက် ၀၆:၀၀ – ၀၈:၀၀'), findsNothing);

    // Select Weekly period, enter name, and calculate
    await tester.scrollUntilVisible(
      find.byType(TextField),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Sithu Min');
    await tester.pump();
    await tester.ensureVisible(find.text('တစ်ပတ်စာ').first);
    await tester.tap(find.text('တစ်ပတ်စာ').first);
    await tester.pumpAndSettle();

    final calcBtn = find.text('ဗေဒင်မေးမည် (တွက်ချက်မည်)');
    await tester.ensureVisible(calcBtn);
    await tester.tap(calcBtn);
    await tester.pumpAndSettle();

    // Verify 7-day Weekly Forecast view
    await tester.scrollUntilVisible(
      find.textContaining('တစ်ပတ်စာ နေ့ရက်အလိုက် ကံဇာတာ (၇ ရက်)'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('တစ်ပတ်စာ နေ့ရက်အလိုက် ကံဇာတာ (၇ ရက်)'), findsOneWidget);

    // Shift to Next Week
    final beforeRange = vm.weeklyForecast!.weekRangeLabelMm;
    vm.shiftWeek(1);
    await tester.pumpAndSettle();
    expect(vm.weeklyForecast!.weekRangeLabelMm, isNot(equals(beforeRange)));

    // Switch to Monthly Forecast
    vm.setActivePeriod(BaydinForecastPeriod.monthly);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('တစ်လစာ ကံအတက်အကျ (၃ ပိုင်းခွဲ)'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('လဆန်းပိုင်း (၁ – ၁၀ ရက်)'), findsOneWidget);
    expect(find.text('လလယ်ပိုင်း (၁၁ – ၂၀ ရက်)'), findsOneWidget);
    expect(find.text('လကုန်ပိုင်း (၂၁ – ၃၀ ရက်)'), findsOneWidget);

    // Switch to 2-Person Compatibility tab
    await tester.tap(find.text('တိုက်ဆိုင်စစ်'));
    await tester.pumpAndSettle();
    expect(find.textContaining('နှစ်ဦးသား မွေးနံတိုက်ဆိုင်စစ်'), findsOneWidget);

    vm.setCompatPersonA(MyanmarWeekday.sunday);
    vm.setCompatPersonB(MyanmarWeekday.friday);
    await tester.pumpAndSettle();
    expect(find.textContaining('ဥဿာ – စိန်ပန်း – ဒန်းလှ – ကိုရှာ'), findsOneWidget);
  });
}
