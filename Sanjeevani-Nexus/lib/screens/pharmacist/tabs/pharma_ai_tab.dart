import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/alerts_service.dart';
import '../../../services/dashboard_service.dart';
import '../../../theme/app_theme.dart';

class PharmaAiTab extends StatefulWidget {
  const PharmaAiTab({super.key});

  @override
  State<PharmaAiTab> createState() => _PharmaAiTabState();
}

class _PharmaAiTabState extends State<PharmaAiTab> {
  final DashboardService _dashboardService = DashboardService();
  final AlertsService _alertsService = AlertsService();

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Map<String, dynamic> _overview = const {};
  Map<String, dynamic> _alertsSummary = const {};

  @override
  void initState() {
    super.initState();
    _loadData(showLoader: false);
  }

  Future<void> _loadData({bool showLoader = true}) async {
    if (mounted) {
      setState(() {
        _error = null;
        if (showLoader && _overview.isEmpty) {
          _loading = true;
        } else {
          _refreshing = true;
        }
      });
    }

    try {
      final results = await Future.wait([
        _dashboardService.getOverview(),
        _alertsService.getSummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0];
        _alertsSummary = results[1];
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _refreshing = false;
      });
    }
  }

  int _intValue(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _overview.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 54, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                'Unable to load AI panel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final totalOrders = _intValue(_overview, 'total_orders');
    final highRiskRefills = _intValue(_overview, 'high_risk_refills');
    final lowStockItems = _intValue(_overview, 'low_stock_items');
    final unresolvedAlerts = _intValue(_alertsSummary, 'total_unresolved');

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoader: false),
      color: AppTheme.darkGreen,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.darkGreen, Color(0xFF0F4A42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Assistant Summary',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Live guidance from your current pharmacy activity',
                  style: GoogleFonts.inter(
                    color: AppTheme.neonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _AiStatWidget(value: '$totalOrders', label: 'Orders'),
                    _divider(),
                    _AiStatWidget(value: '$unresolvedAlerts', label: 'Open Alerts'),
                    _divider(),
                    _AiStatWidget(value: '$lowStockItems', label: 'Low Stock'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _LiveInsightCard(
            icon: Icons.warning_amber_rounded,
            iconColor: AppTheme.amber,
            title: 'Refill follow-up needed',
            description:
                '$highRiskRefills patients are at refill risk. Prioritize reminder outreach today.',
          ),
          _LiveInsightCard(
            icon: Icons.inventory_2_rounded,
            iconColor: AppTheme.red,
            title: 'Inventory attention',
            description:
                '$lowStockItems medicines are below safe stock level. Plan restocking to avoid shortages.',
          ),
          _LiveInsightCard(
            icon: Icons.security_rounded,
            iconColor: AppTheme.blue,
            title: 'Open safety alerts',
            description:
                '$unresolvedAlerts alerts still need action. Reviewing these first can reduce patient risk.',
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 42,
      color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _AiStatWidget extends StatelessWidget {
  final String value;
  final String label;

  const _AiStatWidget({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.65),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveInsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _LiveInsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
