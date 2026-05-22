import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/order_service.dart';
import '../../../models/order_model.dart';

class PharmaOrdersTab extends StatefulWidget {
  const PharmaOrdersTab({super.key});

  @override
  State<PharmaOrdersTab> createState() => _PharmaOrdersTabState();
}

class _PharmaOrdersTabState extends State<PharmaOrdersTab> {
  final OrderService _orderService = OrderService();
  String _filter = 'All';
  String? _error;
  int _activeRequestId = 0;

  List<Order> _allOrders = [];
  OrderStats? _stats;

  final _filters = ['All', 'Pending', 'Validated', 'Completed', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final requestId = ++_activeRequestId;
    if (mounted) setState(() => _error = null);

    try {
      final statsResult = await _orderService.getOrderStats();
      final ordersResult = await _orderService.getOrders(page: 1, pageSize: 100);

      if (!mounted || requestId != _activeRequestId) return;
      setState(() {
        _stats = statsResult;
        _allOrders = ordersResult['orders'] as List<Order>;
      });
    } catch (e) {
      if (!mounted || requestId != _activeRequestId) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  List<Order> get _filteredOrders {
    if (_filter == 'All') return _allOrders;
    return _allOrders.where((o) => o.orderStatus.toLowerCase() == _filter.toLowerCase()).toList();
  }

  void _openOrderDetails(Order order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OrderDetailsSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _allOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load orders',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkGreen,
                foregroundColor: AppTheme.neonGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              // Stats row
              Row(
                children: [
                  _OrderStat(
                    label: 'Pending',
                    value:
                        (_stats?.getCountForStatus('Pending') ?? 0).toString(),
                    color: AppTheme.amber,
                    bg: const Color(0xFFFEFCE8),
                  ),
                  const SizedBox(width: 8),
                  _OrderStat(
                    label: 'Validated',
                    value: (_stats?.getCountForStatus('Validated') ?? 0)
                        .toString(),
                    color: AppTheme.blue,
                    bg: const Color(0xFFEFF6FF),
                  ),
                  const SizedBox(width: 8),
                  _OrderStat(
                    label: 'Completed',
                    value: (_stats?.getCountForStatus('Completed') ?? 0)
                        .toString(),
                    color: AppTheme.lightGreen,
                    bg: const Color(0xFFF0FDF4),
                  ),
                  const SizedBox(width: 8),
                  _OrderStat(
                    label: 'Rejected',
                    value:
                        (_stats?.getCountForStatus('Rejected') ?? 0).toString(),
                    color: AppTheme.red,
                    bg: const Color(0xFFFEF2F2),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Filter chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final f = _filters[i];
                    final isActive = _filter == f;
                    return GestureDetector(
                      onTap: () {
                        if (_filter == f) return;
                        setState(() => _filter = f);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.darkGreen : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.darkGreen
                                : AppTheme.cardBorder,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          f,
                          style: GoogleFonts.inter(
                            color: isActive
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),

        // Orders list
        Expanded(
          child: _filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'No orders found',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.darkGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (ctx, i) => _OrderCard(
                      order: _filteredOrders[i],
                      onTap: () => _openOrderDetails(_filteredOrders[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _OrderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _OrderStat({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color.withOpacity(0.8),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  Color get _statusColor {
    switch (order.orderStatus) {
      case 'Validated':
        return AppTheme.blue;
      case 'Completed':
      case 'Fulfilled':
        return AppTheme.lightGreen;
      case 'Rejected':
        return AppTheme.red;
      default:
        return AppTheme.amber;
    }
  }

  Color get _statusBg {
    switch (order.orderStatus) {
      case 'Validated':
        return const Color(0xFFEFF6FF);
      case 'Completed':
      case 'Fulfilled':
        return const Color(0xFFF0FDF4);
      case 'Rejected':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFFEFCE8);
    }
  }

  IconData get _channelIcon {
    final channel = order.orderChannel.toLowerCase();
    if (channel.contains('whatsapp')) {
      return Icons.chat_bubble_rounded;
    } else if (channel.contains('call') || channel.contains('voice')) {
      return Icons.phone_rounded;
    } else if (channel.contains('sms')) {
      return Icons.sms_rounded;
    } else if (channel.contains('telegram')) {
      return Icons.send_rounded;
    } else {
      return Icons.language_rounded;
    }
  }

  Color get _channelColor {
    final channel = order.orderChannel.toLowerCase();
    if (channel.contains('whatsapp')) {
      return const Color(0xFF25D366);
    } else if (channel.contains('call') || channel.contains('voice')) {
      return AppTheme.purple;
    } else if (channel.contains('sms')) {
      return AppTheme.blue;
    } else if (channel.contains('telegram')) {
      return const Color(0xFF0088CC);
    } else {
      return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.patientName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '#${order.orderId}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.darkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    order.orderStatus,
                    style: GoogleFonts.inter(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${order.medicineName} x ${order.quantityOrdered}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(_channelIcon, size: 13, color: _channelColor),
                const SizedBox(width: 4),
                Text(
                  order.orderChannel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _channelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (order.orderDate != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today, size: 11, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    order.orderDate!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMuted),
              ],
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 12, color: AppTheme.purple),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      order.notes!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (order.orderStatus == 'Pending') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.amber.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 14, color: AppTheme.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order pending validation in central workflow',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  final Order order;

  const _OrderDetailsSheet({required this.order});

  static const List<String> _progressFlow = [
    'Pending',
    'Validated',
    'Completed',
  ];

  int get _stageIndex {
    final normalized = order.orderStatus.toLowerCase();
    if (normalized.contains('complete') || normalized.contains('fulfill')) return 2;
    if (normalized.contains('valid')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.52,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          children: [
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
              'Order Details',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusProgress(),
            const SizedBox(height: 16),
            _detailTile('Order ID', order.orderId),
            _detailTile('Patient', order.patientName.isEmpty ? 'Unknown' : order.patientName),
            _detailTile('Medicine', order.medicineName),
            _detailTile('Quantity', '${order.quantityOrdered}'),
            _detailTile('Current Status', order.orderStatus),
            _detailTile('Order Channel', order.orderChannel),
            _detailTile('Order Date', order.orderDate ?? 'Not available'),
            _detailTile('Payment', order.paymentMethod ?? 'Not set'),
            _detailTile('Contact', order.contactNumber ?? 'Not shared'),
            _detailTile('Notes', (order.notes == null || order.notes!.trim().isEmpty) ? 'No notes' : order.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_progressFlow.length, (index) {
          final done = index <= _stageIndex;
          final title = _progressFlow[index];
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: done ? AppTheme.darkGreen : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: done ? AppTheme.darkGreen : AppTheme.cardBorder,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: done ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (index < _progressFlow.length - 1)
                  Container(
                    width: 16,
                    height: 2,
                    color: done ? AppTheme.darkGreen : AppTheme.cardBorder,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _detailTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
