import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import 'package:myanmar_daily_app/domain/models/baydin_reading.dart';

/// Deterministic offline engine for Myanmar Calendar (ရက်ရာဇာ/ပြဿဒါး/ဥပုသ်),
/// Sayar San Zarni Bo style Mahabote, Current-Age Thet-Yauk, Name-Day analysis,
/// Pagoda Flower offerings, and Auspicious Clothing guidance.
class MyanmarBaydinEngine {
  MyanmarBaydinEngine();

  /// Clockwise 8-planet ring used in Myanmar Thet-Yauk calculations.
  static const List<MyanmarWeekday> thetYaukRing = [
    MyanmarWeekday.sunday,
    MyanmarWeekday.monday,
    MyanmarWeekday.tuesday,
    MyanmarWeekday.wednesday,
    MyanmarWeekday.saturday,
    MyanmarWeekday.thursday,
    MyanmarWeekday.rahu,
    MyanmarWeekday.friday,
  ];

  static const Map<MyanmarWeekday, MyanmarWeekday> _friendPairs = {
    MyanmarWeekday.sunday: MyanmarWeekday.thursday,
    MyanmarWeekday.thursday: MyanmarWeekday.sunday,
    MyanmarWeekday.monday: MyanmarWeekday.wednesday,
    MyanmarWeekday.wednesday: MyanmarWeekday.monday,
    MyanmarWeekday.tuesday: MyanmarWeekday.friday,
    MyanmarWeekday.friday: MyanmarWeekday.tuesday,
    MyanmarWeekday.saturday: MyanmarWeekday.rahu,
    MyanmarWeekday.rahu: MyanmarWeekday.saturday,
  };

  static const Map<MyanmarWeekday, MyanmarWeekday> _enemyPairs = {
    MyanmarWeekday.sunday: MyanmarWeekday.tuesday,
    MyanmarWeekday.tuesday: MyanmarWeekday.sunday,
    MyanmarWeekday.monday: MyanmarWeekday.thursday,
    MyanmarWeekday.thursday: MyanmarWeekday.monday,
    MyanmarWeekday.friday: MyanmarWeekday.saturday,
    MyanmarWeekday.saturday: MyanmarWeekday.friday,
    MyanmarWeekday.wednesday: MyanmarWeekday.rahu,
    MyanmarWeekday.rahu: MyanmarWeekday.wednesday,
  };

  static const Map<MyanmarWeekday, MyanmarWeekday> _spouseMatchPairs = {
    MyanmarWeekday.sunday: MyanmarWeekday.friday,
    MyanmarWeekday.friday: MyanmarWeekday.sunday,
    MyanmarWeekday.tuesday: MyanmarWeekday.thursday,
    MyanmarWeekday.thursday: MyanmarWeekday.tuesday,
    MyanmarWeekday.saturday: MyanmarWeekday.wednesday,
    MyanmarWeekday.wednesday: MyanmarWeekday.saturday,
    MyanmarWeekday.monday: MyanmarWeekday.rahu,
    MyanmarWeekday.rahu: MyanmarWeekday.monday,
  };

  static void _ensureMyanmarLanguageConfigured() {
    MyanmarCalendar.configure(language: Language.myanmar);
  }

  /// Resolves the Myanmar weekday from a Gregorian [DateTime].
  MyanmarWeekday weekdayFromDate(
    DateTime date, {
    bool isWednesdayNightRahu = false,
  }) {
    switch (date.weekday) {
      case DateTime.sunday:
        return MyanmarWeekday.sunday;
      case DateTime.monday:
        return MyanmarWeekday.monday;
      case DateTime.tuesday:
        return MyanmarWeekday.tuesday;
      case DateTime.wednesday:
        return isWednesdayNightRahu
            ? MyanmarWeekday.rahu
            : MyanmarWeekday.wednesday;
      case DateTime.thursday:
        return MyanmarWeekday.thursday;
      case DateTime.friday:
        return MyanmarWeekday.friday;
      case DateTime.saturday:
      default:
        return MyanmarWeekday.saturday;
    }
  }

  /// Extracts the Myanmar planet weekday from the leading core consonant of [rawName],
  /// supporting both Burmese Unicode and English/Romanized Myanmar names.
  MyanmarWeekday? weekdayFromName(String rawName) {
    final cleaned = _stripHonorifics(rawName);
    if (cleaned.isEmpty) return null;

    // 1) Check Burmese Unicode consonants first if Burmese letters are present.
    for (final rune in cleaned.runes) {
      final ch = String.fromCharCode(rune);
      final matched = _weekdayForBurmeseChar(ch);
      if (matched != null) return matched;
    }

    // 2) Fallback to English / Romanized Burmese phonetic onset consonants.
    final latin = _firstRomanizedWord(cleaned);
    if (latin == null) return null;
    return _weekdayForRomanizedOnset(latin).$1;
  }

  String _stripHonorifics(String rawName) {
    var trimmed = rawName.trim();
    if (trimmed.isEmpty) return '';

    const spacedMmTitles = ['မောင် ', 'ကို ', 'မ ', 'ဦး ', 'ဒေါ် ', 'ဆရာ ', 'ဒေါက်တာ '];
    for (final title in spacedMmTitles) {
      if (trimmed.startsWith(title)) {
        final rest = trimmed.substring(title.length).trimLeft();
        if (rest.isNotEmpty) {
          trimmed = rest;
          break;
        }
      }
    }

    // Strip unbroken Burmese prefixes ('ဦး', 'ဒေါ်', 'မောင်', 'ကို', 'မ') when followed
    // immediately by another base consonant (preserving names like 'မာလာ' or 'မေသူ').
    const prefixTokens = ['မောင်', 'ဦး', 'ဒေါ်', 'ကို', 'မ'];
    for (final prefix in prefixTokens) {
      if (trimmed.startsWith(prefix) && trimmed.length > prefix.length) {
        final rest = trimmed.substring(prefix.length);
        final firstRestCode = rest.codeUnitAt(0);
        final isBaseConsonant =
            (firstRestCode >= 0x1000 && firstRestCode <= 0x102A);
        if (isBaseConsonant && rest.length >= 2) {
          trimmed = rest;
          break;
        }
      }
    }

    // Strip whitespace-separated English/Romanized Myanmar honorifics when multi-word.
    const spacedEnTitles = [
      'mg ',
      'maung ',
      'ko ',
      'ma ',
      'u ',
      'daw ',
      'mr ',
      'mr. ',
      'ms ',
      'ms. ',
      'mrs ',
      'mrs. ',
      'dr ',
      'dr. ',
      'sayar ',
    ];
    final lower = trimmed.toLowerCase();
    for (final title in spacedEnTitles) {
      if (lower.startsWith(title)) {
        final rest = trimmed.substring(title.length).trimLeft();
        if (rest.isNotEmpty) {
          trimmed = rest;
          break;
        }
      }
    }
    return trimmed;
  }

  String? _firstRomanizedWord(String input) {
    final matches = RegExp(r'[A-Za-z]+').allMatches(input);
    if (matches.isEmpty) return null;
    return matches.first.group(0)!.toLowerCase();
  }

