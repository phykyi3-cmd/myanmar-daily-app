import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myanmar_daily_app/domain/models/baydin_forecast.dart';
import 'package:myanmar_daily_app/domain/models/baydin_reading.dart';
import 'package:myanmar_daily_app/domain/use_cases/baydin_forecast_engine.dart';
import 'package:myanmar_daily_app/domain/use_cases/myanmar_baydin_engine.dart';

/// Three primary sub-views inside the 'ဗေဒင်/ယတြာ' tab.
enum BaydinSection { calculator, compatibility, calendar }

/// Filter modes for the 30-day Auspicious & Sabbath Calendar list.
enum CalendarFilter { all, yatyazaOnly, sabbathOnly, pyathadaOnly }

/// ViewModel powering Mahabote / Yadaya, Weekly & Monthly Horoscopes,
/// Daily Auspicious Hours, 2-Person Compatibility, and Myanmar Calendar.
class BaydinViewModel extends ChangeNotifier {
  BaydinViewModel({
    MyanmarBaydinEngine? engine,
    BaydinForecastEngine? forecastEngine,
  })  : _engine = engine ?? MyanmarBaydinEngine(),
        _forecastEngine =
            forecastEngine ?? BaydinForecastEngine(baseEngine: engine);

  final MyanmarBaydinEngine _engine;
  final BaydinForecastEngine _forecastEngine;

  static const _prefNameKey = 'baydin_saved_name_v1';
  static const _prefBirthKey = 'baydin_saved_birth_iso_v1';
  static const _prefRahuKey = 'baydin_saved_wed_rahu_v1';
  static const _prefGenderKey = 'baydin_saved_gender_v1';
  static const _prefFocusKey = 'baydin_saved_focus_v1';

  BaydinSection _activeSection = BaydinSection.calculator;
  BaydinSection get activeSection => _activeSection;

  BaydinForecastPeriod _activePeriod = BaydinForecastPeriod.mahabote;
  BaydinForecastPeriod get activePeriod => _activePeriod;

  CalendarFilter _calendarFilter = CalendarFilter.all;
  CalendarFilter get calendarFilter => _calendarFilter;

  String _nameInput = '';
  String get nameInput => _nameInput;

  DateTime _birthDate = DateTime(1995, 5, 10);
  DateTime get birthDate => _birthDate;

  bool _isWednesdayNightRahu = false;
  bool get isWednesdayNightRahu => _isWednesdayNightRahu;

  BaydinGender _gender = BaydinGender.female;
  BaydinGender get gender => _gender;

  YadayaFocus _focus = YadayaFocus.generalToday;
  YadayaFocus get focus => _focus;

  bool _hasSavedProfile = false;
  bool get hasSavedProfile => _hasSavedProfile;

  DateTime _referenceNow = DateTime.now();

  BaydinReading? _currentReading;
  BaydinReading? get currentReading => _currentReading;

  int _weekOffset = 0;
  int get weekOffset => _weekOffset;

  int _monthOffset = 0;
  int get monthOffset => _monthOffset;

  WeeklyBaydinForecast? _weeklyForecast;
  WeeklyBaydinForecast? get weeklyForecast => _weeklyForecast;

  MonthlyBaydinForecast? _monthlyForecast;
  MonthlyBaydinForecast? get monthlyForecast => _monthlyForecast;

  DailyAuspiciousGuide? _todayAuspiciousGuide;
  DailyAuspiciousGuide? get todayAuspiciousGuide => _todayAuspiciousGuide;

  MyanmarWeekday _compatPersonA = MyanmarWeekday.wednesday;
  MyanmarWeekday get compatPersonA => _compatPersonA;

  MyanmarWeekday _compatPersonB = MyanmarWeekday.monday;
  MyanmarWeekday get compatPersonB => _compatPersonB;

  CompatibilityResult? _compatibilityResult;
  CompatibilityResult get compatibilityResult =>
      _compatibilityResult ??= _forecastEngine.calculateCompatibility(
        personA: _compatPersonA,
        personB: _compatPersonB,
      );

  DateTime _selectedCalendarDate = DateTime.now();
  DateTime get selectedCalendarDate => _selectedCalendarDate;

  CalendarDaySummary? _todaySummary;
  CalendarDaySummary? get todaySummary => _todaySummary;

  CalendarDaySummary? _selectedDaySummary;
  CalendarDaySummary? get selectedDaySummary => _selectedDaySummary;

  List<CalendarDaySummary> _upcomingDays = const [];
  List<CalendarDaySummary> get upcomingDays => _upcomingDays;

  bool _loaded = false;

  MyanmarWeekday get userBirthWeekday => _engine.weekdayFromDate(
        _birthDate,
        isWednesdayNightRahu: _isWednesdayNightRahu,
      );

  void setActiveSection(BaydinSection section) {
    if (_activeSection == section) return;
    _activeSection = section;
    notifyListeners();
  }

