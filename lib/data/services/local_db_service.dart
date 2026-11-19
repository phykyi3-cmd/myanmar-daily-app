import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Shared local storage service using SQLite on mobile and SharedPreferences on Web.
class LocalDbService {
  static const String _dbName = 'myanmar_daily.db';
  static const int _dbVersion = 4;
  static const String _webTablePrefix = 'web_sql_table_';

  static const String tableLedger = 'ledger_entries';
  static const String tableLoansRentals = 'loans_rentals';
  static const String tableShopping = 'shopping_items';
  static const String tablePurchaseRecords = 'purchase_records';
  static const String tableReminders = 'reminders';
  static const String tableDonationCampaigns = 'donation_campaigns';
  static const String tableSuMaeGroups = 'su_mae_groups';

  Database? _db;

  /// Lazily opens and initializes the local SQLite database on mobile/desktop.
  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _dbName);
    _db = await openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableLedger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount_mmk INTEGER NOT NULL,
        is_income INTEGER NOT NULL,
        note TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableLoansRentals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_name TEXT NOT NULL,
        item_name TEXT NOT NULL,
        type TEXT NOT NULL,
        amount_mmk INTEGER NOT NULL,
        due_date TEXT NOT NULL,
        is_settled INTEGER NOT NULL,
        note TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableShopping (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity TEXT NOT NULL,
        estimated_cost_mmk INTEGER NOT NULL,
        recipe_name TEXT NOT NULL DEFAULT '',
        is_checked INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablePurchaseRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_key TEXT NOT NULL UNIQUE,
        record_date TEXT NOT NULL,
        dish_names_json TEXT NOT NULL,
        items_json TEXT NOT NULL,
        total_cost_mmk INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableReminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        due_date TEXT NOT NULL,
        mileage_km INTEGER,
        note TEXT NOT NULL,
        is_completed INTEGER NOT NULL
      )
    ''');

    await _createCommunityTables(db);
  }

  Future<void> _createCommunityTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableDonationCampaigns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        target_amount_mmk INTEGER NOT NULL DEFAULT 0,
        event_date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        contributions_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSuMaeGroups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        style TEXT NOT NULL,
        cycle TEXT NOT NULL,
        contribution_per_share_mmk INTEGER NOT NULL,
        planned_rounds INTEGER NOT NULL,
        organizer_name TEXT NOT NULL DEFAULT '',
        organizer_fee_mmk INTEGER NOT NULL DEFAULT 0,
        start_date TEXT NOT NULL,
        members_json TEXT NOT NULL,
        rounds_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          "ALTER TABLE $tableShopping ADD COLUMN recipe_name TEXT NOT NULL DEFAULT ''",
        );
      } catch (_) {
        // Column may already exist if migrated earlier.
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tablePurchaseRecords (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date_key TEXT NOT NULL UNIQUE,
          record_date TEXT NOT NULL,
          dish_names_json TEXT NOT NULL,
          items_json TEXT NOT NULL,
          total_cost_mmk INTEGER NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await _createCommunityTables(db);
    }
  }

  Future<List<Map<String, Object?>>> _readWebTable(String table) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_webTablePrefix$table');
    if (raw == null || raw.isEmpty) return <Map<String, Object?>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<String, Object?>>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((m) => Map<String, Object?>.from(m))
        .toList();
  }

  Future<void> _writeWebTable(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_webTablePrefix$table', jsonEncode(rows));
  }

  Future<List<Map<String, Object?>>> queryAll(
    String table, {
    String? orderBy,
  }) async {
    if (kIsWeb) {
      final rows = await _readWebTable(table);
      if (orderBy != null && orderBy.contains('created_at DESC')) {
        rows.sort((a, b) =>
            '${b['created_at'] ?? ''}'.compareTo('${a['created_at'] ?? ''}'));
      } else if (orderBy != null && orderBy.contains('date_key DESC')) {
        rows.sort((a, b) =>
            '${b['date_key'] ?? ''}'.compareTo('${a['date_key'] ?? ''}'));
      } else if (orderBy != null && orderBy.contains('due_date ASC')) {
        rows.sort((a, b) =>
            '${a['due_date'] ?? ''}'.compareTo('${b['due_date'] ?? ''}'));
      } else if (orderBy != null && orderBy.contains('updated_at DESC')) {
        rows.sort((a, b) =>
            '${b['updated_at'] ?? ''}'.compareTo('${a['updated_at'] ?? ''}'));
      }
      return rows;
    }
    final db = await database;
    return db.query(table, orderBy: orderBy);
  }

  Future<int> insert(String table, Map<String, Object?> values) async {
    if (kIsWeb) {
      final rows = await _readWebTable(table);
      var maxId = 0;
      for (final row in rows) {
        final id = (row['id'] as num?)?.toInt() ?? 0;
        if (id > maxId) maxId = id;
      }
      final nextId = maxId + 1;
      final newRow = Map<String, Object?>.from(values)..['id'] = nextId;
      rows.add(newRow);
      await _writeWebTable(table, rows);
      return nextId;
    }
    final db = await database;
    return db.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateById(
    String table,
    int id,
    Map<String, Object?> values,
  ) async {
    if (kIsWeb) {
      final rows = await _readWebTable(table);
      var updated = 0;
      for (final row in rows) {
        if ((row['id'] as num?)?.toInt() == id) {
          row.addAll(values);
          updated++;
        }
      }
      await _writeWebTable(table, rows);
      return updated;
    }
    final db = await database;
    return db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteById(String table, int id) async {
    if (kIsWeb) {
      final rows = await _readWebTable(table);
      final before = rows.length;
      rows.removeWhere((row) => (row['id'] as num?)?.toInt() == id);
      await _writeWebTable(table, rows);
      return before - rows.length;
    }
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteWhere(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    if (kIsWeb) {
      final rows = await _readWebTable(table);
      if (where == 'is_checked = ?' && whereArgs.isNotEmpty) {
        rows.removeWhere((row) => row['is_checked'] == whereArgs.first);
      } else if (where == 'date_key = ?' && whereArgs.isNotEmpty) {
        rows.removeWhere((row) => row['date_key'] == whereArgs.first);
      }
      await _writeWebTable(table, rows);
      return;
    }
    final db = await database;
    await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> clearTable(String table) async {
    if (kIsWeb) {
      await _writeWebTable(table, <Map<String, Object?>>[]);
      return;
    }
    final db = await database;
    await db.delete(table);
  }
}
