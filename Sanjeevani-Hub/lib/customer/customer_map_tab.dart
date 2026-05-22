import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../services/map_service.dart';
import '../delivery/chatbot_page.dart';
import '../delivery/shop_profile_page.dart';
import '../delivery/search_page.dart';
import '../core/services/user_service.dart';
import 'customer_orders_page.dart';
import 'customer_profile_page.dart';
import 'customer_notifications_page.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Pharmacy Tier Model is now in MapService ──────────────────────────────────

class CustomerMapTab extends StatefulWidget {
  const CustomerMapTab({super.key});

  @override
  State<CustomerMapTab> createState() => _CustomerMapTabState();
}

class _CustomerMapTabState extends State<CustomerMapTab>
    with AutomaticKeepAliveClientMixin {
  static const double _nandedLat = 19.1383;
  static const double _nandedLng = 77.3210;
  @override
  bool get wantKeepAlive => true;

  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  mapbox.PointAnnotationManager? _medicalAnnotationManager;
  mapbox.PointAnnotationManager? _userAnnotationManager;
  final MapService _mapService = MapService();
  bool _mapInitialized = false;
  Timer? _styleCheckTimer;

  final GlobalKey _mapKey = GlobalKey();

  Position? _currentPosition;
  Uint8List? _pharmacyIconData;
  Uint8List? _hospitalIconData;
  Uint8List? _userIconData;

  Timer? _locationUpdateTimer;
  bool _isTrackingLocation = false;

  // Real user data from auth
  User? _currentUser;
  StreamSubscription<User?>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _startLocationTracking();
    _initUser();
  }

  void _initUser() {
    final svc = UserService();
    // Get initial
    svc.currentUser.then((u) {
      if (mounted) setState(() => _currentUser = u);
    });
    // Listen for updates
    _userSubscription = svc.userStream.listen((u) {
      if (mounted) setState(() => _currentUser = u);
    });
  }

  Future<void> _loadIcons() async {
    _pharmacyIconData = await _getAssetImage(
      'assets/icons/pharmacy_3d.png',
      120,
    );
    _hospitalIconData = await _getAssetImage(
      'assets/icons/hospital_3d.png',
      120,
    );
    _userIconData = await _generateUserMarker();
  }

  void _startLocationTracking() {
    // Request permission first, then start periodic updates
    _requestAndStartTracking();
  }

  Future<void> _requestAndStartTracking() async {
    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions permanently denied.');
      return;
    }

    // Try to get initial position immediately
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() => _currentPosition = pos);
        if (_mapInitialized) {
          await _addPharmacyMarkers();
        }
      }
    } catch (e) {
      debugPrint('Initial location: $e');
    }

    // Then poll every 10 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        setState(() => _currentPosition = pos);
        if (_mapInitialized) {
          _updateUserLocationAnnotation();
          if (_nearbyPharmacies.isEmpty) {
            await _addPharmacyMarkers();
          }
        }
      } catch (e) {
        debugPrint('Location error: $e');
      }
    });
  }

  Future<void> _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // 🕵️ HIDE ALL ORNAMENTS IMMEDIATELY (Logo, Compass, ScaleBar, Attribution)
    _mapboxMap!.compass.updateSettings(mapbox.CompassSettings(enabled: false));
    _mapboxMap!.logo.updateSettings(mapbox.LogoSettings(enabled: false));
    _mapboxMap!.attribution.updateSettings(
      mapbox.AttributionSettings(enabled: false),
    );
    _mapboxMap!.scaleBar.updateSettings(
      mapbox.ScaleBarSettings(enabled: false),
    );

    // Poll until style is loaded to ensure 3D features and markers work
    _styleCheckTimer?.cancel();
    _styleCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (!mounted || _mapboxMap == null) {
        timer.cancel();
        return;
      }
      final bool loaded = await _mapboxMap!.style.isStyleLoaded();
      if (loaded || timer.tick > 20) {
        timer.cancel();
        _initializeMapComponents();
      }
    });
  }

  Future<void> _initializeMapComponents() async {
    if (_mapInitialized || _mapboxMap == null) return;
    _mapInitialized = true;

    _pointAnnotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();
    _medicalAnnotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();
    _userAnnotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();

    _pointAnnotationManager?.addOnPointAnnotationClickListener(
      _OnPharmacyClickListener(
        context: context,
        shopsProvider: () => _nearbyPharmacies,
      ),
    );

    await _addPharmacyMarkers();
    _enable3DFeatures();

    // 📍 IMMEDIATE INITIAL LOCATION CENTERING
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = pos;
      _centerOnCurrentLocation();
    } catch (e) {
      debugPrint('Initial location fetch failed: $e');
    }

    await _updateUserLocationAnnotation();
  }

  void _enable3DFeatures() async {
    if (_mapboxMap == null) return;
    try {
      // 🏗️ FORCE ACTUAL 3D BUILDINGS (Fill-Extrusion)
      final buildingLayer = mapbox.FillExtrusionLayer(
        id: '3d-buildings-extrusion',
        sourceId: 'composite',
      );
      buildingLayer.sourceLayer = 'building';
      buildingLayer.minZoom = 13.0; // Show blocks earlier
      buildingLayer.filter = [
        '==',
        ['get', 'extrude'],
        'true',
      ];

      buildingLayer.fillExtrusionColor = const Color(0xFFFFFFFF).toARGB32();
      buildingLayer.fillExtrusionOpacity = 0.85;
      buildingLayer.fillExtrusionAmbientOcclusionIntensity = 0.3;

      await _mapboxMap!.style.addLayer(buildingLayer);

      // Use expressions to pull height from Mapbox vector data
      await _mapboxMap!.style.setStyleLayerProperty(
        '3d-buildings-extrusion',
        'fill-extrusion-height',
        ['get', 'height'],
      );
      await _mapboxMap!.style.setStyleLayerProperty(
        '3d-buildings-extrusion',
        'fill-extrusion-base',
        ['get', 'min_height'],
      );

      // ⛰️ ADD 3D TERRAIN (Elevation)
      try {
        await _mapboxMap!.style.addSource(
          mapbox.RasterDemSource(
            id: 'mapbox-dem',
            url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
            tileSize: 512,
          ),
        );
        await _mapboxMap!.style.setStyleTerrainProperty('source', 'mapbox-dem');
        await _mapboxMap!.style.setStyleTerrainProperty('exaggeration', 1.5);
      } catch (e) {
        debugPrint('Terrain error: $e');
      }

      // Set high pitch and zoom for 3D effect
      await _mapboxMap!.setCamera(
        mapbox.CameraOptions(pitch: 65.0, zoom: 16.2, bearing: -17.6),
      );
    } catch (e) {
      debugPrint('Map 3D setting error: $e');
    }
  }

  void _centerOnCurrentLocation() async {
    if (_mapboxMap == null) return;

    // ⚡ FAST LOCATION FETCH: Use cached _currentPosition first
    Position? pos = _currentPosition;

    if (pos == null) {
      try {
        pos = await Geolocator.getLastKnownPosition();
        pos ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 3),
        );
      } catch (e) {
        debugPrint('Fast location failed: $e');
      }
    }

    if (pos != null) {
      _currentPosition = pos;
      _mapboxMap!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(pos.longitude, pos.latitude),
          ),
          zoom: 16.5,
          pitch: 62.0,
        ),
        mapbox.MapAnimationOptions(duration: 1000),
      );
    } else {
      _mapboxMap!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(_nandedLng, _nandedLat),
          ),
          zoom: 14.8,
          pitch: 55.0,
        ),
        mapbox.MapAnimationOptions(duration: 900),
      );
    }
  }

  List<Pharmacy> _nearbyPharmacies = [];

  Future<void> _addPharmacyMarkers() async {
    if (_pointAnnotationManager == null) return;

    final targetLat = _currentPosition?.latitude ?? _nandedLat;
    final targetLng = _currentPosition?.longitude ?? _nandedLng;
    final shops = await _mapService.fetchNearbyPharmacies(targetLat, targetLng);
    if (mounted) setState(() => _nearbyPharmacies = shops);

    if (_nearbyPharmacies.isEmpty) return;

    // Wait for icon data if not yet loaded
    if (_pharmacyIconData == null) {
      await _loadIcons();
    }
    if (_pharmacyIconData == null) return;

    await _pointAnnotationManager!.deleteAll();

    for (final shop in _nearbyPharmacies) {
      try {
        await _pointAnnotationManager!.create(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(
              coordinates: mapbox.Position(shop.lng, shop.lat),
            ),
            image: _pharmacyIconData,
            textField: shop.name,
            textColor: Colors.blueAccent.toARGB32(),
            textSize: 12.0,
            textHaloColor: Colors.white.toARGB32(),
            textHaloWidth: 2.0,
            textOffset: [0, 2.5],
            textAnchor: mapbox.TextAnchor.TOP,
          ),
        );
      } catch (e) {
        debugPrint('Marker error for ${shop.name}: $e');
      }
    }
  }

  Future<void> _updateUserLocationAnnotation() async {
    if (_userAnnotationManager == null ||
        _currentPosition == null ||
        _userIconData == null)
      return;

    try {
      await _userAnnotationManager!.deleteAll();
      await _userAnnotationManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(
              _currentPosition!.longitude,
              _currentPosition!.latitude,
            ),
          ),
          image: _userIconData,
          iconSize: 0.25, // Bigger beacon like Google Maps
        ),
      );
    } catch (e) {
      debugPrint('Failed to update user location: $e');
    }
  }

  void _zoomToNearbyShops() {
    if (_mapboxMap == null || _nearbyPharmacies.isEmpty) return;

    // Calculate dynamic center
    double sumLat = 0;
    double sumLng = 0;
    for (var s in _nearbyPharmacies) {
      sumLat += s.lat;
      sumLng += s.lng;
    }
    final double centerLat = sumLat / _nearbyPharmacies.length;
    final double centerLng = sumLng / _nearbyPharmacies.length;

    _mapboxMap!.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(centerLng, centerLat),
        ),
        zoom: 14.5,
        pitch: 45.0,
        bearing: 0.0,
      ),
      mapbox.MapAnimationOptions(duration: 1200),
    );
    HapticFeedback.heavyImpact();
  }

  Future<Uint8List> _getAssetImage(String path, int width) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<Uint8List> _generateUserMarker() async {
    const double sz = 120.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, sz, sz));

    // Outer shadow/glow
    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0xFF0066FF).withOpacity(0.25)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);
    canvas.drawCircle(
      const ui.Offset(sz / 2, sz / 2),
      sz / 2 - 10,
      shadowPaint,
    );

    // White border
    final borderPaint = ui.Paint()
      ..color = ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(
      const ui.Offset(sz / 2, sz / 2),
      sz / 2 - 15,
      borderPaint,
    );

    // Core Blue Beacon
    final corePaint = ui.Paint()
      ..color = const ui.Color(0xFF0066FF)
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(const ui.Offset(sz / 2, sz / 2), sz / 2 - 25, corePaint);

    // Inner highlight
    final highlightPaint = ui.Paint()
      ..color = ui.Color(0xFFFFFFFF).withOpacity(0.4)
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(
      const ui.Offset(sz / 2 - 10, sz / 2 - 10),
      10,
      highlightPaint,
    );

    final img = await recorder.endRecording().toImage(sz.toInt(), sz.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _styleCheckTimer?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        RepaintBoundary(
          child: mapbox.MapWidget(
            key: _mapKey,
            onMapCreated: _onMapCreated,
            textureView: true,
            styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
            cameraOptions: mapbox.CameraOptions(
              center: mapbox.Point(
                coordinates: mapbox.Position(77.3210, 19.1383),
              ), // Start in Nanded
              zoom: 15.0,
              pitch: 62.0,
            ),
          ),
        ),

        // TOP OVERLAY (Premium Navigation)
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: RepaintBoundary(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Search Button
                _buildCircularButton(
                  Icons.search_rounded,
                  Colors.white,
                  const Color(0xFF374151),
                  onTap: () => Navigator.of(
                    context,
                  ).push(_fastRoute(const SearchPage())),
                ),

                const Spacer(),

                // Notification Button with Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildCircularButton(
                      Icons.notifications_rounded,
                      Colors.white,
                      const Color(0xFF374151),
                      onTap: () => Navigator.of(
                        context,
                      ).push(_fastRoute(const CustomerNotificationsPage())),
                    ),
                    Builder(
                      builder: (context) {
                        final unread = CustomerNotificationsPage.inbox
                            .where((n) => n.isUnread)
                            .length;
                        if (unread == 0) return const SizedBox.shrink();
                        return Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Profile Avatar — shows real Google photo
                GestureDetector(
                  onTap: () => Navigator.of(
                    context,
                  ).push(_fastRoute(const CustomerProfilePage())),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF374151),
                    backgroundImage: _currentUser?.photoUrl != null
                        ? NetworkImage(_currentUser!.photoUrl!)
                        : null,
                    child: _currentUser?.photoUrl == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),

        // BOTTOM OVERLAY (Status Pill & Action Group)
        Positioned(
          bottom: 30,
          left: 16,
          right: 16,
          child: RepaintBoundary(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nearby Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(
                          context,
                        ).push(_fastRoute(const CustomerOrdersPage()));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Orders',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ACTION BUTTONS GROUP
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🏥 Find Shops Button (Quick 3D View)
                    Material(
                      color: const Color(0xFF10B981),
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: const Color(0xFF10B981).withOpacity(0.3),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _zoomToNearbyShops();
                        },
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: const Color(0xFF0066FF).withOpacity(0.2),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(
                            context,
                          ).push(_fastRoute(const ChatbotPage()));
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            'assets/icons/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Live Location Control
                    _buildCircularButton(
                      Icons.my_location_rounded,
                      Colors.white,
                      const Color(0xFF0066FF),
                      size: 54,
                      onTap: _centerOnCurrentLocation,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularButton(
    IconData icon,
    Color bgColor,
    Color iconColor, {
    double size = 44,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.46),
      ),
    );
  }

  static Route<T> _fastRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

// ─── Animated Profile Avatar ──────────────────────────────────────────────────
class _AnimatedProfileAvatar extends StatelessWidget {
  const _AnimatedProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF00C2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

class _OnPharmacyClickListener extends mapbox.OnPointAnnotationClickListener {
  final BuildContext context;
  final List<Pharmacy> Function() shopsProvider;

  _OnPharmacyClickListener({
    required this.context,
    required this.shopsProvider,
  });

  @override
  bool onPointAnnotationClick(mapbox.PointAnnotation annotation) {
    final shops = shopsProvider();
    final shopName = annotation.textField ?? "";
    final shop = shops.firstWhere(
      (s) => s.name == shopName,
      orElse: () => shops.isNotEmpty ? shops.first : Pharmacy(
        id: 'tmp', name: shopName, lat: 0, lng: 0, tier: PharmacyTier.base
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Official Sanjeevani Partner',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'ORDER OPTIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                if (shop.tier == PharmacyTier.ultraPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: const Text(
                      'ULTRA PRO',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // MAIN ACTION: AI CHAT (Always Available)
            _buildTieredButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => ChatbotPage(initialPharmacy: shop),
                  ),
                );
              },
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat with Sanjeevani AI',
              color: const Color(0xFF0066FF),
              isPrimary: true,
            ),
            
            // TIERED ACTIONS: Pro and Ultra Pro
            if (shop.tier == PharmacyTier.pro || shop.tier == PharmacyTier.ultraPro) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                   // WhatsApp
                  Expanded(
                    child: _buildTieredButton(
                      onPressed: () => _launchURL('https://wa.me/${shop.whatsapp}'),
                      icon: Icons.message_rounded,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Telegram
                  Expanded(
                    child: _buildTieredButton(
                      onPressed: () => _launchURL('https://t.me/${shop.telegram}'),
                      icon: Icons.send_rounded,
                      label: 'Telegram',
                      color: const Color(0xFF0088CC),
                    ),
                  ),
                ],
              ),
            ],

            // ULTRA PRO EXCLUSIVE: Call
            if (shop.tier == PharmacyTier.ultraPro) ...[
              const SizedBox(height: 12),
              _buildTieredButton(
                onPressed: () => _launchURL('tel:${shop.phone}'),
                icon: Icons.phone_forwarded_rounded,
                label: 'Direct Call to Pharmacy',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Exclusive Ultra Pro Partner: Guaranteed 20-min processing',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            // PHARMACY PROFILE
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => ShopProfilePage(shopName: shop.name),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'View Pharmacy Profile & Reviews',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
    return true;
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  Widget _buildTieredButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: color.withOpacity(0.3),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }
}
