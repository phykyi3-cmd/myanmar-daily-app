import '../models/maternal_child_models.dart';

/// WHO Weight-for-Age evaluation result (`0–60 months`).
class GrowthEvaluation {
  const GrowthEvaluation({
    required this.whoMedianKg,
    required this.statusLabelMm,
    required this.adviceMm,
    required this.isAlert,
  });

  final double whoMedianKg;
  final String statusLabelMm;
  final String adviceMm;
  final bool isAlert;
}

/// Offline clinical rules engine grounded in Myanmar MOHS EPI & WHO Child Growth Standards.
class MaternalChildEngine {
  const MaternalChildEngine();

  static const String medicalDisclaimerMm =
      'ဤကဏ္ဍပါ အချက်အလက်များသည် မြန်မာနိုင်ငံ ကျန်းမာရေးဝန်ကြီးဌာန (EPI) နှင့် ကမ္ဘာ့ကျန်းမာရေးအဖွဲ့ (WHO) စံနှုန်းများအပေါ် အခြေခံသည့် ကျန်းမာရေးမှတ်တမ်းနှင့် အကြံပြုလမ်းညွှန်ချက်သာ ဖြစ်ပါသည်။ ရောဂါရှာဖွေကုသမှု အစားထိုးမဟုတ်ပါ။ အရေးပေါ်လက္ခဏာများ တွေ့ရှိပါက နီးစပ်ရာ ဆေးရုံ/ဆေးခန်း သို့မဟုတ် ဆရာဝန်နှင့် ချက်ချင်းပြသပါ။';

