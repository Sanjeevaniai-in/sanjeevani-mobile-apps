/// Typed product model with full unit hierarchy support.
class PackagingLevel {
  final String level; // 'unit' | 'strip' | 'box' | 'bottle'
  final String label;
  final int toBaseUnits;

  const PackagingLevel({
    required this.level,
    required this.label,
    required this.toBaseUnits,
  });

  factory PackagingLevel.fromJson(Map<String, dynamic> j) => PackagingLevel(
        level: j['level'] ?? 'unit',
        label: j['label'] ?? 'Unit',
        toBaseUnits: (j['to_base_units'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'level': level,
        'label': label,
        'to_base_units': toBaseUnits,
      };
}

class ProductModel {
  final String productId;
  final String medicineName;
  final String? genericName;
  final String? brandName;
  final String category;
  final int currentStock;
  final int reorderLevel;
  final String? batchNo;
  final String? expiryDate;
  final double mrp;
  final double sellingPrice;
  final String schedule;
  final bool prescriptionRequired;
  final bool isLowStock;
  final bool isExpiryRisk;
  final String baseUom;
  final List<PackagingLevel> packagingLevels;
  final String? imageUrl;

  const ProductModel({
    required this.productId,
    required this.medicineName,
    this.genericName,
    this.brandName,
    this.category = 'General',
    this.currentStock = 0,
    this.reorderLevel = 10,
    this.batchNo,
    this.expiryDate,
    this.mrp = 0,
    this.sellingPrice = 0,
    this.schedule = 'OTC',
    this.prescriptionRequired = false,
    this.isLowStock = false,
    this.isExpiryRisk = false,
    this.baseUom = 'unit',
    this.packagingLevels = const [],
    this.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) {
    List<PackagingLevel> levels = [];
    final raw = j['packaging'];
    if (raw is Map<String, dynamic>) {
      final rawLevels = raw['levels'];
      if (rawLevels is List) {
        levels = rawLevels
            .whereType<Map<String, dynamic>>()
            .map(PackagingLevel.fromJson)
            .toList();
      }
    }
    if (levels.isEmpty) {
      levels = [
        const PackagingLevel(level: 'unit', label: 'Unit', toBaseUnits: 1),
        const PackagingLevel(level: 'strip', label: 'Strip', toBaseUnits: 10),
        const PackagingLevel(level: 'box', label: 'Box', toBaseUnits: 100),
      ];
    }

    return ProductModel(
      productId: j['Product ID'] ?? j['product_id'] ?? '',
      medicineName: j['Medicine Name'] ?? j['medicine_name'] ?? '',
      genericName: j['generic_name']?.toString(),
      brandName: j['brand_name']?.toString(),
      category: j['category']?.toString() ?? 'General',
      currentStock: _toInt(j['current_stock'] ?? j['Current Stock']),
      reorderLevel: _toInt(j['reorder_level'] ?? j['Reorder Level'] ?? 10),
      batchNo: j['batch_no']?.toString(),
      expiryDate: j['expiry_date']?.toString() ?? j['Expiry Date']?.toString(),
      mrp: _toDouble(j['mrp'] ?? j['MRP']),
      sellingPrice: _toDouble(j['selling_price'] ?? j['Selling Price']),
      schedule: j['schedule']?.toString() ?? 'OTC',
      prescriptionRequired: j['prescription_required'] == true,
      isLowStock: j['is_low_stock'] == true,
      isExpiryRisk: j['is_expiry_risk'] == true,
      baseUom: j['base_uom']?.toString() ?? 'unit',
      packagingLevels: levels,
      imageUrl: j['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'medicine_name': medicineName,
        'generic_name': genericName,
        'brand_name': brandName,
        'category': category,
        'current_stock': currentStock,
        'reorder_level': reorderLevel,
        'batch_no': batchNo,
        'expiry_date': expiryDate,
        'mrp': mrp,
        'selling_price': sellingPrice,
        'schedule': schedule,
        'prescription_required': prescriptionRequired,
        'is_low_stock': isLowStock,
        'is_expiry_risk': isExpiryRisk,
        'base_uom': baseUom,
        'packaging': {
          'base_uom': baseUom,
          'levels': packagingLevels.map((l) => l.toJson()).toList(),
        },
        'image_url': imageUrl,
      };

  /// Total base units for a given packaging level + quantity.
  int totalBaseUnits(String level, int qty) {
    final found = packagingLevels.where((l) => l.level == level).toList();
    if (found.isEmpty) return qty;
    return found.first.toBaseUnits * qty;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
}
