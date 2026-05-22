import 'dart:convert';

import 'api_client.dart';
import 'api_config.dart';

class ProductService {
  final ApiClient _client = ApiClient();
  static const Duration _cacheTtl = Duration(minutes: 2);
  static DateTime? _allCachedAt;
  static DateTime? _lowCachedAt;
  static DateTime? _expiryCachedAt;
  static List<Map<String, dynamic>> _allCache = const [];
  static List<Map<String, dynamic>> _lowCache = const [];
  static List<Map<String, dynamic>> _expiryCache = const [];

  bool _isFresh(DateTime? time) {
    if (time == null) return false;
    return DateTime.now().difference(time) <= _cacheTtl;
  }

  void clearCache() {
    _allCache = const [];
    _lowCache = const [];
    _expiryCache = const [];
    _allCachedAt = null;
    _lowCachedAt = null;
    _expiryCachedAt = null;
  }

  Future<List<Map<String, dynamic>>> getAllProducts({
    int page = 1,
    int pageSize = 100,
    String? search,
    bool useCache = true,
  }) async {
    if (useCache &&
        search == null &&
        _allCache.isNotEmpty &&
        _isFresh(_allCachedAt)) {
      return _allCache;
    }

    final queryParams = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final uri = Uri.parse('${ApiConfig.productsEndpoint}/')
        .replace(queryParameters: queryParams);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load inventory: ${response.statusCode}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is List) {
      final parsed = data.whereType<Map<String, dynamic>>().toList();
      if (search == null) {
        _allCache = parsed;
        _allCachedAt = DateTime.now();
      }
      return parsed;
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> getLowStock({bool useCache = true}) async {
    if (useCache && _lowCache.isNotEmpty && _isFresh(_lowCachedAt)) {
      return _lowCache;
    }
    final uri = Uri.parse('${ApiConfig.productsEndpoint}/low-stock');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final all = await getAllProducts(useCache: true);
      final derived = all.where((item) {
        final stock = _toInt(item['current_stock'] ?? item['Current Stock']);
        final reorder = _toInt(item['reorder_level'] ?? item['Reorder Level']);
        if (item['is_low_stock'] == true) return true;
        if (reorder > 0) return stock <= reorder;
        return stock <= 10;
      }).toList();
      _lowCache = derived;
      _lowCachedAt = DateTime.now();
      return derived;
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is List) {
      final parsed = data.whereType<Map<String, dynamic>>().toList();
      _lowCache = parsed;
      _lowCachedAt = DateTime.now();
      return parsed;
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> getExpiryRisk(
      {bool useCache = true}) async {
    if (useCache && _expiryCache.isNotEmpty && _isFresh(_expiryCachedAt)) {
      return _expiryCache;
    }
    final uri = Uri.parse('${ApiConfig.productsEndpoint}/expiry-risk');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final now = DateTime.now();
      final all = await getAllProducts(useCache: true);
      final derived = all.where((item) {
        if (item['is_expiry_risk'] == true) return true;
        final raw = item['expiry_date'] ?? item['Expiry Date'];
        if (raw == null || '$raw'.trim().isEmpty) return false;
        final parsed = DateTime.tryParse('$raw'.replaceAll('/', '-'));
        if (parsed == null) return false;
        return parsed.difference(now).inDays <= 90;
      }).toList();
      _expiryCache = derived;
      _expiryCachedAt = DateTime.now();
      return derived;
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is List) {
      final parsed = data.whereType<Map<String, dynamic>>().toList();
      _expiryCache = parsed;
      _expiryCachedAt = DateTime.now();
      return parsed;
    }
    return const [];
  }

  Future<void> addProduct({
    required String medicineName,
    required int stock,
    String category = 'General',
    String? genericName,
    String? brandName,
    String? batchNo,
    String? expiryDate,
    double? mrp,
    double? sellingPrice,
    String? schedule,
    bool? prescriptionRequired,
  }) async {
    final uri = Uri.parse('${ApiConfig.productsEndpoint}/');
    final body = <String, dynamic>{
      'medicine_name': medicineName,
      'stock': stock,
      'category': category,
      if (genericName != null && genericName.isNotEmpty)
        'generic_name': genericName,
      if (brandName != null && brandName.isNotEmpty) 'brand_name': brandName,
      if (batchNo != null && batchNo.isNotEmpty) 'batch_no': batchNo,
      if (expiryDate != null && expiryDate.isNotEmpty)
        'expiry_date': expiryDate,
      if (mrp != null) 'mrp': mrp,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (sellingPrice == null && mrp != null) 'selling_price': mrp,
      if (schedule != null && schedule.isNotEmpty) 'schedule': schedule,
      if (prescriptionRequired != null)
        'prescription_required': prescriptionRequired,
    };

    final response = await _client.post(uri, body: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to add medicine: ${response.body}');
    }
    clearCache();
  }

  Future<void> addProductsBulk(List<Map<String, dynamic>> products) async {
    if (products.isEmpty) return;
    final uri = Uri.parse('${ApiConfig.productsEndpoint}/bulk');
    final response = await _client.post(uri, body: products);
    if (response.statusCode != 200) {
      throw Exception('Failed to add products: ${response.body}');
    }
    clearCache();
  }

  Future<void> addProductRaw(Map<String, dynamic> productData) async {
    final uri = Uri.parse('${ApiConfig.productsEndpoint}/');
    final response = await _client.post(uri, body: productData);
    if (response.statusCode != 200) {
      throw Exception('Failed to add medicine: ${response.body}');
    }
    clearCache();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
