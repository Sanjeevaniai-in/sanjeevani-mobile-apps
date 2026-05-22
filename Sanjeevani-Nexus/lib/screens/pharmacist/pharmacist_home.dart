import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'pharmacist_profile_screen.dart';
import 'tabs/pharma_overview_tab.dart';
import 'tabs/pharma_inventory_tab.dart';
import 'tabs/pharma_billing_tab.dart';
import 'tabs/pharma_patients_tab.dart';
import 'add_medicine_screen.dart';
import 'scan_product_screen.dart';

class PharmacistHome extends StatefulWidget {
  const PharmacistHome({super.key});

  @override
  State<PharmacistHome> createState() => _PharmacistHomeState();
}

class _PharmacistHomeState extends State<PharmacistHome> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  Map<String, dynamic>? _user;

  // 4 real tabs — index 2 is the FAB placeholder (never rendered)
  final List<Widget?> _loadedTabs = List<Widget?>.filled(4, null);

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getGoogleUser();
    if (!mounted) return;
    setState(() => _user = user);
    await _authService.refreshGoogleUserFromBackend();
    final refreshed = await _authService.getGoogleUser();
    if (!mounted) return;
    setState(() => _user = refreshed ?? user);
  }

  Widget _tabAt(int index) {
    _loadedTabs[index] ??= switch (index) {
      0 => const PharmaOverviewTab(),
      1 => const PharmaInventoryTab(),
      2 => const PharmaBillingTab(),
      _ => const PharmaPatientsTab(),
    };
    return _loadedTabs[index]!;
  }

  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSheet(
        onCamera: () async {
          Navigator.pop(context);
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ScanProductScreen()),
          );
        },
        onManual: () async {
          Navigator.pop(context);
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGray,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(4, _tabAt),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _pharmacyName(),
                        style: GoogleFonts.inter(
                          color: AppTheme.darkGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Sanjeevani Nexus',
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Avatar
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PharmacistProfileScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.neonGreen, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: AppTheme.darkGreen,
                      backgroundImage: _avatarUrl().isNotEmpty
                          ? NetworkImage(_avatarUrl())
                          : null,
                      child: _avatarUrl().isEmpty
                          ? Text(
                              _avatarInitials(),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _showAddOptions,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppTheme.darkGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkGreen.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 12,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            // Left 2 tabs
            _NavBtn(
              icon: Icons.dashboard_rounded,
              label: 'Overview',
              active: _selectedIndex == 0,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            _NavBtn(
              icon: Icons.inventory_2_rounded,
              label: 'Inventory',
              active: _selectedIndex == 1,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            // Center spacer for FAB notch
            const Expanded(child: SizedBox()),
            // Right 2 tabs
            _NavBtn(
              icon: Icons.receipt_long_rounded,
              label: 'Billing',
              active: _selectedIndex == 2,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            _NavBtn(
              icon: Icons.people_rounded,
              label: 'Patients',
              active: _selectedIndex == 3,
              onTap: () => setState(() => _selectedIndex = 3),
            ),
          ],
        ),
      ),
    );
  }

  String _avatarUrl() => (_user?['picture'] ?? '').toString();

  String _avatarInitials() {
    final name = (_user?['name'] ?? 'SN').toString().trim();
    final parts =
        name.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'SN';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  String _pharmacyName() {
    final name = (_user?['pharmacy_name'] ?? '').toString().trim();
    return name.isNotEmpty ? name : 'My Pharmacy';
  }
}

// ── Nav Button ────────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppTheme.darkGreen : AppTheme.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppTheme.darkGreen : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Options Sheet ─────────────────────────────────────────────────────────

class _AddSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onManual;

  const _AddSheet({required this.onCamera, required this.onManual});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.cardBorder,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Add Product',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you want to add',
            style:
                GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 22),
          _tile(
            context,
            icon: Icons.camera_alt_rounded,
            color: AppTheme.darkGreen,
            title: 'Scan with Camera',
            subtitle: 'Auto-extract name, batch, expiry, MRP via OCR',
            onTap: onCamera,
          ),
          const SizedBox(height: 10),
          _tile(
            context,
            icon: Icons.edit_note_rounded,
            color: AppTheme.amber,
            title: 'Manual Entry',
            subtitle: 'Type all details yourself',
            onTap: onManual,
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
