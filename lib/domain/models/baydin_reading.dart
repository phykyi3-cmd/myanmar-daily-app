/// Traditional Myanmar 8-planet weekdays (including Wednesday Night / Rahu).
enum MyanmarWeekday {
  sunday(
    planetNumber: 1,
    mmcalWeekdayIndex: 1,
    planetYears: 6,
    labelMm: 'တနင်္ဂနွေ',
    animalMm: 'ဂဠုန်',
    directionMm: 'အရှေ့မြောက်',
    sampleLettersMm: 'အ ဥ ဦ ဧ ဩ',
    flowerNameMm: 'အုန်းညွန့်နှင့် နှင်းဆီနီ',
    flowerCount: 6,
    flowerAsset: 'assets/images/baydin/flower_sunday.jpg',
    flowerNoteMm: 'ဘုရားတွင် အုန်းညွန့် (၆) ညွန့်နှင့် နှင်းဆီနီ (၆) ပွင့် သန့်ရှင်းစွာ ကပ်လှူပူဇော်ပါ။',
    candleTitleMm: 'ဖယောင်းတိုင်နီ (၆) တိုင်နှင့် မြေဆီမီး (၆) ခွက်',
    lightAsset: 'assets/images/baydin/light_sunday.jpg',
    candleNoteMm: 'တနင်္ဂနွေနံ မနက်ပိုင်းတွင် ကြေးလင်ပန်းထဲ၌ အနီ/ရွှေရောင် ဖယောင်းတိုင် (၆) တိုင်နှင့် မြေဆီမီး (၆) ခွက် ထွန်းညှိပူဇော်ပါ။',
    outfitColorLabelMm: 'အနီရောင် / ကြက်သွေးရောင်',
    avoidColorLabelMm: 'အနက် / နက်ပြာရင့်',
    outfitColorHex: 0xFFDC2626,
    secondaryColorHex: 0xFFFB7185,
    outfitAsset: 'assets/images/baydin/outfit_sunday.jpg',
    outfitNoteMm: 'အရေးကြီးကိစ္စ၊ အလှူမင်္ဂလာသွားလျှင် အနီရောင် သို့မဟုတ် ကြက်သွေးရောင် ဝတ်စုံကို ဦးစားပေးဝတ်ဆင်ပါ။',
  ),
  monday(
    planetNumber: 2,
    mmcalWeekdayIndex: 2,
    planetYears: 15,
    labelMm: 'တနင်္လာ',
    animalMm: 'ကျား',
    directionMm: 'အရှေ့',
    sampleLettersMm: 'က ခ ဂ ဃ င',
    flowerNameMm: 'ကံ့ကော်ညွန့်နှင့် စံပယ်ပန်း',
    flowerCount: 15,
    flowerAsset: 'assets/images/baydin/flower_monday.jpg',
    flowerNoteMm: 'ဘုရားတွင် ကံ့ကော်ညွန့်နှင့် စံပယ်ပန်း (၁၅) ပွင့်/ညွန့် စီ၍ ကပ်လှူပူဇော်ပါ။',
    candleTitleMm: 'အဖြူ/ရွှေဝါ ဖယောင်းတိုင် (၁၅) တိုင်နှင့် ဆီမီး (၅) ခွက်',
    lightAsset: 'assets/images/baydin/light_monday.jpg',
    candleNoteMm: 'အိမ်ဘုရားတွင် အဖြူ သို့မဟုတ် ရွှေဝါရောင် ဖယောင်းတိုင်နှင့် မြေဆီမီးခွက် (၅) ခွက် မေတ္တာပို့ ထွန်းညှိပူဇော်ပါ။',
    outfitColorLabelMm: 'အဝါရောင် / ရွှေစင် / ဆင်စွယ်ဖြူ',
    avoidColorLabelMm: 'အနီရင့် / အညိုရင့်',
    outfitColorHex: 0xFFFACC15,
    secondaryColorHex: 0xFFFEF08A,
    outfitAsset: 'assets/images/baydin/outfit_monday.jpg',
    outfitNoteMm: 'ငွေကြေးလာဘ်ပွင့်စေရန် အဝါနု၊ ရွှေအိုရောင် သို့မဟုတ် ဆင်စွယ်ဖြူ ဝတ်စုံများ ဝတ်ဆင်ပါ။',
  ),
  tuesday(
    planetNumber: 3,
    mmcalWeekdayIndex: 3,
    planetYears: 8,
    labelMm: 'အင်္ဂါ',
    animalMm: 'ခြင်္သေ့',
    directionMm: 'အရှေ့တောင်',
    sampleLettersMm: 'စ ဆ ဇ ဈ ည',
    flowerNameMm: 'ဇီးညွန့်နှင့် ဂန္ဓမာပန်း',
    flowerCount: 8,
    flowerAsset: 'assets/images/baydin/flower_tuesday.jpg',
    flowerNoteMm: 'ဘုရားတွင် ဇီးညွန့် (၈) ညွန့်နှင့် ဂန္ဓမာပန်း (၈) ပွင့် တွဲဖက်ပူဇော်ပါ။',
    candleTitleMm: 'ပန်းရောင် ဖယောင်းတိုင် (၈) တိုင်နှင့် ဆီမီး (၈) ခွက်',
    lightAsset: 'assets/images/baydin/light_tuesday.jpg',
    candleNoteMm: 'အင်္ဂါနေ့ ညနေပိုင်းတွင် ပန်းရောင်/ပျားဖယောင်းတိုင် (၈) တိုင်နှင့် ဆီမီးခွက် (၈) ခွက် ငြိမ်းချမ်းစွာ ထွန်းညှိပူဇော်ပါ။',
    outfitColorLabelMm: 'ပန်းရောင် / ကြက်သွေးနု / ခရမ်းနု',
    avoidColorLabelMm: 'အဝါရင့် / အနက်',
    outfitColorHex: 0xFFEC4899,
    secondaryColorHex: 0xFFF9A8D4,
    outfitAsset: 'assets/images/baydin/outfit_tuesday.jpg',
    outfitNoteMm: 'စိတ်အေးချမ်းပြီး လူချစ်လူခင်ပေါစေရန် ပန်းရောင် သို့မဟုတ် ခရမ်းနုရောင် ဝတ်စုံ ဝတ်ဆင်ပါ။',
  ),
  wednesday(
    planetNumber: 4,
    mmcalWeekdayIndex: 4,
    planetYears: 17,
    labelMm: 'ဗုဒ္ဓဟူး',
    animalMm: 'ဆင်',
    directionMm: 'တောင်',
    sampleLettersMm: 'လ ဝ ဠ',
    flowerNameMm: 'ရွက်လှညွန့်နှင့် သပြေညွန့်',
    flowerCount: 17,
    flowerAsset: 'assets/images/baydin/flower_wednesday.jpg',
    flowerNoteMm: 'ဘုရားတွင် ရွက်လှညွန့် (သို့) သပြေညွန့် (၁၇) ညွန့် ရေချမ်းကပ်လှူပူဇော်ပါ။',
    candleTitleMm: 'အစိမ်း/ပျားဖယောင်းတိုင် (၁၇) တိုင်နှင့် ဆီမီး (၄) ခွက်',
    lightAsset: 'assets/images/baydin/light_wednesday.jpg',
    candleNoteMm: 'ဗုဒ္ဓဟူးနံနက်ပိုင်းတွင် အစိမ်းနု/ပျားဖယောင်းတိုင်နှင့် မြေဆီမီး (၄) ခွက် (သို့) (၁၇) ခွက် အလင်းဓာတ် ပူဇော်ပါ။',
    outfitColorLabelMm: 'အစိမ်းရောင် / မြစိမ်းရောင်',
    avoidColorLabelMm: 'ပန်းရောင် / လိမ္မော်ရင့်',
    outfitColorHex: 0xFF22C55E,
    secondaryColorHex: 0xFF86EFAC,
    outfitAsset: 'assets/images/baydin/outfit_wednesday.jpg',
    outfitNoteMm: 'အကြံအစည်အောင်မြင်ရန် အစိမ်းနု သို့မဟုတ် မြစိမ်းရောင် အင်္ကျီလုံချည် ဝတ်ဆင်ပါ။',
  ),
  thursday(
    planetNumber: 5,
    mmcalWeekdayIndex: 5,
    planetYears: 19,
    labelMm: 'ကြာသပတေး',
    animalMm: 'ကြွက်',
    directionMm: 'အနောက်',
    sampleLettersMm: 'ပ ဖ ဗ ဘ မ',
    flowerNameMm: 'ပိတောက်ပန်းနှင့် ကြာပန်းဖြူ',
    flowerCount: 19,
    flowerAsset: 'assets/images/baydin/flower_thursday.jpg',
    flowerNoteMm: 'ဘုရားတွင် အဝါ/အဖြူ ပန်း (ပိတောက်/ကြာ/မေမြို့) (၁၉) ပွင့် ကပ်လှူပူဇော်ပါ။',
    candleTitleMm: 'လိမ္မော်နု/အဖြူ ဖယောင်းတိုင် (၁၉) တိုင်နှင့် ဆီမီး (၅) ခွက်',
    lightAsset: 'assets/images/baydin/light_thursday.jpg',
    candleNoteMm: 'ကြာသပတေးနေ့တွင် ရွှေ/လိမ္မော်နု ဖယောင်းတိုင်နှင့် သန့်ရှင်းသော မြေဆီမီးခွက် (၅) ခွက် ထွန်းညှိဆုတောင်းပါ။',
    outfitColorLabelMm: 'လိမ္မော်နု / အဖြူစင် / ရွှေအို',
    avoidColorLabelMm: 'မီးခိုးရင့် / အညို',
    outfitColorHex: 0xFFF97316,
    secondaryColorHex: 0xFFFEF3C7,
    outfitAsset: 'assets/images/baydin/outfit_thursday.jpg',
    outfitNoteMm: 'အိမ်တွင်းရေးသာယာပြီး ပညာဉာဏ်ပွင့်ရန် အဖြူစင် သို့မဟုတ် လိမ္မော်နု ဝတ်စုံ ဝတ်ဆင်ပါ။',
  ),
  friday(
    planetNumber: 6,
    mmcalWeekdayIndex: 6,
    planetYears: 21,
    labelMm: 'သောကြာ',
    animalMm: 'ပူး',
    directionMm: 'မြောက်',
    sampleLettersMm: 'သ ဟ',
    flowerNameMm: 'သီဟိုဠ်သပြေနှင့် နှင်းဆီဖြူ',
    flowerCount: 21,
    flowerAsset: 'assets/images/baydin/flower_friday.jpg',
    flowerNoteMm: 'ဘုရားတွင် သပြေညွန့်နှင့် နှင်းဆီဖြူ (၂၁) ပွင့်/ညွန့် မွှေးကြိုင်စွာ ပူဇော်ပါ။',
    candleTitleMm: 'အဖြူ/မိုးပြာ ဖယောင်းတိုင် (၂၁) တိုင်နှင့် ဆီမီး (၆) ခွက်',
    lightAsset: 'assets/images/baydin/light_friday.jpg',
    candleNoteMm: 'သောကြာနေ့တွင် ငွေလင်ပန်း၌ ဖယောင်းတိုင်ဖြူနှင့် မြေဆီမီး (၆) ခွက် (သို့) (၂၁) တိုင် ထွန်းညှိပူဇော်ပါ။',
    outfitColorLabelMm: 'အပြာနုရောင် / မိုးပြာ / ငွေဖြူ',
    avoidColorLabelMm: 'အညိုရင့် / အမည်း',
    outfitColorHex: 0xFF38BDF8,
    secondaryColorHex: 0xFFE0F2FE,
    outfitAsset: 'assets/images/baydin/outfit_friday.jpg',
    outfitNoteMm: 'ငွေဝင်ကောင်းပြီး ကျက်သရေရှိစေရန် မိုးပြာနု သို့မဟုတ် အဖြူ/ငွေရောင် ဝတ်စုံ ဝတ်ဆင်ပါ။',
  ),
  saturday(
    planetNumber: 7,
    mmcalWeekdayIndex: 0,
    planetYears: 10,
    labelMm: 'စနေ',
    animalMm: 'နဂါး',
    directionMm: 'အနောက်တောင်',
    sampleLettersMm: 'တ ထ ဒ ဓ န ဋ ဌ ဍ ဎ ဏ',
    flowerNameMm: 'ထန်းညွန့်နှင့် ခရေပန်း',
    flowerCount: 10,
    flowerAsset: 'assets/images/baydin/flower_saturday.jpg',
    flowerNoteMm: 'ဘုရားတွင် ထန်းညွန့် သို့မဟုတ် ခရေပန်း (၁၀) ညွန့်/ပွင့် စီ၍ ပူဇော်ပါ။',
    candleTitleMm: 'နက်ပြာ/ပျားဖယောင်းတိုင် (၁၀) တိုင်နှင့် ဆီမီး (၇) ခွက်',
    lightAsset: 'assets/images/baydin/light_saturday.jpg',
    candleNoteMm: 'စနေနေ့တွင် နက်ပြာ/ပျားဖယောင်းတိုင် (၁၀) တိုင်နှင့် မြေဆီမီးခွက် (၇) ခွက် အန္တရာယ်ကင်းစွာ ထွန်းညှိပူဇော်ပါ။',
    outfitColorLabelMm: 'နက်ပြာရောင် / မီးခိုး / အပြာရင့်',
    avoidColorLabelMm: 'အစိမ်း / အဝါတောက်',
    outfitColorHex: 0xFF3B82F6,
    secondaryColorHex: 0xFF64748B,
    outfitAsset: 'assets/images/baydin/outfit_saturday.jpg',
    outfitNoteMm: 'အခက်အခဲကျော်လွှားနိုင်ရန် နက်ပြာရောင် သို့မဟုတ် မီးခိုးနုရောင် ဝတ်စုံ ဝတ်ဆင်ပါ။',
  ),
  rahu(
    planetNumber: 8,
    mmcalWeekdayIndex: 4,
    planetYears: 12,
    labelMm: 'ရာဟု (ဗုဒ္ဓဟူး ည)',
    animalMm: 'ဟိုင်းဆင်',
    directionMm: 'အနောက်မြောက်',
    sampleLettersMm: 'ယ ရ',
    flowerNameMm: 'ရဲယိုညွန့်နှင့် ထပ်တရာပန်း',
    flowerCount: 12,
    flowerAsset: 'assets/images/baydin/flower_rahu.jpg',
    flowerNoteMm: 'ဘုရားတွင် ရဲယိုညွန့် (သို့) ထပ်တရာ/ခရေပန်း (၁၂) ညွန့် ကပ်လှူဆုတောင်းပါ။',
    candleTitleMm: 'ပျားဖယောင်းတိုင်ညို (၁၂) တိုင်နှင့် ဆီမီး (၁၂) ခွက်',
    lightAsset: 'assets/images/baydin/light_rahu.jpg',
    candleNoteMm: 'ဗုဒ္ဓဟူးည/ရာဟုအချိန်တွင် ရွှေညိုပျားဖယောင်းတိုင် (၁၂) တိုင်နှင့် မြေဆီမီး (၁၂) ခွက် ကြည်ညိုစွာ ထွန်းညှိပူဇော်ပါ။',
    outfitColorLabelMm: 'အညိုရောင် / ကြေးညို / ကော်ဖီရောင်',
    avoidColorLabelMm: 'အဖြူ / မိုးပြာ',
    outfitColorHex: 0xFFD97706,
    secondaryColorHex: 0xFF78350F,
    outfitAsset: 'assets/images/baydin/outfit_rahu.jpg',
    outfitNoteMm: 'အလုပ်အကိုင်တည်ငြိမ်စေရန် ကြေးညို၊ ကော်ဖီရောင် သို့မဟုတ် ရွှေညို ဝတ်စုံ ဝတ်ဆင်ပါ။',
  );

