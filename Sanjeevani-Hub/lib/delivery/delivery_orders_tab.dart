import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';
import '../core/config/api_config.dart';

class DeliveryOrdersTab extends StatefulWidget {
  final String? riderId;

  const DeliveryOrdersTab({super.key, this.riderId});

  @override
  State<DeliveryOrdersTab> createState() => _DeliveryOrdersTabState();
}

class _DeliveryOrdersTabState extends State<DeliveryOrdersTab> {
  final NotificationService _notificationService = NotificationService();
  final List<Map<String, dynamic>> _notifications = [];
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final riderId = widget.riderId ?? 'default_rider';
    await _notificationService.initialize(riderId);

    final pastNotifications = await _notificationService.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications.addAll(pastNotifications);
      });
    }

    _notificationSubscription = _notificationService.notificationStream.listen((notification) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, {
            ...notification,
            'received_at': DateTime.now().toIso8601String(),
          });
        });
        _showNotificationToast(notification);
      }
    });
  }

  void _showNotificationToast(Map<String, dynamic> notification) {
    final type = notification['type'] ?? notification['notification_type'];
    final isEmergency = type == 'emergency' || type == 'officer_sos_alert';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notification['title'] ?? 'New Notification'),
        backgroundColor: isEmergency ? Colors.red : const Color(0xFF1F2937),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(time);
      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Deliveries',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Assigned tasks and emergency alerts',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        
        _notifications.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationCard(_notifications[index]);
                },
              ),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] ?? notification['notification_type'];
    final isEmergency = type == 'emergency' || type == 'officer_sos_alert';
    final title = notification['title'] ?? 'New Delivery Alert';
    final message = notification['message'] ?? notification['message_text'] ?? 'New task assigned to you.';
    final time = _getTimeAgo(notification['received_at'] ?? notification['created_at'] ?? notification['triggered_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEmergency ? Colors.red.withOpacity(0.3) : Colors.grey[200]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEmergency ? Colors.red.withOpacity(0.1) : const Color(0xFF0066FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isEmergency ? Icons.warning_rounded : Icons.local_shipping_rounded,
                  color: isEmergency ? Colors.red : const Color(0xFF0066FF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isEmergency ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isEmergency ? 'URGENT' : 'ACTIVE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isEmergency ? Colors.red : Colors.green,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final orderId = notification['order_id']?.toString() ?? notification['_id']?.toString() ?? '';
                    if (orderId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No order ID to accept.')),
                      );
                      return;
                    }
                    try {
                      final response = await http.patch(
                        Uri.parse('${ApiConfig.engineBaseUrl}/api/v1/orders/$orderId/status'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'status': isEmergency ? 'responding' : 'accepted'}),
                      ).timeout(ApiConfig.receiveTimeout);

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEmergency ? '🚨 Responding to emergency!' : '✅ Task accepted!'),
                              backgroundColor: isEmergency ? Colors.red : const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Server error: ${response.statusCode}')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Network error. Please retry.')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEmergency ? Colors.red : const Color(0xFF1F2937),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEmergency ? 'Respond Now' : 'Accept Task',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final lat = notification['lat']?.toString() ?? notification['delivery_lat']?.toString() ?? '';
                    final lng = notification['lng']?.toString() ?? notification['delivery_lng']?.toString() ?? '';
                    final label = Uri.encodeComponent(notification['title'] ?? 'Delivery Location');
                    final Uri mapsUrl = lat.isNotEmpty && lng.isNotEmpty
                        ? Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)')
                        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$label');
                    if (await canLaunchUrl(mapsUrl)) {
                      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.location_on_outlined, color: Color(0xFF1F2937)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_motion_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All Caught Up!',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New delivery tasks will appear here.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
