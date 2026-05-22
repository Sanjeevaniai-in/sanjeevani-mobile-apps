import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/order_model.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/order_service.dart';
import '../../../services/patient_service.dart';
import '../../../services/product_service.dart';
import '../../../theme/app_theme.dart';

class PharmaOverviewTab extends StatefulWidget {
  const PharmaOverviewTab({super.key});

  @override
  State<PharmaOverviewTab> createState() => _PharmaOverviewTabState();
}

class _PharmaOverviewTabState extends State<PharmaOverviewTab> {
  final DashboardService _dashboardService = DashboardService();
  final OrderService _orderService = OrderService();
  final PatientService _patientService = PatientService();
  final ProductService _productService = ProductService();

  Map<String, dynamic> _overview = const {};
  List<Order> _recentOrders = const [];
  List<Map<String, dynamic>> _patients = const [];
  List<Map<String, dynamic>> _lowStock = const [];
  List<Map<String, dynamic>> _expiryRisk = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _dashboardService.getOverview().catchError((_) => <String, dynamic>{}),
        _orderService
            .getOrders(page: 1, pageSize: 8)
            .catchError((_) => <String, dynamic>{'orders': <Order>[]}),
        _patientService.getLivePatients().catchError((_) => <String, dynamic>{
              'patients': <Map<String, dynamic>>[],
              'summary': <String, dynamic>{}
            }),
        _productService
            .getLowStock(useCache: true)
            .catchError((_) => <Map<String, dynamic>>[]),
        _productService
            .getExpiryRisk(useCache: true)
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      final ordersMap = results[1] as Map<String, dynamic>;
      final patientsMap = results[2] as Map<String, dynamic>;
      final patientsRaw = patientsMap['patients'];
      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        _recentOrders = (ordersMap['orders'] as List<Order>?) ?? [];
        _patients = patientsRaw is List
            ? patientsRaw.whereType<Map<String, dynamic>>().take(5).toList()
            : [];
        _lowStock = results[3] as List<Map<String, dynamic>>;
        _expiryRisk = results[4] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _int(String key) {
    final v = _overview[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  String _metric(String key) {
    if (_overview.isEmpty) return '--';
    return '${_int(key)}';
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
              const Icon(Icons.wifi_off_rounded,
                  size: 52, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text('Could not connect to server',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.darkGreen,
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _buildHero(),
                const SizedBox(height: 16),
                _buildAlertBanner(),
                const SizedBox(height: 16),
                _buildQuickStats(),
                const SizedBox(height: 20),
                _buildSectionTitle('Recent Orders', Icons.receipt_long_rounded,
                    AppTheme.darkGreen,
                    onTap: () => _showOrdersSheet()),
                const SizedBox(height: 10),
                _buildOrdersList(),
                const SizedBox(height: 20),
                _buildSectionTitle(
                    'Patients', Icons.people_rounded, AppTheme.purple,
                    onTap: () => _showPatientsSheet()),
                const SizedBox(height: 10),
                _buildPatientsList(),
                const SizedBox(height: 20),
                _buildRevenueCard(),
              ],
            ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkGreen, Color(0xFF0047CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting,
              style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text("Today's Summary",
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroTile(_metric('total_orders'), 'Orders'),
              _heroTile(_metric('total_patients'), 'Patients'),
              _heroTile(_metric('total_products'), 'Products'),
              _heroTile(_metric('active_alerts'), 'Alerts'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroTile(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  color: AppTheme.neonGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Alert Banner ──────────────────────────────────────────────────────────

  Widget _buildAlertBanner() {
    final total = _lowStock.length + _expiryRisk.length;
    if (total == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_lowStock.length} low stock  •  ${_expiryRisk.length} expiry risk',
              style: GoogleFonts.inter(
                  color: AppTheme.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          Text('View Inventory',
              style: GoogleFonts.inter(
                  color: AppTheme.darkGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Quick Stats ───────────────────────────────────────────────────────────

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statCard('Low Stock', '${_lowStock.length}',
            Icons.inventory_2_outlined, AppTheme.amber),
        const SizedBox(width: 10),
        _statCard('Expiry Risk', '${_expiryRisk.length}',
            Icons.event_busy_outlined, AppTheme.error),
        const SizedBox(width: 10),
        _statCard('High-Risk', _metric('high_risk_refills'),
            Icons.priority_high_rounded, AppTheme.purple),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Section Title ─────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        const Spacer(),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                Text('See all',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.darkGreen,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: AppTheme.darkGreen),
              ],
            ),
          ),
      ],
    );
  }

  // ── Orders List ───────────────────────────────────────────────────────────

  Widget _buildOrdersList() {
    if (_recentOrders.isEmpty) {
      return _emptyCard('No recent orders');
    }
    return Column(
      children: _recentOrders.take(3).map((o) => _OrderTile(order: o)).toList(),
    );
  }

  void _showOrdersSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrdersSheet(orders: _recentOrders),
    );
  }

  // ── Patients List ─────────────────────────────────────────────────────────

  Widget _buildPatientsList() {
    if (_patients.isEmpty) return _emptyCard('No patient records yet');
    return Column(
      children: _patients.map((p) => _PatientTile(patient: p)).toList(),
    );
  }

  void _showPatientsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientsSheet(patients: _patients),
    );
  }

  // ── Revenue Card ──────────────────────────────────────────────────────────

  Widget _buildRevenueCard() {
    final revenue = _overview['monthly_revenue'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.darkGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Revenue',
                    style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('₹ ${revenue ?? 0}',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.trending_up_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Text(msg,
          style:
              GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
    );
  }
}

// ── Order Tile ────────────────────────────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order});

  Color get _statusColor {
    final s = order.orderStatus.toLowerCase();
    if (s.contains('complete')) return AppTheme.lightGreen;
    if (s.contains('pending')) return AppTheme.amber;
    if (s.contains('valid')) return AppTheme.blue;
    if (s.contains('reject')) return AppTheme.error;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.bgGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppTheme.darkGreen, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.patientName.isEmpty ? 'Unknown' : order.patientName,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.textPrimary),
                ),
                Text(
                  order.medicineName,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(order.orderStatus,
                style: GoogleFonts.inter(
                    color: _statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ── Patient Tile ──────────────────────────────────────────────────────────────

class _PatientTile extends StatelessWidget {
  final Map<String, dynamic> patient;
  const _PatientTile({required this.patient});

  @override
  Widget build(BuildContext context) {
    final name = (patient['name'] ?? 'Customer').toString();
    final orders = (patient['orders_count'] ?? 0).toString();
    final medicine = (patient['latest_medicine'] ?? '').toString();
    final initials = _initials(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.purple.withValues(alpha: 0.12),
            child: Text(initials,
                style: GoogleFonts.inter(
                    color: AppTheme.purple,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary)),
                if (medicine.isNotEmpty)
                  Text(medicine,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.bgGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$orders orders',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  String _initials(String v) {
    final parts =
        v.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── Orders Bottom Sheet ───────────────────────────────────────────────────────

class _OrdersSheet extends StatelessWidget {
  final List<Order> orders;
  const _OrdersSheet({required this.orders});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            Text('All Orders',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 14),
            if (orders.isEmpty)
              Text('No orders found',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary))
            else
              ...orders.map((o) => _OrderDetailCard(order: o)),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailCard extends StatelessWidget {
  final Order order;
  const _OrderDetailCard({required this.order});

  Color get _statusColor {
    final s = order.orderStatus.toLowerCase();
    if (s.contains('complete')) return AppTheme.lightGreen;
    if (s.contains('pending')) return AppTheme.amber;
    if (s.contains('valid')) return AppTheme.blue;
    if (s.contains('reject')) return AppTheme.error;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    order.patientName.isEmpty ? 'Unknown' : order.patientName,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(order.orderStatus,
                    style: GoogleFonts.inter(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${order.medicineName}  ×  ${order.quantityOrdered}',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text('#${order.orderId}  •  ${order.orderChannel}',
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

// ── Patients Bottom Sheet ─────────────────────────────────────────────────────

class _PatientsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> patients;
  const _PatientsSheet({required this.patients});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            Text('All Patients',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 14),
            if (patients.isEmpty)
              Text('No patients found',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary))
            else
              ...patients.map((p) => _PatientTile(patient: p)),
          ],
        ),
      ),
    );
  }
}
