import 'package:http/http.dart' as http;

import '../../domain/models/maternal_child_models.dart';
import '../../domain/use_cases/maternal_child_engine.dart';
import '../services/local_db_service.dart';
import '../services/preferences_service.dart';
import '../services/telehealth_gateway.dart';

/// Persists Maternal & Child profiles, EPI vaccination schedules, growth/vital logs,
/// local security PIN, and optional Phase 2 Firebase Telehealth consultation state.
class MaternalChildRepository {
  MaternalChildRepository({
    required LocalDbService dbService,
    required PreferencesService preferencesService,
    MaternalChildEngine engine = const MaternalChildEngine(),
    TelehealthGateway telehealthGateway = const OfflinePreparedTelehealthGateway(),
    http.Client? httpClient,
  })  : _dbService = dbService,
        _preferencesService = preferencesService,
        _engine = engine,
        _telehealthGateway = telehealthGateway,
        _httpClient = httpClient;

  final LocalDbService _dbService;
  final PreferencesService _preferencesService;
  final MaternalChildEngine _engine;
  final TelehealthGateway _telehealthGateway;
  final http.Client? _httpClient;

  MaternalChildEngine get engine => _engine;

  Future<List<FamilyHealthProfile>> getProfiles() async {
    final rows = await _dbService.queryAll(
      LocalDbService.tableMaternalChildProfiles,
      orderBy: 'created_at DESC',
    );
    return rows.map(FamilyHealthProfile.fromMap).toList();
  }

  /// Inserts a profile and automatically populates its official MOHS EPI / Maternal ANC doses.
  Future<FamilyHealthProfile> createProfile(FamilyHealthProfile profile) async {
    final insertedId = await _dbService.insert(
      LocalDbService.tableMaternalChildProfiles,
      profile.toMap(),
    );
    final savedProfile = profile.copyWith(id: insertedId);
    final schedule = _engine.buildInitialImmunizationSchedule(savedProfile);
    for (final dose in schedule) {
      await _dbService.insert(
        LocalDbService.tableImmunizationRecords,
        dose.toMap(),
      );
    }
    return savedProfile;
  }

  Future<void> restoreProfileRaw(FamilyHealthProfile profile) async {
    await _dbService.insert(
      LocalDbService.tableMaternalChildProfiles,
      profile.toMap(),
    );
  }

