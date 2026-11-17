import 'dart:convert';

/// Offline emergency, contact, Wi-Fi, and payment QR card data.
class EmergencyQrCard {
  const EmergencyQrCard({
    this.fullName = '',
    this.phone = '',
    this.bloodType = '',
    this.emergencyContact = '',
    this.addressNote = '',
    this.paymentAccount = '',
    this.wifiSsid = '',
    this.wifiPassword = '',
  });

  final String fullName;
  final String phone;
  final String bloodType;
  final String emergencyContact;
  final String addressNote;
  final String paymentAccount;
  final String wifiSsid;
  final String wifiPassword;

  bool get isEmpty =>
      fullName.trim().isEmpty &&
      phone.trim().isEmpty &&
      emergencyContact.trim().isEmpty &&
      paymentAccount.trim().isEmpty &&
      wifiSsid.trim().isEmpty;

  /// Human-readable offline QR payload string for contact/emergency sharing.
  String toEmergencyQrPayload() {
    final lines = <String>[
      if (fullName.trim().isNotEmpty) 'Name: ${fullName.trim()}',
      if (phone.trim().isNotEmpty) 'Phone: ${phone.trim()}',
      if (bloodType.trim().isNotEmpty) 'Blood: ${bloodType.trim()}',
      if (emergencyContact.trim().isNotEmpty)
        'Emergency: ${emergencyContact.trim()}',
      if (addressNote.trim().isNotEmpty) 'Address: ${addressNote.trim()}',
      if (paymentAccount.trim().isNotEmpty) 'Pay: ${paymentAccount.trim()}',
    ];
    return lines.isEmpty ? 'Myanmar Daily Emergency Card' : lines.join('\n');
  }

  /// Standard Wi-Fi QR code string (`WIFI:T:WPA;S:<ssid>;P:<pass>;;`).
  String toWifiQrPayload() {
    final ssid = wifiSsid.trim();
    if (ssid.isEmpty) return '';
    final pass = wifiPassword.trim();
    final security = pass.isEmpty ? 'nopass' : 'WPA';
    return 'WIFI:T:$security;S:$ssid;P:$pass;;';
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'bloodType': bloodType,
        'emergencyContact': emergencyContact,
        'addressNote': addressNote,
        'paymentAccount': paymentAccount,
        'wifiSsid': wifiSsid,
        'wifiPassword': wifiPassword,
      };

  factory EmergencyQrCard.fromJson(Map<String, dynamic> json) {
    return EmergencyQrCard(
      fullName: (json['fullName'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      bloodType: (json['bloodType'] as String?) ?? '',
      emergencyContact: (json['emergencyContact'] as String?) ?? '',
      addressNote: (json['addressNote'] as String?) ?? '',
      paymentAccount: (json['paymentAccount'] as String?) ?? '',
      wifiSsid: (json['wifiSsid'] as String?) ?? '',
      wifiPassword: (json['wifiPassword'] as String?) ?? '',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory EmergencyQrCard.fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const EmergencyQrCard();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return EmergencyQrCard.fromJson(decoded);
      }
    } catch (_) {
      // Fallback safely if stored preference string is malformed.
    }
    return const EmergencyQrCard();
  }
}
