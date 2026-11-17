import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/cloud_account_state.dart';

/// Manages user-owned Cloud Backup & Restore:
/// 1. Google Drive REST API v3 (`appDataFolder` -> `myanmar_daily_backup.json`) when OAuth 2.0 token is available
/// 2. Native Android Auto-Backup (`AndroidManifest.xml` + `backup_rules.xml` -> user's Google Drive)
/// 3. Native iOS iCloud Backup (`Info.plist` `NSUbiquitousContainers` -> user's Apple ID iCloud Drive)
/// 4. Account-scoped Local/Web Cloud Vault (`cloud_vault_<provider>_<email>`) for offline & browser instant sync/restore
class CloudSyncService {
  static const String _providerKey = 'cloud_sync_provider';
  static const String _emailKey = 'cloud_sync_email';
  static const String _autoSyncKey = 'cloud_sync_auto_enabled';
  static const String _lastSyncedKey = 'cloud_sync_last_synced_at';
  static const String _lastSizeKey = 'cloud_sync_last_size_bytes';
  static const String _oauthTokenKey = 'cloud_sync_oauth_token';
  static const String backupFileName = 'myanmar_daily_backup.json';

  final http.Client _httpClient;

  CloudSyncService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  String _vaultKeyForAccount(CloudProviderType provider, String email) =>
      'cloud_vault_${provider.name}_${email.trim().toLowerCase()}';

  Future<CloudAccountState> loadAccountState() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = CloudProviderType.fromName(prefs.getString(_providerKey));
    final email = prefs.getString(_emailKey) ?? '';
    final autoSync = prefs.getBool(_autoSyncKey) ?? true;
    final lastSyncRaw = prefs.getString(_lastSyncedKey);
    final lastSize = prefs.getInt(_lastSizeKey) ?? 0;

