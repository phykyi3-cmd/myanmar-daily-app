/// Supported user-owned cloud storage providers (Zero server cost for developer).
enum CloudProviderType {
  none('ချိတ်ဆက်မထားပါ', ''),
  googleDrive(
    'Google Drive (Gmail)',
    'Google Drive → appDataFolder/myanmar_daily_backup.json',
  ),
  appleICloud(
    'Apple iCloud (Apple ID)',
    'iCloud Drive → iCloud.com.myanmardaily.app/backup.json',
  );

  const CloudProviderType(this.labelMm, this.storagePathLabel);
  final String labelMm;
  final String storagePathLabel;

  static CloudProviderType fromName(String? raw) {
    return CloudProviderType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => CloudProviderType.none,
    );
  }
}

/// Represents the current user's linked Google Drive or Apple iCloud backup state.
class CloudAccountState {
  const CloudAccountState({
    this.provider = CloudProviderType.none,
    this.accountEmail = '',
    this.autoSyncEnabled = true,
    this.lastSyncedAt,
    this.lastBackupSizeBytes = 0,
  });

  final CloudProviderType provider;
  final String accountEmail;
  final bool autoSyncEnabled;
  final DateTime? lastSyncedAt;
  final int lastBackupSizeBytes;

  bool get isConnected =>
      provider != CloudProviderType.none && accountEmail.trim().isNotEmpty;

  CloudAccountState copyWith({
    CloudProviderType? provider,
    String? accountEmail,
    bool? autoSyncEnabled,
    DateTime? lastSyncedAt,
    int? lastBackupSizeBytes,
  }) {
    return CloudAccountState(
      provider: provider ?? this.provider,
      accountEmail: accountEmail ?? this.accountEmail,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastBackupSizeBytes: lastBackupSizeBytes ?? this.lastBackupSizeBytes,
    );
  }
}
