import 'dart:async';
import '../models/product_model.dart';
import 'local_db_service.dart';
import 'product_service.dart';

/// Background sync manager — keeps local DB fresh without hammering the API.
///
/// Strategy:
///   1. On first launch → fetch all from API → store locally.
///   2. Subsequent reads → serve from local DB instantly.
///   3. Background timer syncs every [syncInterval] (default 5 min).
///   4. Force-refresh available on pull-to-refresh.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration staleness = Duration(minutes: 2);

  final LocalDbService _localDb = LocalDbService();
  final ProductService _productService = ProductService();

  Timer? _timer;
  bool _syncing = false;

  // Listeners notified after each successful sync.
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in _listeners) {
      cb();
    }
  }

  /// Start periodic background sync. Safe to call multiple times.
  void startPeriodicSync() {
    _timer?.cancel();
    _timer = Timer.periodic(syncInterval, (_) => syncIfStale());
  }

  void stopPeriodicSync() {
    _timer?.cancel();
    _timer = null;
  }

  /// Sync only if local data is stale or empty.
  Future<void> syncIfStale() async {
    final count = await _localDb.getProductCount();
    if (count == 0) {
      await forceSync();
      return;
    }
    final lastSync = await _localDb.getLastSyncTime();
    if (lastSync == null || DateTime.now().difference(lastSync) > staleness) {
      await forceSync();
    }
  }

  /// Always fetch from API and update local DB.
  Future<void> forceSync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      _productService.clearCache();
      final raw = await _productService.getAllProducts(
          page: 1, pageSize: 500, useCache: false);
      final models = raw.map(ProductModel.fromJson).toList();
      await _localDb.upsertProducts(models);
      await _localDb.setLastSyncTime(DateTime.now());
      _notify();
    } catch (_) {
      // Silently fail — local data still served.
    } finally {
      _syncing = false;
    }
  }

  bool get isSyncing => _syncing;

  /// Get products — local-first, sync in background if stale.
  Future<List<ProductModel>> getProducts({String? search}) async {
    final count = await _localDb.getProductCount();
    if (count == 0) {
      await forceSync();
    } else {
      // Background refresh without blocking UI.
      syncIfStale();
    }
    if (search != null && search.trim().isNotEmpty) {
      return _localDb.searchProducts(search);
    }
    return _localDb.getAllProducts();
  }
}

// Alias so we don't need to import dart:ui in sync_service.dart
typedef VoidCallback = void Function();
