import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cloud configuration and authenticated patient session for Phase 2 Firebase Telehealth.
///
/// Stores only client-side Firebase Web config (`projectId`, `apiKey`) and the signed-in
/// patient's short-lived Firebase Auth `idToken` + `patientUid`. Doctor triage requires
/// server-enforced custom claims (`doctor_verified == true`) per `cloud_backend/firestore.rules`.
class CloudTelehealthConfig {
  const CloudTelehealthConfig({
    this.projectId = '',
    this.apiKey = '',
    this.patientUid = '',
    this.patientEmail = '',
    this.idToken = '',
    this.lastTicketId = '',
    this.lastTicketStatus = '',
  });

  final String projectId;
  final String apiKey;
  final String patientUid;
  final String patientEmail;
  final String idToken;
  final String lastTicketId;
  final String lastTicketStatus;

  bool get hasProjectConfig =>
      projectId.trim().isNotEmpty && apiKey.trim().isNotEmpty;

  bool get isAuthenticated =>
      hasProjectConfig &&
      patientUid.trim().isNotEmpty &&
      idToken.trim().isNotEmpty;

  CloudTelehealthConfig copyWith({
    String? projectId,
    String? apiKey,
    String? patientUid,
    String? patientEmail,
    String? idToken,
    String? lastTicketId,
    String? lastTicketStatus,
  }) {
    return CloudTelehealthConfig(
      projectId: projectId ?? this.projectId,
      apiKey: apiKey ?? this.apiKey,
      patientUid: patientUid ?? this.patientUid,
      patientEmail: patientEmail ?? this.patientEmail,
      idToken: idToken ?? this.idToken,
      lastTicketId: lastTicketId ?? this.lastTicketId,
      lastTicketStatus: lastTicketStatus ?? this.lastTicketStatus,
    );
  }

  Map<String, Object?> toJson() => {
        'projectId': projectId,
        'apiKey': apiKey,
        'patientUid': patientUid,
        'patientEmail': patientEmail,
        'idToken': idToken,
        'lastTicketId': lastTicketId,
        'lastTicketStatus': lastTicketStatus,
      };

  factory CloudTelehealthConfig.fromJson(Map<String, dynamic> map) {
    return CloudTelehealthConfig(
      projectId: (map['projectId'] as String?) ?? '',
      apiKey: (map['apiKey'] as String?) ?? '',
      patientUid: (map['patientUid'] as String?) ?? '',
      patientEmail: (map['patientEmail'] as String?) ?? '',
      idToken: (map['idToken'] as String?) ?? '',
      lastTicketId: (map['lastTicketId'] as String?) ?? '',
      lastTicketStatus: (map['lastTicketStatus'] as String?) ?? '',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static CloudTelehealthConfig fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const CloudTelehealthConfig();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return CloudTelehealthConfig.fromJson(decoded);
      }
    } catch (_) {
      // Ignore malformed stored configuration and fall back to offline defaults.
    }
    return const CloudTelehealthConfig();
  }
}

/// Phase 2 Telehealth preparation contract and structured consultation intake payload.
class TelehealthConsultRequest {
  const TelehealthConsultRequest({
    required this.profileName,
    required this.stageLabelMm,
    required this.sbarSummary,
    required this.urgencyLevel,
    required this.requestedAt,
  });

  final String profileName;
  final String stageLabelMm;
  final String sbarSummary;
  final String urgencyLevel;
  final DateTime requestedAt;

  Map<String, Object?> toJson() => {
        'profileName': profileName,
        'stageLabelMm': stageLabelMm,
        'sbarSummary': sbarSummary,
        'urgencyLevel': urgencyLevel,
        'requestedAt': requestedAt.toIso8601String(),
      };
}

/// Persisted or fetched Firestore consultation triage ticket status.
class TelehealthTicketReceipt {
  const TelehealthTicketReceipt({
    required this.ticketId,
    required this.profileName,
    required this.urgencyLevel,
    required this.status,
    required this.requestedAt,
    this.assignedDoctorName = '',
    this.doctorNoteMm = '',
  });

  final String ticketId;
  final String profileName;
  final String urgencyLevel;
  final String status;
  final DateTime requestedAt;
  final String assignedDoctorName;
  final String doctorNoteMm;

  String get statusLabelMm => switch (status) {
        'pending_triage' => 'ဆရာဝန် စိစစ်လက်ခံရန် စောင့်ဆိုင်းနေသည်',
        'in_review' => 'ဆရာဝန်မှ စစ်ဆေးနေပါသည်',
        'completed' => 'ဆရာဝန် အကြံပြုချက် ပြန်ကြားပြီး',
        'referred' => 'အရေးပေါ်/ပြင်ပဆေးခန်းသို့ ညွှန်ပို့ထားသည်',
        _ => status,
      };
}

