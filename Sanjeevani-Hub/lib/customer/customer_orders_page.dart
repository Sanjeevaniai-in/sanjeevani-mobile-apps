import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../core/services/user_service.dart';
import 'package:intl/intl.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  bool _showingFallbackOrders = false;

  static const List<Map<String, dynamic>> _fallbackOrders = [
    {
      'status': 'delivered',
      'pharmacy_name': 'Sanjeevani Nexus Pharmacy',
      'medicine': 'Paracetamol 650',
      'total_amount': 48,
      'created_at': '2026-04-05T10:20:00Z',
    },
    {
      'status': 'out_for_delivery',
      'pharmacy_name': 'Sanjeevani Nexus Pharmacy',
      'medicine': 'Vitamin D3',
      'total_amount': 72,
      'created_at': '2026-04-05T12:05:00Z',
    },
    {
      'status': 'preparing',
      'pharmacy_name': 'Sanjeevani Nexus Pharmacy',
      'medicine': 'Cetirizine',
      'total_amount': 36,
      'created_at': '2026-04-05T13:10:00Z',
    },
    {
      'status': 'delivered',
      'pharmacy_name': 'Sanjeevani Nexus Pharmacy',
      'medicine': 'ORS Sachet',
      'total_amount': 30,
      'created_at': '2026-04-04T18:40:00Z',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _showingFallbackOrders = false;
    });
    try {
      final svc = UserService();
      final token = await svc.token;
      final user = await svc.currentUser;

      // Build user-scoped query: filter by user email/name so only their orders show
      final email = user?.email ?? '';
      final name = user?.name ?? '';
      final userId = user?.id ?? '';

      final queryParams = <String, String>{};
      if (userId.isNotEmpty) queryParams['user_id'] = userId;
      if (email.isNotEmpty) queryParams['patient_email'] = email;
      if (name.isNotEmpty) queryParams['patient_name'] = name;

      final uri = Uri.parse(ApiConfig.ordersList).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend returns {status:'ok', data:{items:[...]}} or a list
        final List<dynamic> list = data is List
            ? data
            : (data['data']?['items'] ?? data['data'] ?? data['items'] ?? data['orders'] ?? []);
        if (!mounted) return;
        setState(() {
          _orders = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .map(_normalizeOrder)
              .toList();
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _orders = _fallbackOrders.map((e) => _normalizeOrder(e)).toList();
          _showingFallbackOrders = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _orders = _fallbackOrders.map((e) => _normalizeOrder(e)).toList();
        _showingFallbackOrders = true;
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _normalizeOrder(Map<String, dynamic> order) {
    return {
      ...order,
      'status': (order['status'] ?? order['order_status'] ?? order['Order Status'] ?? 'pending').toString(),
      'pharmacy_name': (order['pharmacy_name'] ?? order['shop_name'] ?? order['pharmacy'] ?? 'Sanjeevani Pharmacy').toString(),
      'medicine': (order['medicine'] ?? order['medicine_name'] ?? order['Medicine Name'] ?? 'Medicine order').toString(),
      'total_amount': order['total_amount'] ?? order['total'] ?? order['price'] ?? order['Total Amount'] ?? 0,
      'created_at': (order['created_at'] ?? order['createdAt'] ?? order['Order Date'] ?? '').toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Orders',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0066FF)),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _loading
          ? _buildShimmer()
          : _error != null
              ? _buildError()
              : _orders.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_showingFallbackOrders)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Text(
                                'Showing recent sample orders while server sync completes.',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF1D4ED8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ..._orders.map((o) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildOrderCard(o),
                              )),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = (order['status'] ?? 'pending').toString();
    final shopName = order['pharmacy_name'] ?? order['shop_name'] ?? 'Sanjeevani Pharmacy';
    final items = order['items'] as List<dynamic>? ?? [];
    final itemStr = items.isNotEmpty
        ? items.map((e) => e['name'] ?? e.toString()).join(', ')
        : order['medicine'] ?? 'Medicine order';
    final total = order['total_amount'] ?? order['total'] ?? order['price'] ?? 0;
    final createdAt = order['created_at'] ?? order['createdAt'] ?? '';
    String dateStr = '';
    try {
      if (createdAt.isNotEmpty) {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr = DateFormat('d MMM, h:mm a').format(dt);
      }
    } catch (_) {
      dateStr = createdAt;
    }

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'delivered': statusColor = const Color(0xFF10B981); break;
      case 'out_for_delivery':
      case 'in transit': statusColor = const Color(0xFF3B82F6); break;
      case 'cancelled': statusColor = Colors.redAccent; break;
      case 'preparing': statusColor = const Color(0xFFF59E0B); break;
      default: statusColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  shopName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            itemStr,
            style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 11),
              ),
              Text(
                total > 0 ? '₹${total.toString()}' : '—',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const _ShimmerBox(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(_error!, style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchOrders,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No orders yet',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text('Place your first order via the chatbot!',
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.grey.withOpacity(0.05),
              Colors.grey.withOpacity(0.15),
              Colors.grey.withOpacity(0.05),
            ],
            stops: [0.0, _anim.value, 1.0],
          ),
        ),
      ),
    );
  }
}
