import 'package:flutter/foundation.dart';

import 'package:myanmar_daily_app/data/repositories/maternal_child_repository.dart';
import 'package:myanmar_daily_app/data/services/telehealth_gateway.dart';
import 'package:myanmar_daily_app/domain/models/maternal_child_models.dart';
import 'package:myanmar_daily_app/domain/use_cases/maternal_child_engine.dart';

/// Five core offline + telehealth-ready sub-views inside the Maternal & Child Hub.
enum MaternalChildSection {
  immunization(labelMm: 'ကာကွယ်ဆေး'),
  growthCare(labelMm: 'ကိုယ်ဝန်/ကြီးထွား'),
  nutrition(labelMm: 'အာဟာရ'),
  wellness(labelMm: 'စိတ်အပန်းဖြေ'),
  consultPrep(labelMm: 'ဆရာဝန်ပြ');

  const MaternalChildSection({required this.labelMm});
  final String labelMm;
}

/// ViewModel managing Maternal Pregnancy tracking, Child EPI immunizations,
/// WHO growth evaluation, weaning/maternal meals, mindfulness mood state, and PIN security.
class MaternalChildViewModel extends ChangeNotifier {
  MaternalChildViewModel({
    required MaternalChildRepository repository,
  }) : _repository = repository;

  final MaternalChildRepository _repository;

  MaternalChildSection _activeSection = MaternalChildSection.immunization;
  MaternalChildSection get activeSection => _activeSection;

  List<FamilyHealthProfile> _profiles = const [];
  List<FamilyHealthProfile> get profiles => _profiles;

  FamilyHealthProfile? _selectedProfile;
  FamilyHealthProfile? get selectedProfile => _selectedProfile;

  List<ImmunizationRecord> _immunizations = const [];
  List<ImmunizationRecord> get immunizations => _immunizations;

  List<HealthGrowthLog> _growthLogs = const [];
  List<HealthGrowthLog> get growthLogs => _growthLogs;

  bool _isLocked = false;
  bool get isLocked => _isLocked;

  bool _hasPinSet = false;
  bool get hasPinSet => _hasPinSet;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  TelehealthConnectionStatus? _telehealthStatus;
  TelehealthConnectionStatus? get telehealthStatus => _telehealthStatus;

  CloudTelehealthConfig _cloudConfig = const CloudTelehealthConfig();
  CloudTelehealthConfig get cloudConfig => _cloudConfig;

  List<TelehealthTicketReceipt> _cloudTickets = const [];
  List<TelehealthTicketReceipt> get cloudTickets => _cloudTickets;

  bool _isCloudBusy = false;
  bool get isCloudBusy => _isCloudBusy;

  String? _cloudErrorMm;
  String? get cloudErrorMm => _cloudErrorMm;

  final Set<String> _checkedMilestones = <String>{};
  Set<String> get checkedMilestones => _checkedMilestones;

  MaternalChildEngine get engine => _repository.engine;

