import '../../domain/models/app_module.dart';
import '../../domain/models/emergency_qr_card.dart';
import '../services/preferences_service.dart';

/// Repository managing enabled module visibility and offline QR card info.
class SettingsQrRepository {
  SettingsQrRepository({required PreferencesService preferencesService})
      : _preferencesService = preferencesService;

  final PreferencesService _preferencesService;

  Future<Set<AppModule>> getEnabledModules() =>
      _preferencesService.loadEnabledModules();

  Future<void> setModuleEnabled(AppModule module, bool enabled) =>
      _preferencesService.setModuleEnabled(module, enabled);

  Future<EmergencyQrCard> getQrCard() => _preferencesService.loadQrCard();

  Future<void> saveQrCard(EmergencyQrCard card) =>
      _preferencesService.saveQrCard(card);
}