  /// Official Myanmar National EPI Immunization Schedule (`0–18 months`).
  static const List<EpiVaccineTemplate> officialChildEpiTemplates = [
    EpiVaccineTemplate(
      code: 'BCG',
      nameMm: 'BCG (တီဘီကာကွယ်ဆေး)',
      doseLabelMm: 'မွေးစ - ၂ လအတွင်း',
      dueAgeDays: 0,
      protectAgainstMm: 'ပြင်းထန် တီဘီရောဂါ',
    ),
    EpiVaccineTemplate(
      code: 'HEPB_BIRTH',
      nameMm: 'HepB Birth Dose (ဘီပိုးကာကွယ်ဆေး)',
      doseLabelMm: 'မွေးပြီး ၂၄ နာရီအတွင်း',
      dueAgeDays: 1,
      protectAgainstMm: 'မိခင်မှကလေးသို့ ဘီပိုးကူးစက်ခြင်း',
    ),
    EpiVaccineTemplate(
      code: 'PENTA_1',
      nameMm: 'Pentavalent (၅ မျိုးစပ် • ၁ ကြိမ်)',
      doseLabelMm: '၂ လ',
      dueAgeDays: 60,
      protectAgainstMm: 'ဆုံဆို့၊ ကြက်ညှာ၊ မေးခိုင်၊ ဘီပိုး၊ Hib',
    ),
    EpiVaccineTemplate(
      code: 'OPV_1',
      nameMm: 'OPV (ပိုလီယို အစက်ချ • ၁ ကြိမ်)',
      doseLabelMm: '၂ လ',
      dueAgeDays: 60,
      protectAgainstMm: 'ပိုလီယို အကြောသေရောဂါ',
    ),
    EpiVaccineTemplate(
      code: 'PCV_1',
      nameMm: 'PCV (အဆုတ်ရောင် • ၁ ကြိမ်)',
      doseLabelMm: '၂ လ',
      dueAgeDays: 60,
      protectAgainstMm: 'ပြင်းထန်အဆုတ်ရောင်နှင့် နားအူရောင်',
    ),
    EpiVaccineTemplate(
      code: 'ROTA_1',
      nameMm: 'Rotavirus (ဝမ်းလျှော • ၁ ကြိမ်)',
      doseLabelMm: '၂ လ',
      dueAgeDays: 60,
      protectAgainstMm: 'ရိုတာဗိုင်းရပ်စ် ဝမ်းပျက်ဝမ်းလျှော',
    ),
    EpiVaccineTemplate(
      code: 'PENTA_2',
      nameMm: 'Pentavalent (၅ မျိုးစပ် • ၂ ကြိမ်)',
      doseLabelMm: '၄ လ',
      dueAgeDays: 120,
      protectAgainstMm: 'ဆုံဆို့၊ ကြက်ညှာ၊ မေးခိုင်၊ ဘီပိုး၊ Hib',
    ),
    EpiVaccineTemplate(
      code: 'OPV_2',
      nameMm: 'OPV (ပိုလီယို အစက်ချ • ၂ ကြိမ်)',
      doseLabelMm: '၄ လ',
      dueAgeDays: 120,
      protectAgainstMm: 'ပိုလီယို အကြောသေရောဂါ',
    ),
    EpiVaccineTemplate(
      code: 'IPV_1',
      nameMm: 'IPV (ပိုလီယို ထိုးဆေး)',
      doseLabelMm: '၄ လ',
      dueAgeDays: 120,
      protectAgainstMm: 'ပိုလီယို အကြောသေရောဂါ ထပ်ဆောင်းကာကွယ်မှု',
    ),
    EpiVaccineTemplate(
      code: 'PCV_2',
      nameMm: 'PCV (အဆုတ်ရောင် • ၂ ကြိမ်)',
      doseLabelMm: '၄ လ',
      dueAgeDays: 120,
      protectAgainstMm: 'ပြင်းထန်အဆုတ်ရောင်',
    ),
    EpiVaccineTemplate(
      code: 'ROTA_2',
      nameMm: 'Rotavirus (ဝမ်းလျှော • ၂ ကြိမ်)',
      doseLabelMm: '၄ လ',
      dueAgeDays: 120,
      protectAgainstMm: 'ရိုတာဗိုင်းရပ်စ် ဝမ်းပျက်ဝမ်းလျှော',
    ),
    EpiVaccineTemplate(
      code: 'PENTA_3',
      nameMm: 'Pentavalent (၅ မျိုးစပ် • ၃ ကြိမ်)',
      doseLabelMm: '၆ လ',
      dueAgeDays: 180,
      protectAgainstMm: 'ဆုံဆို့၊ ကြက်ညှာ၊ မေးခိုင်၊ ဘီပိုး၊ Hib',
    ),
    EpiVaccineTemplate(
      code: 'OPV_3',
      nameMm: 'OPV (ပိုလီယို အစက်ချ • ၃ ကြိမ်)',
      doseLabelMm: '၆ လ',
      dueAgeDays: 180,
      protectAgainstMm: 'ပိုလီယို အကြောသေရောဂါ',
    ),
    EpiVaccineTemplate(
      code: 'PCV_3',
      nameMm: 'PCV (အဆုတ်ရောင် • ၃ ကြိမ်)',
      doseLabelMm: '၆ လ',
      dueAgeDays: 180,
      protectAgainstMm: 'ပြင်းထန်အဆုတ်ရောင်',
    ),
    EpiVaccineTemplate(
      code: 'MR_1',
      nameMm: 'MR (ဝက်သက်-ဂျိုက်သိုး • ၁ ကြိမ်)',
      doseLabelMm: '၉ လ',
      dueAgeDays: 270,
      protectAgainstMm: 'ဝက်သက်နှင့် ဂျိုက်သိုးရောဂါ',
    ),
    EpiVaccineTemplate(
      code: 'JE_1',
      nameMm: 'JE (ဂျပန်ဦးနှောက်ရောင်)',
      doseLabelMm: '၉ လ',
      dueAgeDays: 270,
      protectAgainstMm: 'ဂျပန်ဦးနှောက်ရောင်ရောဂါ',
    ),
    EpiVaccineTemplate(
      code: 'MR_2',
      nameMm: 'MR (ဝက်သက်-ဂျိုက်သိုး • ၂ ကြိမ်)',
      doseLabelMm: '၁၈ လ (၁ နှစ်ခွဲ)',
      dueAgeDays: 548,
      protectAgainstMm: 'ဝက်သက်နှင့် ဂျိုက်သိုးရောဂါ ရေရှည်ခုခံအား',
    ),
    EpiVaccineTemplate(
      code: 'PENTA_BOOSTER',
      nameMm: 'Pentavalent Booster (အားဖြည့်)',
      doseLabelMm: '၁၈ လ (၁ နှစ်ခွဲ)',
      dueAgeDays: 548,
      protectAgainstMm: 'ဆုံဆို့၊ ကြက်ညှာ၊ မေးခိုင်၊ ဘီပိုး၊ Hib အားဖြည့်',
    ),
  ];