  /// Resolves phonetic Romanized Burmese onset -> (MyanmarWeekday, matchedPrefixLength).
  (MyanmarWeekday, int) _weekdayForRomanizedOnset(String lowerWord) {
    const digraphMap = <(String, MyanmarWeekday)>[
      ('hl', MyanmarWeekday.wednesday), // လှ (Hlaing, Hla)
      ('hw', MyanmarWeekday.wednesday), // ဝှ
      ('hn', MyanmarWeekday.saturday), // နှ (Hnin)
      ('hm', MyanmarWeekday.thursday), // မှ (Hmwe, Hmu)
      ('ht', MyanmarWeekday.saturday), // ထ (Htet, Htun, Htay)
      ('sh', MyanmarWeekday.rahu), // ရှ / ရွှ (Shwe, Shine)
      ('th', MyanmarWeekday.friday), // သ (Thura, Thet, Thida)
      ('kh', MyanmarWeekday.monday), // ခ (Khin, Khant)
      ('ky', MyanmarWeekday.monday), // ကျ (Kyaw)
      ('gy', MyanmarWeekday.monday), // ဂျ (Gyi)
      ('ng', MyanmarWeekday.monday), // င (Nge)
      ('ch', MyanmarWeekday.tuesday), // ချ (Chaw, Chit, Chan)
      ('ny', MyanmarWeekday.tuesday), // ည (Nyi, Nyein, Nyunt)
      ('ph', MyanmarWeekday.thursday), // ဖ (Phyo, Phyu)
      ('bh', MyanmarWeekday.thursday), // ဘ
      ('py', MyanmarWeekday.thursday), // ပြ (Pyae)
      ('by', MyanmarWeekday.thursday), // ဗြ
      ('my', MyanmarWeekday.thursday), // မြ (Myo, Myat)
      ('rh', MyanmarWeekday.rahu),
    ];
    for (final (prefix, weekday) in digraphMap) {
      if (lowerWord.startsWith(prefix)) {
        return (weekday, prefix.length);
      }
    }

    final first = lowerWord[0];
    final single = switch (first) {
      'a' || 'e' || 'i' || 'o' || 'u' => MyanmarWeekday.sunday,
      'k' || 'g' || 'q' => MyanmarWeekday.monday,
      'c' || 's' || 'z' || 'j' => MyanmarWeekday.tuesday,
      'l' || 'w' => MyanmarWeekday.wednesday,
      'p' || 'b' || 'm' || 'f' || 'v' => MyanmarWeekday.thursday,
      'h' => MyanmarWeekday.friday,
      't' || 'd' || 'n' || 'x' => MyanmarWeekday.saturday,
      'y' || 'r' => MyanmarWeekday.rahu,
      _ => MyanmarWeekday.sunday,
    };
    return (single, 1);
  }

  /// Extracts a human-readable script indicator and multi-syllable planet chain.
  (String, String) _analyzeNameScriptAndChain(String rawName) {
    final cleaned = _stripHonorifics(rawName);
    if (cleaned.isEmpty) {
      return ('မွေးနံအဓိက', 'အမည်စာလုံး မထည့်ရသေးပါ');
    }

    final hasBurmese = RegExp(r'[\u1000-\u109F]').hasMatch(cleaned);
    if (hasBurmese) {
      final parts = <String>[];
      // Extract base consonants per syllable ignoring medials/vowels/virama stacks cleanly.
      final units = cleaned.runes.toList();
      for (var i = 0; i < units.length; i++) {
        final code = units[i];
        // Skip stacked subjoined consonant right after asat/virama (U+1039).
        if (i > 0 && units[i - 1] == 0x1039) continue;
        // Skip devowelizer-marked final consonant (next char is U+103A, i.e., အသတ်).
        if (i + 1 < units.length && units[i + 1] == 0x103A) continue;
        final ch = String.fromCharCode(code);
        final wd = _weekdayForBurmeseChar(ch);
        if (wd != null) {
          parts.add('$ch (${wd.labelMm.split(' ').first})');
          if (parts.length >= 4) break;
        }
      }
      return (
        'မြန်မာအမည် ခွဲခြမ်းစိတ်ဖြာချက်',
        parts.isEmpty ? cleaned : parts.join(' • '),
      );
    }

    // English / Romanized Burmese syllable decomposition.
    final words = RegExp(r'[A-Za-z]+')
        .allMatches(cleaned)
        .map((m) => m.group(0)!)
        .toList();
    final parts = <String>[];
    for (final rawWord in words) {
      final lower = rawWord.toLowerCase();
      var idx = 0;
      while (idx < lower.length && parts.length < 4) {
        final sub = lower.substring(idx);
        final (wd, step) = _weekdayForRomanizedOnset(sub);
        final token = rawWord.substring(idx, idx + step);
        parts.add('$token → ${wd.labelMm.split(' ').first}');
        idx += step;

        // Advance through vowels (`a e i o u y` after onset) toward next syllable.
        var sawVowel = 'aeiou'.contains(lower[idx - step]);
        while (idx < lower.length && 'aeiouy'.contains(lower[idx])) {
          sawVowel = true;
          idx++;
        }
        if (!sawVowel) {
          break;
        }
        // Skip nasal/stop syllable coda (n, m, ng, r, t, p, k, w) when followed by
        // another consonant onset (e.g. "San-dar", "Nan-dar", "Kyaw-zin").
        while (idx + 1 < lower.length &&
            'nmrtkpw'.contains(lower[idx]) &&
            !'aeiouy'.contains(lower[idx + 1])) {
          // Preserve 'th', 'ht', 'hn', 'hm', 'hw', 'hl' onset digraphs if current+next form one.
          final two = lower.substring(idx, idx + 2);
          if (const {'th', 'ht', 'hn', 'hm', 'hw', 'hl', 'ny', 'ng'}.contains(two) &&
              idx + 2 < lower.length &&
              'aeiou'.contains(lower[idx + 2])) {
            break;
          }
          idx++;
        }
        final rest = lower.substring(idx);
        if (rest.isEmpty || !RegExp(r'[aeiou]').hasMatch(rest)) {
          break;
        }
      }
    }

    return (
      'English / Romanized အမည် ခွဲခြမ်းချက်',
      parts.isEmpty ? cleaned : parts.join(' • '),
    );
  }

  MyanmarWeekday? _weekdayForBurmeseChar(String ch) {
    if ('အဥဦဧဩဪဣဤ'.contains(ch)) return MyanmarWeekday.sunday;
    if ('ကခဂဃင'.contains(ch)) return MyanmarWeekday.monday;
    if ('စဆဇဈညဉ'.contains(ch)) return MyanmarWeekday.tuesday;
    if ('လဝဠ'.contains(ch)) return MyanmarWeekday.wednesday;
    if ('ပဖဗဘမ'.contains(ch)) return MyanmarWeekday.thursday;
    if ('သဟ'.contains(ch)) return MyanmarWeekday.friday;
    if ('တထဒဓနဋဌဍဎဏ'.contains(ch)) return MyanmarWeekday.saturday;
    if ('ယရ'.contains(ch)) return MyanmarWeekday.rahu;
    return null;
  }

  String _formatBurmeseLunarDate(MyanmarDate md) {
    final pattern = (md.moonPhase == 1 || md.moonPhase == 3)
        ? '&y ခုနှစ်၊ &M&Pနေ့'
        : '&y ခုနှစ်၊ &M&P &f ရက်';
    final raw = MyanmarCalendar.formatMyanmar(
      md,
      pattern: pattern,
      language: Language.myanmar,
    );
    return _toBurmeseDigits(raw);
  }

  String _toBurmeseDigits(String input) {
    const mmDigits = ['၀', '၁', '၂', '၃', '၄', '၅', '၆', '၇', '၈', '၉'];
    final buf = StringBuffer();
    for (final code in input.codeUnits) {
      if (code >= 0x30 && code <= 0x39) {
        buf.write(mmDigits[code - 0x30]);
      } else {
        buf.writeCharCode(code);
      }
    }
    return buf.toString();
  }

  /// Computes Myanmar Calendar daily indicators (`ရက်ရာဇာ / ပြဿဒါး / ဥပုသ်နေ့`).
  CalendarDaySummary inspectDate(DateTime date) {
    _ensureMyanmarLanguageConfigured();
    final complete = MyanmarCalendar.getCompleteDateFor(
      date.year,
      date.month,
      date.day,
      language: Language.myanmar,
    );
    final astro = complete.astro;
    final formatted = _formatBurmeseLunarDate(complete.myanmar);

    final nagahleMm = switch (astro.nagahle.toLowerCase()) {
      'east' => 'အရှေ့',
      'south' => 'တောင်',
      'west' => 'အနောက်',
      'north' => 'မြောက်',
      _ => astro.nagahle,
    };

    final tags = <String>[];
    for (final day in astro.astrologicalDays) {
      final lower = day.toLowerCase();
      if (lower == 'amyeittasote') {
        tags.add('အမြိတ္တစုတ် (အထူးကောင်း)');
      } else if (lower == 'thamanyo') {
        tags.add('သမညို (သတိပြုရန်)');
      } else if (lower == 'warameittugyi' || lower == 'warameittunge') {
        tags.add('ဝါရမိတ္တု (မင်္ဂလာရှောင်)');
      } else if (lower == 'yatyotema') {
        tags.add('ရက်ယုတ်မာ (ခရီး/မင်္ဂလာရှောင်)');
      } else if (lower == 'mahayatkyan') {
        tags.add('မဟာရက်ကြမ်း (သတိပြုရန်)');
      } else {
        tags.add(day);
      }
    }

    final wdLabel = _burmeseWeekdayLabel(date.weekday);
    return CalendarDaySummary(
      date: DateTime(date.year, date.month, date.day),
      myanmarDateFormatted: formatted,
      weekdayLabelMm: wdLabel,
      isYatyaza: astro.yatyaza.isNotEmpty,
      isPyathada: astro.pyathada == 'Pyathada',
      isAfternoonPyathada: astro.pyathada == 'Afternoon Pyathada',
      isSabbath: astro.sabbathType == SabbathType.sabbath,
      isSabbathEve: astro.sabbathType == SabbathType.sabbathEve,
      isHighlyAuspicious: astro.isHighlyAuspicious,
      nagahleMm: nagahleMm,
      astrologicalTagsMm: tags,
      holidaysMm: complete.holidays.allHolidays,
    );
  }