  Future<void> deleteProfile(int profileId) async {
    await _dbService.deleteWhere(
      LocalDbService.tableImmunizationRecords,
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
    await _dbService.deleteWhere(
      LocalDbService.tableHealthGrowthLogs,
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
    await _preferencesService.saveCheckedMilestones(profileId, const {});
    await _dbService.deleteById(
      LocalDbService.tableMaternalChildProfiles,
      profileId,
    );
  }

  Future<Set<String>> loadCheckedMilestones(int profileId) =>
      _preferencesService.loadCheckedMilestones(profileId);

  Future<void> saveCheckedMilestones(int profileId, Set<String> items) =>
      _preferencesService.saveCheckedMilestones(profileId, items);

  Future<List<ImmunizationRecord>> getAllImmunizationRecords() async {
    final rows = await _dbService.queryAll(
      LocalDbService.tableImmunizationRecords,
      orderBy: 'due_date ASC',
    );
    return rows.map(ImmunizationRecord.fromMap).toList();
  }

  Future<List<ImmunizationRecord>> getImmunizationsForProfile(
    int profileId,
  ) async {
    final all = await getAllImmunizationRecords();
    final filtered = all.where((r) => r.profileId == profileId).toList()
      ..sort((a, b) => a.dueAgeDays.compareTo(b.dueAgeDays));
    return filtered;
  }

  Future<void> insertImmunizationRecord(ImmunizationRecord record) async {
    await _dbService.insert(
      LocalDbService.tableImmunizationRecords,
      record.toMap(),
    );
  }

  Future<void> toggleImmunizationCompleted(
    ImmunizationRecord record,
    bool completed,
  ) async {
    if (record.id == null) return;
    final updated = record.copyWith(
      isCompleted: completed,
      completedDate: completed ? DateTime.now() : null,
    );
    await _dbService.updateById(
      LocalDbService.tableImmunizationRecords,
      record.id!,
      {
        'is_completed': updated.isCompleted ? 1 : 0,
        'completed_date': updated.completedDate?.toIso8601String(),
      },
    );
  }

  Future<List<HealthGrowthLog>> getAllGrowthLogs() async {
    final rows = await _dbService.queryAll(
      LocalDbService.tableHealthGrowthLogs,
      orderBy: 'recorded_at DESC',
    );
    return rows.map(HealthGrowthLog.fromMap).toList();
  }

  Future<List<HealthGrowthLog>> getGrowthLogsForProfile(int profileId) async {
    final all = await getAllGrowthLogs();
    final filtered = all.where((l) => l.profileId == profileId).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return filtered;
  }

  Future<int> addGrowthLog(HealthGrowthLog log) async {
    return _dbService.insert(
      LocalDbService.tableHealthGrowthLogs,
      log.toMap(),
    );
  }

  Future<void> deleteGrowthLog(int logId) async {
    await _dbService.deleteById(LocalDbService.tableHealthGrowthLogs, logId);
  }

  Future<bool> hasHealthPin() => _preferencesService.hasHealthPin();
  Future<bool> verifyHealthPin(String pin) =>
      _preferencesService.verifyHealthPin(pin);
  Future<void> saveHealthPin(String? pin) =>
      _preferencesService.saveHealthPin(pin);

  Future<CloudTelehealthConfig> loadCloudTelehealthConfig() =>
      _preferencesService.loadCloudTelehealthConfig();

  Future<TelehealthConnectionStatus> checkTelehealthStatus() async {
    final config = await loadCloudTelehealthConfig();
    if (config.isAuthenticated) {
      return FirebaseTelehealthGateway(
        config: config,
        httpClient: _httpClient,
      ).checkStatus();
    }
    return _telehealthGateway.checkStatus();
  }

  Future<CloudTelehealthConfig> connectCloudTelehealth({
    required String projectId,
    required String apiKey,
    String email = '',
    String password = '',
    bool createAccount = false,
  }) async {
    final baseConfig = CloudTelehealthConfig(
      projectId: projectId.trim(),
      apiKey: apiKey.trim(),
    );
    final gateway = FirebaseTelehealthGateway(
      config: baseConfig,
      httpClient: _httpClient,
    );
    final signedIn = await gateway.authenticate(
      email: email,
      password: password,
      createAccount: createAccount,
    );
    await _preferencesService.saveCloudTelehealthConfig(signedIn);
    return signedIn;
  }

  Future<void> disconnectCloudTelehealth() async {
    await _preferencesService.saveCloudTelehealthConfig(
      const CloudTelehealthConfig(),
    );
  }

  Future<TelehealthTicketReceipt> submitCloudConsult(
    TelehealthConsultRequest request,
  ) async {
    final config = await loadCloudTelehealthConfig();
    final gateway = FirebaseTelehealthGateway(
      config: config,
      httpClient: _httpClient,
    );
    final receipt = await gateway.submitConsultTicket(request);
    await _preferencesService.saveCloudTelehealthConfig(
      config.copyWith(
        lastTicketId: receipt.ticketId,
        lastTicketStatus: receipt.status,
      ),
    );
    return receipt;
  }

  Future<List<TelehealthTicketReceipt>> fetchCloudTickets() async {
    final config = await loadCloudTelehealthConfig();
    if (!config.isAuthenticated) return const [];
    return FirebaseTelehealthGateway(
      config: config,
      httpClient: _httpClient,
    ).fetchPatientTickets();
  }
}