  /// Maternal Antenatal Td & ANC checkpoint schedule anchored to LMP date.
  static const List<EpiVaccineTemplate> officialMotherAncTemplates = [
    EpiVaccineTemplate(
      code: 'ANC_1',
      nameMm: 'သားဖွားဆေးခန်း ပထမအကြိမ် စစ်ဆေးမှု (ANC-1)',
      doseLabelMm: 'ကိုယ်ဝန် ၈–၁၂ ပတ်',
      dueAgeDays: 70,
      protectAgainstMm: 'သွေးအုပ်စု၊ သွေးအားနည်း/ဆီးချိုနှင့် ဖောလစ်အက်စစ် စတင်ရန်',
    ),
    EpiVaccineTemplate(
      code: 'TD_1',
      nameMm: 'Td 1 (မေးခိုင်-ဆုံဆို့ မိခင်ကာကွယ်ဆေး ပထမအကြိမ်)',
      doseLabelMm: 'ကိုယ်ဝန် ၁၆–၂၀ ပတ်',
      dueAgeDays: 120,
      protectAgainstMm: 'မွေးကင်းစနှင့် မိခင် မေးခိုင်ရောဂါကာကွယ်မှု',
    ),
    EpiVaccineTemplate(
      code: 'TD_2',
      nameMm: 'Td 2 (မေးခိုင်-ဆုံဆို့ ဒုတိယအကြိမ် — ၄ ပတ်အကြာ)',
      doseLabelMm: 'ကိုယ်ဝန် ၂၀–၂၄ ပတ်',
      dueAgeDays: 148,
      protectAgainstMm: 'မိခင်နှင့် ကလေး မေးခိုင်ခုခံအား ပြည့်ဝစေရန်',
    ),
    EpiVaccineTemplate(
      code: 'ANC_28W',
      nameMm: 'ANC ၂၈ ပတ် စစ်ဆေးမှုနှင့် သံဓာတ်ဆေး',
      doseLabelMm: 'ကိုယ်ဝန် ၂၈ ပတ်',
      dueAgeDays: 196,
      protectAgainstMm: 'သွေးပေါင်ချိန်၊ ကိုယ်ဝန်ဆီးချိုနှင့် ကလေးကြီးထွားမှုစစ်ဆေးရန်',
    ),
    EpiVaccineTemplate(
      code: 'ANC_36W',
      nameMm: 'မွေးဖွားရန် အကြိုစစ်ဆေးမှု (ANC ၃၆ ပတ်)',
      doseLabelMm: 'ကိုယ်ဝန် ၃၆ ပတ်',
      dueAgeDays: 252,
      protectAgainstMm: 'ကလေးအနေအထားနှင့် မွေးဖွားမည့်ဆေးရုံ ပြင်ဆင်မှု',
    ),
  ];

  /// WHO Child Growth Standards 50th percentile Weight-for-Age (`0–60 months`).
  static const List<(int months, double boyKg, double girlKg)> whoWeightAnchors = [
    (0, 3.3, 3.2),
    (3, 6.4, 5.8),
    (6, 7.9, 7.3),
    (9, 8.9, 8.2),
    (12, 9.6, 8.9),
    (18, 10.9, 10.2),
    (24, 12.2, 11.5),
    (36, 14.3, 13.9),
    (48, 16.3, 16.1),
    (60, 18.3, 18.2),
  ];

