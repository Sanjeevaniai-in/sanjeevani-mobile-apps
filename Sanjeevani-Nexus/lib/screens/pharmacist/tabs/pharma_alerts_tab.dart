import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/alerts_service.dart';
import '../../../services/product_service.dart';
import '../../../theme/app_theme.dart';

class PharmaAlertsTab extends StatefulWidget {
  const PharmaAlertsTab({super.key});

  @override
  State<PharmaAlertsTab> createState() => _PharmaAlertsTabState();
}

class _PharmaAlertsTabState extends State<PharmaAlertsTab> {
  final ProductService _productService = ProductService();
  final AlertsService _alertsService = AlertsService();

  String? _error;
  Map<String, dynamic> _summary = const {};
  List<Map<String, dynamic>> _lowStockItems = const [];
  List<Map<String, dynamic>> _expiryRiskItems = const [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _productService.clearCache();
    }
    if (mounted) setState(() => _error = null);
    try {
      final results = await Future.wait([
        _alertsService.getSummary(),
        _productService.getLowStock(useCache: !forceRefresh),
        _productService.getExpiryRisk(useCache: !forceRefresh),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _lowStockItems = results[1] as List<Map<String, dynamic>>;
        _expiryRiskItems = results[2] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  int _summaryInt(String key) {
    final value = _summary[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final alertsOpen = _summaryInt('total_unresolved');
    final liveTotal = _lowStockItems.length + _expiryRiskItems.length;

    if (_error != null && liveTotal == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 52),
              const SizedBox(height: 10),
              Text(
                'Notifications not available',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(onPressed: _loadAlerts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAlerts(forceRefresh: true),
      color: AppTheme.darkGreen,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B57D0), Color(0xFF0066FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Pharmacy Notifications',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$alertsOpen unresolved backend alerts',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _countCard(
                title: 'Refill Needed',
                value: '${_lowStockItems.length}',
                color: AppTheme.amber,
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 10),
              _countCard(
                title: 'Expiry Risk',
                value: '${_expiryRiskItems.length}',
                color: AppTheme.error,
                icon: Icons.event_busy_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Priority Feed',
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          if (liveTotal == 0)
            _emptyCard('No live notifications right now.')
          else ...[
            ..._lowStockItems.take(6).map((item) => _alertCard(
                  title: _name(item),
                  subtitle: 'Refill needed. Stock is getting low.',
                  badge: 'Refill',
                  color: AppTheme.amber,
                  trailing: 'Stock: ${_int(item['current_stock'] ?? item['Current Stock'])}',
                )),
            ..._expiryRiskItems.take(6).map((item) => _alertCard(
                  title: _name(item),
                  subtitle: 'Expiry attention required for this item.',
                  badge: 'Expiry',
                  color: AppTheme.error,
                  trailing: _expiryText(item),
                )),
          ],
        ],
      ),
    );
  }

  Widget _countCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color color,
    required String trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trailing,
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _name(Map<String, dynamic> item) {
    final raw = item['medicine_name'] ?? item['Medicine Name'] ?? item['product_name'];
    return (raw?.toString().trim().isNotEmpty ?? false) ? raw.toString() : 'Unnamed medicine';
  }

  String _expiryText(Map<String, dynamic> item) {
    final days = item['days_until_expiry'];
    if (days is int) return '$days days left';
    if (days is num) return '${days.toInt()} days left';
    final raw = item['expiry_date'] ?? item['Expiry Date'];
    if (raw == null || '$raw'.trim().isEmpty) return 'Check expiry date';
    return '$raw';
  }

  int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