class TelehealthConnectionStatus {
  const TelehealthConnectionStatus({
    required this.isLiveProviderConfigured,
    required this.statusLabelMm,
    required this.requirementsSummaryMm,
    this.activeProjectId = '',
    this.patientUid = '',
  });

  final bool isLiveProviderConfigured;
  final String statusLabelMm;
  final String requirementsSummaryMm;
  final String activeProjectId;
  final String patientUid;
}

abstract class TelehealthGateway {
  Future<TelehealthConnectionStatus> checkStatus();
  Future<String> stageConsultRequest(TelehealthConsultRequest request);
}

/// Offline Phase 1 implementation preparing verified SBAR data without simulating a fake doctor reply.
class OfflinePreparedTelehealthGateway implements TelehealthGateway {
  const OfflinePreparedTelehealthGateway();

  @override
  Future<TelehealthConnectionStatus> checkStatus() async {
    return const TelehealthConnectionStatus(
      isLiveProviderConfigured: false,
      statusLabelMm: 'Offline ကြိုတင်ပြင်ဆင်မှု အဆင့် (Phase 1 Ready)',
      requirementsSummaryMm:
          'Firebase Project ID နှင့် Web API Key ချိတ်ဆက်ပြီးပါက Encrypted Auth + Cloud Firestore SBAR Queue ဖြင့် ဆရာဝန်ထံ တိုက်ရိုက်ပေးပို့နိုင်ပါမည်။ လက်ရှိတွင် ဆေးခန်းပြရန် SBAR မှတ်တမ်းနှင့် QR ကို Offline အသင့်ထုတ်ယူနိုင်ပါပြီ။',
    );
  }

  @override
  Future<String> stageConsultRequest(TelehealthConsultRequest request) async {
    return request.sbarSummary;
  }
}

/// Live Phase 2 Gateway powered by Firebase Auth REST API + Cloud Firestore REST API.
class FirebaseTelehealthGateway implements TelehealthGateway {
  FirebaseTelehealthGateway({
    required this.config,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final CloudTelehealthConfig config;
  final http.Client _client;

  static const _authBase = 'https://identitytoolkit.googleapis.com/v1';

  Uri _firestoreCollectionUri() => Uri.parse(
        'https://firestore.googleapis.com/v1/projects/${config.projectId.trim()}/databases/(default)/documents/consult_requests',
      );

  Uri _firestoreQueryUri() => Uri.parse(
        'https://firestore.googleapis.com/v1/projects/${config.projectId.trim()}/databases/(default)/documents:runQuery',
      );

  /// Authenticates a family account (Email/Password Sign-Up, Sign-In, or Anonymous session).
  Future<CloudTelehealthConfig> authenticate({
    String email = '',
    String password = '',
    bool createAccount = false,
  }) async {
    if (!config.hasProjectConfig) {
      throw StateError('Firebase Project ID နှင့် Web API Key ထည့်သွင်းပါ');
    }
    final cleanEmail = email.trim();
    final endpoint = cleanEmail.isEmpty
        ? 'accounts:signUp'
        : (createAccount ? 'accounts:signUp' : 'accounts:signInWithPassword');
    final uri = Uri.parse('$_authBase/$endpoint?key=${config.apiKey.trim()}');
    final body = cleanEmail.isEmpty
        ? <String, Object?>{'returnSecureToken': true}
        : <String, Object?>{
            'email': cleanEmail,
            'password': password,
            'returnSecureToken': true,
          };

    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final decoded = _decodeJsonMap(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final errMsg =
          (decoded['error'] as Map?)?['message']?.toString() ?? 'AUTH_FAILED';
      throw StateError('Firebase Auth Error: $errMsg');
    }

    final uid = (decoded['localId'] as String?) ?? '';
    final token = (decoded['idToken'] as String?) ?? '';
    if (uid.isEmpty || token.isEmpty) {
      throw StateError('Firebase Auth response missing session token');
    }
    return config.copyWith(
      patientUid: uid,
      patientEmail: cleanEmail.isEmpty ? 'Guest ($uid)' : cleanEmail,
      idToken: token,
    );
  }

  @override
  Future<TelehealthConnectionStatus> checkStatus() async {
    if (!config.isAuthenticated) {
      return const OfflinePreparedTelehealthGateway().checkStatus();
    }
    return TelehealthConnectionStatus(
      isLiveProviderConfigured: true,
      activeProjectId: config.projectId.trim(),
      patientUid: config.patientUid,
      statusLabelMm: 'Cloud Telehealth ချိတ်ဆက်ပြီး (Phase 2 Active)',
      requirementsSummaryMm:
          'Firebase Project (${config.projectId.trim()}) နှင့် ချိတ်ဆက်ထားပြီး Patient UID (${_shortId(config.patientUid)}) ဖြင့် Security Rules စိစစ်ကာ SBAR တိုင်ပင်မှုများ ပေးပို့နိုင်ပါပြီ။',
    );
  }

  @override
  Future<String> stageConsultRequest(TelehealthConsultRequest request) async {
    final receipt = await submitConsultTicket(request);
    return receipt.ticketId;
  }

  /// Writes an authenticated SBAR triage ticket directly to Firestore `/consult_requests`.
  Future<TelehealthTicketReceipt> submitConsultTicket(
    TelehealthConsultRequest request,
  ) async {
    if (!config.isAuthenticated) {
      throw StateError('Cloud Telehealth Account မချိတ်ဆက်ရသေးပါ');
    }

    final payload = {
      'fields': {
        'patientUid': {'stringValue': config.patientUid},
        'profileName': {'stringValue': request.profileName},
        'stageLabelMm': {'stringValue': request.stageLabelMm},
        'sbarSummary': {'stringValue': request.sbarSummary},
        'urgencyLevel': {'stringValue': request.urgencyLevel},
        'status': {'stringValue': 'pending_triage'},
        'assignedDoctorName': {'stringValue': ''},
        'doctorNoteMm': {'stringValue': ''},
        'requestedAt': {'timestampValue': request.requestedAt.toUtc().toIso8601String()},
      },
    };

    final res = await _client.post(
      _firestoreCollectionUri(),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.idToken}',
      },
      body: jsonEncode(payload),
    );
    final decoded = _decodeJsonMap(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final errMsg =
          (decoded['error'] as Map?)?['message']?.toString() ?? 'WRITE_FAILED';
      throw StateError('Firestore Error (${res.statusCode}): $errMsg');
    }

    final docName = (decoded['name'] as String?) ?? '';
    final ticketId = docName.split('/').lastOrNull ?? 'ticket';
    return TelehealthTicketReceipt(
      ticketId: ticketId,
      profileName: request.profileName,
      urgencyLevel: request.urgencyLevel,
      status: 'pending_triage',
      requestedAt: request.requestedAt,
    );
  }

