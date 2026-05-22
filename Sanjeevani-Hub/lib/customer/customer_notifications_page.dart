import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Customer-facing notifications page that shows real FCM notifications.
class CustomerNotificationsPage extends StatefulWidget {
  const CustomerNotificationsPage({super.key});

  /// Global list so notifications persist while the app is alive.
  static final List<_NotifItem> inbox = [];

  @override
  State<CustomerNotificationsPage> createState() => _CustomerNotificationsPageState();
}

class _CustomerNotificationsPageState extends State<CustomerNotificationsPage> {
  final List<_NotifItem> _notifications = CustomerNotificationsPage.inbox;

  @override
  void initState() {
    super.initState();
    // Listen for new foreground messages while this page is open
    FirebaseMessaging.onMessage.listen(_onMessage);
    // Mark page open — mark all as read
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAllRead());
  }

  void _onMessage(RemoteMessage msg) {
    if (!mounted) return;
    final n = msg.notification;
    if (n != null) {
      setState(() {
        CustomerNotificationsPage.inbox.insert(0, _NotifItem(
          title: n.title ?? 'Notification',
          body: n.body ?? '',
          time: _ago(DateTime.now()),
          isUnread: true,
          tag: _guessTag(n.title ?? ''),
          icon: _guessIcon(n.title ?? ''),
          gradient: _guessGradient(n.title ?? ''),
        ));
      });
    }
  }

  void _markAllRead() {
    setState(() {
      for (var n in _notifications) {
        n.isUnread = false;
      }
    });
  }

  int get _unreadCount => _notifications.where((n) => n.isUnread).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text('Notifications',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: const Color(0xFF1F2937))),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$_unreadCount',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
        ],
      ),
      body: _notifications.isEmpty ? _buildEmpty() : _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _notifications.length,
      itemBuilder: (_, i) => _buildCard(_notifications[i], i),
    );
  }

  Widget _buildCard(_NotifItem notif, int index) {
    return GestureDetector(
      onTap: () => setState(() => notif.isUnread = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: notif.isUnread ? Colors.white : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: notif.isUnread
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(notif.isUnread ? 0.06 : 0.02),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: notif.gradient),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(notif.icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: notif.gradient[0].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(notif.tag,
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: notif.gradient[0],
                                  letterSpacing: 0.5)),
                        ),
                        const Spacer(),
                        Text(notif.time,
                            style: GoogleFonts.inter(
                                color: const Color(0xFF9CA3AF), fontSize: 11)),
                        if (notif.isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Color(0xFF10B981), shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(notif.title,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: const Color(0xFF1F2937))),
                    const SizedBox(height: 3),
                    Text(notif.body,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No Notifications',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text("You'll see order updates here!",
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  String _guessTag(String title) {
    if (title.toLowerCase().contains('order')) return 'Order';
    if (title.toLowerCase().contains('deliver')) return 'Delivery';
    if (title.toLowerCase().contains('payment')) return 'Payment';
    return 'Update';
  }

  IconData _guessIcon(String title) {
    if (title.toLowerCase().contains('order')) return Icons.receipt_long_rounded;
    if (title.toLowerCase().contains('deliver')) return Icons.local_shipping_rounded;
    return Icons.notifications_rounded;
  }

  List<Color> _guessGradient(String title) {
    if (title.toLowerCase().contains('order')) {
      return [const Color(0xFF0066FF), const Color(0xFF4338CA)];
    }
    if (title.toLowerCase().contains('deliver')) {
      return [const Color(0xFF10B981), const Color(0xFF059669)];
    }
    return [const Color(0xFF8B5CF6), const Color(0xFFEC4899)];
  }
}

class _NotifItem {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String body;
  final String time;
  bool isUnread;
  final String tag;

  _NotifItem({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
    required this.tag,
  });
}

/// Call this from main.dart's onMessage handler to fill the inbox.
void addNotificationToCustomerInbox(RemoteMessage msg) {
  final n = msg.notification;
  if (n != null) {
    CustomerNotificationsPage.inbox.insert(0, _NotifItem(
      title: n.title ?? 'Notification',
      body: n.body ?? '',
      time: 'Just now',
      isUnread: true,
      tag: _guessTagGlobal(n.title ?? ''),
      icon: _guessIconGlobal(n.title ?? ''),
      gradient: _guessGradientGlobal(n.title ?? ''),
    ));
  }
}

String _guessTagGlobal(String title) {
  if (title.toLowerCase().contains('order')) return 'Order';
  if (title.toLowerCase().contains('deliver')) return 'Delivery';
  return 'Update';
}

IconData _guessIconGlobal(String title) {
  if (title.toLowerCase().contains('order')) return Icons.receipt_long_rounded;
  if (title.toLowerCase().contains('deliver')) return Icons.local_shipping_rounded;
  return Icons.notifications_rounded;
}

List<Color> _guessGradientGlobal(String title) {
  if (title.toLowerCase().contains('order')) {
    return [const Color(0xFF0066FF), const Color(0xFF4338CA)];
  }
  return [const Color(0xFF10B981), const Color(0xFF059669)];
}
