import '../../domain/models/renewal_reminder.dart';
import '../services/local_db_service.dart';

/// Repository managing vehicle maintenance and document renewal reminders.
class ReminderRepository {
  ReminderRepository({required LocalDbService dbService})
      : _dbService = dbService;

  final LocalDbService _dbService;

  Future<List<RenewalReminder>> getReminders() async {
    final rows = await _dbService.queryAll(
      LocalDbService.tableReminders,
      orderBy: 'is_completed ASC, due_date ASC',
    );
    return rows.map(RenewalReminder.fromMap).toList();
  }

  Future<void> addReminder(RenewalReminder reminder) async {
    await _dbService.insert(
      LocalDbService.tableReminders,
      reminder.copyWith(id: null).toMap(),
    );
  }

  Future<void> toggleCompleted(RenewalReminder reminder) async {
    final id = reminder.id;
    if (id == null) return;
    await _dbService.updateById(
      LocalDbService.tableReminders,
      id,
      {'is_completed': reminder.isCompleted ? 0 : 1},
    );
  }

  Future<void> deleteReminder(int id) async {
    await _dbService.deleteById(LocalDbService.tableReminders, id);
  }
}
