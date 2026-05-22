import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';

/// SQLite-backed local cache for offline-first inventory.
class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'sanjeevani_nexus.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        product_id TEXT PRIMARY KEY,
        medicine_name TEXT NOT NULL,
        data TEXT NOT NULL,
        synced_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE products ADD COLUMN synced_at INTEGER NOT NULL DEFAULT 0');
    }
  }

  // ── Products ──────────────────────────────────────────────────────────────

  Future<void> upsertProducts(List<ProductModel> products) async {
    final database = await db;
    final batch = database.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final p in products) {
      batch.insert(
        'products',
        {
          'product_id': p.productId,
          'medicine_name': p.medicineName,
          'data': jsonEncode(p.toJson()),
          'synced_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ProductModel>> getAllProducts() async {
    final database = await db;
    final rows = await database.query('products', orderBy: 'medicine_name ASC');
    return rows.map((r) {
      final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
      return ProductModel.fromJson(data);
    }).toList();
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) return getAllProducts();
    final database = await db;
    final q = '%${query.trim().toLowerCase()}%';
    final rows = await database.rawQuery(
      'SELECT * FROM products WHERE LOWER(medicine_name) LIKE ? ORDER BY medicine_name ASC LIMIT 50',
      [q],
    );
    return rows.map((r) {
      final data = jsonDecode(r['data'] as String) as Map<String, dynamic>;
      return ProductModel.fromJson(data);
    }).toList();
  }

  Future<int> getProductCount() async {
    final database = await db;
    final result =
        await database.rawQuery('SELECT COUNT(*) as cnt FROM products');
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<DateTime?> getLastSyncTime() async {
    final database = await db;
    final rows = await database
        .query('sync_meta', where: 'key = ?', whereArgs: ['last_sync']);
    if (rows.isEmpty) return null;
    final ms = int.tryParse(rows.first['value'] as String);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastSyncTime(DateTime time) async {
    final database = await db;
    await database.insert(
      'sync_meta',
      {'key': 'last_sync', 'value': '${time.millisecondsSinceEpoch}'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearProducts() async {
    final database = await db;
    await database.delete('products');
  }
}