  static const List<PregnancyTrimesterGuide> trimesterGuides = [
    PregnancyTrimesterGuide(
      trimester: 1,
      titleMm: 'ပထမ ၃ လပတ် (သီတင်းပတ် ၁ မှ ၁၃ ပတ်)',
      babyGrowthMm:
          'သန္ဓေသားလောင်း၏ ဦးနှောက်၊ နှလုံးနှင့် အဓိကအင်္ဂါများ စတင်ဖွဲ့စည်းနေချိန် ဖြစ်ပါသည်။',
      motherCareMm:
          'ဖောလစ်အက်စစ် (Folic Acid) နေ့စဉ်မှန်မှန်သောက်ပါ။ ပျို့အန်တတ်လျှင် နည်းနည်းစီ ခွဲစားပြီး ရေဓာတ်ပြည့်အောင် သောက်ပါ။ ဆရာဝန်ညွှန်ကြားချက်မပါဘဲ မည်သည့်ဆေးမျှ မသောက်ပါနှင့်။',
      ancVisitReminderMm: 'သားဖွား/မီးယပ်ဆရာဝန်နှင့် ပထမအကြိမ် ANC စစ်ဆေးမှု ခံယူပါ။',
    ),
    PregnancyTrimesterGuide(
      trimester: 2,
      titleMm: 'ဒုတိယ ၃ လပတ် (သီတင်းပတ် ၁၄ မှ ၂၇ ပတ်)',
      babyGrowthMm:
          'ကလေးလှုပ်ရှားမှု စတင်ခံစားရပြီး အရိုးနှင့် ကြွက်သားများ သန်မာကြီးထွားလာချိန် ဖြစ်ပါသည်။',
      motherCareMm:
          'သံဓာတ်နှင့် ကယ်လ်စီယမ်ကြွယ်ဝသော ငါး၊ အစိမ်းရောင်ဟင်းသီးဟင်းရွက်၊ ကြက်ဥနှင့် နို့ထွက်ပစ္စည်းများ ပိုစားပါ။ Td ကာကွယ်ဆေး (၂) ကြိမ် ထိုးနှံပါ။',
      ancVisitReminderMm:
          '၁၈–၂၂ ပတ် Ultrasound နှင့် ၂၄–၂၈ ပတ် သွေးချို/သွေးပေါင် စစ်ဆေးမှု ပြုလုပ်ပါ။',
    ),
    PregnancyTrimesterGuide(
      trimester: 3,
      titleMm: 'တတိယ ၃ လပတ် (သီတင်းပတ် ၂၈ မှ ၄၀+ ပတ်)',
      babyGrowthMm:
          'ကလေးကိုယ်အလေးချိန် အမြန်ဆုံးတက်ပြီး မွေးဖွားရန် ဦးခေါင်းအောက်လှည့် ပြင်ဆင်ချိန် ဖြစ်ပါသည်။',
      motherCareMm:
          'နေ့စဉ် ကလေးကန်ချက်/လှုပ်ရှားမှု (`Kick Count`) ကို ဂရုစိုက်မှတ်သားပါ။ ဘေးတစောင်း (ဘယ်ဘက်) အိပ်စက်ပါ။ ဆေးရုံသွားမည့် အိတ်နှင့် မှတ်ပုံတင်/ANC စာအုပ် အဆင်သင့်ထားပါ။',
      ancVisitReminderMm:
          '၃၆ ပတ်နောက်ပိုင်း အပတ်စဉ် သွေးပေါင်ချိန်နှင့် ကလေးအနေအထား စစ်ဆေးပါ။',
    ),
  ];

  static const List<String> maternalDangerSignsMm = [
    'မွေးလမ်းကြောင်းမှ သွေးဆင်းခြင်း သို့မဟုတ် ရေမွှာပေါက်ခြင်း',
    'ပြင်းထန်စွာ ခေါင်းကိုက်ခြင်း၊ မျက်စိပြာ/ဝါးခြင်း (သွေးဆိပ်တက်လက္ခဏာ)',
    'ခြေလက်နှင့် မျက်နှာ ရုတ်တရက် အလွန်ဖောရောင်ခြင်း',
    'ကလေးလှုပ်ရှားမှု သိသိသာသာ နည်းသွားခြင်း (သို့) လုံးဝမလှုပ်ခြင်း',
    'အဖျားကြီးခြင်း သို့မဟုတ် ဗိုက်အလွန်နာကျင်တောင့်တင်းခြင်း',
  ];

