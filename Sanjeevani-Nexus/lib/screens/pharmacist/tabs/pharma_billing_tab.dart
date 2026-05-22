import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/product_model.dart';
import '../../../services/billing_service.dart';
import '../../../services/sync_service.dart';
import '../../../theme/app_theme.dart';

class PharmaBillingTab extends StatefulWidget {
  const PharmaBillingTab({super.key});

  @override
  State<PharmaBillingTab> createState() => _PharmaBillingTabState();
}

class _PharmaBillingTabState extends State<PharmaBillingTab> {
  final BillingService _billing = BillingService();
  final SyncService _sync = SyncService();

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<ProductModel> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final results = await _sync.getProducts(search: q);
      if (!mounted) return;
      setState(() => _results = results.take(30).toList());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _addToCart(ProductModel product) {
    _billing.addItem(product, level: 'unit', qty: 1);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.medicineName} added to bill'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openBillSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BillSheet(
        billing: _billing,
        onChanged: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = _billing.itemCount;

    return Scaffold(
      backgroundColor: AppTheme.bgGray,
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Search medicine to add to bill...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 14, color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.textMuted),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppTheme.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _results = []);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.bgGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (cartCount > 0) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openBillSheet,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.darkGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long_rounded,
                              color: Colors.white, size: 22),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppTheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$cartCount',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Results
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : _searchCtrl.text.isEmpty
                    ? _buildEmptyState()
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              'No medicines found',
                              style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _results.length,
                            itemBuilder: (_, i) => _SearchResultTile(
                              product: _results[i],
                              onAdd: () => _addToCart(_results[i]),
                            ),
                          ),
          ),
        ],
      ),
      // Floating bill button
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: _openBillSheet,
              backgroundColor: AppTheme.darkGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.receipt_long_rounded),
              label: Text(
                'Bill  ₹${_billing.total.toStringAsFixed(0)}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded,
              size: 64, color: AppTheme.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'Search a medicine to start billing',
            style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Type medicine name above',
            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Search Result Tile ────────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const _SearchResultTile({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final stockOk = product.currentStock > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Text(
          product.medicineName,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.textPrimary),
        ),
        subtitle: Text(
          '₹${product.sellingPrice.toStringAsFixed(0)}  •  Stock: ${product.currentStock}',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: stockOk
            ? GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.darkGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 20),
                ),
              )
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Out',
                  style: GoogleFonts.inter(
                      color: AppTheme.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
      ),
    );
  }
}

// ── Bill Bottom Sheet ─────────────────────────────────────────────────────────

class _BillSheet extends StatefulWidget {
  final BillingService billing;
  final VoidCallback onChanged;

  const _BillSheet({required this.billing, required this.onChanged});

  @override
  State<_BillSheet> createState() => _BillSheetState();
}

class _BillSheetState extends State<_BillSheet> {
  final TextEditingController _customerCtrl = TextEditingController();
  String _paymentMethod = 'Cash';
  bool _confirmed = false;

  @override
  void dispose() {
    _customerCtrl.dispose();
    super.dispose();
  }

  void _confirmBill() {
    // In a real integration: POST bill to backend here.
    widget.billing.generateBill(
      customerName: _customerCtrl.text.trim().isEmpty
          ? 'Walk-in Customer'
          : _customerCtrl.text.trim(),
      paymentMethod: _paymentMethod,
    );
    widget.billing.clear();
    widget.onChanged();
    setState(() => _confirmed = true);
    // Show success then close.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.billing.items;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _confirmed
            ? _buildSuccess()
            : ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBorder,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Current Bill',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 14),

                  // Customer name
                  TextField(
                    controller: _customerCtrl,
                    decoration: InputDecoration(
                      hintText: 'Customer name (optional)',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment method
                  Row(
                    children: ['Cash', 'UPI', 'Card'].map((m) {
                      final sel = _paymentMethod == m;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentMethod = m),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.darkGreen : AppTheme.bgGray,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppTheme.darkGreen
                                    : AppTheme.cardBorder,
                              ),
                            ),
                            child: Text(
                              m,
                              style: GoogleFonts.inter(
                                color:
                                    sel ? Colors.white : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Items
                  ...List.generate(items.length, (i) {
                    final item = items[i];
                    return _CartItemRow(
                      item: item,
                      onRemove: () {
                        widget.billing.removeItem(i);
                        widget.onChanged();
                        setState(() {});
                      },
                      onQtyChange: (q) {
                        widget.billing.updateQty(i, q);
                        widget.onChanged();
                        setState(() {});
                      },
                    );
                  }),

                  const Divider(height: 24),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      Text(
                        '₹${widget.billing.total.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: items.isEmpty ? null : _confirmBill,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Confirm & Generate Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.lightGreen, size: 72),
          const SizedBox(height: 16),
          Text(
            'Bill Generated!',
            style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaction recorded successfully.',
            style:
                GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Cart Item Row ─────────────────────────────────────────────────────────────

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChange;

  const _CartItemRow({
    required this.item,
    required this.onRemove,
    required this.onQtyChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.medicineName,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.textPrimary),
                ),
                Text(
                  '${item.displayUnit}  •  ₹${item.unitPrice.toStringAsFixed(0)} each',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Qty stepper
          Row(
            children: [
              _stepBtn(
                  Icons.remove_rounded, () => onQtyChange(item.quantity - 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              _stepBtn(Icons.add_rounded, () => onQtyChange(item.quantity + 1)),
            ],
          ),
          const SizedBox(width: 10),
          Text(
            '₹${item.lineTotal.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.darkGreen),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 18, color: AppTheme.error),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Icon(icon, size: 16, color: AppTheme.textPrimary),
      ),
    );
  }
}
