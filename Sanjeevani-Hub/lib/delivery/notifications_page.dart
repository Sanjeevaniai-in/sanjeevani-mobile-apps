import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<_NotifItem> _notifications = [
    _NotifItem(
      icon: Icons.local_shipping_outlined,
      gradient: [const Color(0xFF0066FF), const Color(0xFF4338CA)],
      title: 'Order #ORD-2841 Assigned',
      body: 'New delivery order from MedPlus Pharmacy to Kalyani Nagar.',
      time: '2 min ago',
      isUnread: true,
      tag: 'Order',
    ),
    _NotifItem(
      icon: Icons.location_on_outlined,
      gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
      title: 'Customer Reached',
      body: 'The customer for Order #ORD-2836 is ready to receive delivery.',
      time: '14 min ago',
      isUnread: true,
      tag: 'Location',
    ),
    _NotifItem(
      icon: Icons.account_balance_wallet_outlined,
      gradient: [const Color(0xFFFF8A00), const Color(0xFFEF4444)],
      title: 'Earnings Credited',
      body: '₹340 has been credited to your wallet for today\'s deliveries.',
      time: '1 hr ago',
      isUnread: true,
      tag: 'Payment',
    ),
    _NotifItem(
      icon: Icons.star_rate_outlined,
      gradient: [const Color(0xFFFBBF24), const Color(0xFFFF8A00)],
      title: 'New Rating Received',
      body: 'You received a 5-star rating! Great job on the last delivery.',
      time: '2 hrs ago',
      isUnread: false,
      tag: 'Review',
    ),
    _NotifItem(
      icon: Icons.warning_amber_outlined,
      gradient: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      title: 'Order Cancelled',
      body: 'Order #ORD-2830 was cancelled by the pharmacy. No action needed.',
      time: 'Yesterday',
      isUnread: false,
      tag: 'Alert',
    ),
    _NotifItem(
      icon: Icons.local_offer_outlined,
      gradient: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      title: 'Bonus Earned!',
      body: 'You completed 10 deliveries today. ₹200 bonus added to your account.',
      time: 'Yesterday',
      isUnread: false,
      tag: 'Reward',
    ),
    _NotifItem(
      icon: Icons.update_outlined,
      gradient: [const Color(0xFF0EA5E9), const Color(0xFF0066FF)],
      title: 'App Update Available',
      body: 'Sanjeevani v2.1 is available with new route optimization features.',
      time: '2 days ago',
      isUnread: false,
      tag: 'System',
    ),
  ];

  int get _unreadCount => _notifications.where((n) => n.isUnread).length;

  void _markAllRead() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var n in _notifications) {
        n.isUnread = false;
      }
    });
  }

  void _markRead(int index) {
    setState(() => _notifications[index].isUnread = false);
  }

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
            Text(
              'Notifications',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: const Color(0xFF1F2937),
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0066FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF3F4F8)),
        ),
      ),
      body: _notifications.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _notifications.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) return _buildSectionHeader('Recent', _unreadCount);

                final notif = _notifications[i - 1];
                return _buildNotifCard(notif, i - 1);
              },
            ),
    );
  }

  Widget _buildSectionHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(_NotifItem notif, int index) {
    return GestureDetector(
      onTap: () => _markRead(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: notif.isUnread ? Colors.white : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isUnread
                ? const Color(0xFF0066FF).withOpacity(0.2)
                : Colors.transparent,
          ),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: notif.gradient[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notif.tag,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: notif.gradient[0],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notif.time,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                        if (notif.isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0066FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
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
          Icon(Icons.notifications_off_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
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