  /// Queries only tickets owned by [config.patientUid] matching `firestore.rules`.
  Future<List<TelehealthTicketReceipt>> fetchPatientTickets() async {
    if (!config.isAuthenticated) return const [];

    final query = {
      'structuredQuery': {
        'from': [
          {'collectionId': 'consult_requests'},
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'patientUid'},
            'op': 'EQUAL',
            'value': {'stringValue': config.patientUid},
          },
        },
        'orderBy': [
          {
            'field': {'fieldPath': 'requestedAt'},
            'direction': 'DESCENDING',
          },
        ],
        'limit': 10,
      },
    };

    final res = await _client.post(
      _firestoreQueryUri(),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.idToken}',
      },
      body: jsonEncode(query),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final decoded = _decodeJsonMap(res.body);
      final errMsg =
          (decoded['error'] as Map?)?['message']?.toString() ?? 'QUERY_FAILED';
      throw StateError('Firestore Query Error (${res.statusCode}): $errMsg');
    }

    final rawList = jsonDecode(res.body);
    if (rawList is! List) return const [];
    final tickets = <TelehealthTicketReceipt>[];
    for (final entry in rawList) {
      if (entry is! Map<String, dynamic>) continue;
      final doc = entry['document'];
      if (doc is! Map<String, dynamic>) continue;
      final fields = (doc['fields'] as Map<String, dynamic>?) ?? const {};
      final name = (doc['name'] as String?) ?? '';
      tickets.add(
        TelehealthTicketReceipt(
          ticketId: name.split('/').lastOrNull ?? '',
          profileName: _readStringField(fields, 'profileName'),
          urgencyLevel: _readStringField(fields, 'urgencyLevel'),
          status: _readStringField(fields, 'status', fallback: 'pending_triage'),
          requestedAt:
              DateTime.tryParse(_readTimestampField(fields, 'requestedAt')) ??
                  DateTime.now(),
          assignedDoctorName: _readStringField(fields, 'assignedDoctorName'),
          doctorNoteMm: _readStringField(fields, 'doctorNoteMm'),
        ),
      );
    }
    return tickets;
  }

  static String _readStringField(
    Map<String, dynamic> fields,
    String key, {
    String fallback = '',
  }) {
    final entry = fields[key];
    if (entry is Map && entry['stringValue'] is String) {
      return entry['stringValue'] as String;
    }
    return fallback;
  }

  static String _readTimestampField(Map<String, dynamic> fields, String key) {
    final entry = fields[key];
    if (entry is Map && entry['timestampValue'] is String) {
      return entry['timestampValue'] as String;
    }
    return '';
  }

  static Map<String, dynamic> _decodeJsonMap(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {}
    return const {};
  }

  static String _shortId(String id) =>
      id.length <= 10 ? id : '${id.substring(0, 6)}...${id.substring(id.length - 4)}';
}