  const MyanmarWeekday({
    required this.planetNumber,
    required this.mmcalWeekdayIndex,
    required this.planetYears,
    required this.labelMm,
    required this.animalMm,
    required this.directionMm,
    required this.sampleLettersMm,
    required this.flowerNameMm,
    required this.flowerCount,
    required this.flowerAsset,
    required this.flowerNoteMm,
    required this.candleTitleMm,
    required this.lightAsset,
    required this.candleNoteMm,
    required this.outfitColorLabelMm,
    required this.avoidColorLabelMm,
    required this.outfitColorHex,
    required this.secondaryColorHex,
    required this.outfitAsset,
    required this.outfitNoteMm,
  });

  final int planetNumber;
  final int mmcalWeekdayIndex;
  final int planetYears;
  final String labelMm;
  final String animalMm;
  final String directionMm;
  final String sampleLettersMm;
  final String flowerNameMm;
  final int flowerCount;
  final String flowerAsset;
  final String flowerNoteMm;
  final String candleTitleMm;
  final String lightAsset;
  final String candleNoteMm;
  final String outfitColorLabelMm;
  final String avoidColorLabelMm;
  final int outfitColorHex;
  final int secondaryColorHex;
  final String outfitAsset;
  final String outfitNoteMm;
}

/// Seven traditional Myanmar Mahabote houses.
enum MahaboteHouse {
  binga(
    code: 'Binga',
    titleMm: 'ဘင်္ဂဖွား',
    houseNameMm: 'ဘင်္ဂအိမ်',
    householdFortuneMm: 'ကိုယ်တိုင်ကြိုးစားမှ အောင်မြင်မည့်ဇာတာဖြစ်ပြီး အိမ်တွင်းရေးတွင် စိတ်ရှည်သည်းခံမှုဖြင့် ဦးဆောင်နိုင်သူ ဖြစ်ပါသည်။',
    cautionMm: 'စိတ်မြန်လက်မြန် ဆုံးဖြတ်ခြင်းနှင့် မိသားစုအတွင်း စကားပြောတင်းမာခြင်းကို ရှောင်ကြဉ်ပါ။',
    mindsetMm: 'ကိုယ်တိုင်ရုန်းကန်ချင်စိတ် ပြင်းပြပြီး အရာရာကို စေ့စပ်သေချာစွာ တွေးတောပူပန်တတ်သည့် စိတ်နေစိတ်ထားရှိသည်။',
    romanceTraitMm: 'အချစ်ရေးတွင် တည်ငြိမ်စွာ စောင့်ကြည့်တတ်ပြီး စိတ်ချရသူ၊ နားလည်မှုရှိသူကိုသာ အတည်တကျ ရွေးချယ်လေ့ရှိသည်။',
    opportunityTraitMm: 'ကိုယ်ပိုင်လုပ်ငန်း၊ လက်မှုပညာနှင့် အစုရှယ်ယာမပါဘဲ တစ်ဦးတည်း စီမံခန့်ခွဲရသော လုပ်ငန်းများတွင် အထူးအောင်မြင်နိုင်သည်။',
    dangerTraitMm: 'စိတ်လိုက်မာန်ပါ စကားအချေအတင်ဖြစ်ခြင်း၊ ခရီးသွားလာစဉ် မတော်တဆထိခိုက်မှုနှင့် သူတစ်ပါးကိစ္စ ကြားဝင်ခံရခြင်းကို သတိပြုရမည်။',
  ),
  atun(
    code: 'Atun',
    titleMm: 'အထွန်းဖွား',
    houseNameMm: 'အထွန်းအိမ်',
    householdFortuneMm: 'တီထွင်ကြံဆနိုင်စွမ်း ကောင်းမွန်ပြီး မိသားစုစီးပွားရေးနှင့် ဂုဏ်သတင်း ထွန်းတောက်မည့် ဇာတာရှင် ဖြစ်ပါသည်။',
    cautionMm: 'အလုပ်များ၍ မိသားစုကျန်းမာရေးနှင့် အနားယူချိန်ကို မမေ့လျော့ရန် သတိပြုပါ။',
    mindsetMm: 'တက်ကြွထက်မြက်ပြီး အသစ်အဆန်းများကို ရှာဖွေလိုစိတ် ပြင်းထန်ကာ လူအများကြား ထင်ပေါ်လိုစိတ် ရှိတတ်သည်။',
    romanceTraitMm: 'ဆွဲဆောင်မှုကောင်းပြီး စကားပြောချိုသာသဖြင့် လူချစ်လူခင်ပေါကာ သွက်လက်ထက်မြက်သော ချစ်သူ/အိမ်ထောင်ဖက်နှင့် ဆုံတွေ့လွယ်သည်။',
    opportunityTraitMm: 'နည်းပညာ၊ ဈေးရောင်းဈေးဝယ်၊ မီဒီယာနှင့် လူမှုဆက်ဆံရေး ကျယ်ပြန့်သည့် ကဏ္ဍများတွင် ရာထူးတိုး၊ လာဘ်ပွင့်မည့် အခွင့်အလမ်းများ ပေါ်လာတတ်သည်။',
    dangerTraitMm: 'အလုပ်ဖိစီးမှုကြောင့် အိပ်ရေးပျက်ခြင်း၊ မျက်စိ/ဦးခေါင်း ဝေဒနာများနှင့် နာမည်ဂုဏ်သတင်း မနာလိုသူများ၏ စကားရှုပ်မှုကို သတိထားပါ။',
  ),
  yaza(
    code: 'Yaza',
    titleMm: 'ရာဇဖွား',
    houseNameMm: 'ရာဇအိမ်',
    householdFortuneMm: 'ဩဇာတိက္ကမရှိပြီး မိသားစုနှင့် ပတ်ဝန်းကျင်၏ လေးစားအားကိုးမှု ရရှိမည့် မင်္ဂလာဇာတာ ဖြစ်ပါသည်။',
    cautionMm: 'အလွန်အကျွံ ငွေထွက်ခြင်းနှင့် သူတစ်ပါးအတွက် အာမခံကိစ္စများကို သတိထားပါ။',
    mindsetMm: 'မာနတရားနှင့် တာဝန်ယူလိုစိတ် မြင့်မားပြီး မိသားစုအပေါ် စောင့်ရှောက်လိုစိတ် အပြည့်ရှိသော ခေါင်းဆောင်စိတ်ထား ရှိသည်။',
    romanceTraitMm: 'ဂုဏ်သိက္ခာရှိပြီး အဆင့်အတန်းညီမျှသည့် ဖူးစာရှင်နှင့် ကြုံကြိုက်တတ်သော်လည်း နှစ်ဦးစလုံး အလျှော့ပေးညှိနှိုင်းရန် လိုအပ်သည်။',
    opportunityTraitMm: 'အကြီးအကဲ၊ မိတ်ဆွေကောင်းများ၏ ထောက်ခံပံ့ပိုးမှုဖြင့် စီးပွားရေးချဲ့ထွင်ခြင်း၊ ရာထူးကြီးရရှိခြင်း အခွင့်အလမ်း ကောင်းမွန်သည်။',
    dangerTraitMm: 'မိမိအမည်နှင့် လက်မှတ်ထိုးအာမခံပေးမိခြင်း၊ ငွေကြေးစာချုပ်စာတမ်း မသေချာဘဲ ပေးချေးခြင်းကြောင့် ဆုံးရှုံးမှုအန္တရာယ်ကို အထူးရှောင်ကြဉ်ပါ။',
  ),
  adipati(
    code: 'Adipati',
    titleMm: 'အဓိပတိဖွား',
    houseNameMm: 'အဓိပတိအိမ်',
    householdFortuneMm: 'ခေါင်းဆောင်စွမ်းရည်မြင့်မားပြီး အိမ်ထောင်စုတစ်ခုလုံးကို စနစ်တကျ စီမံအုပ်ချုပ်နိုင်မည့် အမြင့်မြတ်ဆုံး အိမ်ခွင် ဖြစ်ပါသည်။',
    cautionMm: 'ကိုယ့်အယူအဆတစ်ခုတည်း မကိုင်စွဲဘဲ မိသားစုဝင်များ၏ သဘောထားကို ညှိနှိုင်းနားထောင်ပါ။',
    mindsetMm: 'အမြင်ကျယ်ပြီး ရည်မှန်းချက်ကြီးမားကာ ပြတ်သားတည်ကြည်သော စိတ်နေသဘောထားကို ပိုင်ဆိုင်ထားသည်။',
    romanceTraitMm: 'အချစ်ရေးတွင် တည်ငြိမ်လေးနက်ပြီး ဘဝတစ်လျှောက်လုံး လက်တွဲနိုင်မည့် အားကိုးရသော အိမ်ထောင်ဖက်ကို ဦးစားပေးရွေးချယ်တတ်သည်။',
    opportunityTraitMm: 'စီမံခန့်ခွဲမှု၊ အိမ်ခြံမြေ၊ စီးပွားရေးလုပ်ငန်းသစ် စတင်ခြင်းနှင့် မိသားစုပိုင်ပစ္စည်း တိုးပွားမည့် အခွင့်အလမ်းကြီးများ ရရှိနိုင်သည်။',
    dangerTraitMm: 'ခေါင်းမာပြီး သူတစ်ပါးအကြံဉာဏ်ကို လျစ်လျူရှုမိခြင်း၊ သွေးတိုး/နှလုံး ကျန်းမာရေးနှင့် မိသားစုတွင်း တင်းမာမှု မဖြစ်အောင် ထိန်းညှိပါ။',
  ),
  marana(
    code: 'Marana',
    titleMm: 'မရဏဖွား',
    houseNameMm: 'မရဏအိမ်',
    householdFortuneMm: 'အခက်အခဲများကို ရင်ဆိုင်ကျော်ဖြတ်နိုင်စွမ်း အလွန်မြင့်မားပြီး ဘာသာရေးကုသိုလ်ဖြင့် ဘဝတိုးတက်မည့် ဇာတာ ဖြစ်ပါသည်။',
    cautionMm: 'ကျန်းမာရေးဂရုစိုက်ခြင်း၊ ရေသန့်နှင့် မွေးနံပန်း ပုံမှန်ကပ်လှူခြင်းဖြင့် အညံ့များကို ပြေပျောက်စေပါ။',
    mindsetMm: 'စိတ်ထဲတွင် အထီးကျန်သလို ခံစားရတတ်ပြီး ဘဝအပြောင်းအလဲများကို နက်နက်နဲနဲ တွေးခေါ်တတ်သည့် စိတ်နေစိတ်ထားရှိသည်။',
    romanceTraitMm: 'အချစ်ရေးတွင် အပြောင်းအလဲနှင့် စိတ်ပူပန်မှု ကြုံတတ်သော်လည်း စိတ်ရှည်သည်းခံနိုင်လျှင် ဘာသာတရားကိုင်းရှိုင်းသူနှင့် တည်မြဲသောအိမ်ထောင်ရေး ရမည်။',
    opportunityTraitMm: 'အခက်အခဲများကြားမှ ကိုယ်ပိုင်အရည်အချင်းဖြင့် ပြန်လည်ထူထောင်နိုင်ပြီး နိုင်ငံခြား/ခရီးဝေးနှင့် ဘာသာရေး/ပညာရေးကဏ္ဍမှ အကျိုးကျေးဇူးရမည်။',
    dangerTraitMm: 'ကျန်းမာရေး ချို့ယွင်းမှု၊ ရေလမ်း/ညဘက်ခရီး အန္တရာယ်နှင့် စိတ်ဓာတ်ကျဆင်းမှု မဖြစ်စေရန် မွေးနံပန်း၊ ဆီမီးနှင့် ပရိတ်တရား မပြတ်ပူဇော်ပါ။',
  ),
  thike(
    code: 'Thike',
    titleMm: 'သိုက်ဖွား',
    houseNameMm: 'သိုက်အိမ်',
    householdFortuneMm: 'ပစ္စည်းဥစ္စာ စုဆောင်းမိလွယ်ပြီး အိမ်မြေယာနှင့် စီးပွားလာဘ်လာဘ မပြတ်ဝင်တတ်သော ဇာတာ ဖြစ်ပါသည်။',
    cautionMm: 'မလိုအပ်သည့် အသုံးအဖြုန်းနှင့် ပစ္စည်းအငှားအချေးကိစ္စများကို စာရင်းတိကျစွာ မှတ်သားပါ။',
    mindsetMm: 'ငွေကြေးနှင့် မိသားစုလုံခြုံရေးကို ဦးစားပေးစဉ်းစားတတ်ပြီး အေးအေးဆေးဆေး တည်ငြိမ်စွာ နေထိုင်လိုစိတ် ရှိသည်။',
    romanceTraitMm: 'ချစ်ခင်ကြင်နာမှု နွေးထွေးပြီး အိမ်ထောင်ဖက်အပေါ် သစ္စာရှိကာ ချမ်းသာသုခပြည့်စုံသည့် အိမ်ထောင်ရေးကံ ပါရှိသည်။',
    opportunityTraitMm: 'ရွှေငွေစုဆောင်းခြင်း၊ အိမ်သုံးကုန်စည်ရောင်းဝယ်ရေး၊ စားသောက်ကုန်နှင့် မိသားစုစီးပွားရေးလုပ်ငန်းများမှ ဝင်ငွေအဆက်မပြတ် တိုးပွားမည်။',
    dangerTraitMm: 'အပေါင်းအသင်းမှားပြီး ငွေအချေးအငှား ဆုံးရှုံးခြင်း၊ ခိုးယူပျောက်ရှခြင်းနှင့် အစားအသောက်မမှန်၍ အစာအိမ်ဝေဒနာဖြစ်ခြင်းကို သတိပြုပါ။',
  ),
  puti(
    code: 'Puti',
    titleMm: 'ပုတိဖွား',
    houseNameMm: 'ပုတိအိမ်',
    householdFortuneMm: 'ပေါင်းသင်းဆက်ဆံရေး ချိုသာပြီး စိတ်နှလုံးနူးညံ့သဖြင့် မိတ်ဆွေကောင်းများ၏ ကူညီမှု အမြဲရရှိတတ်ပါသည်။',
    cautionMm: 'သူတစ်ပါးစကားကြောင့် စိတ်ပူပန်လွယ်တတ်သဖြင့် မေတ္တာသုတ် ရွတ်ဖတ်ပူဇော်ပါ။',
    mindsetMm: 'စိတ်နှလုံးနူးညံ့သိမ်မွေ့ပြီး သူတစ်ပါးခံစားချက်ကို နားလည်ပေးတတ်သော်လည်း အနည်းငယ် စိတ်အားငယ်တတ်သည်။',
    romanceTraitMm: 'ချစ်သူ/မိတ်ဆွေကောင်းများ၏ ချစ်ခင်မှု အပြည့်အဝရတတ်ပြီး စကားပြောချိုသာသူ၊ ကြင်နာတတ်သူနှင့် ဖူးစာဆုံလွယ်သည်။',
    opportunityTraitMm: 'ဝန်ဆောင်မှုလုပ်ငန်း၊ အနုပညာ၊ အစားအသောက်နှင့် ပညာရေး/အတိုင်ပင်ခံကဏ္ဍများတွင် မိတ်ဆွေများ၏ တွဲခေါ်ကူညီမှုဖြင့် တိုးတက်နိုင်သည်။',
    dangerTraitMm: 'စိတ်ခံစားချက်ကြောင့် အဆုံးအဖြတ်မှားခြင်း၊ သူတစ်ပါးစကားယုံလွယ်၍ လိမ်လည်ခံရခြင်းနှင့် လေ/အအေးမိ ကျန်းမာရေးကို ဂရုစိုက်ပါ။',
  );

