import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myanmar_daily_app/domain/models/baydin_reading.dart';
import 'package:myanmar_daily_app/domain/use_cases/myanmar_baydin_engine.dart';

/// Two primary sub-views inside the 'ဗေဒင်/ယတြာ' tab.
enum BaydinSection { calculator, calendar }

/// Filter modes for the 30-day Auspicious & Sabbath Calendar list.
enum CalendarFilter { all, yatyazaOnly, sabbathOnly, pyathadaOnly }

/// ViewModel powering Sayar San Zarni Bo style Mahabote / Yadaya & Myanmar Calendar.
class BaydinViewModel extends ChangeNotifier {
  BaydinViewModel({
    MyanmarBaydinEngine? engine,
  }) : _engine = engine ?? MyanmarBaydinEngine();

  final MyanmarBaydinEngine _engine;

  static const _prefNameKey = 'baydin_saved_name_v1';
  static const _prefBirthKey = 'baydin_saved_birth_iso_v1';
  static const _prefRahuKey = 'baydin_saved_wed_rahu_v1';
  static const _prefGenderKey = 'baydin_saved_gender_v1';
  static const _prefFocusKey = 'baydin_saved_focus_v1';

  BaydinSection _activeSection = BaydinSection.calculator;
  BaydinSection get activeSection => _activeSection;

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

  BaydinReading? _currentReading;
  BaydinReading? get currentReading => _currentReading;

  DateTime _selectedCalendarDate = DateTime.now();
  DateTime get selectedCalendarDate => _selectedCalendarDate;

  CalendarDaySummary? _todaySummary;
  CalendarDaySummary? get todaySummary => _todaySummary;

  CalendarDaySummary? _selectedDaySummary;
  CalendarDaySummary? get selectedDaySummary => _selectedDaySummary;

  List<CalendarDaySummary> _upcomingDays = const [];
  List<CalendarDaySummary> get upcomingDays => _upcomingDays;

  bool _loaded = false;

  void setActiveSection(BaydinSection section) {
    if (_activeSection == section) return;
    _activeSection = section;
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
      }
      if (savedBirth != null) {
        final parsed = DateTime.tryParse(savedBirth);
        if (parsed != null) _birthDate = parsed;
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
      _loaded = true;
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
    notifyListeners();
  }

  void updateBirthDate(DateTime date) {
    _birthDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setWednesdayNightRahu(bool value) {
    if (_isWednesdayNightRahu == value) return;
    _isWednesdayNightRahu = value;
    if (_currentReading != null) {
      _currentReading = _engine.calculateReading(
        name: _nameInput,
        birthDate: _birthDate,
        isWednesdayNightRahu: _isWednesdayNightRahu,
        gender: _gender,
        focus: _focus,
      );
    }
    notifyListeners();
  }

  void setGender(BaydinGender value) {
    if (_gender == value) return;
    _gender = value;
    if (_currentReading != null) {
      _currentReading = _engine.calculateReading(
        name: _nameInput,
        birthDate: _birthDate,
        isWednesdayNightRahu: _isWednesdayNightRahu,
        gender: _gender,
        focus: _focus,
      );
    }
    notifyListeners();
  }

  void setFocus(YadayaFocus value) {
    if (_focus == value) return;
    _focus = value;
    if (_currentReading != null) {
      _currentReading = _engine.calculateReading(
        name: _nameInput,
        birthDate: _birthDate,
        isWednesdayNightRahu: _isWednesdayNightRahu,
        gender: _gender,
        focus: _focus,
      );
    }
    notifyListeners();
  }

  void selectCalendarDate(DateTime date) {
    _selectedCalendarDate = DateTime(date.year, date.month, date.day);
    _selectedDaySummary = _engine.inspectDate(_selectedCalendarDate);
    notifyListeners();
  }

  /// Calculates and persists the personal Baydin + Mahabote + Flower + Alms + Wear/Avoid Outfit reading.
  Future<void> calculateAndSave({
    required String name,
    DateTime? birthDate,
    bool? isWednesdayNightRahu,
    BaydinGender? gender,
    YadayaFocus? focus,
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

    _currentReading = _engine.calculateReading(
      name: _nameInput,
      birthDate: _birthDate,
      isWednesdayNightRahu: _isWednesdayNightRahu,
      gender: _gender,
      focus: _focus,
      referenceDate: referenceDate,
    );
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefNameKey, _nameInput);
    await prefs.setString(_prefBirthKey, _birthDate.toIso8601String());
    await prefs.setBool(_prefRahuKey, _isWednesdayNightRahu);
    await prefs.setString(_prefGenderKey, _gender.name);
    await prefs.setString(_prefFocusKey, _focus.name);
  }
}