  static const List<ChildMilestoneStage> childMilestones = [
    ChildMilestoneStage(
      ageRangeLabelMm: '၀ – ၃ လ (မွေးကင်းစ)',
      minMonths: 0,
      maxMonths: 3,
      milestonesMm: [
        'မျက်နှာချင်းဆိုင်ကြည့်ပြီး ပြုံးပြခြင်း',
        'အသံကြားရာဘက်သို့ ခေါင်းလှည့်ကြည့်ခြင်း',
        'မှောက်လျက်ထားလျှင် ခေါင်းကို အနည်းငယ် ထောင်နိုင်ခြင်း',
      ],
    ),
    ChildMilestoneStage(
      ageRangeLabelMm: '၄ – ၆ လ',
      minMonths: 4,
      maxMonths: 6,
      milestonesMm: [
        'ခေါင်းကို ခိုင်မာစွာ ထိန်းထားနိုင်ပြီး တစ်ဖက်သို့ လှိမ့်နိုင်ခြင်း',
        'အရုပ်များကို လက်ဖြင့် လှမ်းကိုင်ခြင်း',
        '၆ လပြည့်လျှင် မိခင်နို့အပြင် ဖြည့်စွက်စာ စတင်စားနိုင်ခြင်း',
      ],
    ),
    ChildMilestoneStage(
      ageRangeLabelMm: '၇ – ၁၂ လ',
      minMonths: 7,
      maxMonths: 12,
      milestonesMm: [
        'အကူမပါဘဲ ထိုင်နိုင်ခြင်းနှင့် တွားသွားနိုင်ခြင်း',
        'မေမေ / ဖေဖေ စသည့် စကားလုံးတိုများ စတင်ပြောခြင်း',
        'ပစ္စည်းသေးများကို လက်ညှိုးနှင့် လက်မညှပ်၍ ကောက်ယူနိုင်ခြင်း',
      ],
    ),
    ChildMilestoneStage(
      ageRangeLabelMm: '၁၃ – ၂၄ လ (၁–၂ နှစ်)',
      minMonths: 13,
      maxMonths: 24,
      milestonesMm: [
        'ကိုယ်တိုင် လမ်းလျှောက်နိုင်ခြင်း',
        'စကားလုံး ၁၀–၂၀ လုံးအထက် ပြောနိုင်ခြင်းနှင့် အမေးကို နားလည်ခြင်း',
        'ဇွန်းကိုင်၍ အစားစားရန် ကြိုးစားခြင်း',
      ],
    ),
    ChildMilestoneStage(
      ageRangeLabelMm: '၂ – ၅ နှစ်',
      minMonths: 25,
      maxMonths: 60,
      milestonesMm: [
        'ဝါကျတိုများ ပြောနိုင်ခြင်းနှင့် မေးခွန်းများ မေးခြင်း',
        'ပြေးလွှားခုန်ပေါက်နိုင်ခြင်းနှင့် လှေကားတက်နိုင်ခြင်း',
        'အရောင်နှင့် ပုံသဏ္ဌာန်များ ခွဲခြားသိမြင်ခြင်း',
      ],
    ),
  ];