  const MahaboteHouse({
    required this.code,
    required this.titleMm,
    required this.houseNameMm,
    required this.householdFortuneMm,
    required this.cautionMm,
    required this.mindsetMm,
    required this.romanceTraitMm,
    required this.opportunityTraitMm,
    required this.dangerTraitMm,
  });

  final String code;
  final String titleMm;
  final String houseNameMm;
  final String householdFortuneMm;
  final String cautionMm;
  final String mindsetMm;
  final String romanceTraitMm;
  final String opportunityTraitMm;
  final String dangerTraitMm;

  static MahaboteHouse fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    return MahaboteHouse.values.firstWhere(
      (h) => h.code.toLowerCase() == normalized,
      orElse: () => MahaboteHouse.atun,
    );
  }
}

/// Gender selector used for personalized attire guidance (`တိုက်ပုံ/ပုဆိုး` vs `ရင်ဖုံး/ထဘီ`).
enum BaydinGender {
  female(labelMm: 'အမျိုးသမီး'),
  male(labelMm: 'အမျိုးသား');

  const BaydinGender({required this.labelMm});
  final String labelMm;
}

/// Specific Baydin / Yadaya consultation goal selected by the user.
enum YadayaFocus {
  generalToday(
    labelMm: 'ယနေ့ အလုံးစုံ',
    subtitleMm: 'ယနေ့ ဆောင်ရန်/ရှောင်ရန်နှင့် အဝတ်အစား',
  ),
  wealthBusiness(
    labelMm: 'စီးပွား • လာဘ်ပွင့်',
    subtitleMm: 'သိုက်အိမ်နှင့် အညွန့်နံ ငွေဝင်ယတြာ',
  ),
  loveMarriage(
    labelMm: 'အချစ် • အိမ်ထောင်',
    subtitleMm: 'ပုတိအိမ်နှင့် ဖူးစာ/မိသားစု သင့်မြတ်ယတြာ',
  ),
  careerAuthority(
    labelMm: 'အလုပ် • ရာထူးတိုး',
    subtitleMm: 'ရာဇ/အဓိပတိ ဂုဏ်သတင်းမြှင့်တင်ယတြာ',
  ),
  remedyProtection(
    labelMm: 'ဘုမ္မိ • အညံ့ပြေ',
    subtitleMm: 'အမြစ်ရေလောင်း ဘေးအန္တရာယ်ကင်း ယတြာ',
  );

