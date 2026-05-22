import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../services/map_service.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'search_page.dart';
import 'shop_profile_page.dart';

// ── Pharmacy Tier Model ────────────────────────────────────────────────────────
enum PharmacyTier { base, pro, ultraPro }

class _ShopInfo {
  final String name;
  final PharmacyTier tier;
  final String? whatsappNumber; // for pro+
  final String? telegramUsername; // for pro+
  final String? phoneNumber; // for ultraPro only

  const _ShopInfo({
    required this.name,
    required this.tier,
    this.whatsappNumber,
    this.telegramUsername,
    this.phoneNumber,
  });
}

// Demo shops — one per tier
const List<_ShopInfo> _demoShops = [
  _ShopInfo(
    name: 'Sanjeevani Central',
    tier: PharmacyTier.base,
  ),
  _ShopInfo(
    name: 'MedPlus Pharmacy',
    tier: PharmacyTier.pro,
    whatsappNumber: '919876543210',
    telegramUsername: 'medplusPune',
  ),
  _ShopInfo(
    name: 'Apollo HealthHub',
    tier: PharmacyTier.ultraPro,
    whatsappNumber: '919123456789',
    telegramUsername: 'apolloPune',
    phoneNumber: '+919123456789',
  ),
];

class DeliveryMapTab extends StatefulWidget {
  const DeliveryMapTab({super.key});

  @override
  State<DeliveryMapTab> createState() => _DeliveryMapTabState();
}