  static const List<NutritionGuideMeal> nutritionMeals = [
    NutritionGuideMeal(
      id: 'preg_fish_greens',
      titleMm: 'ကိုယ်ဝန်ဆောင် ငါးခူမုန်ညင်းစိမ်း ဟင်းချို',
      stageLabelMm: 'ကိုယ်ဝန်ဆောင် & နို့တိုက်မိခင်',
      forMother: true,
      minChildAgeMonths: 0,
      keyNutrientsMm: 'သံဓာတ်၊ ကယ်လ်စီယမ်၊ ဖောလိတ်နှင့် အိုမီဂါ-၃ DHA',
      prepStepsMm:
          '၁။ ငါးခူကို နနွင်း၊ ဂျင်းနှင့် သန့်စင်စွာ နယ်ပါ။\n၂။ ကြက်သွန်ဖြူ ဓားပြားရိုက် ဆီသတ်ပြီး ရေနွေးဆူထဲ ထည့်ပြုတ်ပါ။\n၃။ မုန်ညင်းစိမ်း ထည့်ပြီး ခေတ္တဆူလျှင် ပူပူနွေးနွေး သုံးဆောင်ပါ။',
      ingredients: [
        NutritionIngredient(nameMm: 'ငါးခူ / ငါးရံ့', quantityMm: '၃၀ ကျပ်သား', estimatedCostMmk: 5500),
        NutritionIngredient(nameMm: 'မုန်ညင်းစိမ်း', quantityMm: '၂ စည်း', estimatedCostMmk: 1200),
        NutritionIngredient(nameMm: 'ဂျင်းနှင့် ကြက်သွန်ဖြူ', quantityMm: 'အနည်းငယ်', estimatedCostMmk: 800),
      ],
    ),
    NutritionGuideMeal(
      id: 'lactating_chicken_gourd',
      titleMm: 'နို့တိုက်မိခင် ကြက်သားဘူးသီး ဟင်းခါး',
      stageLabelMm: 'နို့တိုက်မိခင် (နို့ထွက်ကောင်းစေရန်)',
      forMother: true,
      minChildAgeMonths: 0,
      keyNutrientsMm: 'ပရိုတင်း၊ ရေဓာတ်နှင့် မိခင်နို့ရည် အားဖြည့်ဓာတ်',
      prepStepsMm:
          '၁။ ကြက်ရင်ပုံသားကို ငရုတ်ကောင်းနှင့် ဂျင်းထည့်၍ နူးအောင်ပြုတ်ပါ။\n၂။ ဘူးသီးနုနု ထည့်၍ နူးလျှင် မိခင်အတွက် ပူပူနွေးနွေး တိုက်ကျွေးပါ။',
      ingredients: [
        NutritionIngredient(nameMm: 'ကြက်ရင်ပုံသား', quantityMm: '၂၅ ကျပ်သား', estimatedCostMmk: 4800),
        NutritionIngredient(nameMm: 'ဘူးသီးနု', quantityMm: '၁ စိတ်', estimatedCostMmk: 1000),
        NutritionIngredient(nameMm: 'ငရုတ်ကောင်းနှင့် ဂျင်း', quantityMm: 'အနည်းငယ်', estimatedCostMmk: 600),
      ],
    ),
    NutritionGuideMeal(
      id: 'baby_6m_rice_pumpkin',
      titleMm: '၆ လ+ ရွှေဖရုံသီးနှင့် ဆန်ပြုတ်နု (ဆားမထည့်)',
      stageLabelMm: 'ကလေး ၆ – ၈ လ (ဖြည့်စွက်စာ)',
      forMother: false,
      minChildAgeMonths: 6,
      keyNutrientsMm: 'ဗီတာမင် A၊ ကစီဓာတ်နှင့် အစာကြေလွယ် စွမ်းအင်',
      prepStepsMm:
          '၁။ ဆန်နုကို ရေသန့်ဖြင့် ပြုတ်ပြီး ဖရုံသီးနုနု ရောပြုတ်ပါ။\n၂။ နူးအိလျှင် ဇကာတိုက်/ကြိတ်ချေပြီး မိခင်နို့ သို့မဟုတ် သံလွင်ဆီ ၂ စက် ထည့်ကျွေးပါ (ဆား/အချိုမှုန့် မထည့်ရ)။',
      ingredients: [
        NutritionIngredient(nameMm: 'ဆန်ချော', quantityMm: '၁ နို့ဆီဗူး', estimatedCostMmk: 1200),
        NutritionIngredient(nameMm: 'ရွှေဖရုံသီး', quantityMm: '၁ စိတ်', estimatedCostMmk: 800),
      ],
    ),
    NutritionGuideMeal(
      id: 'baby_8m_fish_egg',
      titleMm: '၈ လ+ ငါးရံ့ ကြက်ဥအနှစ် ဟင်းနုနွယ်ဆန်ပြုတ်',
      stageLabelMm: 'ကလေး ၈ – ၁၁ လ',
      forMother: false,
      minChildAgeMonths: 8,
      keyNutrientsMm: 'သံဓာတ်၊ ဦးနှောက်ဖွံ့ဖြိုးမှု DHA နှင့် ပရိုတင်း',
      prepStepsMm:
          '၁။ အရိုးစင်အောင်ထွင်ထားသော ငါးရံ့သားနှင့် ဟင်းနုနွယ်ရွက်နုကို ဆန်ပြုတ်ထဲ ထည့်ပြုတ်ပါ။\n၂။ ကြက်ဥအနှစ် ကျက်အောင်မွှေထည့်ပြီး ပူနွေးနွေး ကျွေးပါ။',
      ingredients: [
        NutritionIngredient(nameMm: 'ငါးရံ့အသားလွှာ (အရိုးစင်)', quantityMm: '၁၀ ကျပ်သား', estimatedCostMmk: 2500),
        NutritionIngredient(nameMm: 'ဟင်းနုနွယ်ရွက်နု', quantityMm: '၁ စည်း', estimatedCostMmk: 600),
        NutritionIngredient(nameMm: 'ကြက်ဥ', quantityMm: '၂ လုံး', estimatedCostMmk: 1000),
      ],
    ),
    NutritionGuideMeal(
      id: 'toddler_12m_soft_rice',
      titleMm: '၁ နှစ်+ ကြက်သား မုန်လာဥနီ ပဲနီလေး ထမင်းပျော့',
      stageLabelMm: 'ကလေး ၁ – ၅ နှစ်',
      forMother: false,
      minChildAgeMonths: 12,
      keyNutrientsMm: 'ပရိုတင်း၊ သံဓာတ်၊ ဇင့်နှင့် အမျှင်ဓာတ်',
      prepStepsMm:
          '၁။ ပဲနီလေးနှင့် နုတ်နုတ်စင်းထားသော ကြက်သား၊ မုန်လာဥနီတို့ကို နူးအိအောင် ချက်ပါ။\n၂။ ထမင်းပျော့ပျော့ဖြင့် ရောနယ်၍ ကလေးကိုယ်တိုင် စားတတ်အောင် ကျွေးပါ။',
      ingredients: [
        NutritionIngredient(nameMm: 'ကြက်သားစင်းကော', quantityMm: '၁၅ ကျပ်သား', estimatedCostMmk: 3000),
        NutritionIngredient(nameMm: 'ပဲနီလေး', quantityMm: '၁၀ ကျပ်သား', estimatedCostMmk: 1200),
        NutritionIngredient(nameMm: 'မုန်လာဥနီ', quantityMm: '၁ လုံး', estimatedCostMmk: 700),
      ],
    ),
  ];