  void setActivePeriod(BaydinForecastPeriod period) {
    if (_activePeriod == period) return;
    _activePeriod = period;
    notifyListeners();
  }

  void setCalendarFilter(CalendarFilter filter) {
    if (_calendarFilter == filter) return;
    _calendarFilter = filter;
    notifyListeners();
  }

  List<CalendarDaySummary> get filteredUpcomingDays {
    switch (_calendarFilter) {
      case CalendarFilter.all:
        return _upcomingDays;
      case CalendarFilter.yatyazaOnly:
        return _upcomingDays.where((d) => d.isYatyaza).toList();
      case CalendarFilter.sabbathOnly:
        return _upcomingDays
            .where((d) => d.isSabbath || d.isSabbathEve)
            .toList();
      case CalendarFilter.pyathadaOnly:
        return _upcomingDays
            .where((d) => d.isPyathada || d.isAfternoonPyathada)
            .toList();
    }
  }

  Future<void> loadAll({DateTime? now}) async {
    final referenceNow = now ?? DateTime.now();
    _referenceNow = referenceNow;
    _todaySummary = _engine.inspectDate(referenceNow);
    _selectedCalendarDate =
        DateTime(referenceNow.year, referenceNow.month, referenceNow.day);
    _selectedDaySummary = _todaySummary;
    _upcomingDays = _engine.upcomingCalendarDays(referenceNow, days: 30);

    if (!_loaded) {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_prefNameKey);
      final savedBirth = prefs.getString(_prefBirthKey);
      final savedRahu = prefs.getBool(_prefRahuKey) ?? false;
      final savedGender = prefs.getString(_prefGenderKey);
      final savedFocus = prefs.getString(_prefFocusKey);

      if (savedName != null && savedName.isNotEmpty) {
        _nameInput = savedName;
        _hasSavedProfile = true;
      }
      if (savedBirth != null) {
        final parsed = DateTime.tryParse(savedBirth);
        if (parsed != null) {
          _birthDate = parsed;
          _hasSavedProfile = true;
        }
      }
      _isWednesdayNightRahu = savedRahu;
      if (savedGender != null) {
        _gender = BaydinGender.values.firstWhere(
          (g) => g.name == savedGender,
          orElse: () => BaydinGender.female,
        );
      }
      if (savedFocus != null) {
        _focus = YadayaFocus.values.firstWhere(
          (f) => f.name == savedFocus,
          orElse: () => YadayaFocus.generalToday,
        );
      }
      _compatPersonA = userBirthWeekday;
      _compatibilityResult = _forecastEngine.calculateCompatibility(
        personA: _compatPersonA,
        personB: _compatPersonB,
      );
      _loaded = true;
    }

    _todayAuspiciousGuide = _forecastEngine.calculateDailyAuspiciousGuide(
      date: referenceNow,
      userBirthWeekday: userBirthWeekday,
    );

    if (_currentReading != null) {
      _recomputePeriodicForecasts();
    }

