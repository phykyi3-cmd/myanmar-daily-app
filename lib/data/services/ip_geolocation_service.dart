import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:http/http.dart' as http;

import '../../domain/models/regional_market.dart';

/// Detects the user's country via public CORS-enabled HTTPS IP geolocation endpoints,
/// mapping ONLY to the 6 supported markets (`MM, TH, MY, SG, KR, JP`) with offline fallback.
class IpGeolocationService {
  IpGeolocationService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _primaryIpEndpoint = 'https://api.country.is/';
  static const _fallbackIpEndpoint = 'https://get.geojs.io/v1/ip/country.json';

  Future<IpLocationResult> detectCountry() async {
    // 1. Live IP Detection via primary & fallback HTTPS endpoints (CORS-enabled).
    for (final endpoint in const [_primaryIpEndpoint, _fallbackIpEndpoint]) {
      try {
        final res = await _client
            .get(Uri.parse(endpoint))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            final iso = (decoded['country'] as String?)?.trim().toUpperCase() ?? '';
            final ip = (decoded['ip'] as String?)?.trim() ?? '';
            final rawName = (decoded['name'] as String?)?.trim() ?? iso;
            if (iso.isNotEmpty) {
              final matched = SupportedMarketCountry.fromIsoCode(iso);
              if (matched != null) {
                return IpLocationResult(
                  detectedIp: ip,
                  rawCountryCode: iso,
                  rawCountryName: rawName,
                  matchedCountry: matched,
                  effectiveCountry: matched,
                  isFromLiveIp: true,
                  statusSummaryMm: ip.isNotEmpty
                      ? 'IP ($ip) → ${matched.flag} ${matched.nameMm} (${matched.currencyCode})'
                      : '${matched.flag} ${matched.nameMm} (${matched.currencyCode})',
                );
              }
              return IpLocationResult(
                detectedIp: ip,
                rawCountryCode: iso,
                rawCountryName: rawName,
                matchedCountry: null,
                effectiveCountry: SupportedMarketCountry.mm,
                isFromLiveIp: true,
                statusSummaryMm:
                    'IP ($iso) သည် ၆ နိုင်ငံပြင်ပဖြစ်၍ 🇲🇲 မြန်မာ (MMK) ဖြင့် ပြသထားသည်',
              );
            }
          }
        }
      } catch (_) {
        // Try fallback IP endpoint or offline detection below.
      }
    }

    // 2. Offline heuristic fallback: UTC+06:30 uniquely identifies Myanmar,
    //    or check locale country code if within the 6 supported countries.
    final offlineCountry = inferOfflineCountry();
    return IpLocationResult(
      rawCountryCode: offlineCountry.isoCode,
      rawCountryName: offlineCountry.nameMm,
      matchedCountry: offlineCountry,
      effectiveCountry: offlineCountry,
      isFromLiveIp: false,
      statusSummaryMm:
          'Offline (${offlineCountry.flag} ${offlineCountry.nameMm} • ${offlineCountry.currencyCode})',
    );
  }

  /// Infers supported country when IP APIs are unreachable offline.
  SupportedMarketCountry inferOfflineCountry({
    Duration? timeZoneOffset,
    String? localeCountryCode,
    String? localeLanguageCode,
  }) {
    final offsetMin =
        (timeZoneOffset ?? DateTime.now().timeZoneOffset).inMinutes;
    if (offsetMin == 390) return SupportedMarketCountry.mm;

    final locale = PlatformDispatcher.instance.locale;
    final countryCode =
        (localeCountryCode ?? locale.countryCode ?? '').toUpperCase();
    final lang = (localeLanguageCode ?? locale.languageCode).toLowerCase();

    final fromLocale = SupportedMarketCountry.fromIsoCode(countryCode);
    if (fromLocale != null) return fromLocale;

    if (offsetMin == 540) {
      if (lang == 'ko') return SupportedMarketCountry.kr;
      if (lang == 'ja') return SupportedMarketCountry.jp;
    }
    if (lang == 'th' && offsetMin == 420) return SupportedMarketCountry.th;
    return SupportedMarketCountry.mm;
  }
}