  /// Builds initial EPI or Maternal ANC vaccine schedule records anchored to [profile.referenceDate].
  List<ImmunizationRecord> buildInitialImmunizationSchedule(
    FamilyHealthProfile profile,
  ) {
    final profileId = profile.id ?? 0;
    final templates = profile.profileType == HealthProfileType.motherPregnancy
        ? officialMotherAncTemplates
        : officialChildEpiTemplates;

    return templates
        .map(
          (t) => ImmunizationRecord(
            profileId: profileId,
            vaccineCode: t.code,
            vaccineNameMm: t.nameMm,
            doseLabelMm: t.doseLabelMm,
            protectAgainstMm: t.protectAgainstMm,
            dueAgeDays: t.dueAgeDays,
            dueDate: profile.referenceDate.add(Duration(days: t.dueAgeDays)),
          ),
        )
        .toList();
  }

  /// Linearly interpolates the WHO 50th percentile Weight-for-Age (`kg`) for [ageMonths].
  double interpolateWhoMedianWeightKg(int ageMonths, ChildGender gender) {
    final m = ageMonths.clamp(0, 60);
    for (var i = 0; i < whoWeightAnchors.length; i++) {
      final (m0, boy0, girl0) = whoWeightAnchors[i];
      if (m == m0) return gender == ChildGender.boy ? boy0 : girl0;
      if (i + 1 < whoWeightAnchors.length) {
        final (m1, boy1, girl1) = whoWeightAnchors[i + 1];
        if (m > m0 && m < m1) {
          final frac = (m - m0) / (m1 - m0);
          final v0 = gender == ChildGender.boy ? boy0 : girl0;
          final v1 = gender == ChildGender.boy ? boy1 : girl1;
          return double.parse((v0 + (v1 - v0) * frac).toStringAsFixed(1));
        }
      }
    }
    final last = whoWeightAnchors.last;
    return gender == ChildGender.boy ? last.$2 : last.$3;
  }