  const YadayaFocus({
    required this.labelMm,
    required this.subtitleMm,
  });

  final String labelMm;
  final String subtitleMm;
}

/// Personalized authentic Sayar San Zarni Bo + Mahabote + Angavijja Yadaya prescription.
class YadayaPrescription {
  const YadayaPrescription({
    required this.formulaTitleMm,
    required this.formulaReasonMm,
    required this.flowerTitleMm,
    required this.flowerCountLabelMm,
    required this.flowerAsset,
    required this.flowerInstructionMm,
    required this.almsTitleMm,
    required this.almsAsset,
    required this.almsInstructionMm,
    required this.candleTitleMm,
    required this.candleAsset,
    required this.candleInstructionMm,
    required this.wearOutfitTitleMm,
    required this.wearOutfitAsset,
    required this.wearOutfitNoteMm,
    required this.wearPrimaryHex,
    required this.wearSecondaryHex,
    required this.avoidOutfitTitleMm,
    required this.avoidOutfitAsset,
    required this.avoidReasonMm,
    required this.avoidPrimaryHex,
    required this.avoidSecondaryHex,
  });

  final String formulaTitleMm;
  final String formulaReasonMm;
  final String flowerTitleMm;
  final String flowerCountLabelMm;
  final String flowerAsset;
  final String flowerInstructionMm;
  final String almsTitleMm;
  final String almsAsset;
  final String almsInstructionMm;
  final String candleTitleMm;
  final String candleAsset;
  final String candleInstructionMm;
  final String wearOutfitTitleMm;
  final String wearOutfitAsset;
  final String wearOutfitNoteMm;
  final int wearPrimaryHex;
  final int wearSecondaryHex;
  final String avoidOutfitTitleMm;
  final String avoidOutfitAsset;
  final String avoidReasonMm;
  final int avoidPrimaryHex;
  final int avoidSecondaryHex;
}

