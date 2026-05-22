import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/product_model.dart';
import '../../../services/sync_service.dart';
import '../../../theme/app_theme.dart';
import '../add_medicine_screen.dart';
import '../scan_product_screen.dart';
import 'qr_scan_screen.dart';

class PharmaInventoryTab extends StatefulWidget {
  const PharmaInventoryTab({super.key});

  @override
  State<PharmaInventoryTab> createState() => _PharmaInventoryTabState();
}

class _PharmaInventoryTabState extends State<PharmaInventoryTab> {
  final SyncService _sync = SyncService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  String? _error;
  String _activeTab = 'all';
  bool _loading = true;

  List<ProductModel> _allItems = const [];
  List<ProductModel> _filtered = const [];

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSyncUpdate);
    _sync.startPeriodicSync();
    _loadInventory();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncUpdate);
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) _loadInventory(silent: true);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _applyFilter);
  }

  Future<void> _loadInventory(
      {bool forceRefresh = false, bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    if (forceRefresh) await _sync.forceSync();

    try {
      final items = await _sync.getProducts();
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _loading = false;
        _error = null;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<ProductModel> base;
    switch (_activeTab) {
      case 'low':
        base = _allItems.where((p) {
          if (p.isLowStock) return true;
          if (p.reorderLevel > 0) return p.currentStock <= p.reorderLevel;
          return p.currentStock <= 10;
        }).toList();
        break;
      case 'expiry':
        final now = DateTime.now();
        base = _allItems.where((p) {
          if (p.isExpiryRisk) return true;
          if (p.expiryDate == null) return false;
          final parsed = DateTime.tryParse(p.expiryDate!.replaceAll('/', '-'));
          if (parsed == null) return false;
          return parsed.difference(now).inDays <= 90;
        }).toList();
        break;
      default:
        base = _allItems;
    }

    if (q.isNotEmpty) {
      base =
          base.where((p) => p.medicineName.toLowerCase().contains(q)).toList();
    }

    if (mounted) setState(() => _filtered = base);
  }

  int get _lowCount => _allItems.where((p) {
        if (p.isLowStock) return true;
        if (p.reorderLevel > 0) return p.currentStock <= p.reorderLevel;
        return p.currentStock <= 10;
      }).length;

  int get _expiryCount {
    final now = DateTime.now();
    return _allItems.where((p) {
      if (p.isExpiryRisk) return true;
      if (p.expiryDate == null) return false;
      final parsed = DateTime.tryParse(p.expiryDate!.replaceAll('/', '-'));
      if (parsed == null) return false;
      return parsed.difference(now).inDays <= 90;
    }).length;
  }

  Future<void> _scanAndAddMedicine() async {
    final raw = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (raw == null || raw.trim().isEmpty || !mounted) return;
    final parts = raw.trim().split('|');
    final seedName = parts.isNotEmpty ? parts.first.trim() : null;
    final seedStock = parts.length > 1 ? int.tryParse(parts[1].trim()) : null;
    final seedCategory = parts.length > 2 ? parts[2].trim() : null;
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicineScreen(
          seedName: seedName,
          seedStock: seedStock,
          seedCategory: seedCategory,
        ),
      ),
    );
    if (added == true) await _loadInventory(forceRefresh: true);
  }

  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddOptionsSheet(
        onCamera: () async {
          Navigator.pop(context);
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ScanProductScreen()),
          );
          if (added == true) await _loadInventory(forceRefresh: true);
        },
        onManual: () async {
          Navigator.pop(context);
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
          );
          if (added == true) await _loadInventory(forceRefresh: true);
        },
        onQr: () async {
          Navigator.pop(context);
          await _scanAndAddMedicine();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _allItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () => _loadInventory(forceRefresh: true),
                  child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgGray,
      body: Column(
        children: [
          // Tab bar + search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Tabs
                Row(
                  children: [
                    Expanded(
                      child: _InventoryTab(
                        title: 'All',
                        isActive: _activeTab == 'all',
                        count: '${_allItems.length}',
                        onTap: () {
                          setState(() => _activeTab = 'all');
                          _applyFilter();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InventoryTab(
                        title: 'Low Stock',
                        isActive: _activeTab == 'low',
                        count: '$_lowCount',
                        onTap: () {
                          setState(() => _activeTab = 'low');
                          _applyFilter();
                        },
                        alertColor: AppTheme.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InventoryTab(
                        title: 'Expiry',
                        isActive: _activeTab == 'expiry',
                        count: '$_expiryCount',
                        onTap: () {
                          setState(() => _activeTab = 'expiry');
                          _applyFilter();
                        },
                        alertColor: AppTheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textMuted, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppTheme.textMuted, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.bgGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),

          // Sync indicator
          if (_sync.isSyncing)
            Container(
              color: AppTheme.darkGreen.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Syncing inventory...',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadInventory(forceRefresh: true),
                    child: _filtered.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.45,
                                child: Center(
                                  child: Text(
                                    _searchCtrl.text.isNotEmpty
                                        ? 'No results for "${_searchCtrl.text}"'
                                        : _activeTab == 'all'
                                            ? 'No inventory items yet'
                                            : 'No items in this section',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) =>
                                _StockItem(product: _filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
      // Floating add button
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: AppTheme.darkGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ── Add Options Bottom Sheet ──────────────────────────────────────────────────

class _AddOptionsSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onManual;
  final VoidCallback onQr;

  const _AddOptionsSheet({
    required this.onCamera,
    required this.onManual,
    required this.onQr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.cardBorder,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Add Medicine',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 20),
          _OptionTile(
            icon: Icons.camera_alt_rounded,
            color: AppTheme.darkGreen,
            title: 'Scan with Camera',
            subtitle: 'Auto-extract name, batch, expiry, MRP',
            onTap: onCamera,
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.qr_code_scanner_rounded,
            color: AppTheme.purple,
            title: 'Scan QR / Barcode',
            subtitle: 'Quick add via QR code',
            onTap: onQr,
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.edit_rounded,
            color: AppTheme.amber,
            title: 'Manual Entry',
            subtitle: 'Type details manually',
            onTap: onManual,
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Inventory Tab Chip ────────────────────────────────────────────────────────

class _InventoryTab extends StatelessWidget {
  final String title;
  final bool isActive;
  final String count;
  final VoidCallback onTap;
  final Color? alertColor;

  const _InventoryTab({
    required this.title,
    required this.isActive,
    required this.count,
    required this.onTap,
    this.alertColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = alertColor ?? AppTheme.darkGreen;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor : AppTheme.bgGray,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : AppTheme.cardBorder,
          ),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white70 : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stock Item Card ───────────────────────────────────────────────────────────

class _StockItem extends StatelessWidget {
  final ProductModel product;

  const _StockItem({required this.product});

  @override
  Widget build(BuildContext context) {
    final isCritical = product.isLowStock ||
        (product.reorderLevel > 0 &&
            product.currentStock <= product.reorderLevel);
    final isLow = !isCritical && product.currentStock <= 10;
    final color = isCritical
        ? AppTheme.error
        : (isLow ? AppTheme.amber : AppTheme.lightGreen);
    final status = isCritical ? 'Critical' : (isLow ? 'Low' : 'Healthy');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.medicineName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stock: ${product.currentStock}  •  ${product.expiryDate ?? 'No expiry'}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
