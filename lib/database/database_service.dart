import 'package:firebase_auth/firebase_auth.dart';
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

  String _getCurrentUserId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception(
        'DatabaseService: No authenticated user found. '
        'Ensure the user is logged in before accessing the database.',
      );
    }
    return uid;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chia_cpd.db');
    return _database!;
  }

  Future<void> initDatabase() async {
    try {
      await database;
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> seedDefaultCycleIfNeeded() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final existing = await getActiveCycle();
    if (existing == null) {
      final now = DateTime.now();
      await createCycle(
        RecertificationCycle(
          userId: userId,
          cycleName: 'Cycle 1',
          startDate: now.toIso8601String().substring(0, 10),
          endDate: now
              .add(const Duration(days: 1095))
              .toIso8601String()
              .substring(0, 10),
          targetPoints: 60,
          isActive: true,
          createdAt: now.toIso8601String(),
        ),
      );
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE cpd_activities ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE recertification_cycles ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE app_settings ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
      );
      await db.execute('''
        CREATE TABLE app_settings_new (
          user_id TEXT NOT NULL DEFAULT '',
          key TEXT NOT NULL,
          value TEXT,
          PRIMARY KEY (user_id, key)
        )
      ''');
      await db.execute('''
        INSERT INTO app_settings_new (user_id, key, value)
        SELECT user_id, key, value FROM app_settings
      ''');
      await db.execute('DROP TABLE app_settings');
      await db.execute('ALTER TABLE app_settings_new RENAME TO app_settings');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recertification_cycles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL DEFAULT '',
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
        user_id TEXT NOT NULL DEFAULT '',
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
        user_id TEXT NOT NULL DEFAULT '',
        key TEXT NOT NULL,
        value TEXT,
        PRIMARY KEY (user_id, key)
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
      final userId = _getCurrentUserId();
      final cycleWithUser = cycle.copyWith(userId: userId);
      final id = await db.insert(
        'recertification_cycles',
        cycleWithUser.toMap()..remove('id'),
      );
      return cycleWithUser.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to create cycle: $e');
    }
  }

  Future<RecertificationCycle?> getActiveCycle() async {
    try {
      final db = await database;
      final userId = _getCurrentUserId();
      final maps = await db.query(
        'recertification_cycles',
        where: 'is_active = ? AND user_id = ?',
        whereArgs: [1, userId],
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
      final userId = _getCurrentUserId();
      final maps = await db.query(
        'recertification_cycles',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'id DESC',
      );
      return maps.map(RecertificationCycle.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to fetch all cycles: $e');
    }
  }

  Future<int> archiveAndCreateNewCycle(RecertificationCycle newCycle) async {
    try {
      final db = await database;
      final userId = _getCurrentUserId();
      final cycleWithUser = newCycle.copyWith(userId: userId, isActive: true);
      return db.transaction((txn) async {
        await txn.update(
          'recertification_cycles',
          {'is_active': 0},
          where: 'is_active = ? AND user_id = ?',
          whereArgs: [1, userId],
        );
        return txn.insert(
          'recertification_cycles',
          cycleWithUser.toMap()..remove('id'),
        );
      });
    } catch (e) {
      throw Exception('Failed to archive and create new cycle: $e');
    }
  }

  Future<CpdActivity> addActivity(CpdActivity activity) async {
    try {
      final db = await database;
      final userId = _getCurrentUserId();
      final activityWithUser = activity.copyWith(userId: userId);
      final isDuplicate = await hasPotentialDuplicate(
        cycleId: activityWithUser.cycleId,
        dateLogged: activityWithUser.dateLogged,
        categoryId: activityWithUser.categoryId,
        activityDescription: activityWithUser.activityDescription,
        providerName: activityWithUser.providerName,
      );
      if (isDuplicate) {
        throw StateError('Duplicate activity detected for this cycle.');
      }
      final now = DateTime.now().toIso8601String();
      final points = _resolvePoints(activityWithUser);
      final toInsert = activityWithUser
          .copyWith(pointsClaimed: points, createdAt: now, updatedAt: now, deletedAt: null)
          .toMap()
        ..remove('id');
      final id = await db.insert('cpd_activities', toInsert);
      return activityWithUser.copyWith(
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
      final userId = _getCurrentUserId();
      if (activity.id == null) {
        throw Exception('Activity id is required for updates.');
      }
      final now = DateTime.now().toIso8601String();
      final activityWithUser = activity.copyWith(userId: userId);
      final points = _resolvePoints(activityWithUser);
      final isDuplicate = await hasPotentialDuplicate(
        cycleId: activityWithUser.cycleId,
        dateLogged: activityWithUser.dateLogged,
        categoryId: activityWithUser.categoryId,
        activityDescription: activityWithUser.activityDescription,
        providerName: activityWithUser.providerName,
        excludeId: activityWithUser.id,
      );
      if (isDuplicate) {
        throw StateError('Duplicate activity detected for this cycle.');
      }
      return db.update(
        'cpd_activities',
        activityWithUser.copyWith(pointsClaimed: points, updatedAt: now).toMap()..remove('id'),
        where: 'id = ? AND user_id = ?',
        whereArgs: [activityWithUser.id, userId],
      );
    } catch (e) {
      throw Exception('Failed to update activity: $e');
    }
  }

  Future<int> softDeleteActivity(int id) async {
    try {
      final db = await database;
      final userId = _getCurrentUserId();
      final now = DateTime.now().toIso8601String();
      return db.update(
        'cpd_activities',
        {'deleted_at': now, 'updated_at': now},
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
    } catch (e) {
      throw Exception('Failed to soft delete activity: $e');
    }
  }

  Future<List<CpdActivity>> getActivitiesByCycle(int cycleId) async {
    try {
      final db = await database;
      final userId = _getCurrentUserId();
      final maps = await db.query(
        'cpd_activities',
        where: 'cycle_id = ? AND user_id = ? AND deleted_at IS NULL',
        whereArgs: [cycleId, userId],
        orderBy: 'date_logged DESC, id DESC',
      );
      return maps.map(CpdActivity.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to fetch activities by cycle: $e');
    }
  }

  Future<double> getTotalPointsByCycle(int cycleId) async {
    try {
      final pointsByCategory = await getPointsByCategory(cycleId);
      return pointsByCategory.values.fold<double>(
        0,
        (sum, entry) => sum + (entry['effective'] ?? 0),
      );
    } catch (e) {
      throw Exception('Failed to fetch total points by cycle: $e');
    }
  }

  Future<Map<int, Map<String, double>>> getPointsByCategory(int cycleId) async {
    try {
      final db = await database;
      final userId = _getCurrentUserId();
      final pointsByCategory = emptyPointsByCategory();
      final result = await db.rawQuery(
        '''
        SELECT category_id, COALESCE(SUM(points_claimed), 0) AS total
        FROM cpd_activities
        WHERE cycle_id = ? AND user_id = ? AND deleted_at IS NULL
        GROUP BY category_id
        ''',
        [cycleId, userId],
      );
      for (final row in result) {
        final categoryId = row['category_id'] as int;
        final claimed = (row['total'] as num).toDouble();
        pointsByCategory[categoryId] = {
          'claimed': claimed,
          'effective': effectiveCategoryPoints(claimed, categoryId),
        };
      }
      return pointsByCategory;
    } catch (e) {
      throw Exception('Failed to fetch points by category: $e');
    }
  }

  Future<Map<String, dynamic>> getExportData(int cycleId) async {
    try {
      final db = await database;
      final userId = _getCurrentUserId();
      final cycleRows = await db.query(
        'recertification_cycles',
        where: 'id = ? AND user_id = ?',
        whereArgs: [cycleId, userId],
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
      final userId = _getCurrentUserId();
      final normalizedDescription = activityDescription.trim().toLowerCase();
      final normalizedProvider = (providerName ?? '').trim().toLowerCase();
      final rows = await db.query(
        'cpd_activities',
        columns: ['id'],
        where: '''
          cycle_id = ?
          AND user_id = ?
          AND date_logged = ?
          AND category_id = ?
          AND LOWER(TRIM(activity_description)) = ?
          AND LOWER(TRIM(COALESCE(provider_name, ''))) = ?
          AND deleted_at IS NULL
          ${excludeId != null ? 'AND id != ?' : ''}
        ''',
        whereArgs: [
          cycleId,
          userId,
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
      final userId = _getCurrentUserId();
      final rows = await db.query(
        'app_settings',
        columns: ['value'],
        where: 'user_id = ? AND key = ?',
        whereArgs: [userId, key],
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
      final userId = _getCurrentUserId();
      if (value == null) {
        await db.delete(
          'app_settings',
          where: 'user_id = ? AND key = ?',
          whereArgs: [userId, key],
        );
        return;
      }
      await db.insert(
        'app_settings',
        {'user_id': userId, 'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to write setting "$key": $e');
    }
  }
}