/// Complete Sayar San Zarni Bo style Mahabote, Yadaya, Flower, Alms, Candle Light, Wear & Avoid Outfit reading.
class BaydinReading {
  const BaydinReading({
    required this.name,
    required this.gender,
    required this.focus,
    required this.referenceDate,
    required this.todayWeekday,
    required this.nameDetectedScriptMm,
    required this.nameLetterChainMm,
    required this.birthDate,
    required this.myanmarBirthDateLabel,
    required this.myanmarBirthYear,
    required this.birthWeekday,
    required this.nameWeekday,
    required this.nameCompatibilityLabelMm,
    required this.nameCompatibilityNoteMm,
    required this.mahaboteHouse,
    required this.mahaboteChart,
    required this.rootPlanet,
    required this.tipPlanet,
    required this.runningAge,
    required this.currentThetYaukPlanet,
    required this.isBummiYear,
    required this.yadayaTargetPlanet,
    required this.prescription,
    required this.zataPositionReasonMm,
    required this.householdDetailsMm,
    required this.mindsetProfileMm,
    required this.loveRomanceForecastMm,
    required this.financeForecastMm,
    required this.opportunitiesPathMm,
    required this.risksAndDangersMm,
    required this.yadayaStepsMm,
    required this.meritCountMm,
    required this.partnerSuggestionMm,
  });