  /// Generates calendar summaries for [days] starting from [start].
  List<CalendarDaySummary> upcomingCalendarDays(
    DateTime start, {
    int days = 30,
  }) {
    final base = DateTime(start.year, start.month, start.day);
    return List.generate(
      days,
      (i) => inspectDate(base.add(Duration(days: i))),
    );
  }

  /// Computes a full Sayar San Zarni Bo style Mahabote (7-house chart),
  /// Angavijja Root/Tip, Question-Focused Yadaya, Dāna Alms, Candle Light,
  /// Gender Wear Outfit, and Today's Avoid Outfit reading.
  BaydinReading calculateReading({
    required String name,
    required DateTime birthDate,
    bool isWednesdayNightRahu = false,
    BaydinGender gender = BaydinGender.female,
    YadayaFocus focus = YadayaFocus.generalToday,
    DateTime? referenceDate,
  }) {
    _ensureMyanmarLanguageConfigured();
    final now = referenceDate ?? DateTime.now();
    final complete = MyanmarCalendar.getCompleteDateFor(
      birthDate.year,
      birthDate.month,
      birthDate.day,
      language: Language.myanmar,
    );
    final birthWd = weekdayFromDate(
      birthDate,
      isWednesdayNightRahu: isWednesdayNightRahu,
    );
    final todayWd = weekdayFromDate(now);
    final nameWd = weekdayFromName(name);
    final (scriptLabel, letterChain) = _analyzeNameScriptAndChain(name);
    final mahabote = MahaboteHouse.fromCode(complete.astro.mahabote);
    final mahaboteChart = _buildMahaboteChart(complete.myanmar.year);
    final (rootPlanet, tipPlanet) = _rootAndTipPlanets(birthWd);

    // Traditional Burmese running age (`ရောက်ဆဲအသက်`).
    var completedYears = now.year - birthDate.year;
    final hasNotReachedBirthdayYet = now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day);
    if (hasNotReachedBirthdayYet) {
      completedYears -= 1;
    }
    if (completedYears < 0) completedYears = 0;
    final runningAge = completedYears + 1;

    final startIndex = thetYaukRing.indexOf(birthWd);
    final offset = (runningAge - 1) % 8;
    final currentThetYauk = thetYaukRing[(startIndex + offset) % 8];
    final isBummiYear = runningAge % 8 == 4;

    final (compatLabel, compatNote) = _evaluateNameHarmony(birthWd, nameWd);

    final friendPlanet = _friendPairs[birthWd] ?? birthWd;
    final spouseIdeal = _spouseMatchPairs[birthWd] ?? friendPlanet;

    final (yadayaPlanet, prescription) = _buildPersonalizedPrescription(
      focus: focus,
      gender: gender,
      myanmarBirthYear: complete.myanmar.year,
      birthWd: birthWd,
      todayWd: todayWd,
      house: mahabote,
      chart: mahaboteChart,
      rootPlanet: rootPlanet,
      tipPlanet: tipPlanet,
      thetYauk: currentThetYauk,
      runningAge: runningAge,
      isBummi: isBummiYear,
      friendPlanet: friendPlanet,
      spouseIdeal: spouseIdeal,
    );

    final zataReason = _buildZataPositionReason(
      myanmarYear: complete.myanmar.year,
      birthWd: birthWd,
      nameWd: nameWd,
      house: mahabote,
      chart: mahaboteChart,
      rootPlanet: rootPlanet,
      tipPlanet: tipPlanet,
      runningAge: runningAge,
      thetYauk: currentThetYauk,
      isBummi: isBummiYear,
      targetPlanet: yadayaPlanet,
    );

    final householdDetails = _buildHouseholdDetails(
      birthWd: birthWd,
      nameWd: nameWd,
      house: mahabote,
      thetYauk: currentThetYauk,
      isBummi: isBummiYear,
    );

    final mindsetProfile = _buildMindsetProfile(
      birthWd: birthWd,
      house: mahabote,
      thetYauk: currentThetYauk,
      isBummi: isBummiYear,
    );

    final loveRomanceForecast = _buildLoveRomanceForecast(
      birthWd: birthWd,
      house: mahabote,
      thetYauk: currentThetYauk,
      spouseIdeal: spouseIdeal,
      friendPlanet: friendPlanet,
      isBummi: isBummiYear,
    );

    final financeForecast = _buildHouseholdFinanceForecast(
      birthWd: birthWd,
      house: mahabote,
      thetYauk: currentThetYauk,
      isBummi: isBummiYear,
    );

    final opportunitiesPath = _buildOpportunitiesPath(
      birthWd: birthWd,
      house: mahabote,
      thetYauk: currentThetYauk,
      targetPlanet: yadayaPlanet,
      friendPlanet: friendPlanet,
    );

    final risksAndDangers = _buildRisksAndDangers(
      birthWd: birthWd,
      house: mahabote,
      thetYauk: currentThetYauk,
      isBummi: isBummiYear,
    );

    final yadayaSteps = _buildYadayaSteps(
      birthWd: birthWd,
      targetPlanet: yadayaPlanet,
      prescription: prescription,
      mahabote: mahabote,
      thetYauk: currentThetYauk,
      isBummi: isBummiYear,
    );

    final partnerText =
        'အိမ်ထောင်ရေး/မိတ်ဆွေကောင်း တွဲဖက် - ${spouseIdeal.labelMm} (အိမ်ထောင်ဖက်) နှင့် ${friendPlanet.labelMm} (ဓာတ်မိတ်)';

    final formattedBirth = _formatBurmeseLunarDate(complete.myanmar);

