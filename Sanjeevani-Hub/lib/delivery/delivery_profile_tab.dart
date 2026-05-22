import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/delivery_location_service.dart';
import '../core/config/api_config.dart';
import '../core/constants/app_colors.dart';

class DeliveryProfileTab extends StatefulWidget {
  const DeliveryProfileTab({super.key});

  @override
  State<DeliveryProfileTab> createState() => _DeliveryProfileTabState();
}

class _DeliveryProfileTabState extends State<DeliveryProfileTab> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _riderData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiderData();
  }

  Future<void> _loadRiderData() async {
    try {
      String? riderId = await _storage.read(key: 'rider_id') ?? 'default_rider';
      final response = await http.get(
        Uri.parse(ApiConfig.riderDetails(riderId)),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _riderData = json.decode(response.body);
            _isLoading = false;
          });
        }
      } else {
        _useLocalFallback();
      }
    } catch (e) {
      _useLocalFallback();
    }
  }

  Future<void> _useLocalFallback() async {
    String? name = await _storage.read(key: 'rider_name') ?? 'Sanjeevani Rider';
    String? id = await _storage.read(key: 'rider_id') ?? 'RIDER-001';
    if (mounted) {
      setState(() {
        _riderData = {'full_name': name, 'rider_id': id, 'status': 'Active'};
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final locationService = DeliveryLocationService();
    await locationService.stopTracking();
    await _storage.deleteAll();

    // In a real app, we'd navigate back to login,
    // but here we just restart the app logic or show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully (Demo Mode)')),
      );
    }
  }

  void _showOfficialDetails() {
    if (_riderData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              'Rider Profile',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildDetailItem('Full Name', _riderData!['full_name']),
            _buildDetailItem('Rider ID', _riderData!['rider_id']),
            _buildDetailItem('Status', _riderData!['status']),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.surface,
            child: Icon(Icons.person, size: 50, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            _riderData?['full_name'] ?? 'Rider',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Delivery Partner',
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          _buildMenuTile(
            icon: Icons.badge_outlined,
            title: 'Profile Details',
            onTap: _showOfficialDetails,
          ),
          _buildMenuTile(
            icon: Icons.history,
            title: 'Delivery History',
            onTap: () {},
          ),
          _buildMenuTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          _buildMenuTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => _handleLogout(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? AppColors.errorRed : AppColors.primaryBlue)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.errorRed : AppColors.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: isDestructive ? AppColors.errorRed : AppColors.textMain,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppColors.textLight,
      ),
    );
  }
}