  final String name;
  final BaydinGender gender;
  final YadayaFocus focus;
  final DateTime referenceDate;
  final MyanmarWeekday todayWeekday;
  final String nameDetectedScriptMm;
  final String nameLetterChainMm;
  final DateTime birthDate;
  final String myanmarBirthDateLabel;
  final int myanmarBirthYear;
  final MyanmarWeekday birthWeekday;
  final MyanmarWeekday? nameWeekday;
  final String nameCompatibilityLabelMm;
  final String nameCompatibilityNoteMm;
  final MahaboteHouse mahaboteHouse;

  /// Full 7-house Mahabote birth chart derived from [myanmarBirthYear].
  final Map<MahaboteHouse, MyanmarWeekday> mahaboteChart;

  /// Angavijja Root planet (`အမြစ်နံ` = birth weekday - 1).
  final MyanmarWeekday rootPlanet;

  /// Angavijja Tip/Foliage planet (`အညွန့်နံ` = birth weekday + 1).
  final MyanmarWeekday tipPlanet;

  final int runningAge;
  final MyanmarWeekday currentThetYaukPlanet;
  final bool isBummiYear;

  /// Planet whose flower offering, candle lights & outfit colors best harmonize this reading.
  final MyanmarWeekday yadayaTargetPlanet;
  final YadayaPrescription prescription;

