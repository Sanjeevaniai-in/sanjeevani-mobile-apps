import 'package:flutter/material.dart';
// Sanjeevani Chatbot

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/config/api_config.dart';
import '../core/services/user_service.dart';
import '../services/map_service.dart';

import 'shop_profile_page.dart';

class CartItem {
  final String name;
  int quantity;
  String unit; // 'Unit', 'Strip', 'Box'
  final double price;
  final String imageUrl;

  CartItem({
    required this.name,
    this.quantity = 1,
    this.unit = 'Strip',
    this.price = 0.0,
    required this.imageUrl,
  });
}

// ─── Data Model ──────────────────────────────────────────────────────────────

class PharmacyResult {
  final String name;
  final String address;
  final double rating;
  final String distance;
  final bool isOpen;
  final String hours;

  const PharmacyResult({
    required this.name,
    required this.address,
    required this.rating,
    required this.distance,
    required this.isOpen,
    required this.hours,
  });
}

final List<PharmacyResult> demoPharmacies = [
  PharmacyResult(
    name: 'Sanjeevani Central',
    address: 'Main Market, Pune',
    rating: 4.9,
    distance: '0.2 km',
    isOpen: true,
    hours: '24/7 Open',
  ),
  PharmacyResult(
    name: 'MedPlus Pharmacy',
    address: 'Kalyani Nagar, Pune',
    rating: 4.8,
    distance: '0.3 km',
    isOpen: true,
    hours: '8AM – 10PM',
  ),
  PharmacyResult(
    name: 'Apollo HealthHub',
    address: 'Baner Road, Pune',
    rating: 4.6,
    distance: '0.7 km',
    isOpen: true,
    hours: '24/7 Open',
  ),
  PharmacyResult(
    name: 'Jan Arogya Medical',
    address: 'Wakad, Pune',
    rating: 4.4,
    distance: '1.1 km',
    isOpen: false,
    hours: '9AM – 9PM',
  ),
  PharmacyResult(
    name: 'Wellness Medicals',
    address: 'Hinjewadi, Pune',
    rating: 4.7,
    distance: '1.5 km',
    isOpen: true,
    hours: '7AM – 11PM',
  ),
];

// ─── Chat Message ─────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final bool showPharmacyList;
  final bool isBanner;
  final bool showTracking;
  final String? imagePath;
  final List<CartItem>? cartItems;
  final bool showCart;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.showPharmacyList = false,
    this.isBanner = false,
    this.showTracking = false,
    this.imagePath,
    this.cartItems,
    this.showCart = false,
  });
}

class _RecentOrderPreview {
  final String id;
  final String item;
  final String status;
  final String ago;

  const _RecentOrderPreview({
    required this.id,
    required this.item,
    required this.status,
    required this.ago,
  });
}

// ─── ChatbotPage ─────────────────────────────────────────────────────────────

class ChatbotPage extends StatefulWidget {
  final Pharmacy? initialPharmacy;
  const ChatbotPage({super.key, this.initialPharmacy});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  Pharmacy? _selectedShop;
  List<Pharmacy> _displayPharmacies = [];
  final MapService _mapService = MapService();
  bool _orderPlaced = false;
  int _trackingStep = 0;

  // Animation Keys
  final GlobalKey _cartIconKey = GlobalKey();
  final List<CartItem> _globalCart = [];
  int _activeHeaderTab = 0; // 0: Chat, 1: Cart

  String? _lastItemRequested;
  String _selectedModel = "Pro"; // Perplexity style model

  // Theme Colors (Perplexity-Light Style)
  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _pillBg = Color(0xFFF3F3F5);
  static const Color _inputBorder = Color(0xFFE5E7EB);
  static const Color _dark = Color(0xFF1A1A1B);
  static const Color _textSub = Color(0xFF6B7280);
  static const Color _accent = Color(
    0xFF000000,
  ); // Sharp black for premium feel
  static const Color _msgBot = Color(0xFFF9FAFB);
  static const Color _msgUser = Color(0xFFFFFFFF);
  static const Color _card = Colors.white;
  static const Color _green = Color(0xFF10B981);

  int _lastQuantityRequested = 1;
  String? _chatSessionId;
  String _realOrderId = '—'; // populated after backend confirms order
  bool _isUploadingPrescription = false;
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _dotAnimController;
  late AnimationController _bannerAnimController;
  late Animation<double> _bannerAnimation;

