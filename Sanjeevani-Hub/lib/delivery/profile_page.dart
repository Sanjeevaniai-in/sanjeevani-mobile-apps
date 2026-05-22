import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/auth_service.dart';
import '../core/services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _riderData = {
    'full_name': '...',
    'rider_id': '—',
    'status': 'Active',
    'email': '',
  };
  String? _photoUrl;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final svc = UserService();
    final name = await svc.name;
    final email = await svc.email;
    final photo = await svc.photoUrl;
    final id = await svc.userId;
    if (mounted) {
      setState(() {
        _riderData = {
          'full_name': name,
          'rider_id': id ?? 'RIDER-001',
          'status': 'Active',
          'email': email,
        };
        _photoUrl = photo;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }


  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/role-select', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(context),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 28),
                  _buildSection('Account Overview', [
                    _buildTile(
                      icon: Icons.badge_rounded,
                      iconColor: const Color(0xFF0066FF),
                      title: 'Delivery Details',
                      subtitle: 'View your partner credentials',
                      onTap: () => _showProfileDetails(context),
                    ),
                    _buildTile(
                      icon: Icons.history_edu_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Delivery Logs',
                      subtitle: 'View your completed task history',
                      onTap: () {},
                    ),
                    _buildTile(
                      icon: Icons.account_balance_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Payout Summary',
                      subtitle: 'Manage your earnings and wallet',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('System Settings', [
                    _buildTile(
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Work Alerts',
                      subtitle: 'Manage push notifications',
                      onTap: () {},
                    ),
                    _buildTile(
                      icon: Icons.gpp_good_rounded,
                      iconColor: const Color(0xFF06B6D4),
                      title: 'Safety & Trust',
                      subtitle: 'Your data and compliance',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Support', [
                    _buildTile(
                      icon: Icons.help_center_rounded,
                      iconColor: const Color(0xFF64748B),
                      title: 'Help Center',
                      subtitle: 'Contact support team',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Material(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _handleLogout(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.logout_rounded,
                                    color: Color(0xFFEF4444), size: 18),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Exit Application',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Color(0xFF94A3B8), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1F2937), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          child: Stack(
            children: [
              Positioned(
                top: -80,
                left: -40,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0066FF).withOpacity(0.04),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0066FF).withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 54,
                              backgroundColor: const Color(0xFFF3F4F6),
                              backgroundImage: _photoUrl != null
                                  ? NetworkImage(_photoUrl!)
                                  : null,
                              child: _photoUrl == null
                                  ? const Icon(Icons.delivery_dining_rounded,
                                      size: 52, color: Color(0xFF374151))
                                  : null,
                            ),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _riderData['full_name'] ?? 'Delivery Partner',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF111827),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF0066FF).withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          'Sanjeevani Partner  ·  ${_riderData['status'] ?? 'Active'}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0066FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(height: 1, color: const Color(0xFFF1F5F9)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStatItem('42', 'Trips', Icons.local_shipping_rounded),
            _verticalDivider(),
            _buildStatItem('4.9', 'Rating', Icons.star_rounded),
            _verticalDivider(),
            _buildStatItem('₹12.4K', 'Wallet', Icons.account_balance_wallet_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0066FF), size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF1F2937),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 50, color: const Color(0xFFF3F4F8));
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: tiles),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFD1D5DB), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Profile Details',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _detailItem(Icons.person_outline, 'Full Name',
                _riderData['full_name'] ?? '—'),
            _detailItem(Icons.badge_outlined, 'Rider ID',
                _riderData['rider_id'] ?? '—'),
            _detailItem(Icons.phone_outlined, 'Phone',
                _riderData['phone'] ?? '+91 98765 43210'),
            _detailItem(Icons.email_outlined, 'Email',
                _riderData['email'] ?? 'rider@sanjeevani.app'),
            _detailItem(Icons.two_wheeler_outlined, 'Vehicle',
                _riderData['vehicle'] ?? 'Honda Activa'),
            _detailItem(Icons.calendar_today_outlined, 'Member Since',
                _riderData['since'] ?? 'March 2024'),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: const Color(0xFF0066FF),
                  ),
                  child: Text('Close',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0066FF)),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