    // Keep flower, alms, candle/oil-lamp, outfit, and fortune cards hidden until
    // the user explicitly taps the fortune query button ("ဗေဒင်မေးမည်").
    notifyListeners();
  }

  void updateName(String value) {
    _nameInput = value;
  }

  void clearReading() {
    if (_currentReading == null) return;
    _currentReading = null;
    _weeklyForecast = null;
    _monthlyForecast = null;
    notifyListeners();
  }

  Future<void> clearSavedProfile() async {
    _nameInput = '';
    _hasSavedProfile = false;
    _currentReading = null;
    _weeklyForecast = null;
    _monthlyForecast = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefNameKey);
    await prefs.remove(_prefBirthKey);
    await prefs.remove(_prefRahuKey);
    await prefs.remove(_prefGenderKey);
    await prefs.remove(_prefFocusKey);
  }

  void updateBirthDate(DateTime date) {
    _birthDate = DateTime(date.year, date.month, date.day);
    _todayAuspiciousGuide = _forecastEngine.calculateDailyAuspiciousGuide(
      date: _referenceNow,
      userBirthWeekday: userBirthWeekday,
    );
    if (_currentReading != null) {
      _recalculateReadingOnly();
    }
    notifyListeners();
  }

  void setWednesdayNightRahu(bool value) {
    if (_isWednesdayNightRahu == value) return;
    _isWednesdayNightRahu = value;
    _todayAuspiciousGuide = _forecastEngine.calculateDailyAuspiciousGuide(
      date: _referenceNow,
      userBirthWeekday: userBirthWeekday,
    );
    if (_currentReading != null) {
      _recalculateReadingOnly();
    }
    notifyListeners();
  }

  void setGender(BaydinGender value) {
    if (_gender == value) return;
    _gender = value;
    if (_currentReading != null) {
      _recalculateReadingOnly();
    }
    notifyListeners();
  }

  void setFocus(YadayaFocus value) {
    if (_focus == value) return;
    _focus = value;
    if (_currentReading != null) {
      _recalculateReadingOnly();
    }
    notifyListeners();
  }

  void shiftWeek(int delta) {
    _weekOffset = (_weekOffset + delta).clamp(-8, 12);
    _recomputePeriodicForecasts();
    notifyListeners();
  }

  void resetToCurrentWeek() {
    if (_weekOffset == 0) return;
    _weekOffset = 0;
    _recomputePeriodicForecasts();
    notifyListeners();
  }

  void shiftMonth(int delta) {
    _monthOffset = (_monthOffset + delta).clamp(-6, 12);
    _recomputePeriodicForecasts();
    notifyListeners();
  }

  void resetToCurrentMonth() {
    if (_monthOffset == 0) return;
    _monthOffset = 0;
    _recomputePeriodicForecasts();
    notifyListeners();
  }

  void setCompatPersonA(MyanmarWeekday weekday) {
    if (_compatPersonA == weekday) return;
    _compatPersonA = weekday;
    _compatibilityResult = _forecastEngine.calculateCompatibility(
      personA: _compatPersonA,
      personB: _compatPersonB,
    );
    notifyListeners();
  }

  void setCompatPersonB(MyanmarWeekday weekday) {
    if (_compatPersonB == weekday) return;
    _compatPersonB = weekday;
    _compatibilityResult = _forecastEngine.calculateCompatibility(
      personA: _compatPersonA,
      personB: _compatPersonB,
    );
    notifyListeners();
  }

  void useMyWeekdayForCompat() {
    setCompatPersonA(userBirthWeekday);
  }

  void selectCalendarDate(DateTime date) {
    _selectedCalendarDate = DateTime(date.year, date.month, date.day);
    _selectedDaySummary = _engine.inspectDate(_selectedCalendarDate);
    notifyListeners();
  }

  void _recalculateReadingOnly({DateTime? referenceDate}) {
    final ref = referenceDate ?? _referenceNow;
    _currentReading = _engine.calculateReading(
      name: _nameInput,
      birthDate: _birthDate,
      isWednesdayNightRahu: _isWednesdayNightRahu,
      gender: _gender,
      focus: _focus,
      referenceDate: ref,
    );
    _recomputePeriodicForecasts();
  }

  void _recomputePeriodicForecasts() {
    final reading = _currentReading;
    if (reading == null) {
      _weeklyForecast = null;
      _monthlyForecast = null;
      return;
    }
    final weekAnchor =
        reading.referenceDate.add(Duration(days: _weekOffset * 7));
    _weeklyForecast = _forecastEngine.calculateWeeklyForecast(
      reading: reading,
      targetDate: weekAnchor,
    );

    final targetMonthDate = DateTime(
      reading.referenceDate.year,
      reading.referenceDate.month + _monthOffset,
      1,
    );
    _monthlyForecast = _forecastEngine.calculateMonthlyForecast(
      reading: reading,
      year: targetMonthDate.year,
      month: targetMonthDate.month,
    );
  }

  /// Calculates and persists personal Baydin + Weekly + Monthly + Mahabote/Yadaya reading.
  Future<void> calculateAndSave({
    required String name,
    DateTime? birthDate,
    bool? isWednesdayNightRahu,
    BaydinGender? gender,
    YadayaFocus? focus,
    BaydinForecastPeriod? period,
    DateTime? referenceDate,
  }) async {
    _nameInput = name.trim();
    if (birthDate != null) {
      _birthDate = DateTime(birthDate.year, birthDate.month, birthDate.day);
    }
    if (isWednesdayNightRahu != null) {
      _isWednesdayNightRahu = isWednesdayNightRahu;
    }
    if (gender != null) _gender = gender;
    if (focus != null) _focus = focus;
    if (period != null) _activePeriod = period;
    if (referenceDate != null) _referenceNow = referenceDate;

    _weekOffset = 0;
    _monthOffset = 0;
    _hasSavedProfile = true;
    _compatPersonA = userBirthWeekday;
    _compatibilityResult = _forecastEngine.calculateCompatibility(
      personA: _compatPersonA,
      personB: _compatPersonB,
    );
    _todayAuspiciousGuide = _forecastEngine.calculateDailyAuspiciousGuide(
      date: _referenceNow,
      userBirthWeekday: userBirthWeekday,
    );

    _recalculateReadingOnly(referenceDate: _referenceNow);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefNameKey, _nameInput);
    await prefs.setString(_prefBirthKey, _birthDate.toIso8601String());
    await prefs.setBool(_prefRahuKey, _isWednesdayNightRahu);
    await prefs.setString(_prefGenderKey, _gender.name);
    await prefs.setString(_prefFocusKey, _focus.name);
  }
}
