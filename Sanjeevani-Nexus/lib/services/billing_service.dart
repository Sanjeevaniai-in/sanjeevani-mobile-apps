import '../models/product_model.dart';

/// A single line item in the cart.
class CartItem {
  final ProductModel product;
  final String packagingLevel; // 'unit' | 'strip' | 'box' | 'bottle'
  int quantity;

  CartItem({
    required this.product,
    required this.packagingLevel,
    this.quantity = 1,
  });

  int get baseUnits => product.totalBaseUnits(packagingLevel, quantity);
  double get unitPrice => product.sellingPrice;
  double get lineTotal => unitPrice * baseUnits;

  String get displayUnit {
    final found = product.packagingLevels
        .where((l) => l.level == packagingLevel)
        .toList();
    return found.isEmpty ? packagingLevel : found.first.label;
  }
}

/// In-memory cart + bill generation.
class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.lineTotal);

  double get total => subtotal; // Extend with tax/discount later.

  void addItem(ProductModel product, {String level = 'unit', int qty = 1}) {
    final existing = _items
        .where(
          (i) =>
              i.product.productId == product.productId &&
              i.packagingLevel == level,
        )
        .toList();
    if (existing.isNotEmpty) {
      existing.first.quantity += qty;
    } else {
      _items.add(
          CartItem(product: product, packagingLevel: level, quantity: qty));
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) _items.removeAt(index);
  }

  void updateQty(int index, int qty) {
    if (index >= 0 && index < _items.length) {
      if (qty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = qty;
      }
    }
  }

  void clear() => _items.clear();

  /// Returns a structured bill map ready for display or API submission.
  Map<String, dynamic> generateBill(
      {String? customerName, String paymentMethod = 'Cash'}) {
    return {
      'customer_name': customerName ?? 'Walk-in Customer',
      'payment_method': paymentMethod,
      'items': _items
          .map((i) => {
                'product_id': i.product.productId,
                'medicine_name': i.product.medicineName,
                'packaging_level': i.packagingLevel,
                'quantity': i.quantity,
                'base_units': i.baseUnits,
                'unit_price': i.unitPrice,
                'line_total': i.lineTotal,
              })
          .toList(),
      'subtotal': subtotal,
      'total': total,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }
}