  void setActiveSection(MaternalChildSection section) {
    if (_activeSection == section) return;
    _activeSection = section;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    _hasPinSet = await _repository.hasHealthPin();
    _isLocked = _hasPinSet;
    _cloudConfig = await _repository.loadCloudTelehealthConfig();
    _telehealthStatus = await _repository.checkTelehealthStatus();
    if (_cloudConfig.isAuthenticated) {
      try {
        _cloudTickets = await _repository.fetchCloudTickets();
      } catch (_) {
        // Offline or expired session token silently keeps cached Phase 1 tools active.
      }
    }

    await _reloadData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _reloadData() async {
    _profiles = await _repository.getProfiles();
    if (_profiles.isEmpty) {
      _selectedProfile = null;
      _immunizations = const [];
      _growthLogs = const [];
      return;
    }

    final currentId = _selectedProfile?.id;
    _selectedProfile = _profiles.firstWhere(
      (p) => p.id == currentId,
      orElse: () => _profiles.first,
    );

    final activeId = _selectedProfile?.id;
    if (activeId != null) {
      _immunizations = await _repository.getImmunizationsForProfile(activeId);
      _growthLogs = await _repository.getGrowthLogsForProfile(activeId);
      _checkedMilestones
        ..clear()
        ..addAll(await _repository.loadCheckedMilestones(activeId));
    } else {
      _checkedMilestones.clear();
    }
  }

  Future<void> selectProfile(FamilyHealthProfile profile) async {
    _selectedProfile = profile;
    if (profile.id != null) {
      _immunizations =
          await _repository.getImmunizationsForProfile(profile.id!);
      _growthLogs = await _repository.getGrowthLogsForProfile(profile.id!);
      _checkedMilestones
        ..clear()
        ..addAll(await _repository.loadCheckedMilestones(profile.id!));
    } else {
      _checkedMilestones.clear();
    }
    notifyListeners();
  }

  Future<FamilyHealthProfile> addProfile({
    required String name,
    required HealthProfileType profileType,
    required DateTime referenceDate,
    ChildGender childGender = ChildGender.girl,
    String bloodType = '',
    String allergyNote = '',
  }) async {
    final profile = FamilyHealthProfile(
      name: name.trim(),
      profileType: profileType,
      childGender: childGender,
      referenceDate: DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
      ),
      bloodType: bloodType.trim(),
      allergyNote: allergyNote.trim(),
      createdAt: DateTime.now(),
    );
    final created = await _repository.createProfile(profile);
    _selectedProfile = created;
    await _reloadData();
    notifyListeners();
    return created;
  }

  Future<void> deleteProfile(int profileId) async {
    await _repository.deleteProfile(profileId);
    if (_selectedProfile?.id == profileId) {
      _selectedProfile = null;
    }
    await _reloadData();
    notifyListeners();
  }

  Future<void> toggleImmunization(
    ImmunizationRecord record,
    bool completed,
  ) async {
    await _repository.toggleImmunizationCompleted(record, completed);
    final activeId = _selectedProfile?.id;
    if (activeId != null) {
      _immunizations = await _repository.getImmunizationsForProfile(activeId);
    }
    notifyListeners();
  }

  Future<void> addGrowthOrVitalLog({
    double? weightKg,
    double? heightCm,
    int? bpSystolic,
    int? bpDiastolic,
    int moodScore = 3,
    String symptomsNote = '',
  }) async {
    final activeId = _selectedProfile?.id;
    if (activeId == null) return;
    await _repository.addGrowthLog(
      HealthGrowthLog(
        profileId: activeId,
        recordedAt: DateTime.now(),
        weightKg: weightKg,
        heightCm: heightCm,
        bpSystolic: bpSystolic,
        bpDiastolic: bpDiastolic,
        moodScore: moodScore,
        symptomsNote: symptomsNote.trim(),
      ),
    );
    _growthLogs = await _repository.getGrowthLogsForProfile(activeId);
    notifyListeners();
  }

  Future<void> deleteGrowthLog(int logId) async {
    await _repository.deleteGrowthLog(logId);
    final activeId = _selectedProfile?.id;
    if (activeId != null) {
      _growthLogs = await _repository.getGrowthLogsForProfile(activeId);
    }
    notifyListeners();
  }

  Future<void> toggleMilestoneChecked(String milestone) async {
    if (_checkedMilestones.contains(milestone)) {
      _checkedMilestones.remove(milestone);
    } else {
      _checkedMilestones.add(milestone);
    }
    final activeId = _selectedProfile?.id;
    if (activeId != null) {
      await _repository.saveCheckedMilestones(activeId, _checkedMilestones);
    }
    notifyListeners();
  }

  GrowthEvaluation? evaluateLatestChildWeight([DateTime? now]) {
    final profile = _selectedProfile;
    if (profile == null || profile.profileType != HealthProfileType.child) {
      return null;
    }
    final latestWithWeight = _growthLogs
        .where((l) => l.weightKg != null && l.weightKg! > 0)
        .firstOrNull;
    if (latestWithWeight == null) return null;
    return engine.evaluateChildWeight(
      weightKg: latestWithWeight.weightKg!,
      ageMonths: profile.ageMonthsAt(now),
      gender: profile.childGender,
    );
  }

