import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_module.dart';
import '../../domain/models/emergency_qr_card.dart';
import '../../domain/models/maternal_child_models.dart'
    show normalizeAsciiDigits;
import '../../domain/models/regional_market.dart';
import 'telehealth_gateway.dart';

/// Persists lightweight app preferences, module visibility, QR card, price index,
/// regional market settings, health lock PIN digest, and Phase 2 Cloud Telehealth config.
class PreferencesService {
  static const String _modulePrefix = 'module_enabled_';
  static const String _qrCardKey = 'emergency_qr_card_json';
  static const String _marketMultiplierKey = 'market_price_multiplier';
  static const String _healthPinDigestKey = 'maternal_child_pin_digest_v1';
  static const String _milestonePrefix = 'mch_milestones_v1_';
  static const String _telehealthConfigKey = 'cloud_telehealth_config_v1';
  static const String _marketCountryModeKey = 'market_country_mode_v1';
  static const String _regionalPriceOverridePrefix =
      'regional_price_overrides_v1_';

  Future<Set<AppModule>> loadEnabledModules() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = <AppModule>{};
    for (final module in AppModule.values) {
      final isEnabled = prefs.getBool('$_modulePrefix${module.key}') ?? true;
      if (isEnabled) enabled.add(module);
    }
    return enabled;
  }

  Future<void> setModuleEnabled(AppModule module, bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_modulePrefix${module.key}', isEnabled);
  }

  Future<EmergencyQrCard> loadQrCard() async {
    final prefs = await SharedPreferences.getInstance();
    return EmergencyQrCard.fromJsonString(prefs.getString(_qrCardKey));
  }

  Future<void> saveQrCard(EmergencyQrCard card) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_qrCardKey, card.toJsonString());
  }

  Future<double> loadMarketPriceMultiplier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_marketMultiplierKey) ?? 1.0;
  }

  Future<void> saveMarketPriceMultiplier(double multiplier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_marketMultiplierKey, multiplier);
  }

  /// Derives a salted 64-bit FNV-1a digest so raw PINs are never persisted in plaintext.
  static String hashHealthPin(String pin) {
    const salt = 'mm_daily_mch_lock_v1:';
    final normalizedPin = normalizeAsciiDigits(pin);
    var hash = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = BigInt.parse('ffffffffffffffff', radix: 16);
    for (final unit in '$salt$normalizedPin'.codeUnits) {
      hash = hash ^ BigInt.from(unit);
      hash = (hash * prime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  Future<bool> hasHealthPin() async {
    final prefs = await SharedPreferences.getInstance();
    final digest = prefs.getString(_healthPinDigestKey);
    return digest != null && digest.isNotEmpty;
  }

  Future<bool> verifyHealthPin(String candidatePin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_healthPinDigestKey);
    if (stored == null || stored.isEmpty) return true;
    return stored == hashHealthPin(candidatePin);
  }

  Future<void> saveHealthPin(String? newPin) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = newPin == null ? '' : normalizeAsciiDigits(newPin);
    if (cleaned.isEmpty) {
      await prefs.remove(_healthPinDigestKey);
      return;
    }
    await prefs.setString(_healthPinDigestKey, hashHealthPin(cleaned));
  }

  Future<Set<String>> loadCheckedMilestones(int profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_milestonePrefix$profileId') ?? const [];
    return list.toSet();
  }

  Future<void> saveCheckedMilestones(
    int profileId,
    Set<String> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_milestonePrefix$profileId',
      items.toList(),
    );
  }

  Future<CloudTelehealthConfig> loadCloudTelehealthConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return CloudTelehealthConfig.fromJsonString(
      prefs.getString(_telehealthConfigKey),
    );
  }

  Future<void> saveCloudTelehealthConfig(CloudTelehealthConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    if (!config.hasProjectConfig) {
      await prefs.remove(_telehealthConfigKey);
      return;
    }
    await prefs.setString(_telehealthConfigKey, config.toJsonString());
  }

  /// Returns `'auto'` or one of the 6 supported ISO codes (`MM, TH, MY, SG, KR, JP`).
  Future<String> loadMarketCountryMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_marketCountryModeKey) ?? 'auto';
    if (saved == 'auto' || SupportedMarketCountry.fromIsoCode(saved) != null) {
      return saved;
    }
    return 'auto';
  }

  Future<void> saveMarketCountryMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = (mode == 'auto' || SupportedMarketCountry.fromIsoCode(mode) != null)
        ? mode
        : 'auto';
    await prefs.setString(_marketCountryModeKey, clean);
  }

  Future<Map<String, double>> loadRegionalPriceOverrides(
    SupportedMarketCountry country,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_regionalPriceOverridePrefix${country.isoCode}');
    if (raw == null || raw.isEmpty) return <String, double>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          if (entry.value is num && (entry.value as num) > 0)
            entry.key: (entry.value as num).toDouble(),
      };
    } catch (_) {
      return <String, double>{};
    }
  }

  Future<void> saveRegionalPriceOverride({
    required SupportedMarketCountry country,
    required String commodityId,
    required double localUnitPrice,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await loadRegionalPriceOverrides(country);
    map[commodityId] = localUnitPrice;
    await prefs.setString(
      '$_regionalPriceOverridePrefix${country.isoCode}',
      jsonEncode(map),
    );
  }
}
