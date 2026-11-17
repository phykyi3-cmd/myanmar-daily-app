import 'package:flutter/foundation.dart';

import 'package:myanmar_daily_app/data/repositories/reminder_repository.dart';
import 'package:myanmar_daily_app/data/repositories/settings_qr_repository.dart';
import 'package:myanmar_daily_app/domain/models/emergency_qr_card.dart';
import 'package:myanmar_daily_app/domain/models/renewal_reminder.dart';

/// Quiet sub-sections tucked under the secondary 'အခြား' Tools tab.
enum ToolsSection { overview, reminders, qrCard, backup }

/// ViewModel managing vehicle/document reminders and the offline QR info card.
class RemindersQrViewModel extends ChangeNotifier {
  RemindersQrViewModel({
    required ReminderRepository reminderRepository,
    required SettingsQrRepository settingsQrRepository,
  })  : _reminderRepository = reminderRepository,
        _settingsQrRepository = settingsQrRepository;

  final ReminderRepository _reminderRepository;
  final SettingsQrRepository _settingsQrRepository;

  ToolsSection _activeSection = ToolsSection.overview;
  ToolsSection get activeSection => _activeSection;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<RenewalReminder> _reminders = const [];
  List<RenewalReminder> get reminders => _reminders;

  EmergencyQrCard _qrCard = const EmergencyQrCard();
  EmergencyQrCard get qrCard => _qrCard;

  void setActiveSection(ToolsSection section) {
    if (_activeSection == section) return;
    _activeSection = section;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _reminders = await _reminderRepository.getReminders();
      _qrCard = await _settingsQrRepository.getQrCard();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReminder(RenewalReminder reminder) async {
    await _reminderRepository.addReminder(reminder);
    _reminders = await _reminderRepository.getReminders();
    notifyListeners();
  }

  Future<void> toggleCompleted(RenewalReminder reminder) async {
    await _reminderRepository.toggleCompleted(reminder);
    _reminders = await _reminderRepository.getReminders();
    notifyListeners();
  }

  Future<void> deleteReminder(int id) async {
    await _reminderRepository.deleteReminder(id);
    _reminders = await _reminderRepository.getReminders();
    notifyListeners();
  }

  Future<void> saveQrCard(EmergencyQrCard card) async {
    await _settingsQrRepository.saveQrCard(card);
    _qrCard = card;
    notifyListeners();
  }
}