class _DeliveryMapTabState extends State<DeliveryMapTab>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true; // ← keeps map alive across navigation

  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  mapbox.PointAnnotationManager? _medicalAnnotationManager;
  final MapService _mapService = MapService();
  final _storage = const FlutterSecureStorage();
  bool _mapInitialized = false; // guard against double platform view creation
  Timer? _styleCheckTimer;    // kept so we can cancel on dispose

  // Stable GlobalKey prevents Flutter re-creating the native view on rebuild
  final GlobalKey _mapKey = GlobalKey();

  Position? _currentPosition;
  String? _currentRiderId;
  Map<String, RiderLocation> _riders = {};
  final List<(String, bool, double, double)> _addedShops = [];
  Uint8List? _pharmacyIconData;
  Uint8List? _hospitalIconData;

  StreamSubscription? _ridersSubscription;
  Timer? _locationUpdateTimer;
  bool _isTrackingLocation = false;
  bool _isUpdatingRiders = false;
  Uint8List? _riderIconData;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    _initializeServices();
    _startLiveLocationTracking();
  }

  Future<void> _loadMarkerIcons() async {
    try {
      final pData = await rootBundle.load('assets/icons/pharmacy_3d.png');
      final hData = await rootBundle.load('assets/icons/hospital_3d.png');
      final rData = await rootBundle.load(
        'assets/icons/logo.png',
      ); // using logo for riders as demo
      setState(() {
        _pharmacyIconData = pData.buffer.asUint8List();
        _hospitalIconData = hData.buffer.asUint8List();
        _riderIconData = rData.buffer.asUint8List();
      });
    } catch (e) {
      debugPrint('Error loading 3D icons: $e');
    }
  }

  Future<void> _initializeServices() async {
    _currentRiderId = await _storage.read(key: 'rider_id') ?? 'default_rider';
    await _mapService.connect();

    _ridersSubscription = _mapService.ridersStream.listen((riders) {
      if (mounted) {
        _riders = riders;
        _throttledMarkerUpdate();
      }
    });
  }

  // Throttled marker update to avoid UI lag
  Timer? _markerThrottleTimer;
  void _throttledMarkerUpdate() {
    if (_markerThrottleTimer?.isActive ?? false) return;
    _markerThrottleTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
           _updateMarkers();
        });
      }
    });
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) {
    // Guard: if already initialized (e.g. hot-reload), do nothing
    if (_mapInitialized) return;
    _mapboxMap = mapboxMap;

    // Disable ornaments
    _mapboxMap!.compass.updateSettings(mapbox.CompassSettings(enabled: false));
    _mapboxMap!.logo.updateSettings(mapbox.LogoSettings(enabled: false));
    _mapboxMap!.attribution.updateSettings(
      mapbox.AttributionSettings(enabled: false),
    );
    _mapboxMap!.scaleBar.updateSettings(
      mapbox.ScaleBarSettings(enabled: false),
    );

    // Cancel any previously running style-check timer
    _styleCheckTimer?.cancel();

    // Poll until style is loaded, then init features exactly once
    _styleCheckTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) async {
        if (!mounted || _mapboxMap == null) {
          timer.cancel();
          return;
        }
        if (_mapInitialized) {
          timer.cancel();
          return;
        }
        final bool loaded = await _mapboxMap!.style.isStyleLoaded();
        if (loaded || timer.tick > 20) {
          timer.cancel();
          _initializeMapFeatures();
        }
      },
    );
  }

  void _initializeMapFeatures() async {
    // Atomic guard — only ever run once per map instance
    if (_mapInitialized || _mapboxMap == null) return;
    _mapInitialized = true;

    _pointAnnotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();
    _medicalAnnotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();

    _medicalAnnotationManager!.addOnPointAnnotationClickListener(
      _MedicalClickListener((annotation) {
        _handleMedicalClick(annotation);
      }),
    );

    if (_hospitalIconData != null) {
      // Note: Staying with image property in PointAnnotation for now as it handles fallbacks better
    }
    if (_riderIconData != null) {
      // Pre-fetching done, using image buffers for stability
    }

    _enable3DFeatures();
    _updateMarkers();
    _addMedicalMarkers();
    debugPrint('Map Features Initialized');
  }

  // ── URL helpers (fallback: copies link + opens via Android intent) ──────
  Future<void> _launchUrl(String url) async {
    try {
      // Try Android platform channel intent first
      const platform = MethodChannel('android/intent');
      await platform.invokeMethod('openUrl', {'url': url});
    } catch (_) {
      // Fallback: copy to clipboard and notify user
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link copied! Open it in your app: $url'),
            backgroundColor: const Color(0xFF1F2937),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _openWhatsApp(String number, String shopName) {
    _launchUrl(
      'https://wa.me/$number?text=${Uri.encodeComponent("Hi $shopName, I want to order medicines via Sanjeevani 🌿")}',
    );
  }

  void _openTelegram(String username) {
    _launchUrl('https://t.me/$username');
  }

  void _openCall(String phone) {
    _launchUrl('tel:$phone');
  }

  // ── Bottom Sheet ─────────────────────────────────────────────────────────
  void _handleMedicalClick(mapbox.PointAnnotation annotation) {
    HapticFeedback.mediumImpact();
    final name = annotation.textField ?? 'Medical Shop';

    // Find shop info for this marker
    final shop = _demoShops.firstWhere(
      (s) => s.name == name,
      orElse: () => _ShopInfo(name: name, tier: PharmacyTier.base),
    );

    // Tier badge details
    final tierLabel = switch (shop.tier) {
      PharmacyTier.base     => ('Base', const Color(0xFF6B7280), const Color(0xFFF3F4F6)),
      PharmacyTier.pro      => ('Pro', const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
      PharmacyTier.ultraPro => ('Ultra Pro ⚡', const Color(0xFFD97706), const Color(0xFFFFF7ED)),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).padding.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Shop header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_pharmacy_rounded,
                      color: Color(0xFF10B981), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF10B981), size: 13),
                          const SizedBox(width: 4),
                          const Text(
                            'Sanjeevani Partner  ·  ',
                            style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                          // Tier badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: tierLabel.$3,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tierLabel.$1,
                              style: TextStyle(
                                color: tierLabel.$2,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 16),

            // ── Order Channels Section ─────────────────────────────────
            const Text(
              'ORDER VIA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Order via Sanjeevani (Removed Chatbot, using Dashboard)
            _channelBtn(
              ctx: ctx,
              icon: 'assets/icons/logo.png',
              label: 'Go to Dashboard',
              sublabel: 'Manage orders and deliveries',
              color: const Color(0xFF1F2937),
              onTap: () {
                Navigator.pop(ctx);
                // The dashboard is already open as the bottom sheet in DeliveryHome
              },
            ),

            // WhatsApp (Pro & Ultra)
            if (shop.tier == PharmacyTier.pro ||
                shop.tier == PharmacyTier.ultraPro) ...
              [
                const SizedBox(height: 10),
                _channelBtnIcon(
                  ctx: ctx,
                  iconWidget: const Icon(Icons.chat_rounded,
                      color: Color(0xFF25D366), size: 20),
                  label: 'WhatsApp',
                  sublabel: 'Chat directly with the pharmacy',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openWhatsApp(shop.whatsappNumber!, shop.name);
                  },
                ),
                const SizedBox(height: 10),
                _channelBtnIcon(
                  ctx: ctx,
                  iconWidget: const Icon(Icons.send_rounded,
                      color: Color(0xFF0088CC), size: 20),
                  label: 'Telegram',
                  sublabel: 'Message on Telegram bot',
                  color: const Color(0xFF0088CC),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openTelegram(shop.telegramUsername!);
                  },
                ),
              ],

            // Call (Ultra only)
            if (shop.tier == PharmacyTier.ultraPro) ...
              [
                const SizedBox(height: 10),
                _channelBtnIcon(
                  ctx: ctx,
                  iconWidget: const Icon(Icons.call_rounded,
                      color: Color(0xFFEF4444), size: 20),
                  label: 'Call Now',
                  sublabel: 'Speak directly with pharmacist',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openCall(shop.phoneNumber!);
                  },
                ),
              ],

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),

            // View Profile button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                      _fastRoute(ShopProfilePage(shopName: shop.name)));
                },
                icon: const Icon(Icons.person_pin_rounded, size: 18),
                label: const Text('View Profile',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Channel Button Builders ───────────────────────────────────────────────
  Widget _channelBtn({
    required BuildContext ctx,
    required String icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(icon, width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(sublabel,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white60, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _channelBtnIcon({
    required BuildContext ctx,
    required Widget iconWidget,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(sublabel,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.4), size: 14),
          ],
        ),
      ),
    );
  }



  void _addMedicalMarkers() async {
    if (_medicalAnnotationManager == null || _mapboxMap == null) return;
    try {
      final camera = await _mapboxMap!.getCameraState();
      final lng = camera.center.coordinates.lng.toDouble();
      final lat = camera.center.coordinates.lat.toDouble();

      final hasP = _pharmacyIconData != null;
      final hasH = _hospitalIconData != null;
      final pSize = hasP ? 0.08 : 0.9;
      final hSize = hasH ? 0.08 : 0.9;

      final pIcon = _pharmacyIconData ?? await _makeMarkerIcon(const Color(0xFF10B981));
      final hIcon = _hospitalIconData ?? await _makeMarkerIcon(const Color(0xFFEF4444));

      await _medicalAnnotationManager!.deleteAll();
      List<mapbox.PointAnnotationOptions> allMedical = [];

      final demoData = [
        (_demoShops[0].name, true,  -0.005,  0.005),
        (_demoShops[1].name, true,   0.010, -0.010),
        (_demoShops[2].name, false, -0.012,  0.012),
      ];

      for (final (name, isPharmacy, dlng, dlat) in demoData) {
        allMedical.add(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(
              coordinates: mapbox.Position(lng + dlng, lat + dlat),
            ),
            image: isPharmacy ? pIcon : hIcon,
            iconSize: isPharmacy ? pSize : hSize,
            textField: name,
            textSize: 10,
            textOffset: [0, 2.2],
            textColor: const Color(0xFF1F2937).value,
            textHaloColor: Colors.white.value,
            textHaloWidth: 1.5,
          ),
        );
      }

      await _medicalAnnotationManager!.createMulti(allMedical);
      debugPrint('Demo markers added: ${allMedical.length}');
    } catch (e) {
      debugPrint('Medical marker error: $e');
    }
  }

  /// Renders a colored circle with a white + symbol into PNG bytes for use as
  /// a map annotation icon.
  Future<Uint8List> _makeMarkerIcon(Color color) async {
    const sz = 40.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Drop shadow
    canvas.drawCircle(
      const Offset(sz / 2, sz / 2 + 1.5),
      sz / 2 - 5,
      Paint()..color = Colors.black.withOpacity(0.2),
    );
    // Filled circle
    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      sz / 2 - 5,
      Paint()..color = color,
    );
    // White border
    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      sz / 2 - 5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // White plus symbol
    final p = Paint()..color = Colors.white;
    const barL = 12.0, barW = 3.5;
    const cx = sz / 2, cy = sz / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(cx - barL / 2, cy - barW / 2, barL, barW),
        const Radius.circular(2),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(cx - barW / 2, cy - barL / 2, barW, barL),
        const Radius.circular(2),
      ),
      p,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(sz.toInt(), sz.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
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

  void _updateMarkers() async {
    if (_pointAnnotationManager == null || _isUpdatingRiders || _mapboxMap == null) return;
    _isUpdatingRiders = true;

    try {
      await _pointAnnotationManager!.deleteAll();

      List<mapbox.PointAnnotationOptions> annotations = [];

      // Add current rider marker
      if (_currentPosition != null) {
        annotations.add(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(
              coordinates: mapbox.Position(
                _currentPosition!.longitude,
                _currentPosition!.latitude,
              ),
            ),
            image: _riderIconData, // Use image buffer directly for best perf
            iconSize: 0.08,
          ),
        );
      }

      // Add other riders
      for (var rider in _riders.values) {
        if (rider.riderId != _currentRiderId) {
          annotations.add(
            mapbox.PointAnnotationOptions(
              geometry: mapbox.Point(
                coordinates: mapbox.Position(rider.lng, rider.lat),
              ),
              image: _riderIconData,
              iconSize: 0.06,
            ),
          );
        }
      }

      if (annotations.isNotEmpty) {
        await _pointAnnotationManager!.createMulti(annotations);
      }
    } catch (e) {
      debugPrint('Rider update error: $e');
    } finally {
      _isUpdatingRiders = false;
    }
  }

  void _startLiveLocationTracking() {
    // ... rest of _startLiveLocationTracking ...
    if (_isTrackingLocation) return;
    _isTrackingLocation = true;
    _updateLiveLocation();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _isTrackingLocation) {
        _updateLiveLocation();
      }
    });
  }

  Future<void> _updateLiveLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _updateMarkers();
        });
      }
    } catch (e) {
      print('Live location update failed: $e');
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null && _mapboxMap != null) {
      _mapboxMap!.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              _currentPosition!.longitude,
              _currentPosition!.latitude,
            ),
          ),
          zoom: 15.0,
          pitch: 45.0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _styleCheckTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _ridersSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return Stack(
      children: [
        mapbox.MapWidget(
          key: _mapKey, // GlobalKey — stable across rebuilds
          onMapCreated: _onMapCreated,
          textureView: true,
          styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
          cameraOptions: mapbox.CameraOptions(
            center: mapbox.Point(
              coordinates: mapbox.Position(77.3210, 19.1383),
            ),
            zoom: 12.0,
            pitch: 60.0,
          ),
        ),
        // Top Overlay Elements
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Search Button
              _buildCircularButton(
                Icons.search,
                Colors.white,
                const Color(0xFF374151),
                onTap: () =>
                    Navigator.of(context).push(_fastRoute(const SearchPage())),
              ),

              const Spacer(),

              // Notification Button with Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildCircularButton(
                    Icons.notifications,
                    Colors.white,
                    const Color(0xFF374151),
                    onTap: () => Navigator.of(
                      context,
                    ).push(_fastRoute(const NotificationsPage())),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Profile Button
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).push(_fastRoute(const ProfilePage())),
                child: const _AnimatedProfileAvatar(),
              ),
            ],
          ),
        ),

        // Bottom Overlay Elements
        Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Delivery Status Pill (Left)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                    const Text(
                      'Orders',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Home + Location grouped (Right)
              // Live Location Button (Right)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
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
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}

// ─── Profile Avatar ──────────────────────────────────────────────────────────
class _AnimatedProfileAvatar extends StatelessWidget {
  final String? imageUrl;

  const _AnimatedProfileAvatar({this.imageUrl});

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
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 22,
              ),
            )
          : null,
    );
  }
}

class _MedicalClickListener extends mapbox.OnPointAnnotationClickListener {
  final void Function(mapbox.PointAnnotation) onClick;
  _MedicalClickListener(this.onClick);

  @override
  void onPointAnnotationClick(mapbox.PointAnnotation annotation) {
    onClick(annotation);
  }
}