  static const List<_RecentOrderPreview> _demoRecentOrders = [];

  @override
  void initState() {
    super.initState();

    _dotAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _bannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bannerAnimation = CurvedAnimation(
      parent: _bannerAnimController,
      curve: Curves.easeOutCubic,
    );

    if (widget.initialPharmacy != null) {
      _selectedShop = widget.initialPharmacy;
      _bannerAnimController.forward();
    } else {
      _autoSelectDefaultPharmacy();
    }

    _ensurePharmaciesLoaded();
  }

  bool _argsProcessed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsProcessed) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _argsProcessed = true;
        final deepLinkedMed = args['med'];

        if (deepLinkedMed != null) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _sendMessageWithCustomText("I want $deepLinkedMed");
            }
          });
        }
      }
    }
  }

  Future<void> _sendMessageWithCustomText(String text) async {
    _controller.text = text;
    await _sendMessage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _dotAnimController.dispose();
    _bannerAnimController.dispose();
    super.dispose();
  }

  // ── Helpers ──

  void _addBotMessage(
    String text, {
    bool showPharmacyList = false,
    bool showTracking = false,
    List<CartItem>? cartItems,
    bool showCart = false,
  }) {
    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: false,
          time: _timeNow(),
          showPharmacyList: showPharmacyList,
          showTracking: showTracking,
          cartItems: cartItems,
          showCart: showCart,
        ),
      );

      if (showPharmacyList) {
        _displayPharmacies = _mapService.loadedPharmacies;
      }
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: _timeNow()));
    });
    _scrollToBottom();
  }

  void _addSystemBanner(String text) {
    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: false,
          time: _timeNow(),
          isBanner: true,
        ),
      );
    });
    _scrollToBottom();
  }

  void _addRecentOrdersPreview() {
    final rows = _demoRecentOrders
        .map((o) => '• ${o.id} - ${o.item} (${o.status}, ${o.ago})')
        .join('\n');
    _addBotMessage(
      "Recent orders at this pharmacy:\n$rows\n\nYou can place a new order now.",
    );
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 300,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isMedical(String text) {
    const keywords = [
      'medicine',
      'pharmacy',
      'medical',
      'tablet',
      'capsule',
      'injection',
      'drug',
      'paracetamol',
      'fever',
      'pain',
      'headache',
      'cough',
      'cold',
      'hospital',
      'doctor',
      'prescription',
      'antibiotic',
      'vitamin',
      'syrup',
      'need',
      'find',
      'buy',
      'get',
      'shop',
      'chemist',
      'health',
      'dolo',
      'nearest',
      'near',
      'nearby',
      'crocin',
      'aspirin',
      'order',
    ];
    final lower = text.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }

  bool _isGreetingMessage(String text) {
    final lower = text.toLowerCase().trim();
    const greetings = [
      'hi',
      'hii',
      'hey',
      'hello',
      'namaste',
      'namaskar',
      'good morning',
      'good evening',
      'good night',
    ];
    return greetings.any((g) => lower == g || lower.startsWith('$g '));
  }

  bool _isConfirmation(String text) {
    const words = [
      'yes',
      'confirm',
      'ok',
      'okay',
      'haan',
      'ha',
      'sure',
      'place',
      'order',
      'do it',
      'proceed',
      'chalega',
      'bilkul',
      'hn',
      'yep',
    ];
    final lower = text.toLowerCase();
    return words.any((k) => lower.contains(k));
  }

  Future<void> _ensurePharmaciesLoaded() async {
    if (_mapService.loadedPharmacies.isNotEmpty) {
      if (!mounted) return;
      setState(() => _displayPharmacies = _mapService.loadedPharmacies);
      _autoSelectDefaultPharmacy();
      return;
    }

    try {
      // Nanded fallback center until we persist user live location in profile.
      final shops = await _mapService.fetchNearbyPharmacies(19.1383, 77.3210);
      if (!mounted) return;
      setState(() => _displayPharmacies = shops);
      _autoSelectDefaultPharmacy();
    } catch (_) {
      // Keep empty; UI still lets user retry with find pharmacy button.
    }
  }

  void _autoSelectDefaultPharmacy() {
    if (_selectedShop != null) return;

    final defaultId = ApiConfig.primaryPharmacyId.trim();
    if (defaultId.isEmpty) return;

    Pharmacy? match;
    for (final p in _displayPharmacies) {
      if (p.id.trim() == defaultId) {
        match = p;
        break;
      }
    }

    match ??= Pharmacy(
      id: defaultId,
      name: 'Sanjeevani Store',
      lat: 19.1383,
      lng: 77.3210,
      tier: PharmacyTier.base,
      isOpen: true,
      distance: 'Near you',
    );

    setState(() => _selectedShop = match);
    _bannerAnimController.forward();
  }

  Future<Map<String, dynamic>?> _sendChatToBackend(String text) async {
    try {
      final svc = UserService();
      final user = await svc.currentUser;
      final pharmacyId = _resolvePharmacyId();
      if (pharmacyId == null || pharmacyId.isEmpty) {
        return null;
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.chatbotFast),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': user?.id.isNotEmpty == true
                  ? user!.id
                  : (user?.email ?? 'app-user'),
              'message': text,
              'pharmacy_id': pharmacyId,
              'session_id': _chatSessionId,
            }),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final sid = data['session_id']?.toString();
        if (sid != null && sid.isNotEmpty) {
          _chatSessionId = sid;
        }
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _resolveUserId() async {
    final svc = UserService();
    final user = await svc.currentUser;
    return user?.id.isNotEmpty == true ? user!.id : (user?.email ?? 'app-user');
  }

  void _pickImage() {
    _pickAndUploadPrescription();
  }

  Future<void> _pickAndUploadPrescription() async {
    if (_selectedShop == null) {
      _addBotMessage(
        "Please select a pharmacy first, then upload prescription.",
      );
      return;
    }
    if (_isUploadingPrescription) {
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Capture from camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 75,
    );
    if (picked == null) {
      return;
    }

    await _uploadPrescriptionImage(picked);
  }

  Future<void> _uploadPrescriptionImage(XFile image) async {
    final pharmacyId = _resolvePharmacyId();
    if (pharmacyId == null || pharmacyId.isEmpty) {
      _addBotMessage("Please select a valid pharmacy before upload.");
      return;
    }

    setState(() => _isUploadingPrescription = true);
    _addBotMessage(
      'Analyzing prescription image... This may take a few seconds.',
    );
    setState(() {
      _messages.add(
        _ChatMessage(
          text: 'Uploaded prescription',
          isUser: true,
          time: _timeNow(),
          imagePath: image.path,
        ),
      );
    });
    _scrollToBottom();

    try {
      final userId = await _resolveUserId();
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse(ApiConfig.chatbotUploadPrescription),
            )
            ..fields['user_id'] = userId
            ..fields['pharmacy_id'] = pharmacyId
            ..fields['session_id'] = _chatSessionId ?? ''
            ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final streamed = await request.send().timeout(ApiConfig.receiveTimeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        _addBotMessage(
          'Prescription upload failed (code ${response.statusCode}). Please try again with a clearer image.',
        );
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final sid = data['session_id']?.toString();
      if (sid != null && sid.isNotEmpty) {
        _chatSessionId = sid;
      }

      final replyText =
          ((data['message'] ?? data['text'] ?? data['reply']) ?? '')
              .toString()
              .trim();
      if (replyText.isNotEmpty) {
        _addBotMessage(replyText);
      }

      final payload = (data['data'] as Map?)?.cast<String, dynamic>() ?? {};
      final medicinesRaw = payload['extracted_medicines'];
      if (medicinesRaw is List && medicinesRaw.isNotEmpty) {
        final medicineNames = medicinesRaw
            .map((m) => (m as Map)['name']?.toString() ?? '')
            .where((name) => name.trim().isNotEmpty)
            .toList();
        if (medicineNames.isNotEmpty) {
          _lastItemRequested = medicineNames.join(', ');
          final cartItems = medicineNames
              .map(
                (name) => CartItem(
                  name: name,
                  imageUrl: _getMedicineImage(name),
                  quantity: 1,
                ),
              )
              .toList();
          _addCartMessage(cartItems);
        }
      } else {
        _addBotMessage(
          'I could not confidently extract medicine names from this image. Please upload a clearer prescription photo or type medicine names manually.',
        );
      }
    } catch (_) {
      _addBotMessage(
        'Network issue while uploading prescription. Please retry in a moment.',
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPrescription = false);
      }
    }
  }

  Future<void> _startOrderTracking({String? existingOrderId}) async {
    final pharmacyId = _resolvePharmacyId();
    if (pharmacyId == null || pharmacyId.isEmpty) {
      _addBotMessage(
        "Please select a valid pharmacy before confirming the order.",
      );
      return;
    }

    setState(() {
      _orderPlaced = true;
      _messages.add(
        _ChatMessage(
          text: 'Tracking your order...',
          isUser: false,
          time: _timeNow(),
          showTracking: true,
        ),
      );
    });
    _scrollToBottom();

    if (existingOrderId != null && existingOrderId.trim().isNotEmpty) {
      if (mounted) {
        setState(() => _realOrderId = existingOrderId.trim());
      }
    } else {
      // POST real order to backend
      try {
        final svc = UserService();
        final token = await svc.token;
        final customerName = await svc.name;

        // Build items list from cart (multi-item support)
        final cartSnapshot = List<CartItem>.from(_globalCart);
        final itemsList = cartSnapshot.isNotEmpty
            ? cartSnapshot
                .map((c) => {
                      'name': c.name,
                      'quantity': c.quantity,
                      'unit': c.unit,
                    })
                .toList()
            : [
                {
                  'name': _lastItemRequested ?? 'General Medicine',
                  'quantity': _lastQuantityRequested,
                  'unit': 'Strip',
                },
              ];

        final response = await http
            .post(
              Uri.parse(ApiConfig.ordersManual),
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'patient_name': customerName,
                // Legacy single-item fields (kept for backward compat)
                'medicine_name': cartSnapshot.isNotEmpty
                    ? cartSnapshot.first.name
                    : (_lastItemRequested ?? 'General Medicine'),
                'quantity': cartSnapshot.isNotEmpty
                    ? cartSnapshot.first.quantity
                    : _lastQuantityRequested,
                // ── New multi-item payload ──
                'items': itemsList,
                'channel': 'Sanjeevani App',
                'merchant_id': pharmacyId,
                'pharmacy_id': pharmacyId,
                'source_channel': 'app',
                'source_provider': 'delivery_app',
                'source_message_id':
                    'app:${DateTime.now().millisecondsSinceEpoch}:${customerName ?? 'customer'}',
              }),
            )
            .timeout(ApiConfig.receiveTimeout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final orderId = data['order_id'] ?? data['_id'] ?? data['id'] ?? '—';
          if (mounted) setState(() => _realOrderId = orderId.toString());
          debugPrint('✅ Order placed: $orderId');
        } else {
          debugPrint(
            '❌ Order API error: ${response.statusCode} → ${response.body}',
          );
          if (mounted) {
            _addBotMessage(
              "Order request send hua, lekin server confirm nahi kar paya (code: ${response.statusCode}). Please retry once.",
            );
          }
        }
      } catch (e) {
        debugPrint('🔥 Order POST error: $e');
        if (mounted) {
          _addBotMessage(
            "Network issue ki wajah se order confirm nahi hua. Please retry in a few seconds.",
          );
        }
      }
    }

    // Simulate status steps locally while waiting for webhooks
    for (final step in [0, 1, 2, 3]) {
      await Future.delayed(Duration(seconds: step == 0 ? 1 : 5));
      if (!mounted) return;
      setState(() => _trackingStep = step);
    }
  }

  String? _resolvePharmacyId() {
    final fallback = ApiConfig.primaryPharmacyId.trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }
    final fromSelection = _selectedShop?.id.trim();
    if (fromSelection != null && fromSelection.isNotEmpty) {
      return fromSelection;
    }
    return null;
  }

  void _selectPharmacy(Pharmacy p) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedShop = p);
    _bannerAnimController.forward();
    _addSystemBanner('✅  **${p.name}** selected as your pharmacy.');
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _addBotMessage(
        "Great choice! 🏥 **${p.name}** is ${p.isOpen ? 'open right now' : 'currently closed'}.\n\nNow tell me what medicine or health item you need!",
      );
    });
  }

  void _changePharmacy() {
    HapticFeedback.lightImpact();
    setState(() => _selectedShop = null);
    _bannerAnimController.reverse();
    _addBotMessage(
      "Sure! Please select a different pharmacy from the list below:",
      showPharmacyList: true,
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    _controller.clear();
    _addUserMessage(text);

    _autoSelectDefaultPharmacy();

    // Gate: must select a pharmacy first
    if (_selectedShop == null) {
      setState(() => _isTyping = true);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addBotMessage(
        "Please select a nearby pharmacy first before placing an order! 🏥",
        showPharmacyList: true,
      );
      return;
    }

    // Order already placed — cool down
    if (_orderPlaced) {
      setState(() => _isTyping = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addBotMessage("📦 Your order is already on its way! Track it above.");
      return;
    }

    setState(() => _isTyping = true);
    _scrollToBottom();
    await Future.delayed(Duration(milliseconds: 900 + Random().nextInt(600)));
    if (!mounted) return;
    setState(() => _isTyping = false);

    final shop = _selectedShop!;

    // Check if user is confirming a pending order
    if (_isConfirmation(text) &&
        _messages.any((m) => m.text.toLowerCase().contains('confirm'))) {
      _addBotMessage("🛍 Processing your order at **${shop.name}**...");
      _startOrderTracking();
      return;
    }

    // Backend chatbot integration (WhatsApp-like intelligence) - primary path
    final backendReply = await _sendChatToBackend(text);
    if (backendReply == null) {
      // Fallback local behavior if backend chat is temporarily unavailable.
      if (_isMedical(text)) {
        _lastItemRequested = text;
        final cartItems = [
          CartItem(name: text, imageUrl: _getMedicineImage(text), quantity: 1),
        ];
        _addCartMessage(cartItems);
      } else {
        if (_isGreetingMessage(text)) {
          _addBotMessage(
            "Namaste! I am ready to help with your order from **${shop.name}**.\n\nPlease tell me medicine name and quantity, for example: *Paracetamol 650, 2 strips*.",
          );
        } else {
          _addBotMessage(
            "I can help with medicine orders, prescription upload, and delivery tracking.\n\nPlease share medicine name and quantity, or upload prescription image.",
          );
        }
      }
      return;
    }

    final extracted =
        (backendReply['extracted_data'] as Map?)?.cast<String, dynamic>() ?? {};
    final medicine = extracted['medicine_name']?.toString();
    final qty = extracted['quantity'];
    if (medicine != null && medicine.trim().isNotEmpty) {
      _lastItemRequested = medicine.trim();
    }
    if (qty is num && qty > 0) {
      _lastQuantityRequested = qty.toInt();
    }

    final replyText = (backendReply['text'] ?? backendReply['reply'] ?? '')
        .toString()
        .trim();
    if (replyText.isNotEmpty) {
      if (medicine != null && medicine.trim().isNotEmpty) {
        final cartItems = [
          CartItem(
            name: medicine.trim(),
            imageUrl: _getMedicineImage(medicine.trim()),
            quantity: _lastQuantityRequested,
          ),
        ];
        _addCartMessage(cartItems);
      } else {
        _addBotMessage(replyText);
      }
    }

    final state = (backendReply['state'] ?? '').toString().toUpperCase();
    final backendOrderId = (extracted['order_id'] ?? '').toString().trim();
    if (!_orderPlaced && backendOrderId.isNotEmpty) {
      _addBotMessage("Order confirmed. Tracking is live now.");
      _startOrderTracking(existingOrderId: backendOrderId);
      return;
    }
    final confirmedByUser = _isConfirmation(text);
    if (!_orderPlaced &&
        confirmedByUser &&
        (state.contains('FINALIZING') ||
            state.contains('CONFIRM') ||
            replyText.toLowerCase().contains('confirm'))) {
      _addBotMessage("🛍 Processing your order at **${shop.name}**...");
      _startOrderTracking();
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // 1. Centered Branding (Only show when no messages)
          if (_messages.isEmpty)
            Center(
              child: Opacity(
                opacity: 0.15,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sanjeevani',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -2,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your personal healthcare AI',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _textSub,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Chat Content
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 80),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              if (_isTyping) _buildTypingIndicator(),
              _buildInputArea(),
            ],
          ),

          _buildPillHeader(),
        ],
      ),
    );
  }

  Widget _buildPillHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 4,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Back/Profile Button (Left)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _inputBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: _dark,
              ),
            ),
          ),

          // 2. Center Pill (Toggle)
          Container(
            height: 54,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: _inputBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderTab(0, Icons.search_rounded),
                _buildHeaderTab(1, Icons.computer_rounded),
              ],
            ),
          ),

          // 3. Stacked Cart View (Right)
          GestureDetector(
            key: _cartIconKey,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _buildFullCartPage()),
            ),
            child: SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(-8, 2),
                    child: Transform.rotate(
                      angle: -0.15,
                      child: _buildHeaderCartImage(
                        _globalCart.isNotEmpty
                            ? _globalCart.first.imageUrl
                            : 'https://img.freepik.com/free-photo/pills-spilling-out-bottle-white-background_23-2148285748.jpg',
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(8, -2),
                    child: Transform.rotate(
                      angle: 0.15,
                      child: _buildHeaderCartImage(
                        _globalCart.length > 1
                            ? _globalCart[1].imageUrl
                            : 'https://cdn-icons-png.flaticon.com/512/3028/3028561.png',
                      ),
                    ),
                  ),
                  if (_globalCart.isNotEmpty)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${_globalCart.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTab(int index, IconData icon) {
    final isSelected = _activeHeaderTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _activeHeaderTab = index);
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _buildFullPharmacyPage()),
          );
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _activeHeaderTab = 0);
          });
        }
      },
      child: Container(
        width: 60,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? _pillBg : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? _dark : _dark.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildHeaderCartImage(String url) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildFullPharmacyPage() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nearby Pharmacies',
          style: GoogleFonts.outfit(color: _dark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _displayPharmacies.length,
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (ctx, idx) {
          final shop = _displayPharmacies[idx];
          final isSelected = _selectedShop?.id == shop.id;
          return GestureDetector(
            onTap: () {
              _selectPharmacy(shop);
              Navigator.pop(ctx);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? _dark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? _dark : const Color(0xFFF3F4F6),
                  width: 1.5,
                ),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://img.freepik.com/free-photo/pills-spilling-out-bottle-white-background_23-2148285748.jpg',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name ?? 'Pharmacy',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isSelected ? Colors.white : _dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shop.address ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white.withOpacity(0.7)
                                : _textSub,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullCartPage() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Cart',
          style: GoogleFonts.outfit(color: _dark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _globalCart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 80,
                    color: _textSub.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      color: _dark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Add some medicines to get started',
                    style: GoogleFonts.inter(color: _textSub),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _globalCart.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (ctx, idx) {
                      final item = _globalCart[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _inputBorder),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity} x ${item.unit}',
                                    style: GoogleFonts.inter(
                                      color: _textSub,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  setState(() => _globalCart.removeAt(idx)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (_globalCart.isEmpty) return;
                        // Set last item info for legacy single-item tracking label
                        _lastItemRequested = _globalCart
                            .map((c) => '${c.name} x${c.quantity}')
                            .join(', ');
                        _addBotMessage(
                          "🛍 Processing your order for ${_globalCart.length} item(s) at **${_selectedShop?.name ?? 'the pharmacy'}**...",
                        );
                        _startOrderTracking();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dark,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Confirm Order',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;

    // If it has cart items, we show them as a full-width block below the text
    if (message.cartItems != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message.text.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                decoration: BoxDecoration(
                  color: _msgBot,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: _inputBorder),
                ),
                child: Text(
                  message.text,
                  style: GoogleFonts.inter(
                    color: _dark,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          _buildCartCard(message.cartItems!),
          const SizedBox(height: 16),
        ],
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? _dark : _msgBot,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: isUser ? null : Border.all(color: _inputBorder),
          boxShadow: [
            if (isUser)
              BoxShadow(
                color: _dark.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            color: isUser ? Colors.white : _dark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFindPharmacyButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _addBotMessage(
          "Here are the best pharmacies near you! 📍 Tap **Select** to choose one:",
          showPharmacyList: true,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F2937), Color(0xFF374151)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _dark.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Find Nearest Pharmacy',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPharmacyCard(Pharmacy p) {
    final isSelected = _selectedShop?.name == p.name;

    return GestureDetector(
      onTap: isSelected ? null : () => _selectPharmacy(p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _green : const Color(0xFFF0F0F5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _green.withOpacity(0.1)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? _green.withOpacity(0.12)
                    : const Color(0xFFF3F4F8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_pharmacy_rounded,
                color: isSelected ? _green : _dark,
                size: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              p.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: _dark,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              p.distance,
              style: GoogleFonts.inter(color: _textSub, fontSize: 11),
            ),
            const Spacer(),
            _cardBtn(
              'Profile',
              const Color(0xFF374151),
              const Color(0xFFF3F4F8),
              Icons.person_pin_rounded,
              () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        ShopProfilePage(shopName: p.name),
                    transitionDuration: const Duration(milliseconds: 220),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardBtn(
    String label,
    Color textColor,
    Color bgColor,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: bgColor == _dark
              ? null
              : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: bgColor == _dark ? Colors.white : textColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: bgColor == _dark ? Colors.white : textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard() {
    final steps = [
      ('Order Confirmed', Icons.check_circle_rounded, const Color(0xFF10B981)),
      ('Preparing', Icons.medication_rounded, const Color(0xFF7C3AED)),
      (
        'Out for Delivery',
        Icons.delivery_dining_rounded,
        const Color(0xFF2563EB),
      ),
      ('Arriving Soon', Icons.home_rounded, const Color(0xFFD97706)),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: _green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Order Tracking',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Order: $_realOrderId',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live',
                      style: GoogleFonts.inter(
                        color: _green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress steps
          ...List.generate(steps.length, (i) {
            final isDone = i <= _trackingStep;
            final isActive = i == _trackingStep;
            final (label, icon, color) = steps[i];
            final isLast = i == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator column
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDone ? color : Colors.white10,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: isDone ? Colors.white : Colors.white30,
                        size: 16,
                      ),
                    ),
                    if (!isLast)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 2,
                        height: 28,
                        color: (i < _trackingStep)
                            ? color.withOpacity(0.6)
                            : Colors.white10,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Label
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: isActive
                          ? Colors.white
                          : (isDone ? Colors.white60 : Colors.white24),
                      fontSize: 13,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _dotAnimController,
                  builder: (ctx, _) {
                    final offset = sin(
                      (_dotAnimController.value * 2 * pi) + (i * pi / 2.2),
                    );
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7,
                      transform: Matrix4.translationValues(0, offset * -4, 0),
                      decoration: const BoxDecoration(
                        color: Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _addCartMessage(List<CartItem> items) {
    // ── AUTO-PUSH into global cart so badge & cart page are always in sync ──
    setState(() {
      for (final incoming in items) {
        final existingIdx = _globalCart.indexWhere(
          (c) => c.name.toLowerCase() == incoming.name.toLowerCase(),
        );
        if (existingIdx >= 0) {
          // Merge: bump quantity instead of duplicating
          _globalCart[existingIdx].quantity += incoming.quantity;
        } else {
          _globalCart.add(
            CartItem(
              name: incoming.name,
              quantity: incoming.quantity,
              unit: incoming.unit,
              imageUrl: incoming.imageUrl,
            ),
          );
        }
      }
    });

    _addBotMessage(
      "✅ Added ${items.length} item(s) to your cart! 🛒 Review below and tap **Confirm Order** when ready.",
      cartItems: items,
      showCart: true,
    );
  }

  String _getMedicineImage(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('paracetamol') || lower.contains('dolo')) {
      return 'https://img.freepik.com/free-photo/pills-spilling-out-bottle-white-background_23-2148285748.jpg';
    } else if (lower.contains('vitamin') || lower.contains('multivitamin')) {
      return 'https://img.freepik.com/free-photo/close-up-pills-bottle_23-2148285750.jpg';
    } else if (lower.contains('syrup') || lower.contains('cough')) {
      return 'https://img.freepik.com/free-photo/medicine-bottle-pills-white-background_23-2148285746.jpg';
    } else if (lower.contains('mask') || lower.contains('surgical')) {
      return 'https://img.freepik.com/free-photo/medical-mask-protection-virus-flu-isolated_1150-35222.jpg';
    }
    return 'https://img.freepik.com/free-photo/pills-spilling-out-bottle-white-background_23-2148285748.jpg';
  }

  Widget _buildCartCard(List<CartItem> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.map((item) {
            final GlobalKey btnKey = GlobalKey();
            return StatefulBuilder(
              builder: (ctx, setCardState) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF3F4F6)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              item.imageUrl,
                              width: 65,
                              height: 65,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.outfit(
                                  color: _dark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: ['Unit', 'Strip', 'Box'].map((u) {
                                  final isSel = item.unit == u;
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setCardState(() => item.unit = u);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? _dark
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSel
                                              ? _dark
                                              : const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Text(
                                        u,
                                        style: GoogleFonts.inter(
                                          color: isSel
                                              ? Colors.white
                                              : _textSub,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _qtyBtn(Icons.remove, () {
                              setCardState(() {
                                if (item.quantity > 1) item.quantity--;
                              });
                            }),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '${item.quantity}',
                                style: GoogleFonts.outfit(
                                  color: _dark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _qtyBtn(Icons.add, () {
                              setCardState(() {
                                item.quantity++;
                              });
                            }),
                          ],
                        ),
                        ElevatedButton(
                          key: btnKey,
                          onPressed: () {
                            _runFlyToCartAnimation(item, btnKey);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add to Cart',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (items.indexOf(item) != items.length - 1)
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 14, color: _dark),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _pillBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _inputBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TextField Area
            TextField(
              controller: _controller,
              style: GoogleFonts.inter(color: _dark, fontSize: 15),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: GoogleFonts.inter(color: _textSub, fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
            // Perplexity Style Bottom Actions
            Row(
              children: [
                const SizedBox(width: 4),
                // Attachment Pill
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.add, color: _textSub, size: 22),
                  ),
                ),
                const Spacer(),
                // Browser/Focus Icon
                const Icon(Icons.public, size: 20, color: _textSub),
                const SizedBox(width: 16),
                // Voice/Mic Icon
                const Icon(Icons.mic_none_outlined, size: 22, color: _textSub),
                const SizedBox(width: 12),
                // Send Button
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _dark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCartSummary() {
    if (_globalCart.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Summary',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _dark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _globalCart.isEmpty
                    ? Center(
                        child: Text(
                          "Your cart is empty",
                          style: GoogleFonts.inter(color: _textSub),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _globalCart.length,
                        itemBuilder: (ctx, idx) {
                          final item = _globalCart[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: true,
                                  activeColor: _dark,
                                  onChanged: (v) {},
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Qty: ${item.quantity} (${item.unit})',
                                        style: GoogleFonts.inter(
                                          color: _textSub,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _globalCart.removeAt(idx));
                                    setModalState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Items',
                    style: GoogleFonts.inter(color: _textSub),
                  ),
                  Text(
                    '${_globalCart.length}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _globalCart.isEmpty
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _addBotMessage(
                            "💳 Initializing secure payment gateway for your order at **${_selectedShop!.name}**...",
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Proceed to Payment',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _runFlyToCartAnimation(CartItem item, GlobalKey btnKey) {
    HapticFeedback.mediumImpact();

    // The target is now always visible in the sectioned header
    final RenderBox? btnBox =
        btnKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? cartBox =
        _cartIconKey.currentContext?.findRenderObject() as RenderBox?;

    if (btnBox != null && cartBox != null) {
      final Offset startPos = btnBox.localToGlobal(Offset.zero);
      final Offset endPos = cartBox.localToGlobal(Offset.zero);
      _createFlyingDot(startPos, endPos);
    }

    setState(() {
      _globalCart.add(
        CartItem(
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
          imageUrl: item.imageUrl,
        ),
      );
    });
  }

  void _createFlyingDot(Offset start, Offset end) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyingItemWidget(
        start: start,
        end: end,
        onComplete: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
  }

  Widget _buildFloatingCartButton() => const SizedBox.shrink();
}

class _FlyingItemWidget extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onComplete;

  const _FlyingItemWidget({
    required this.start,
    required this.end,
    required this.onComplete,
  });

  @override
  State<_FlyingItemWidget> createState() => _FlyingItemWidgetState();
}

class _FlyingItemWidgetState extends State<_FlyingItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _animation = Tween<Offset>(begin: widget.start, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.2), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _animation.value.dx,
          top: _animation.value.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1F2937).withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_shopping_cart,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
