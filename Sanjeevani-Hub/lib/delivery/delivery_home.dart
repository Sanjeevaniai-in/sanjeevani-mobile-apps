import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/auth_service.dart';
import '../services/delivery_location_service.dart';
import '../services/map_service.dart';
import '../services/notification_service.dart';
import 'delivery_map_tab.dart';
import 'delivery_orders_tab.dart';
import 'delivery_notifications_tab.dart';
import 'profile_page.dart';

class DeliveryHome extends StatefulWidget {
  const DeliveryHome({super.key});

  @override
  State<DeliveryHome> createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends State<DeliveryHome> {
  final DeliveryLocationService _locationService = DeliveryLocationService();
  final MapService _mapService = MapService();
  final AuthService _authService = AuthService();

  bool _locationPermissionAsked = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    const storage = FlutterSecureStorage();

    // Start storage and map connection in parallel
    final Future<String?> riderIdFuture = storage.read(key: 'rider_id');
    final Future<void> mapConnectFuture = _mapService.connect();
    final Future<Map<String, dynamic>?> userFuture = _authService.currentUser;

    final String riderId = await riderIdFuture ?? 'default_rider';
    final user = await userFuture;

    if (mounted) {
      setState(() {
        _userData = user;
      });
    }

    // Initialize services that depend on riderId or other services in parallel
    await Future.wait([
      _initNotifications(riderId),
      mapConnectFuture,
      _initializeLocationTracking(),
    ]);
  }

  Future<void> _initNotifications(String riderId) async {
    try {
      await NotificationService().initialize(riderId);
      debugPrint('✅ Notification Service initialized for rider: $riderId');
    } catch (e) {
      debugPrint('⚠️ Notification initialization failed: $e');
    }
  }

  Future<void> _initializeLocationTracking() async {
    if (!_locationPermissionAsked && mounted) {
      _locationPermissionAsked = true;
      await _requestLocationPermission();
    }
  }

  Future<void> _requestLocationPermission() async {
    bool granted = await _locationService.requestPermissions();

    if (granted) {
      await _locationService.startTracking();
    } else {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Sanjeevani needs your location to:\n\n'
          '• Track your delivery progress\n'
          '• Show your position to customers\n'
          '• Enable real-time order tracking\n\n'
          'Please grant location permission to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _mapService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. The Map (Background)
          const DeliveryMapTab(),

          // 2. Sliding Order Panel (Premium look)
          DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Handle bar
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Panel Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildProfileAvatar(),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userData?['name']?.split(' ')[0] ?? 'Partner',
                                    style: GoogleFonts.outfit(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    'Delivery Dashboard',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          _buildStatusPill(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dashboard Tabs
                    DefaultTabController(
                      length: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TabBar(
                            labelColor: const Color(0xFF0066FF),
                            unselectedLabelColor: Colors.grey[400],
                            indicatorColor: const Color(0xFF0066FF),
                            indicatorWeight: 3,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelStyle: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            tabs: const [
                              Tab(text: 'Orders'),
                              Tab(text: 'Notifications'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // ✅ Fixed: TabBarView now renders both tabs
                          SizedBox(
                            height: 480,
                            child: TabBarView(
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: const DeliveryOrdersTab(),
                                ),
                                const DeliveryNotificationsTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final String? imageUrl = _userData?['profile_image'];

    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: () {
          HapticFeedback.mediumImpact();
          _showProfileOptions();
        },
        radius: 28,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF0066FF).withOpacity(0.2),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFF3F4F6),
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 28,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: _userData?['profile_image'] != null
                    ? DecorationImage(
                        image: NetworkImage(_userData!['profile_image']),
                      )
                    : null,
                color: const Color(0xFFF3F4F6),
              ),
              child: _userData?['profile_image'] == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              _userData?['name'] ?? 'Delivery Partner',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _userData?['email'] ?? '',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: Color(0xFF0066FF), size: 20),
              ),
              title: Text('View Profile',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (c) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.redAccent, size: 20),
              ),
              title: Text('Logout',
                  style: GoogleFonts.inter(
                      color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () async {
                await _authService.logout();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/role-select', (route) => false);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Online',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}
