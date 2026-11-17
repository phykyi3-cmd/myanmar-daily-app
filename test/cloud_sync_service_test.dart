import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myanmar_daily_app/data/services/cloud_sync_service.dart';
import 'package:myanmar_daily_app/domain/models/cloud_account_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'Google Drive & Apple iCloud account vaults store, isolate, and restore full backup JSON',
    () async {
      final service = CloudSyncService();

      const gmailPayload = '{"version":1,"ledger_entries":[{"title":"မင်္ဂလာဆောင်လက်ဖွဲ့"}]}';
      final gmailState = await service.connectAccount(
        provider: CloudProviderType.googleDrive,
        email: 'sithu@gmail.com',
        initialBackupJson: gmailPayload,
      );

      expect(gmailState.isConnected, isTrue);
      expect(gmailState.provider, CloudProviderType.googleDrive);
      expect(gmailState.accountEmail, 'sithu@gmail.com');
      expect(gmailState.lastBackupSizeBytes, greaterThan(0));

      final downloadedGmail = await service.downloadFromCloud();
      expect(downloadedGmail, equals(gmailPayload));

      // Switch to Apple iCloud account
      const icloudPayload = '{"version":1,"ledger_entries":[{"title":"စုကြေး အဖွဲ့"}]}';
      final icloudState = await service.connectAccount(
        provider: CloudProviderType.appleICloud,
        email: 'sithu@icloud.com',
        initialBackupJson: icloudPayload,
      );
      expect(icloudState.provider, CloudProviderType.appleICloud);
      expect(await service.downloadFromCloud(), equals(icloudPayload));

      // Disconnect and reconnect back to Gmail account -> should preserve Gmail vault
      await service.disconnectAccount();
      expect((await service.loadAccountState()).isConnected, isFalse);

      await service.connectAccount(
        provider: CloudProviderType.googleDrive,
        email: 'sithu@gmail.com',
        initialBackupJson: '{"version":1,"ledger_entries":[]}',
      );
      expect(await service.downloadFromCloud(), equals(gmailPayload));
    },
  );

  test(
    'Google Drive REST API v3 appDataFolder upload and download works when OAuth token is provided',
    () async {
      String? uploadedRemoteBody;
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/drive/v3/files' &&
            request.url.queryParameters['spaces'] == 'appDataFolder') {
          if (uploadedRemoteBody == null) {
            return http.Response(jsonEncode({'files': []}), 200);
          }
          return http.Response(
            jsonEncode({
              'files': [
                {'id': 'gdrive_file_123', 'name': 'myanmar_daily_backup.json'},
              ],
            }),
            200,
          );
        }
        if (request.method == 'POST' && request.url.path == '/drive/v3/files') {
          return http.Response(jsonEncode({'id': 'gdrive_file_123'}), 200);
        }
        if (request.method == 'PATCH' &&
            request.url.path == '/upload/drive/v3/files/gdrive_file_123') {
          uploadedRemoteBody = request.body;
          return http.Response(jsonEncode({'id': 'gdrive_file_123'}), 200);
        }
        if (request.method == 'GET' &&
            request.url.path == '/drive/v3/files/gdrive_file_123' &&
            request.url.queryParameters['alt'] == 'media') {
          return http.Response.bytes(
            utf8.encode(uploadedRemoteBody ?? ''),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = CloudSyncService(httpClient: mockClient);
      const testBackup = '{"version":1,"reminders":[{"title":"Passport သက်တမ်းတိုးရန်"}]}';

      await service.connectAccount(
        provider: CloudProviderType.googleDrive,
        email: 'sithu@gmail.com',
        initialBackupJson: testBackup,
        oauthAccessToken: 'ya29.test_oauth_token',
      );

      expect(uploadedRemoteBody, equals(testBackup));

      final remoteDownloaded = await service.downloadFromCloud();
      expect(remoteDownloaded, equals(testBackup));
    },
  );
}