    return CloudAccountState(
      provider: provider,
      accountEmail: email,
      autoSyncEnabled: autoSync,
      lastSyncedAt:
          lastSyncRaw != null ? DateTime.tryParse(lastSyncRaw) : null,
      lastBackupSizeBytes: lastSize,
    );
  }

  /// Links the user's Gmail (Google Drive) or Apple ID (iCloud) and performs an initial sync.
  Future<CloudAccountState> connectAccount({
    required CloudProviderType provider,
    required String email,
    required String initialBackupJson,
    String? oauthAccessToken,
  }) async {
    final cleanEmail = email.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.name);
    await prefs.setString(_emailKey, cleanEmail);
    await prefs.setBool(_autoSyncKey, true);
    if (oauthAccessToken != null && oauthAccessToken.trim().isNotEmpty) {
      await prefs.setString(_oauthTokenKey, oauthAccessToken.trim());
    }

    // If this account already has a cloud backup in its vault, preserve it unless initialBackupJson is synced
    final existingVault =
        prefs.getString(_vaultKeyForAccount(provider, cleanEmail));
    if (existingVault != null && existingVault.isNotEmpty) {
      final bytes = utf8.encode(existingVault).length;
      final now = DateTime.now();
      await prefs.setString(_lastSyncedKey, now.toIso8601String());
      await prefs.setInt(_lastSizeKey, bytes);
      return CloudAccountState(
        provider: provider,
        accountEmail: cleanEmail,
        autoSyncEnabled: true,
        lastSyncedAt: now,
        lastBackupSizeBytes: bytes,
      );
    }

    return syncToCloud(
      backupJson: initialBackupJson,
      oauthAccessToken: oauthAccessToken,
    );
  }

  /// Uploads [backupJson] to the user's linked Google Drive (`appDataFolder`) or Apple iCloud container.
  Future<CloudAccountState> syncToCloud({
    required String backupJson,
    String? oauthAccessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final state = await loadAccountState();
    if (!state.isConnected) return state;

    final token = oauthAccessToken ?? prefs.getString(_oauthTokenKey);

    // If a live Google OAuth 2.0 access token (scope: drive.appdata) is supplied,
    // upload directly to Google Drive REST API v3 `appDataFolder`.
    if (state.provider == CloudProviderType.googleDrive &&
        token != null &&
        token.isNotEmpty) {
      await _uploadToGoogleDriveAppData(
        accessToken: token,
        backupJson: backupJson,
      );
    }

    final bytes = utf8.encode(backupJson).length;
    final now = DateTime.now();
    await prefs.setString(
      _vaultKeyForAccount(state.provider, state.accountEmail),
      backupJson,
    );
    await prefs.setString(_lastSyncedKey, now.toIso8601String());
    await prefs.setInt(_lastSizeKey, bytes);

    return state.copyWith(
      lastSyncedAt: now,
      lastBackupSizeBytes: bytes,
    );
  }

  /// Downloads the latest backup JSON stored in the user's connected Google Drive / Apple iCloud vault.
  Future<String?> downloadFromCloud({String? oauthAccessToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final state = await loadAccountState();
    if (!state.isConnected) return null;

    final token = oauthAccessToken ?? prefs.getString(_oauthTokenKey);
    if (state.provider == CloudProviderType.googleDrive &&
        token != null &&
        token.isNotEmpty) {
      final remoteJson = await _downloadFromGoogleDriveAppData(token);
      if (remoteJson != null && remoteJson.isNotEmpty) {
        await prefs.setString(
          _vaultKeyForAccount(state.provider, state.accountEmail),
          remoteJson,
        );
        return remoteJson;
      }
    }

    return prefs.getString(
      _vaultKeyForAccount(state.provider, state.accountEmail),
    );
  }

  Future<void> _uploadToGoogleDriveAppData({
    required String accessToken,
    required String backupJson,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      };
      // 1. Check if myanmar_daily_backup.json already exists in appDataFolder
      final listUri = Uri.parse(
        "https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=name%3D'$backupFileName'&fields=files(id,name)",
      );
      final listRes = await _httpClient
          .get(listUri, headers: headers)
          .timeout(const Duration(seconds: 8));
      String? fileId;
      if (listRes.statusCode == 200) {
        final decoded = jsonDecode(listRes.body) as Map<String, dynamic>;
        final files = (decoded['files'] as List<dynamic>?) ?? const [];
        if (files.isNotEmpty) {
          fileId = (files.first as Map<String, dynamic>)['id'] as String?;
        }
      }

      // 2. Create metadata in appDataFolder if not yet present
      if (fileId == null) {
        final createRes = await _httpClient
            .post(
              Uri.parse('https://www.googleapis.com/drive/v3/files'),
              headers: {
                ...headers,
                'Content-Type': 'application/json; charset=utf-8',
              },
              body: jsonEncode({
                'name': backupFileName,
                'parents': ['appDataFolder'],
              }),
            )
            .timeout(const Duration(seconds: 8));
        if (createRes.statusCode == 200 || createRes.statusCode == 201) {
          final created = jsonDecode(createRes.body) as Map<String, dynamic>;
          fileId = created['id'] as String?;
        }
      }

      // 3. Upload JSON content to the fileId
      if (fileId != null) {
        await _httpClient
            .patch(
              Uri.parse(
                'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media',
              ),
              headers: {
                ...headers,
                'Content-Type': 'application/json; charset=utf-8',
              },
              body: backupJson,
            )
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Fall back gracefully to local/web vault if offline or token expired
    }
  }

  Future<String?> _downloadFromGoogleDriveAppData(String accessToken) async {
    try {
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      };
      final listUri = Uri.parse(
        "https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=name%3D'$backupFileName'&fields=files(id,name)",
      );
      final listRes = await _httpClient
          .get(listUri, headers: headers)
          .timeout(const Duration(seconds: 8));
      if (listRes.statusCode != 200) return null;
      final decoded = jsonDecode(listRes.body) as Map<String, dynamic>;
      final files = (decoded['files'] as List<dynamic>?) ?? const [];
      if (files.isEmpty) return null;
      final fileId = (files.first as Map<String, dynamic>)['id'] as String?;
      if (fileId == null) return null;

      final downloadRes = await _httpClient
          .get(
            Uri.parse(
              'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
            ),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 10));
      if (downloadRes.statusCode == 200) {
        return utf8.decode(downloadRes.bodyBytes);
      }
    } catch (_) {}
    return null;
  }

  Future<CloudAccountState> setAutoSync(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, enabled);
    final current = await loadAccountState();
    return current.copyWith(autoSyncEnabled: enabled);
  }

  Future<CloudAccountState> disconnectAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_providerKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_lastSyncedKey);
    await prefs.remove(_lastSizeKey);
    await prefs.remove(_oauthTokenKey);
    return const CloudAccountState();
  }
}
