import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/cpd_categories.dart';
import '../models/cpd_activity.dart';
import '../models/recertification_cycle.dart';

/// Local SQLite access for CPD cycles, activities, and app settings.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chia_cpd.db');
    return _database!;
  }

  Future<void> initDatabase() async {
    try {
      final db = await database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT
        );
      ''');
      final countResult = await db.rawQuery('SELECT COUNT(*) AS count FROM recertification_cycles');
      final count = (countResult.first['count'] as int?) ?? 0;
      if (count == 0) {
        final now = DateTime.now();
        final defaultCycle = RecertificationCycle(
          cycleName: 'Cycle 1',
          startDate: now.toIso8601String().substring(0, 10),
          endDate: now.add(const Duration(days: 1095)).toIso8601String().substring(0, 10),
          targetPoints: 60,
          isActive: true,
          createdAt: now.toIso8601String(),
        );
        await createCycle(defaultCycle);
      }
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recertification_cycles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cycle_name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        target_points REAL NOT NULL DEFAULT 60,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cpd_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cycle_id INTEGER NOT NULL,
        date_logged TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        category_name TEXT NOT NULL,
        subcategory TEXT,
        activity_description TEXT NOT NULL,
        provider_name TEXT,
        duration_hours REAL,
        points_claimed REAL NOT NULL,
        competency_domain TEXT,
        evidence_note TEXT,
        deleted_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (cycle_id) REFERENCES recertification_cycles(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');
  }

  double _resolvePoints(CpdActivity activity) {
    if (activity.pointsClaimed > 0) return activity.pointsClaimed;
    final hourlyRate = kHourlyRateCategories[activity.categoryId];
    if (hourlyRate != null && activity.durationHours != null) {
      return activity.durationHours! * hourlyRate;
    }
    return 0.0;
  }

  Future<RecertificationCycle> createCycle(RecertificationCycle cycle) async {
    try {
      final db = await database;
      final id = await db.insert('recertification_cycles', cycle.toMap()..remove('id'));
      return cycle.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to create cycle: $e');
    }
  }

  Future<RecertificationCycle?> getActiveCycle() async {
    try {
      final db = await database;
      final maps = await db.query(
        'recertification_cycles',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'id DESC',
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return RecertificationCycle.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to fetch active cycle: $e');
    }
  }

  Future<List<RecertificationCycle>> getAllCycles() async {
    try {
      final db = await database;
      final maps = await db.query('recertification_cycles', orderBy: 'id DESC');
      return maps.map(RecertificationCycle.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to fetch all cycles: $e');
    }
  }

  Future<int> archiveAndCreateNewCycle(RecertificationCycle newCycle) async {
    try {
      final db = await database;
      return db.transaction((txn) async {
        await txn.update('recertification_cycles', {'is_active': 0}, where: 'is_active = 1');
        final id = await txn.insert(
          'recertification_cycles',
          newCycle.copyWith(isActive: true).toMap()..remove('id'),
        );
        return id;
      });
    } catch (e) {
      throw Exception('Failed to archive and create new cycle: $e');
    }
  }

  Future<CpdActivity> addActivity(CpdActivity activity) async {
    try {
      final db = await database;
      final isDuplicate = await hasPotentialDuplicate(
        cycleId: activity.cycleId,
        dateLogged: activity.dateLogged,
        categoryId: activity.categoryId,
        activityDescription: activity.activityDescription,
        providerName: activity.providerName,
      );
      if (isDuplicate) {
        throw StateError('Duplicate activity detected for this cycle.');
      }
      final now = DateTime.now().toIso8601String();
      final points = _resolvePoints(activity);
      final toInsert = activity
          .copyWith(pointsClaimed: points, createdAt: now, updatedAt: now, deletedAt: null)
          .toMap()
        ..remove('id');
      final id = await db.insert('cpd_activities', toInsert);
      return activity.copyWith(
        id: id,
        pointsClaimed: points,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
      );
    } catch (e) {
      throw Exception('Failed to add activity: $e');
    }
  }

  Future<int> updateActivity(CpdActivity activity) async {
    try {
      final db = await database;
      if (activity.id == null) {
        throw Exception('Activity id is required for updates.');
      }
      final now = DateTime.now().toIso8601String();
      final points = _resolvePoints(activity);
      final isDuplicate = await hasPotentialDuplicate(
        cycleId: activity.cycleId,
        dateLogged: activity.dateLogged,
        categoryId: activity.categoryId,
        activityDescription: activity.activityDescription,
        providerName: activity.providerName,
        excludeId: activity.id,
      );
      if (isDuplicate) {
        throw StateError('Duplicate activity detected for this cycle.');
      }
      return db.update(
        'cpd_activities',
        activity.copyWith(pointsClaimed: points, updatedAt: now).toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [activity.id],
      );
    } catch (e) {
      throw Exception('Failed to update activity: $e');
    }
  }

  Future<int> softDeleteActivity(int id) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      return db.update(
        'cpd_activities',
        {'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to soft delete activity: $e');
    }
  }

  Future<List<CpdActivity>> getActivitiesByCycle(int cycleId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'cpd_activities',
        where: 'cycle_id = ? AND deleted_at IS NULL',
        whereArgs: [cycleId],
        orderBy: 'date_logged DESC, id DESC',
      );
      return maps.map(CpdActivity.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to fetch activities by cycle: $e');
    }
  }

  Future<double> getTotalPointsByCycle(int cycleId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(points_claimed), 0) AS total FROM cpd_activities WHERE cycle_id = ? AND deleted_at IS NULL',
        [cycleId],
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to fetch total points by cycle: $e');
    }
  }

  Future<Map<int, double>> getPointsByCategory(int cycleId) async {
    try {
      final db = await database;
      final pointsByCategory = <int, double>{for (var i = 1; i <= 10; i++) i: 0.0};
      final result = await db.rawQuery(
        '''
        SELECT category_id, COALESCE(SUM(points_claimed), 0) AS total
        FROM cpd_activities
        WHERE cycle_id = ? AND deleted_at IS NULL
        GROUP BY category_id
        ''',
        [cycleId],
      );
      for (final row in result) {
        final categoryId = row['category_id'] as int;
        pointsByCategory[categoryId] = (row['total'] as num).toDouble();
      }
      return pointsByCategory;
    } catch (e) {
      throw Exception('Failed to fetch points by category: $e');
    }
  }

  Future<Map<String, dynamic>> getExportData(int cycleId) async {
    try {
      final db = await database;
      final cycleRows = await db.query(
        'recertification_cycles',
        where: 'id = ?',
        whereArgs: [cycleId],
        limit: 1,
      );
      if (cycleRows.isEmpty) {
        throw Exception('Cycle $cycleId not found.');
      }
      final cycle = RecertificationCycle.fromMap(cycleRows.first);
      final activities = await getActivitiesByCycle(cycleId);
      final totalPoints = await getTotalPointsByCycle(cycleId);

      return {
        'cycle': {
          'name': cycle.cycleName,
          'startDate': cycle.startDate,
          'endDate': cycle.endDate,
          'totalPoints': totalPoints,
          'targetPoints': cycle.targetPoints,
        },
        'activities': activities
            .map(
              (activity) => {
                'id': activity.id,
                'dateLogged': activity.dateLogged,
                'categoryId': activity.categoryId,
                'categoryName': activity.categoryName,
                'subcategory': activity.subcategory,
                'activityDescription': activity.activityDescription,
                'providerName': activity.providerName,
                'durationHours': activity.durationHours,
                'pointsClaimed': activity.pointsClaimed,
                'competencyDomain': activity.competencyDomain,
                'evidenceNote': activity.evidenceNote,
              },
            )
            .toList(),
      };
    } catch (e) {
      throw Exception('Failed to build export data: $e');
    }
  }

  Future<bool> hasPotentialDuplicate({
    required int cycleId,
    required String dateLogged,
    required int categoryId,
    required String activityDescription,
    String? providerName,
    int? excludeId,
  }) async {
    try {
      final db = await database;
      final normalizedDescription = activityDescription.trim().toLowerCase();
      final normalizedProvider = (providerName ?? '').trim().toLowerCase();
      final rows = await db.query(
        'cpd_activities',
        columns: ['id'],
        where: '''
          cycle_id = ?
          AND date_logged = ?
          AND category_id = ?
          AND LOWER(TRIM(activity_description)) = ?
          AND LOWER(TRIM(COALESCE(provider_name, ''))) = ?
          AND deleted_at IS NULL
          ${excludeId != null ? 'AND id != ?' : ''}
        ''',
        whereArgs: [
          cycleId,
          dateLogged,
          categoryId,
          normalizedDescription,
          normalizedProvider,
          if (excludeId != null) excludeId,
        ],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (e) {
      throw Exception('Failed duplicate check: $e');
    }
  }

  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final rows = await db.query(
        'app_settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['value'] as String?;
    } catch (e) {
      throw Exception('Failed to read setting "$key": $e');
    }
  }

  Future<void> setSetting(String key, String? value) async {
    try {
      final db = await database;
      if (value == null) {
        await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
        return;
      }
      await db.insert(
        'app_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to write setting "$key": $e');
    }
  }

}