  List<NutritionGuideMeal> filteredNutritionMeals([DateTime? now]) {
    final profile = _selectedProfile;
    if (profile == null) return MaternalChildEngine.nutritionMeals;
    if (profile.profileType == HealthProfileType.motherPregnancy) {
      return MaternalChildEngine.nutritionMeals
          .where((m) => m.forMother)
          .toList();
    }
    final ageMonths = profile.ageMonthsAt(now);
    final childMeals = MaternalChildEngine.nutritionMeals
        .where((m) => !m.forMother && ageMonths >= m.minChildAgeMonths)
        .toList();
    return childMeals.isEmpty
        ? MaternalChildEngine.nutritionMeals.where((m) => !m.forMother).toList()
        : childMeals;
  }

  String buildSbarSummary([String customConcern = '', DateTime? now]) {
    final profile = _selectedProfile;
    if (profile == null) return '';
    return engine.buildSbarConsultSummary(
      profile: profile,
      records: _immunizations,
      latestLog: _growthLogs.firstOrNull,
      customConcern: customConcern,
      now: now,
    );
  }

  Future<bool> unlockWithPin(String pin) async {
    final valid = await _repository.verifyHealthPin(pin);
    if (valid) {
      _isLocked = false;
      notifyListeners();
    }
    return valid;
  }

  void lockScreen() {
    if (!_hasPinSet) return;
    _isLocked = true;
    notifyListeners();
  }

  Future<void> configurePin(String? newPin) async {
    await _repository.saveHealthPin(newPin);
    _hasPinSet = newPin != null && newPin.trim().isNotEmpty;
    if (!_hasPinSet) _isLocked = false;
    notifyListeners();
  }

  Future<bool> connectCloudTelehealth({
    required String projectId,
    required String apiKey,
    String email = '',
    String password = '',
    bool createAccount = false,
  }) async {
    _isCloudBusy = true;
    _cloudErrorMm = null;
    notifyListeners();
    try {
      _cloudConfig = await _repository.connectCloudTelehealth(
        projectId: projectId,
        apiKey: apiKey,
        email: email,
        password: password,
        createAccount: createAccount,
      );
      _telehealthStatus = await _repository.checkTelehealthStatus();
      _cloudTickets = await _repository.fetchCloudTickets();
      return true;
    } catch (e) {
      _cloudErrorMm = e.toString().replaceFirst('Bad state: ', '');
      return false;
    } finally {
      _isCloudBusy = false;
      notifyListeners();
    }
  }

  Future<void> disconnectCloudTelehealth() async {
    await _repository.disconnectCloudTelehealth();
    _cloudConfig = const CloudTelehealthConfig();
    _cloudTickets = const [];
    _cloudErrorMm = null;
    _telehealthStatus = await _repository.checkTelehealthStatus();
    notifyListeners();
  }

  Future<TelehealthTicketReceipt?> submitConsultToCloud({
    String customConcern = '',
    String urgencyLevel = 'normal',
  }) async {
    final profile = _selectedProfile;
    if (profile == null) return null;
    _isCloudBusy = true;
    _cloudErrorMm = null;
    notifyListeners();
    try {
      final receipt = await _repository.submitCloudConsult(
        TelehealthConsultRequest(
          profileName: profile.name,
          stageLabelMm: profile.ageOrStageSummaryMm(),
          sbarSummary: buildSbarSummary(customConcern),
          urgencyLevel: urgencyLevel,
          requestedAt: DateTime.now(),
        ),
      );
      _cloudConfig = await _repository.loadCloudTelehealthConfig();
      _cloudTickets = [receipt, ..._cloudTickets];
      return receipt;
    } catch (e) {
      _cloudErrorMm = e.toString().replaceFirst('Bad state: ', '');
      return null;
    } finally {
      _isCloudBusy = false;
      notifyListeners();
    }
  }

  Future<void> refreshCloudTickets() async {
    if (!_cloudConfig.isAuthenticated) return;
    _isCloudBusy = true;
    _cloudErrorMm = null;
    notifyListeners();
    try {
      _cloudTickets = await _repository.fetchCloudTickets();
    } catch (e) {
      _cloudErrorMm = e.toString().replaceFirst('Bad state: ', '');
    } finally {
      _isCloudBusy = false;
      notifyListeners();
    }
  }
}