  /// Compares measured child weight (`kg`) against WHO `0–60 month` median.
  GrowthEvaluation evaluateChildWeight({
    required double weightKg,
    required int ageMonths,
    required ChildGender gender,
  }) {
    final median = interpolateWhoMedianWeightKg(ageMonths, gender);
    if (ageMonths > 60) {
      return GrowthEvaluation(
        whoMedianKg: median,
        statusLabelMm: '၅ နှစ်အထက် ကလေး (WHO 0–60 လ စံနှုန်းပြင်ပ)',
        adviceMm:
            'ကလေးအသက် ($ageMonths လ) သည် WHO 0–60 လ (၅ နှစ်) စံနှုန်းအပိုင်းအခြားထက် ကျော်လွန်နေသဖြင့် ကျောင်းနေအရွယ် BMI-for-Age ကို ဆရာဝန်နှင့် စစ်ဆေးပါ။',
        isAlert: false,
      );
    }
    final ratio = weightKg / median;
    if (ratio < 0.80) {
      return GrowthEvaluation(
        whoMedianKg: median,
        statusLabelMm: 'WHO စံနှုန်းထက် အနည်းငယ် နည်းနေသည်',
        adviceMm:
            'အသက် ($ageMonths) လ WHO ပျမ်းမျှ ($median kg) ထက် လျော့နည်းနေသဖြင့် အာဟာရဖြည့်စွက်ကျွေးမှုနှင့် ကလေးဆရာဝန်/ကျန်းမာရေးမှူးထံ ပြသစစ်ဆေးသင့်ပါသည်။',
        isAlert: true,
      );
    }
    if (ratio > 1.25) {
      return GrowthEvaluation(
        whoMedianKg: median,
        statusLabelMm: 'WHO စံနှုန်းထက် ကိုယ်အလေးချိန် များနေသည်',
        adviceMm:
            'အသက် ($ageMonths) လ WHO ပျမ်းမျှ ($median kg) ထက် များနေသဖြင့် သကြားနှင့် ဆီအဆီများ လျှော့ချ၍ ဆရာဝန်နှင့် တိုင်ပင်စစ်ဆေးပါ။',
        isAlert: true,
      );
    }
    return GrowthEvaluation(
      whoMedianKg: median,
      statusLabelMm: 'WHO ကြီးထွားမှုစံနှုန်းအတွင်း ပုံမှန်ကောင်းမွန်',
      adviceMm:
          'အသက် ($ageMonths) လ WHO ပျမ်းမျှ ($median kg) နှင့် ကိုက်ညီကောင်းမွန်နေပါသည်။ ဆက်လက်မှတ်တမ်းတင်ပါ။',
      isAlert: false,
    );
  }

  PregnancyTrimesterGuide guideForWeek(int gestationalWeek) {
    final tri = gestationalWeek <= 13
        ? 1
        : (gestationalWeek <= 27 ? 2 : 3);
    return trimesterGuides.firstWhere(
      (g) => g.trimester == tri,
      orElse: () => trimesterGuides.first,
    );
  }

  ChildMilestoneStage milestoneStageForMonths(int ageMonths) {
    return childMilestones.firstWhere(
      (s) => ageMonths >= s.minMonths && ageMonths <= s.maxMonths,
      orElse: () => childMilestones.last,
    );
  }

  /// Formats a concise clinical SBAR summary ready for in-person clinics or Phase 2 Telehealth intake.
  String buildSbarConsultSummary({
    required FamilyHealthProfile profile,
    required List<ImmunizationRecord> records,
    required HealthGrowthLog? latestLog,
    String customConcern = '',
    DateTime? now,
  }) {
    final completedCount = records.where((r) => r.isCompleted).length;
    final nextDue = records.where((r) => !r.isCompleted).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final nextLine = nextDue.isEmpty
        ? 'All scheduled doses completed'
        : '${nextDue.first.vaccineNameMm} (${nextDue.first.dueDate.toIso8601String().split('T').first})';
    final vitalsLine = latestLog == null
        ? 'No vitals logged yet'
        : [
            if (latestLog.weightKg != null) 'Wt: ${latestLog.weightKg} kg',
            if (latestLog.heightCm != null) 'Ht: ${latestLog.heightCm} cm',
            if (latestLog.bpSystolic != null && latestLog.bpDiastolic != null)
              'BP: ${latestLog.bpSystolic}/${latestLog.bpDiastolic} mmHg',
            if (latestLog.symptomsNote.trim().isNotEmpty)
              'Note: ${latestLog.symptomsNote.trim()}',
          ].join(' | ');

    final lines = <String>[
      'MYANMAR DAILY - CLINIC CONSULT SUMMARY',
      'Patient: ${profile.name} (${profile.ageOrStageSummaryMm(now)})',
      if (profile.bloodType.trim().isNotEmpty) 'Blood Group: ${profile.bloodType}',
      if (profile.allergyNote.trim().isNotEmpty) 'Allergies: ${profile.allergyNote}',
      'Immunization: $completedCount/${records.length} done | Next: $nextLine',
      'Latest Vitals: $vitalsLine',
      if (customConcern.trim().isNotEmpty) 'Reason/Concern: ${customConcern.trim()}',
    ];
    return lines.join('\n');
  }
}
