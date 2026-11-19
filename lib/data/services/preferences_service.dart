import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_module.dart';
import '../../domain/models/emergency_qr_card.dart';
import '../../domain/models/regional_market.dart';

/// Persists lightweight app preferences, module visibility, QR card, price index,
/// and 6-country regional market settings.
class PreferencesService {
  static const String _modulePrefix = 'module_enabled_';
  static const String _qrCardKey = 'emergency_qr_card_json';
  static const String _marketMultiplierKey = 'market_price_multiplier';
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