    return BaydinReading(
      name: name.trim().isEmpty ? 'မိသားစုဝင်' : name.trim(),
      gender: gender,
      focus: focus,
      referenceDate: DateTime(now.year, now.month, now.day),
      todayWeekday: todayWd,
      nameDetectedScriptMm: scriptLabel,
      nameLetterChainMm: letterChain,
      birthDate: DateTime(birthDate.year, birthDate.month, birthDate.day),
      myanmarBirthDateLabel: '$formattedBirth (${birthWd.labelMm}သား/သမီး)',
      myanmarBirthYear: complete.myanmar.year,
      birthWeekday: birthWd,
      nameWeekday: nameWd,
      nameCompatibilityLabelMm: compatLabel,
      nameCompatibilityNoteMm: compatNote,
      mahaboteHouse: mahabote,
      mahaboteChart: mahaboteChart,
      rootPlanet: rootPlanet,
      tipPlanet: tipPlanet,
      runningAge: runningAge,
      currentThetYaukPlanet: currentThetYauk,
      isBummiYear: isBummiYear,
      yadayaTargetPlanet: yadayaPlanet,
      prescription: prescription,
      zataPositionReasonMm: zataReason,
      householdDetailsMm: householdDetails,
      mindsetProfileMm: mindsetProfile,
      loveRomanceForecastMm: loveRomanceForecast,
      financeForecastMm: financeForecast,
      opportunitiesPathMm: opportunitiesPath,
      risksAndDangersMm: risksAndDangers,
      yadayaStepsMm: yadayaSteps,
      meritCountMm:
          '${birthWd.labelMm}ဂြိုဟ်သက် (${birthWd.planetYears}) ခေါက် မေတ္တာသုတ် ရွတ်ဖတ်ပူဇော်ပါ',
      partnerSuggestionMm: partnerText,
    );
  }

  /// Computes the authentic 7-house Mahabote birth chart (`(year - mmcalWd) % 7`).
  Map<MahaboteHouse, MyanmarWeekday> _buildMahaboteChart(int myanmarYear) {
    const sevenDays = [
      MyanmarWeekday.saturday, // index 0
      MyanmarWeekday.sunday, // index 1
      MyanmarWeekday.monday, // index 2
      MyanmarWeekday.tuesday, // index 3
      MyanmarWeekday.wednesday, // index 4
      MyanmarWeekday.thursday, // index 5
      MyanmarWeekday.friday, // index 6
    ];
    const houses = [
      MahaboteHouse.binga,
      MahaboteHouse.atun,
      MahaboteHouse.yaza,
      MahaboteHouse.adipati,
      MahaboteHouse.marana,
      MahaboteHouse.thike,
      MahaboteHouse.puti,
    ];
    final map = <MahaboteHouse, MyanmarWeekday>{};
    for (final day in sevenDays) {
      final rem = (myanmarYear - day.mmcalWeekdayIndex) % 7;
      map[houses[rem < 0 ? rem + 7 : rem]] = day;
    }
    return map;
  }

  /// Angavijja Root (`အမြစ်` = prev weekday) & Tip (`အညွန့်` = next weekday).
  (MyanmarWeekday, MyanmarWeekday) _rootAndTipPlanets(MyanmarWeekday birthWd) {
    const cycle = [
      MyanmarWeekday.sunday,
      MyanmarWeekday.monday,
      MyanmarWeekday.tuesday,
      MyanmarWeekday.wednesday,
      MyanmarWeekday.thursday,
      MyanmarWeekday.friday,
      MyanmarWeekday.saturday,
    ];
    final canonical =
        birthWd == MyanmarWeekday.rahu ? MyanmarWeekday.wednesday : birthWd;
    final idx = cycle.indexOf(canonical);
    final root = cycle[(idx - 1 + cycle.length) % cycle.length];
    final tip = cycle[(idx + 1) % cycle.length];
    return (root, tip);
  }

  MyanmarWeekday _pickAvoidPlanet({
    required MyanmarWeekday birthWd,
    required MyanmarWeekday todayWd,
    required MyanmarWeekday thetYauk,
    required MyanmarWeekday wearPlanet,
  }) {
    final candidates = [
      _enemyPairs[todayWd],
      _enemyPairs[birthWd],
      _enemyPairs[thetYauk],
      MyanmarWeekday.saturday,
      MyanmarWeekday.tuesday,
      MyanmarWeekday.monday,
    ];
    for (final c in candidates) {
      if (c != null && c != wearPlanet) return c;
    }
    return MyanmarWeekday.saturday;
  }

  String _outfitAssetFor(MyanmarWeekday day, BaydinGender gender) {
    if (gender == BaydinGender.male) {
      switch (day) {
        case MyanmarWeekday.sunday:
          return 'assets/images/baydin/outfit_male_sunday.jpg';
        case MyanmarWeekday.tuesday:
          return 'assets/images/baydin/outfit_male_tuesday.jpg';
        case MyanmarWeekday.wednesday:
          return 'assets/images/baydin/outfit_male_wednesday.jpg';
        case MyanmarWeekday.thursday:
          return 'assets/images/baydin/outfit_male_thursday.jpg';
        case MyanmarWeekday.saturday:
          return 'assets/images/baydin/outfit_male_saturday.jpg';
        case MyanmarWeekday.monday:
        case MyanmarWeekday.friday:
        case MyanmarWeekday.rahu:
          return day.outfitAsset;
      }
    }
    return day.outfitAsset;
  }

  (MyanmarWeekday, YadayaPrescription) _buildPersonalizedPrescription({
    required YadayaFocus focus,
    required BaydinGender gender,
    required int myanmarBirthYear,
    required MyanmarWeekday birthWd,
    required MyanmarWeekday todayWd,
    required MahaboteHouse house,
    required Map<MahaboteHouse, MyanmarWeekday> chart,
    required MyanmarWeekday rootPlanet,
    required MyanmarWeekday tipPlanet,
    required MyanmarWeekday thetYauk,
    required int runningAge,
    required bool isBummi,
    required MyanmarWeekday friendPlanet,
    required MyanmarWeekday spouseIdeal,
  }) {
    final yearMm = _toBurmeseDigits('$myanmarBirthYear');
    final ageMm = _toBurmeseDigits('$runningAge');
    final thikePlanet = chart[MahaboteHouse.thike] ?? tipPlanet;
    final yazaPlanet =
        chart[MahaboteHouse.yaza] ?? chart[MahaboteHouse.adipati] ?? birthWd;
    final putiPlanet = chart[MahaboteHouse.puti] ?? spouseIdeal;

    late MyanmarWeekday targetPlanet;
    late MyanmarWeekday wearPlanet;
    late String formulaTitle;
    late String formulaReason;
    late String flowerTitle;
    late String flowerCountLabel;
    late String flowerAsset;
    late String flowerInstruction;
    late String almsTitle;
    late String almsAsset;
    late String almsInstruction;

    switch (focus) {
      case YadayaFocus.wealthBusiness:
        targetPlanet = thikePlanet;
        wearPlanet = isBummi ? friendPlanet : thikePlanet;
        formulaTitle = 'သိုက်အိမ်နှင့် အညွန့်နံ စီးပွားလာဘ်ပွင့် ယတြာ';
        formulaReason =
            'သင်၏ ($yearMm) ခုနှစ်ဖွား မဟာဘုတ်ခွင်တွင် "သိုက်အိမ် (ဥစ္စာစုဆောင်းအိမ်)" ၌ ${thikePlanet.labelMm}ဂြိုဟ် တည်ရှိပြီး၊ အညွန့်နံမှာ ${tipPlanet.labelMm} ဖြစ်သောကြောင့် ငွေဝင်လာဘ်ပွင့်ရန် ဤယတြာကို ရွေးချယ်ပေးထားပါသည်။';
        if (thikePlanet == MyanmarWeekday.sunday ||
            thikePlanet == MyanmarWeekday.monday ||
            thikePlanet == MyanmarWeekday.thursday) {
          flowerTitle = 'ရွှေပန်း ငွေပန်း (${thikePlanet.flowerCount} ခက်)';
          flowerCountLabel = '${thikePlanet.flowerCount} ခက်';
          flowerAsset = 'assets/images/baydin/yadaya_gold_silver_leaves.jpg';
          flowerInstruction =
              'ဘုရားတွင် ရွှေပန်း ငွေပန်း (${thikePlanet.flowerCount}) ခက် ညီညာစွာ ထိုး၍ စီးပွားလာဘ်ပွင့် ဆုတောင်းပါ။';
        } else {
          flowerTitle = '${tipPlanet.flowerNameMm} (${tipPlanet.flowerCount} ညွန့်/ပွင့်)';
          flowerCountLabel = '${tipPlanet.flowerCount} ညွန့်/ပွင့်';
          flowerAsset = tipPlanet.flowerAsset;
          flowerInstruction = tipPlanet.flowerNoteMm;
        }
        if (runningAge.isEven) {
          almsTitle = 'နနွင်းဆီထမင်းနှင့် ကောက်ညှင်းပေါင်း ဆွမ်းတော်ဒါန';
          almsAsset = 'assets/images/baydin/offering_sweet_rice.jpg';
          almsInstruction =
              'မနက်ပိုင်းတွင် ကြေးလင်ပန်းဖြင့် နနွင်းဆီထမင်း/ကောက်ညှင်းပေါင်း ဆွမ်းတော်ကပ်လှူပြီး အိမ်နီးချင်း သက်ကြီးရွယ်အိုများအား ဒါနပြုပါ။';
        } else {
          almsTitle = 'သစ်သီး (၅) မျိုး ကန်တော့ပွဲ ပူဇော်ဒါန';
          almsAsset = 'assets/images/baydin/offering_fruits.jpg';
          almsInstruction =
              'ငှက်ပျော၊ သရက် စသည့် သစ်သီး (၅) မျိုးစုံလင်စွာ ဘုရားတင်လှူပြီး စီးပွားရေး အတိုက်အခံများ ပြေပျောက်စေရန် အဓိဋ္ဌာန်ပြုပါ။';
        }

      case YadayaFocus.loveMarriage:
        targetPlanet = spouseIdeal;
        wearPlanet = isBummi ? friendPlanet : putiPlanet;
        formulaTitle = 'ပုတိအိမ်နှင့် ဖူးစာ/မိသားစု မေတ္တာဓာတ်ဆင် ယတြာ';
        formulaReason =
            'သင်၏ မဟာဘုတ် "ပုတိအိမ်" တွင် ${putiPlanet.labelMm} တည်ရှိနေပြီး ဖူးစာဓာတ်ဖက် (${spouseIdeal.labelMm}) နှင့် တွဲဖက်ရန် ချစ်ခင်ကြင်နာမှု တိုးပွားစေမည့် မေတ္တာယတြာ ဖြစ်ပါသည်။';
        if (putiPlanet == MyanmarWeekday.saturday ||
            putiPlanet == MyanmarWeekday.tuesday ||
            putiPlanet == MyanmarWeekday.monday) {
          flowerTitle = 'မေမြို့ပန်း မွှေးကြိုင်ပန်းစည်း (${spouseIdeal.flowerCount} ပွင့်)';
          flowerCountLabel = '${spouseIdeal.flowerCount} ပွင့်';
          flowerAsset = 'assets/images/baydin/yadaya_maymyo_aster.jpg';
          flowerInstruction =
              'ဘုရားတွင် မေမြို့ပန်း (${spouseIdeal.flowerCount}) ပွင့် သန့်ရှင်းစွာ ကပ်လှူပြီး မိသားစုနှင့် ချစ်သူကြား နားလည်ချစ်ခင်မှု တိုးပွားစေရန် မေတ္တာပို့ပါ။';
        } else {
          flowerTitle = '${spouseIdeal.flowerNameMm} (${spouseIdeal.flowerCount} ပွင့်)';
          flowerCountLabel = '${spouseIdeal.flowerCount} ပွင့်';
          flowerAsset = spouseIdeal.flowerAsset;
          flowerInstruction = spouseIdeal.flowerNoteMm;
        }
        almsTitle = 'မုန့်ဆွမ်းတော်နှင့် အချိုပွဲ (၅) ခု ဒါန';
        almsAsset = 'assets/images/baydin/offering_sweets.jpg';
        almsInstruction =
            'စိတ်နှလုံး ချိုသာအေးချမ်းစေရန် မုန့်အချို/ကောက်ညှင်းမုန့်များကို ဘုရားတင်ပြီး မိသားစုအတူ ဝေမျှဒါနပြုပါ။';

      case YadayaFocus.careerAuthority:
        targetPlanet = yazaPlanet;
        wearPlanet = yazaPlanet;
        formulaTitle = 'ရာဇ/အဓိပတိနှင့် အညွန့်နံ ရာထူး/အလုပ်အကိုင် ယတြာ';
        formulaReason =
            'သင်၏ မွေးနှစ် မဟာဘုတ်ခွင်တွင် "ရာဇအိမ်" ၌ ${yazaPlanet.labelMm} ဂြိုဟ် တည်ရှိပြီး၊ တက်လမ်းအညွန့်နံ (${tipPlanet.labelMm}) ကို အားဖြည့်ပေးရန် စီစဉ်ထားပါသည်။';
        if (yazaPlanet == MyanmarWeekday.wednesday ||
            yazaPlanet == MyanmarWeekday.tuesday ||
            yazaPlanet == MyanmarWeekday.thursday) {
          flowerTitle = 'သရက်ညွန့် (၁၀) ညွန့် အောင်မြင်ယတြာ';
          flowerCountLabel = '၁၀ ညွန့်';
          flowerAsset = 'assets/images/baydin/yadaya_mango_sprigs.jpg';
          flowerInstruction =
              'နံနက်စောစော ဘုရားတွင် သရက်ညွန့် (၁၀) ညွန့် ကပ်လှူပြီး လုပ်ငန်း/ရာထူး အဆင့်ဆင့် အောင်မြင်စေရန် ဆုတောင်းပါ။';
        } else {
          flowerTitle = 'စိန်ပန်းနှင့် အောင်မြင်ပန်း (${yazaPlanet.flowerCount} ခိုင်)';
          flowerCountLabel = '${yazaPlanet.flowerCount} ခိုင်';
          flowerAsset = 'assets/images/baydin/yadaya_seinpan_flames.jpg';
          flowerInstruction =
              'ဩဇာအာဏာနှင့် လုပ်ငန်းဂုဏ်သတင်း ထွန်းတောက်စေရန် စိန်ပန်း/ကံ့ကော် (${yazaPlanet.flowerCount}) ခိုင် ဘုရားပူဇော်ပါ။';
        }
        almsTitle = 'မုန့်ဟင်းခါး / စတုဒိသာ ကုသိုလ်ဒါန';
        almsAsset = 'assets/images/baydin/offering_mohinga.jpg';
        almsInstruction =
            'မိတ်ဆွေ၊ လုပ်ဖော်ကိုင်ဖက် သို့မဟုတ် သံဃာတော်များအား မုန့်ဟင်းခါး/ဆွမ်းဒါန ပြုခြင်းဖြင့် အလုပ်အကိုင် အထောက်အကူကောင်းများ ဝင်ရောက်လာမည်။';

      case YadayaFocus.remedyProtection:
        targetPlanet = friendPlanet;
        wearPlanet = rootPlanet == _enemyPairs[birthWd] ? friendPlanet : rootPlanet;
        formulaTitle = 'အမြစ်ရေလောင်း ဘုမ္မိ/မရဏ အညံ့ပြေ ယတြာ';
        formulaReason =
            'အသက် ($ageMm) နှစ် ${thetYauk.labelMm}သက်ရောက်${isBummi ? " (ဘုမ္မိကိန်း)" : ""} နှင့် မဟာဘုတ်အညံ့များ ပြေပျောက်စေရန် သင်၏ အမြစ်နံ (${rootPlanet.labelMm}) နှင့် မိတ်နံ (${friendPlanet.labelMm}) ဖြင့် ကာကွယ်ထိန်းညှိပေးထားပါသည်။';
        flowerTitle = '${rootPlanet.flowerNameMm} (${rootPlanet.flowerCount} ညွန့်/ပွင့်)';
        flowerCountLabel = '${rootPlanet.flowerCount} ညွန့်/ပွင့်';
        flowerAsset = rootPlanet.flowerAsset;
        flowerInstruction =
            '${rootPlanet.flowerNoteMm} ထို့ပြင် မွေးနံပင်အမြစ်ကို ရေသန့်လောင်း၍ အညံ့ပြေအောင် မေတ္တာပို့ပါ။';
        if (isBummi || house == MahaboteHouse.marana || thetYauk == _enemyPairs[birthWd]) {
          almsTitle = 'သောက်တော်ရေ (၂) ခွက်နှင့် ပရိတ်ရေစင် ပူဇော်နည်း';
          almsAsset = 'assets/images/baydin/yadaya_water_purification.jpg';
          almsInstruction =
              'ဖန်ခွက်သန့်သန့်ဖြင့် သောက်တော်ရေ (၂) ခွက်နှင့် စံပယ်ပန်းကုံး ကပ်လှူပြီး ပုတီး (၁) ပတ် စိပ်၍ အန္တရာယ်ကင်း မေတ္တာပို့ပါ။';
        } else {
          almsTitle = 'ကွမ်း၊ လက်ဖက်နှင့် ထန်းလျက် ဘုရား/မိဘ ဒါန';
          almsAsset = 'assets/images/baydin/yadaya_betel_tea_platter.jpg';
          almsInstruction =
              'လက်ဖက်အသားနှင့် ထန်းလျက်ကို သန့်ရှင်းစွာ ပူဇော်/ဒါနပြုခြင်းဖြင့် စကားအချေအတင်နှင့် အတိုက်အခံများ ပြေငြိမ်းစေပါသည်။';
        }

      case YadayaFocus.generalToday:
        final isEnemyToday = todayWd == _enemyPairs[birthWd];
        final isFriendToday =
            todayWd == _friendPairs[birthWd] || todayWd == birthWd;
        targetPlanet = (isBummi || isEnemyToday)
            ? friendPlanet
            : (isFriendToday ? todayWd : (chart[MahaboteHouse.atun] ?? birthWd));
        wearPlanet = targetPlanet;
        formulaTitle = isEnemyToday
            ? 'ယနေ့ (${todayWd.labelMm}နေ့) ရန်ဓာတ်ရှောင် • မိတ်ဖက်ယတြာ'
            : 'ယနေ့ (${todayWd.labelMm}နေ့) ခရားဇောက် မင်္ဂလာယတြာ';
        formulaReason =
            'ယနေ့ ${todayWd.labelMm}နေ့၏ နေ့နံစွမ်းအင်နှင့် သင်၏ (${birthWd.labelMm} / $ageMm နှစ် ${thetYauk.labelMm}သက်ရောက်) တို့ ချိန်ညှိတွက်ချက်မှုအရ "${targetPlanet.labelMm}ဓာတ်အိမ်" ဖြင့် ယနေ့ ကံမြှင့်တင်သင့်ပါသည်။';
        flowerTitle = '${targetPlanet.flowerNameMm} (${targetPlanet.flowerCount} ပွင့်/ညွန့်)';
        flowerCountLabel = '${targetPlanet.flowerCount} ပွင့်/ညွန့်';
        flowerAsset = targetPlanet.flowerAsset;
        flowerInstruction = targetPlanet.flowerNoteMm;
        if (isEnemyToday) {
          almsTitle = 'သောက်တော်ရေသန့်နှင့် ပရိတ်ပန်းကုံး ငြိမ်းချမ်းယတြာ';
          almsAsset = 'assets/images/baydin/yadaya_water_purification.jpg';
          almsInstruction =
              'ယနေ့ ရန်ဖက်နေ့နံ တိုက်ဆိုင်သဖြင့် နံနက်တွင် သောက်တော်ရေသန့် ကပ်လှူပြီး စိတ်အေးချမ်းစွာ နေထိုင်ပါ။';
        } else if (todayWd == MyanmarWeekday.tuesday ||
            todayWd == MyanmarWeekday.saturday ||
            todayWd == MyanmarWeekday.rahu) {
          almsTitle = 'ကွမ်း၊ လက်ဖက်နှင့် ထန်းလျက် ကုသိုလ်ဒါန';
          almsAsset = 'assets/images/baydin/yadaya_betel_tea_platter.jpg';
          almsInstruction =
              'ယနေ့ ကြေးလင်ပန်းဖြင့် လက်ဖက်နှင့် ထန်းလျက် ကပ်လှူဒါနပြု၍ တစ်နေ့တာ အလုပ်များ ချောမွေ့စေရန် ဆုတောင်းပါ။';
        } else {
          almsTitle = 'သစ်သီး (၅) မျိုး နေ့စဉ်မင်္ဂလာဒါန';
          almsAsset = 'assets/images/baydin/offering_fruits.jpg';
          almsInstruction =
              'အိမ်ဘုရားတွင် သစ်သီးစုံ ကပ်လှူပြီး မိသားစုတစ်စုလုံး ကျန်းမာချမ်းသာစေရန် ဝေမျှသုံးဆောင်ပါ။';
        }
    }

    final avoidPlanet = _pickAvoidPlanet(
      birthWd: birthWd,
      todayWd: todayWd,
      thetYauk: thetYauk,
      wearPlanet: wearPlanet,
    );

    final attireStyleLabel =
        gender == BaydinGender.male ? 'တိုက်ပုံနှင့် ပုဆိုး' : 'ရင်ဖုံးနှင့် ချိတ်လုံချည်';

    final avoidReason =
        'ယနေ့ (${todayWd.labelMm}နေ့) နှင့် သင်၏ (${birthWd.labelMm} • ${thetYauk.labelMm}သက်ရောက်) ဓာတ်အရ "${avoidPlanet.labelMm}" နံ (${avoidPlanet.outfitColorLabelMm}) သည် ရန်ဓာတ်/ကက္ခတိုက်ဆိုင်နေသောကြောင့် ယနေ့ ဤအရောင် $attireStyleLabel ကို ဝတ်ဆင်ခြင်းမှ ရှောင်ကြဉ်ပါ။';

    return (
      targetPlanet,
      YadayaPrescription(
        formulaTitleMm: formulaTitle,
        formulaReasonMm: formulaReason,
        flowerTitleMm: flowerTitle,
        flowerCountLabelMm: flowerCountLabel,
        flowerAsset: flowerAsset,
        flowerInstructionMm: flowerInstruction,
        almsTitleMm: almsTitle,
        almsAsset: almsAsset,
        almsInstructionMm: almsInstruction,
        candleTitleMm: targetPlanet.candleTitleMm,
        candleAsset: targetPlanet.lightAsset,
        candleInstructionMm: targetPlanet.candleNoteMm,
        wearOutfitTitleMm:
            '${wearPlanet.outfitColorLabelMm} ($attireStyleLabel)',
        wearOutfitAsset: _outfitAssetFor(wearPlanet, gender),
        wearOutfitNoteMm:
            '${wearPlanet.outfitNoteMm} (ကံကောင်းအရပ်မျက်နှာ - ${wearPlanet.directionMm})',
        wearPrimaryHex: wearPlanet.outfitColorHex,
        wearSecondaryHex: wearPlanet.secondaryColorHex,
        avoidOutfitTitleMm:
            '${avoidPlanet.outfitColorLabelMm} ($attireStyleLabel — ယနေ့ မဝတ်ရ)',
        avoidOutfitAsset: _outfitAssetFor(avoidPlanet, gender),
        avoidReasonMm: avoidReason,
        avoidPrimaryHex: avoidPlanet.outfitColorHex,
        avoidSecondaryHex: avoidPlanet.secondaryColorHex,
      ),
    );
  }

  (String, String) _evaluateNameHarmony(
    MyanmarWeekday birth,
    MyanmarWeekday? nameWd,
  ) {
    if (nameWd == null) {
      return (
        'မွေးနံအဓိက တွက်ချက်မှု',
        'မြန်မာအမည် သို့မဟုတ် English အမည် (ဥပမာ - Sithu Min) ထည့်သွင်းပါက နာမည်နေ့နံနှင့် မွေးနံ ဓာတ်ဖက်/မိတ်ဖက် ကိုက်ညီမှုကိုပါ ပူးတွဲစစ်ဆေးပေးပါမည်။',
      );
    }
    if (nameWd == birth) {
      return (
        'တိုက်ရိုက်မွေးနံညီ (သဟဇာတ)',
        'နာမည် (${nameWd.labelMm}နံ) နှင့် မွေးနံ တစ်ထပ်တည်းကျသဖြင့် ကိုယ်ပိုင်အားထုတ်မှု အောင်မြင်လွယ်ပါသည်။',
      );
    }
    if (_friendPairs[birth] == nameWd) {
      return (
        'မိတ်ဖက်ဓာတ်ညီ (အထူးကောင်း)',
        'နာမည် (${nameWd.labelMm}နံ) နှင့် မွေးနံ (${birth.labelMm}) သည် ဓာတ်မိတ်ဖြစ်၍ အိမ်တွင်းရေးနှင့် စီးပွားလာဘ်ဝင် ကောင်းမွန်ပါသည်။',
      );
    }
    if (_enemyPairs[birth] == nameWd) {
      return (
        'ရန်ဖက်အနေအထား (ယတြာဖြင့် ထိန်းညှိရန်)',
        'နာမည် (${nameWd.labelMm}နံ) နှင့် မွေးနံ အချင်းချင်း တွန်းကန်တတ်သဖြင့် မိတ်နံပန်း၊ ဆီမီးနှင့် အရောင်များဖြင့် ယတြာချေပေးပါ။',
      );
    }
    return (
      'သာမန်သင့်တင့် (ပုံမှန်)',
      'နာမည် (${nameWd.labelMm}နံ) နှင့် မွေးနံ မျှတသော အနေအထားရှိပြီး ကုသိုလ်ကောင်းမှု ပြုသလောက် အကျိုးပေးမည်ဖြစ်ပါသည်။',
    );
  }

  String _buildZataPositionReason({
    required int myanmarYear,
    required MyanmarWeekday birthWd,
    required MyanmarWeekday? nameWd,
    required MahaboteHouse house,
    required Map<MahaboteHouse, MyanmarWeekday> chart,
    required MyanmarWeekday rootPlanet,
    required MyanmarWeekday tipPlanet,
    required int runningAge,
    required MyanmarWeekday thetYauk,
    required bool isBummi,
    required MyanmarWeekday targetPlanet,
  }) {
    final ageMm = _toBurmeseDigits('$runningAge');
    final yearMm = _toBurmeseDigits('$myanmarYear');
    final thikeWd = chart[MahaboteHouse.thike]?.labelMm ?? tipPlanet.labelMm;
    final yazaWd = chart[MahaboteHouse.yaza]?.labelMm ?? birthWd.labelMm;
    final transitRelation = isBummi
        ? 'ဘုမ္မိအရပ်ကိန်း (အသက် ÷ ၈ အကြွင်း ၄) သို့ ရောက်ရှိနေသည့် အပြောင်းအလဲကာလ'
        : thetYauk == birthWd
            ? 'မိမိ၏ မူလမွေးနံဂြိုဟ်အိမ် (${birthWd.labelMm}) ပေါ်သို့ ပြန်လည်ဆိုက်ရောက်ချိန်'
            : thetYauk == _friendPairs[birthWd]
                ? 'ဓာတ်မိတ်ဂြိုဟ် (${thetYauk.labelMm}) အိမ်သို့ ရောက်ရှိ၍ မိတ်ဆွေကောင်း/အခွင့်အလမ်းပွင့်ချိန်'
                : thetYauk == _enemyPairs[birthWd]
                    ? 'ရန်ဖက်ဂြိုဟ် (${thetYauk.labelMm}) အိမ်ကို ဖြတ်သန်းနေရသဖြင့် စိတ်ပူပန်မှုနှင့် အပြိုင်အဆိုင်များတတ်ချိန်'
                    : 'ကြားဂြိုဟ် (${thetYauk.labelMm}) အိမ်တွင် တည်ရှိနေသဖြင့် ကိုယ်တိုင်ကြိုးစားသလောက် အကျိုးပေးချိန်';
    final nameClause = nameWd == null
        ? ''
        : ' ထို့ပြင် အမည် (${nameWd.labelMm}နံ) နှင့် မွေးနံ ပေါင်းစပ်အားကြောင့်';
    return 'မြန်မာသက္ကရာဇ် ($yearMm) ခုနှစ်ဖွား ${birthWd.labelMm}သား/သမီး၏ ကိုယ်ပိုင်မဟာဘုတ်တိုင်တွင် "${house.houseNameMm} (${house.titleMm})" ၌ တည်ရှိပြီး၊ သိုက်အိမ် = $thikeWd ၊ ရာဇအိမ် = $yazaWd ၊ အမြစ်နံ = ${rootPlanet.labelMm} ၊ အညွန့်နံ = ${tipPlanet.labelMm} ဖြစ်ပါသည်။ လက်ရှိ ရောက်ဆဲအသက် ($ageMm) နှစ်တွင် "${thetYauk.labelMm}သက်ရောက်" — $transitRelation ကို ဖြတ်သန်းနေသောကြောင့် ဤသို့ ဖြစ်ပေါ်နေခြင်း ဖြစ်ပါသည်။$nameClause အဓိက ညှိယူပူဇော်ရမည့် ဓာတ်အိမ်မှာ "${targetPlanet.labelMm}" ဖြစ်ပါသည်။';
  }

  String _buildHouseholdDetails({
    required MyanmarWeekday birthWd,
    required MyanmarWeekday? nameWd,
    required MahaboteHouse house,
    required MyanmarWeekday thetYauk,
    required bool isBummi,
  }) {
    final tensionNote = isBummi || thetYauk == _enemyPairs[birthWd]
        ? 'လက်ရှိ ${thetYauk.labelMm}သက်ရောက်ကြောင့် မိသားစုအတွင်း အသေးအဖွဲ စကားအမြင်မတူမှုများ ပေါ်တတ်သော်လည်း စိတ်အေးအေးထား၍ ညှိနှိုင်းပြောဆိုလျှင် ပြေလည်ပါမည်။'
        : 'အိမ်တွင်းရေးတွင် လူကြီးမိဘနှင့် မိသားစုဝင်များ၏ နားလည်မှု ပံ့ပိုးမှု ရရှိနေပြီး အေးချမ်းတည်ငြိမ်မှု အားကောင်းနေပါသည်။';
    final nameFamilyBonus = (nameWd != null && _friendPairs[birthWd] == nameWd)
        ? ' အမည်နှင့် မွေးနံ မိတ်ဖက်ညီသဖြင့် အိမ်တွင်းကျက်သရေ တိုးပွားပါမည်။'
        : '';
    return '${house.householdFortuneMm} $tensionNote$nameFamilyBonus';
  }

  String _buildMindsetProfile({
    required MyanmarWeekday birthWd,
    required MahaboteHouse house,
    required MyanmarWeekday thetYauk,
    required bool isBummi,
  }) {
    final moodTransit = isBummi
        ? 'ယခုကာလ ဘုမ္မိကိန်းကြောင့် စိတ်ထဲတွင် မရေမရာ စိုးရိမ်ပူပန်ခြင်း၊ နေရာအပြောင်းအလဲ လုပ်ချင်စိတ် ပေါ်ခြင်းများ ရှိနိုင်ပါသည်။'
        : thetYauk == _enemyPairs[birthWd]
            ? '${thetYauk.labelMm}သက်ရောက်အရှိန်ကြောင့် စိတ်တိုလွယ်၊ စိတ်မြန်လွယ်ပြီး သူတစ်ပါးစကားကို အာရုံစိုက်မိတတ်သဖြင့် သတိထားထိန်းညှိသင့်သည်။'
            : (thetYauk == _friendPairs[birthWd] || thetYauk == birthWd)
                ? 'ယခု ${thetYauk.labelMm}သက်ရောက်တွင် ကိုယ့်ကိုယ်ကိုယ် ယုံကြည်မှုမြင့်မားပြီး စိတ်ကူးဉာဏ်ပွင့်လန်းကာ အကောင်းမြင်စိတ် အားကောင်းနေပါသည်။'
                : 'လက်ရှိတွင် စိတ်တည်ငြိမ်စွာဖြင့် ရှေ့ဆက်ရမည့်အစီအစဉ်များကို အေးအေးဆေးဆေး စဉ်းစားဆုံးဖြတ်လိုစိတ် ရှိနေပါသည်။';
    return '${house.mindsetMm} $moodTransit';
  }

  String _buildLoveRomanceForecast({
    required MyanmarWeekday birthWd,
    required MahaboteHouse house,
    required MyanmarWeekday thetYauk,
    required MyanmarWeekday spouseIdeal,
    required MyanmarWeekday friendPlanet,
    required bool isBummi,
  }) {
    final singleTiming = (thetYauk == MyanmarWeekday.friday ||
            thetYauk == friendPlanet ||
            thetYauk == birthWd) &&
        !isBummi
        ? 'ရည်းစားမရှိသေးသူ (Single) များအတွက် ယခု ${thetYauk.labelMm}သက်ရောက်ကာလအတွင်း မိတ်ဆွေ/လုပ်ငန်းခွင်မှတစ်ဆင့် ဖူးစာရှင်အသစ် ဆုံတွေ့နိုင်ပြီး ချစ်သူရည်းစားရနိုင်ချိန် ကောင်းမွန်နေပါသည်။'
        : (isBummi || thetYauk == _enemyPairs[birthWd] || house == MahaboteHouse.marana)
            ? 'ရည်းစားမရှိသေးသူ (Single) များအတွက် ယခုကာလသည် စိတ်ခံစားချက် မတည်ငြိမ်သေးဘဲ ဖူးစာစစ်မှန်ရန် အချိန်ယူစောင့်ကြည့်သင့်သည့်ကာလ ဖြစ်ပါသည် (မကြာမီ လာမည့် မိတ်နံဂြိုဟ်လပိုင်းတွင် ပိုမိုကောင်းမွန်လာမည်)။'
            : 'ရည်းစားမရှိသေးသူ (Single) များအနေဖြင့် ပေါင်းသင်းဆက်ဆံရေး ပွင့်လင်းသည့် ပွဲလမ်းသဘင်/လုပ်ငန်းခွင်မှ စိတ်သဘောထားကောင်းသူနှင့် စတင်ရင်းနှီးခွင့် ရနိုင်ပါသည်။';

    final marriageText =
        '${house.romanceTraitMm} မြန်မာ့နက္ခတ်ဗေဒင်အရ အလိုက်ဖက်ဆုံး အိမ်ထောင်ဖက်မှာ ${spouseIdeal.labelMm}သား/သမီး (${spouseIdeal.sampleLettersMm}) နှင့် ဓာတ်မိတ် ${friendPlanet.labelMm}သား/သမီး (${friendPlanet.sampleLettersMm}) တို့ ဖြစ်ပါသည်။';
    return '$singleTiming $marriageText';
  }

  String _buildOpportunitiesPath({
    required MyanmarWeekday birthWd,
    required MahaboteHouse house,
    required MyanmarWeekday thetYauk,
    required MyanmarWeekday targetPlanet,
    required MyanmarWeekday friendPlanet,
  }) {
    final boost = thetYauk == _friendPairs[birthWd] || thetYauk == birthWd
        ? 'လက်ရှိ ${thetYauk.labelMm}သက်ရောက်သည် မိမိဘက်တွင် ရှိနေသဖြင့် လုပ်ငန်းသစ်စတင်ခြင်း၊ ရာထူး/ဝင်ငွေတိုးခြင်းများ ရဲရဲတင်းတင်း ဆောင်ရွက်သင့်သည်။'
        : 'ယခုကာလတွင် ရက်ရာဇာရက်များ၌ အရေးကြီးကိစ္စ စတင်ခြင်းနှင့် ${friendPlanet.labelMm}နံ မိတ်ဆွေများနှင့် ပူးပေါင်းဆောင်ရွက်ခြင်းဖြင့် အောင်မြင်မှုရမည်။';
    return '${house.opportunityTraitMm} $boost ကံကောင်းစေမည့် အရပ်မျက်နှာ (${targetPlanet.directionMm}) ဘက်သို့ ဦးတည်ဆောင်ရွက်ပါ။';
  }

  String _buildRisksAndDangers({
    required MyanmarWeekday birthWd,
    required MahaboteHouse house,
    required MyanmarWeekday thetYauk,
    required bool isBummi,
  }) {
    final specificHazard = isBummi
        ? 'ဘုမ္မိကိန်း (${thetYauk.labelMm}သက်ရောက်) ဖြစ်၍ ညဘက်ခရီးဝေးသွားလာခြင်း၊ အမြင့်တက်ခြင်း၊ အာမခံစာချုပ် လက်မှတ်ထိုးခြင်းနှင့် စက်ပစ္စည်းအကြီးစား ဝယ်ယူခြင်းများကို အထူးဆင်ခြင်ပါ။'
        : thetYauk == _enemyPairs[birthWd]
            ? '${thetYauk.labelMm} (ရန်ဖက်ဂြိုဟ်) သက်ရောက်ကြောင့် မနာလိုသူများ၏ စကားရှုပ်ခြင်း၊ စာရွက်စာတမ်းမှားယွင်းခြင်းနှင့် ကျန်းမာရေး ထိခိုက်လွယ်မှုကို သတိထားပါ။'
            : 'ပြဿဒါးရက်များတွင် အရေးကြီးငွေကြေးလွှဲပြောင်းခြင်းနှင့် စိတ်မြန်လက်မြန် ပြောဆိုခြင်းတို့ကို ရှောင်ကြဉ်ပါ။';
    return '${house.dangerTraitMm} $specificHazard';
  }

  String _buildHouseholdFinanceForecast({
    required MyanmarWeekday birthWd,
    required MahaboteHouse house,
    required MyanmarWeekday thetYauk,
    required bool isBummi,
  }) {
    if (isBummi) {
      return 'လက်ရှိအသက်သည် ဘုမ္မိကိန်း (${thetYauk.labelMm}သက်ရောက်) ကျရောက်နေသဖြင့် အိမ်ခြံမြေ၊ ငွေချေးငှားခြင်းနှင့် ရင်းနှီးမြှုပ်နှံမှုကြီးများ ခေတ္တဆိုင်းငံ့ပြီး အိမ်သုံးစရိတ် စနစ်တကျ ထိန်းသိမ်းသင့်ပါသည်။';
    }
    if (thetYauk == _friendPairs[birthWd] || thetYauk == birthWd) {
      return 'ယခုနှစ် ${thetYauk.labelMm}သက်ရောက်သည် မိတ်နံ/ကိုယ်ပိုင်ဂြိုဟ်အားကောင်းချိန်ဖြစ်၍ ${house.titleMm} အတွက် ငွေကြေးဝင်ငွေ တိုးပွားပြီး အိမ်သုံးပစ္စည်းနှင့် ရွှေငွေ စုဆောင်းမိနိုင်ချိန် ဖြစ်ပါသည်။';
    }
    if (thetYauk == _enemyPairs[birthWd]) {
      return 'ယခုနှစ် ${thetYauk.labelMm}သက်ရောက်တွင် မထင်မှတ်ဘဲ အိမ်သုံးအပိုစရိတ် ထွက်တတ်သဖြင့် ရက်ရာဇာရက်များတွင်သာ ငွေအပေးအယူပြုလုပ်ပြီး မွေးနံပန်း မပြတ်ပူဇော်ပါ။';
    }
    return '${house.titleMm} ၏ ${thetYauk.labelMm}သက်ရောက်ကာလတွင် ဝင်ငွေနှင့် အိမ်သုံးထွက်ငွေ မျှတစွာ လည်ပတ်နိုင်မည်ဖြစ်ပြီး ဥပုသ်နေ့တိုင်း ဘုရားဆွမ်းတော်/ပန်းလှူခြင်းဖြင့် လာဘ်လာဘ ပွင့်လန်းမည်။';
  }

  List<String> _buildYadayaSteps({
    required MyanmarWeekday birthWd,
    required MyanmarWeekday targetPlanet,
    required YadayaPrescription prescription,
    required MahaboteHouse mahabote,
    required MyanmarWeekday thetYauk,
    required bool isBummi,
  }) {
    final steps = <String>[
      prescription.flowerInstructionMm,
      prescription.almsInstructionMm,
      prescription.candleInstructionMm,
      'ဝတ်ဆင်/ရှောင်ကြဉ်ရန် - ${prescription.wearOutfitNoteMm}',
      'မိမိမွေးနံ (${birthWd.labelMm}နေ့) နံနက်ပိုင်းတွင် နေအိမ်အတွင်း ${birthWd.directionMm} အရပ်သို့ မျက်နှာမူ၍ မေတ္တာသုတ် (${birthWd.planetYears}) ခေါက် ရွတ်ဖတ်ဆုတောင်းပါ။',
    ];
    if (isBummi || mahabote == MahaboteHouse.marana) {
      steps.add(
        'ဘုမ္မိ/မရဏ အညံ့ပြေစေရန် ဥပုသ်နေ့တွင် သံဃာတော် သို့မဟုတ် သက်ကြီးရွယ်အိုများအား သောက်ရေသန့်နှင့် ဟင်းတစ်ခွက် ဒါနပြုပါ (${thetYauk.labelMm}သက်ရောက်ယတြာ)။',
      );
    }
    return steps;
  }

  String _burmeseWeekdayLabel(int dartWeekday) {
    return switch (dartWeekday) {
      DateTime.sunday => 'တနင်္ဂနွေနေ့',
      DateTime.monday => 'တနင်္လာနေ့',
      DateTime.tuesday => 'အင်္ဂါနေ့',
      DateTime.wednesday => 'ဗုဒ္ဓဟူးနေ့',
      DateTime.thursday => 'ကြာသပတေးနေ့',
      DateTime.friday => 'သောကြာနေ့',
      DateTime.saturday => 'စနေနေ့',
      _ => '',
    };
  }
}
