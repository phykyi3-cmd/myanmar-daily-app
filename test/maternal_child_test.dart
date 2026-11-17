import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myanmar_daily_app/data/repositories/maternal_child_repository.dart';
import 'package:myanmar_daily_app/data/services/backup_service.dart';
import 'package:myanmar_daily_app/data/services/local_db_service.dart';
import 'package:myanmar_daily_app/data/services/preferences_service.dart';
import 'package:myanmar_daily_app/data/services/telehealth_gateway.dart';
import 'package:myanmar_daily_app/domain/models/emergency_qr_card.dart';
import 'package:myanmar_daily_app/domain/models/maternal_child_models.dart';
import 'package:myanmar_daily_app/domain/use_cases/maternal_child_engine.dart';
import 'package:myanmar_daily_app/ui/features/maternal_child/view_models/maternal_child_view_model.dart';
import 'package:myanmar_daily_app/ui/features/maternal_child/views/maternal_child_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryMchDbService extends LocalDbService {
  final Map<String, List<Map<String, Object?>>> _tables = {};
  int _nextId = 1;

  List<Map<String, Object?>> _rows(String table) =>
      _tables.putIfAbsent(table, () => <Map<String, Object?>>[]);

  @override
  Future<List<Map<String, Object?>>> queryAll(
    String table, {
    String? orderBy,
  }) async {
    return _rows(table).map((r) => Map<String, Object?>.from(r)).toList();
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    final row = Map<String, Object?>.from(values);
    final id = _nextId++;
    row['id'] = id;
    _rows(table).add(row);
    return id;
  }

  @override
  Future<int> updateById(
    String table,
    int id,
    Map<String, Object?> values,
  ) async {
    var updated = 0;
    for (final row in _rows(table)) {
      if ((row['id'] as num?)?.toInt() == id) {
        row.addAll(values);
        updated++;
      }
    }
    return updated;
  }

  @override
  Future<int> deleteById(String table, int id) async {
    final rows = _rows(table);
    final before = rows.length;
    rows.removeWhere((row) => (row['id'] as num?)?.toInt() == id);
    return before - rows.length;
  }

  @override
  Future<void> deleteWhere(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final rows = _rows(table);
    if (where == 'profile_id = ?' && whereArgs.isNotEmpty) {
      rows.removeWhere((row) => row['profile_id'] == whereArgs.first);
    }
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Generates official Myanmar MOHS EPI & Maternal ANC schedules accurately', () {
    const engine = MaternalChildEngine();

    final child = FamilyHealthProfile(
      id: 1,
      name: 'မီးမီး',
      profileType: HealthProfileType.child,
      childGender: ChildGender.girl,
      referenceDate: DateTime(2026, 5, 1),
      createdAt: DateTime(2026, 11, 17),
    );
    final childVaccines = engine.buildInitialImmunizationSchedule(child);
    expect(childVaccines.length, MaternalChildEngine.officialChildEpiTemplates.length);
    expect(childVaccines.first.vaccineCode, 'BCG');
    expect(childVaccines.any((v) => v.vaccineCode == 'PENTA_1'), isTrue);
    expect(childVaccines.any((v) => v.vaccineCode == 'JE_1'), isTrue);
    expect(childVaccines.any((v) => v.vaccineCode == 'MR_2'), isTrue);

    final mother = FamilyHealthProfile(
      id: 2,
      name: 'မမေသူ',
      profileType: HealthProfileType.motherPregnancy,
      referenceDate: DateTime(2026, 7, 1),
      createdAt: DateTime(2026, 11, 17),
    );
    expect(mother.expectedDueDate, DateTime(2027, 4, 7));
    final motherAnc = engine.buildInitialImmunizationSchedule(mother);
    expect(motherAnc.any((v) => v.vaccineCode == 'TD_1'), isTrue);
    expect(motherAnc.any((v) => v.vaccineCode == 'TD_2'), isTrue);
  });

  test('Evaluates WHO Child Weight-for-Age medians accurately for boys & girls', () {
    const engine = MaternalChildEngine();

    expect(engine.interpolateWhoMedianWeightKg(0, ChildGender.boy), 3.3);
    expect(engine.interpolateWhoMedianWeightKg(6, ChildGender.boy), 7.9);
    expect(engine.interpolateWhoMedianWeightKg(12, ChildGender.girl), 8.9);
    // Linear interpolation between 6m (7.9) and 9m (8.9) at 7.5 -> 7m = 8.2
    expect(engine.interpolateWhoMedianWeightKg(7, ChildGender.boy), 8.2);

    final normal = engine.evaluateChildWeight(
      weightKg: 7.9,
      ageMonths: 6,
      gender: ChildGender.boy,
    );
    expect(normal.isAlert, isFalse);

    final lowWeight = engine.evaluateChildWeight(
      weightKg: 5.5,
      ageMonths: 6,
      gender: ChildGender.boy,
    );
    expect(lowWeight.isAlert, isTrue);
  });

  test('Salted Health PIN hashes without plaintext storage and Backup v2 round-trips', () async {
    final prefsService = PreferencesService();
    await prefsService.saveHealthPin('4321');
    final prefs = await SharedPreferences.getInstance();
    final storedRaw = prefs.getString('maternal_child_pin_digest_v1');

    expect(storedRaw, isNotNull);
    expect(storedRaw, isNot(equals('4321')));
    expect(await prefsService.verifyHealthPin('4321'), isTrue);
    expect(await prefsService.verifyHealthPin('0000'), isFalse);

    final backupService = BackupService();
    final json = backupService.encodeBackup(
      BackupSnapshot(
        version: BackupService.currentBackupVersion,
        exportedAt: DateTime(2026, 11, 17),
        ledgerEntries: const [],
        loansRentals: const [],
        shoppingItems: const [],
        reminders: const [],
        qrCard: const EmergencyQrCard(),
        healthProfiles: [
          FamilyHealthProfile(
            id: 7,
            name: 'မမေသူ',
            profileType: HealthProfileType.motherPregnancy,
            referenceDate: DateTime(2026, 8, 1),
            bloodType: 'O+',
            createdAt: DateTime(2026, 11, 17),
          ),
        ],
      ),
    );
    final decoded = backupService.decodeBackup(json);
    expect(decoded.healthProfiles.length, 1);
    expect(decoded.healthProfiles.first.bloodType, 'O+');
  });

  testWidgets('MaternalChildScreen manages profiles, vaccines, nutrition, wellness timer & SBAR QR', (tester) async {
    final db = _InMemoryMchDbService();
    final prefs = PreferencesService();
    final repo = MaternalChildRepository(
      dbService: db,
      preferencesService: prefs,
    );
    final vm = MaternalChildViewModel(repository: repo);
    await repo.createProfile(
      FamilyHealthProfile(
        name: 'သားသား',
        profileType: HealthProfileType.child,
        childGender: ChildGender.boy,
        referenceDate: DateTime.now().subtract(const Duration(days: 190)),
        bloodType: 'B+',
        createdAt: DateTime.now(),
      ),
    );
    await vm.loadAll();

    await tester.pumpWidget(
      MaterialApp(
        home: MaternalChildScreen(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Immunization schedule defaults active and renders official MOHS vaccines.
    expect(find.textContaining('မြန်မာ MOHS EPI ကလေးကာကွယ်ဆေးဇယား'), findsOneWidget);
    expect(find.textContaining('BCG'), findsOneWidget);

    // 2. Switch to Growth / Care tab.
    await tester.tap(find.text('ကိုယ်ဝန်/ကြီးထွား'));
    await tester.pumpAndSettle();
    expect(find.textContaining('WHO ကြီးထွားမှုစံနှုန်း'), findsOneWidget);

    // 3. Switch to Nutrition tab.
    await tester.tap(find.text('အာဟာရ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ဈေးဝယ်စာရင်းထဲ ထည့်မည်'), findsWidgets);

    // 4. Switch to Mindfulness / Wellness tab.
    await tester.tap(find.text('စိတ်အပန်းဖြေ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('တရားရှုမှတ် Timer'), findsOneWidget);
    expect(find.text('03:00'), findsOneWidget);

    // 5. Switch to Doctor Consult Prep (Phase 2) tab.
    await tester.tap(find.text('ဆရာဝန်ပြ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Phase 1 Ready'), findsOneWidget);
    expect(find.textContaining('MYANMAR DAILY - CLINIC CONSULT SUMMARY'), findsOneWidget);
  });

  test('Handles Myanmar numerals, >60m children safely, milestone persistence & cascade delete', () async {
    expect(normalizeAsciiDigits('၇.၉'), '7.9');
    expect(normalizeAsciiDigits('၁၂၀'), '120');
    expect(
      PreferencesService.hashHealthPin('၁၂၃၄'),
      PreferencesService.hashHealthPin('1234'),
    );

    const engine = MaternalChildEngine();
    final schoolAge = engine.evaluateChildWeight(
      weightKg: 22.0,
      ageMonths: 72,
      gender: ChildGender.boy,
    );
    expect(schoolAge.isAlert, isFalse);
    expect(schoolAge.statusLabelMm, contains('၅ နှစ်အထက်'));

    final db = _InMemoryMchDbService();
    final prefs = PreferencesService();
    final repo = MaternalChildRepository(dbService: db, preferencesService: prefs);
    final vm1 = MaternalChildViewModel(repository: repo);

    final mom = await vm1.addProfile(
      name: 'မေမေ',
      profileType: HealthProfileType.motherPregnancy,
      referenceDate: DateTime.now().subtract(const Duration(days: 140)),
    );
    final child = await vm1.addProfile(
      name: 'မီးမီး',
      profileType: HealthProfileType.child,
      referenceDate: DateTime.now().subtract(const Duration(days: 100)),
    );
    await vm1.selectProfile(child);
    await vm1.toggleMilestoneChecked('ပြုံးပြတတ်ခြင်း');

    // Reload fresh VM to confirm milestone persisted per child and isolated from mom.
    final vm2 = MaternalChildViewModel(repository: repo);
    await vm2.loadAll();
    await vm2.selectProfile(child);
    expect(vm2.checkedMilestones.contains('ပြုံးပြတတ်ခြင်း'), isTrue);
    await vm2.selectProfile(mom);
    expect(vm2.checkedMilestones, isEmpty);

    // Cascade delete mom leaves child intact.
    await vm2.deleteProfile(mom.id!);
    expect(vm2.profiles.length, 1);
    expect(vm2.profiles.first.name, 'မီးမီး');
    expect((await repo.getImmunizationsForProfile(mom.id!)), isEmpty);
  });

  testWidgets('Mother pregnancy profile shows LMP gestational week, EDD, ANC & Red-Flag alerts + delete', (tester) async {
    final db = _InMemoryMchDbService();
    final prefs = PreferencesService();
    final repo = MaternalChildRepository(dbService: db, preferencesService: prefs);
    final vm = MaternalChildViewModel(repository: repo);

    await vm.addProfile(
      name: 'မမေသူ',
      profileType: HealthProfileType.motherPregnancy,
      referenceDate: DateTime.now().subtract(const Duration(days: 140)),
    );

    await tester.pumpWidget(MaterialApp(home: MaternalChildScreen(viewModel: vm)));
    await tester.pumpAndSettle();

    expect(find.textContaining('မိခင် ANC & Td'), findsOneWidget);
    await tester.tap(find.text('ကိုယ်ဝန်/ကြီးထွား'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Trimester 2'), findsAtLeastNWidgets(1));
    expect(find.textContaining('ခန့်မှန်းမွေးဖွားရက် (EDD)'), findsOneWidget);
    expect(find.textContaining('Red-Flag Signs'), findsOneWidget);

    await tester.tap(find.byTooltip('ပရိုဖိုင် ဖျက်မည်'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ဖျက်မည်'));
    await tester.pumpAndSettle();
    expect(find.textContaining('မိခင် (ကိုယ်ဝန်ဆောင်) သို့မဟုတ် ကလေး ပရိုဖိုင် စတင်ထည့်သွင်းပါ'), findsOneWidget);
  });

  test('FirebaseTelehealthGateway authenticates via REST and submits/fetches SBAR Cloud tickets', () async {
    final mockClient = MockClient((request) async {
      if (request.url.host == 'identitytoolkit.googleapis.com') {
        return http.Response(
          jsonEncode({
            'localId': 'uid_patient_001',
            'idToken': 'jwt_mock_token_123',
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/documents/consult_requests')) {
        expect(request.headers['Authorization'], 'Bearer jwt_mock_token_123');
        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        final fields = decoded['fields'] as Map<String, dynamic>;
        expect(fields['patientUid']['stringValue'], 'uid_patient_001');
        expect(fields['status']['stringValue'], 'pending_triage');
        return http.Response(
          jsonEncode({
            'name':
                'projects/mm-health-test/databases/(default)/documents/consult_requests/ticket_9001',
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/documents:runQuery')) {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode([
              {
                'document': {
                  'name':
                      'projects/mm-health-test/databases/(default)/documents/consult_requests/ticket_9001',
                  'fields': {
                    'profileName': {'stringValue': 'သားသား'},
                    'urgencyLevel': {'stringValue': 'normal'},
                    'status': {'stringValue': 'completed'},
                    'assignedDoctorName': {'stringValue': 'Dr. Su Mon'},
                    'doctorNoteMm': {'stringValue': 'အရည်များများတိုက်ပြီး အဖျားတိုင်းပါ'},
                    'requestedAt': {'timestampValue': '2026-11-17T08:00:00Z'},
                  },
                },
              },
            ]),
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final db = _InMemoryMchDbService();
    final prefs = PreferencesService();
    final repo = MaternalChildRepository(
      dbService: db,
      preferencesService: prefs,
      httpClient: mockClient,
    );

    final signedIn = await repo.connectCloudTelehealth(
      projectId: 'mm-health-test',
      apiKey: 'AIzaTestWebKey',
    );
    expect(signedIn.isAuthenticated, isTrue);
    expect(signedIn.patientUid, 'uid_patient_001');

    final receipt = await repo.submitCloudConsult(
      TelehealthConsultRequest(
        profileName: 'သားသား',
        stageLabelMm: '၃ လသား',
        sbarSummary: 'MYANMAR DAILY - CLINIC CONSULT SUMMARY',
        urgencyLevel: 'normal',
        requestedAt: DateTime.utc(2026, 11, 17, 8),
      ),
    );
    expect(receipt.ticketId, 'ticket_9001');

    final tickets = await repo.fetchCloudTickets();
    expect(tickets.length, 1);
    expect(tickets.first.assignedDoctorName, 'Dr. Su Mon');
    expect(tickets.first.status, 'completed');
  });

  testWidgets('Cloud Telehealth setup dialog connects and submits SBAR ticket in UI', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.host == 'identitytoolkit.googleapis.com') {
        return http.Response(
          jsonEncode({'localId': 'uid_ui_1', 'idToken': 'tok_ui_1'}),
          200,
        );
      }
      if (request.url.path.endsWith('/documents:runQuery')) {
        return http.Response(jsonEncode([]), 200);
      }
      if (request.url.path.endsWith('/documents/consult_requests')) {
        return http.Response(
          jsonEncode({
            'name':
                'projects/demo-proj/databases/(default)/documents/consult_requests/tk_ui_77',
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final db = _InMemoryMchDbService();
    final prefs = PreferencesService();
    final repo = MaternalChildRepository(
      dbService: db,
      preferencesService: prefs,
      httpClient: mockClient,
    );
    final vm = MaternalChildViewModel(repository: repo);
    await vm.addProfile(
      name: 'သားသား',
      profileType: HealthProfileType.child,
      referenceDate: DateTime.now().subtract(const Duration(days: 90)),
    );

    await tester.pumpWidget(MaterialApp(home: MaternalChildScreen(viewModel: vm)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ဆရာဝန်ပြ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cloud Telehealth ချိတ်ဆက်မည်'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Firebase Project ID'),
      'demo-proj',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Firebase Web API Key'),
      'AIzaDemoKey',
    );
    await tester.tap(find.text('ချိတ်ဆက်မည်'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Phase 2 Active'), findsOneWidget);
    final sendBtn = find.text('Cloud မှတစ်ဆင့် ဆရာဝန် Queue သို့ ပို့မည်');
    await tester.scrollUntilVisible(
      sendBtn,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(sendBtn);
    await tester.pumpAndSettle();

    final ticketFinder = find.textContaining('#tk_ui_77');
    await tester.scrollUntilVisible(
      ticketFinder,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(ticketFinder, findsOneWidget);
  });
}