  /// Explicit explanation of *which Zata/Mahabote/Thet-Yauk* the user is standing in and *why*.
  final String zataPositionReasonMm;
  final String householdDetailsMm;
  final String mindsetProfileMm;
  final String loveRomanceForecastMm;
  final String financeForecastMm;
  final String opportunitiesPathMm;
  final String risksAndDangersMm;
  final List<String> yadayaStepsMm;
  final String meritCountMm;
  final String partnerSuggestionMm;
}

/// Daily / Monthly Myanmar Calendar Auspicious Summary (`ရက်ရာဇာ / ပြဿဒါး / ဥပုသ်နေ့`).
class CalendarDaySummary {
  const CalendarDaySummary({
    required this.date,
    required this.myanmarDateFormatted,
    required this.weekdayLabelMm,
    required this.isYatyaza,
    required this.isPyathada,
    required this.isAfternoonPyathada,
    required this.isSabbath,
    required this.isSabbathEve,
    required this.isHighlyAuspicious,
    required this.nagahleMm,
    required this.astrologicalTagsMm,
    required this.holidaysMm,
  });

  final DateTime date;
  final String myanmarDateFormatted;
  final String weekdayLabelMm;
  final bool isYatyaza;
  final bool isPyathada;
  final bool isAfternoonPyathada;
  final bool isSabbath;
  final bool isSabbathEve;
  final bool isHighlyAuspicious;
  final String nagahleMm;
  final List<String> astrologicalTagsMm;
  final List<String> holidaysMm;

  String get primaryStatusTitleMm {
    if (isSabbath && isYatyaza) return 'ဥပုသ်နေ့ • ရက်ရာဇာ (အထူးမင်္ဂလာနေ့)';
    if (isSabbath) return 'ဥပုသ်နေ့ (သီလစောင့်တည်ရန်နေ့မြတ်)';
    if (isYatyaza) return 'ရက်ရာဇာ (မင်္ဂလာကိစ္စစတင်ရန် ကောင်း)';
    if (isAfternoonPyathada) return 'မွန်းလွဲပြဿဒါး (မွန်းလွဲပိုင်း သတိပြုရန်)';
    if (isPyathada) return 'ပြဿဒါး (ကိစ္စကြီးများ ရှောင်ရှားသင့်)';
    if (isSabbathEve) return 'အဖိတ်နေ့ (မနက်ဖြန် ဥပုသ်နေ့)';
    return 'သာမန်နေ့ (နေ့စဉ်ကိစ္စ ပုံမှန်ဆောင်ရွက်နိုင်)';
  }
}
