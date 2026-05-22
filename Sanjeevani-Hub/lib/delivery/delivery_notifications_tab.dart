import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeliveryNotificationsTab extends StatefulWidget {
  const DeliveryNotificationsTab({super.key});

  @override
  State<DeliveryNotificationsTab> createState() =>
      _DeliveryNotificationsTabState();
}

class _DeliveryNotificationsTabState extends State<DeliveryNotificationsTab> {
  final NotificationService _notificationService = NotificationService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<Map<String, dynamic>> _notifications = [];
  StreamSubscription? _notificationSubscription;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  String? _riderId;

  @override
  void initState() {
    super.initState();
    _loadRiderIdAndInitialize();
  }

  Future<void> _loadRiderIdAndInitialize() async {
    _riderId = await _storage.read(key: 'rider_id') ?? 'default_rider';
    await _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (_riderId == null) return;

    await _notificationService.initialize(_riderId!);
    final pastNotifications = await _notificationService.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications.addAll(pastNotifications);
      });
    }

    _notificationSubscription = _notificationService.notificationStream.listen((
      notification,
    ) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, {
            ...notification,
            'received_at': DateTime.now().toIso8601String(),
          });
        });
        _showNotificationToast(notification);
        _listKey.currentState?.insertItem(0);
      }
    });
  }

  void _showNotificationToast(Map<String, dynamic> notification) {
    final type = notification['type'] ?? notification['notification_type'];
    final isEmergency = type == 'emergency';

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _NotificationToast(
        notification: notification,
        isEmergency: isEmergency,
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      overlayEntry.remove();
    });
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

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Color(0xFF00D4FF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Notifications',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'All updates, alerts, and messages',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Notifications List
        Expanded(
          child: _notifications.isEmpty
              ? _buildEmptyState()
              : AnimatedList(
                  key: _listKey,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  initialItemCount: _notifications.length,
                  itemBuilder: (context, index, animation) {
                    final notification = _notifications[index];
                    return _buildAnimatedNotificationCard(
                      notification,
                      animation,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnimatedNotificationCard(
    Map<String, dynamic> notification,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _buildNotificationCard(notification),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] ?? notification['notification_type'];
    final isEmergency = type == 'emergency' || type == 'officer_sos_alert';

    if (type == 'officer_sos_alert') {
      return _SOSAlertCard(
        officerName: notification['officer_name'] ?? 'Unknown Officer',
        badgeNumber: notification['badge_number'],
        emergencyType: notification['emergency_type'] ?? 'emergency',
        message: notification['message_text'],
        time: _getTimeAgo(
          notification['received_at'] ?? notification['triggered_at'],
        ),
        lat: (notification['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (notification['lng'] as num?)?.toDouble() ?? 0.0,
      );
    } else {
      return _NotificationCard(
        title: notification['title'] ?? 'Notification',
        message: notification['message'] ?? notification['message_text'] ?? '',
        time: _getTimeAgo(
          notification['received_at'] ?? notification['created_at'],
        ),
        isEmergency: isEmergency,
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see all updates and alerts here',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// Animated Toast Notification
class _NotificationToast extends StatefulWidget {
  final Map<String, dynamic> notification;
  final bool isEmergency;

  const _NotificationToast({
    required this.notification,
    required this.isEmergency,
  });

  @override
  State<_NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<_NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Auto-dismiss animation
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.notification['title'] ?? 'Notification';
    final message =
        widget.notification['message'] ??
        widget.notification['message_text'] ??
        '';

    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isEmergency
                    ? const Color(0xFFDC2626)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isEmergency
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isEmergency
                        ? const Color(0xFFDC2626).withOpacity(0.4)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.isEmergency
                          ? Colors.white.withOpacity(0.2)
                          : const Color(0xFF00D4FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isEmergency
                          ? Icons.warning_rounded
                          : Icons.notifications_active,
                      color: widget.isEmergency
                          ? Colors.white
                          : const Color(0xFF00D4FF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: widget.isEmergency
                                ? Colors.white
                                : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: widget.isEmergency
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// SOS Alert Card
class _SOSAlertCard extends StatelessWidget {
  final String officerName;
  final String? badgeNumber;
  final String emergencyType;
  final String? message;
  final String time;
  final double lat;
  final double lng;

  const _SOSAlertCard({
    required this.officerName,
    this.badgeNumber,
    required this.emergencyType,
    this.message,
    required this.time,
    required this.lat,
    required this.lng,
  });

  String _getEmergencyTitle() {
    switch (emergencyType) {
      case 'high_emergency':
        return '🚨 HIGH EMERGENCY';
      case 'text_message':
        return '⚠️ EMERGENCY MESSAGE';
      case 'audio_message':
        return '🎤 AUDIO EMERGENCY';
      default:
        return '🚨 EMERGENCY ALERT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getEmergencyTitle(),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      officerName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    if (badgeNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Badge: $badgeNumber',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  time.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.message,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Regular Notification Card
class _NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isEmergency;

  const _NotificationCard({
    required this.title,
    required this.message,
    required this.time,
    required this.isEmergency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmergency
              ? const Color(0xFFDC2626).withOpacity(0.3)
              : Colors.grey[200]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isEmergency
                ? const Color(0xFFDC2626).withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEmergency
                  ? const Color(0xFFDC2626).withOpacity(0.1)
                  : const Color(0xFF00D4FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEmergency ? Icons.warning_rounded : Icons.info_outline,
              color: isEmergency
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF00D4FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 12,
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
