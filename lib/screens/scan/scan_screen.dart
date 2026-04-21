import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/shop_models.dart';
import 'package:flutter_application_1/services/app_session.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final _codeController = TextEditingController();
  final _manualSearchController = TextEditingController();
  late final MobileScannerController _scannerController;
  Timer? _manualSearchDebounce;
  List<ShopDetails> _manualSearchResults = const [];
  bool _isSearching = false;
  bool _isManualSearching = false;
  bool _manualSearchTriggered = false;
  bool _hasDetected = false;
  bool _isCameraStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      autoStart: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
  }

  Future<void> _startCamera() async {
    if (_isCameraStarted) return;
    try {
      await _scannerController.start();
      if (mounted) setState(() => _isCameraStarted = true);
    } catch (_) {
      // Camera may already be started
      if (mounted) setState(() => _isCameraStarted = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_hasDetected) _scannerController.start();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _scannerController.stop();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualSearchDebounce?.cancel();
    _codeController.dispose();
    _manualSearchController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) {
    if (_hasDetected) return;
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    _hasDetected = true;
    _codeController.text = code;
    _scannerController.stop();
    _searchShop();
  }

  Future<void> _rescan() async {
    setState(() {
      _hasDetected = false;
    });
    try {
      await _scannerController.start();
    } catch (_) {
      // Scanner may already be running
    }
  }

  Future<void> _searchShop() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter barcode or QR value first')),
      );
      return;
    }
    setState(() => _isSearching = true);
    final shop = await FirebaseService.fetchShopByScanCode(code);
    if (!mounted) return;
    setState(() => _isSearching = false);

    if (shop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No shop found for this code')),
      );
      return;
    }
    await _openShopDetails(shop);
  }

  Future<void> _openShopDetails(ShopDetails shop) async {
    final reviews = await FirebaseService.fetchStructuredReviews(shop.id);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ShopDetailsPage(
          shop: shop,
          reviews: reviews,
          onWriteReview: _openManualReviewPage,
        ),
      ),
    );
    // Resume camera after returning from shop details
    if (!_hasDetected) {
      try {
        await _scannerController.start();
      } catch (_) {}
    }
  }

  Future<void> _searchShopManually() async {
    final query = _manualSearchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter shop name, location, or code')),
      );
      return;
    }
    await _runManualSearch(query);
  }

  void _onManualSearchChanged(String value) {
    final query = value.trim();
    _manualSearchDebounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _manualSearchResults = const [];
        _manualSearchTriggered = false;
        _isManualSearching = false;
      });
      return;
    }
    _manualSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      _runManualSearch(query);
    });
  }

  Future<void> _runManualSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isManualSearching = true;
      _manualSearchTriggered = true;
    });
    final shops = await FirebaseService.searchShops(query);
    if (!mounted) return;
    setState(() {
      _manualSearchResults = shops;
      _isManualSearching = false;
    });
  }

  Future<void> _openManualReviewPage(BuildContext hostContext, ShopDetails shop) async {
    if (!hostContext.mounted) return;
    final submitted = await Navigator.of(hostContext).push<bool>(
      MaterialPageRoute(builder: (_) => _ManualReviewPage(shop: shop)),
    );
    if (!hostContext.mounted || submitted == null) return;
    ScaffoldMessenger.of(hostContext).showSnackBar(
      SnackBar(
        content: Text(
          submitted
              ? 'Review submitted. Admin will approve it soon.'
              : 'Could not submit review',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Search'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Camera scan section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Live Camera Scan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  child: SizedBox(
                    height: 260,
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: _handleScan,
                          errorBuilder: (context, error, child) {
                            return Container(
                              color: const Color(0xFF0A0E1F),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 48),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Camera permission required',
                                      style: TextStyle(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      error.errorCode.toString(),
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Scan frame overlay
                        Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF6B9FFF), width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        // Corner decorations
                        ..._buildCorners(),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Align QR code inside the frame to scan',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _rescan,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Rescan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F65FF),
                        side: const BorderSide(color: Color(0xFF0F65FF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Manual code entry
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE0E5F2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.barcode_reader, color: Color(0xFF0F65FF), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Enter Code Manually',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode / QR code',
                    hintText: 'e.g. SHOP-1001 or QR-1001',
                    prefixIcon: Icon(Icons.qr_code_2_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _searchShop,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(_isSearching ? 'Searching...' : 'Find By Code'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search by name section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE0E5F2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.search_rounded, color: Color(0xFF0F65FF), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Search Shop Without Scan',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Search by name, location, or code. Live suggestions appear while typing.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _manualSearchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchShopManually(),
                  onChanged: _onManualSearchChanged,
                  decoration: const InputDecoration(
                    labelText: 'Search shop',
                    hintText: 'Try Urban Cart / Dhaka / SHOP-1001',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isManualSearching ? null : _searchShopManually,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(_isManualSearching ? 'Searching...' : 'Search Shop'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                if (_isManualSearching) ...[
                  const SizedBox(height: 14),
                  const Center(child: CircularProgressIndicator(color: Color(0xFF0F65FF))),
                ] else if (_manualSearchTriggered && _manualSearchResults.isEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('No shop found for this query.', style: TextStyle(color: Colors.black54)),
                ] else ...[
                  const SizedBox(height: 4),
                  ..._manualSearchResults.map(
                    (shop) => Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ShopSearchResult(
                        shop: shop,
                        onTap: () => _openShopDetails(shop),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 24.0;
    const thickness = 3.0;
    const color = Color(0xFF6B9FFF);
    const offset = 80.0;

    return [
      // Top-left
      Positioned(
        top: offset,
        left: offset,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: offset,
        right: offset,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 52,
        left: offset,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 52,
        right: offset,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
    ];
  }
}

class _ShopSearchResult extends StatelessWidget {
  const _ShopSearchResult({required this.shop, required this.onTap});

  final ShopDetails shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EAF3)),
        ),
        child: Row(
          children: [
            _shopAvatar(shop),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(shop.location, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${shop.averageRating.toStringAsFixed(1)}  •  ${shop.reviewsCount} reviews',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF0F65FF)),
          ],
        ),
      ),
    );
  }

  Widget _shopAvatar(ShopDetails shop) {
    if (shop.imageUrl.isNotEmpty) {
      if (shop.imageUrl.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            shop.imageUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        );
      } else {
        try {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(base64Decode(shop.imageUrl), width: 44, height: 44, fit: BoxFit.cover),
          );
        } catch (_) {}
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          shop.name.isNotEmpty ? shop.name[0].toUpperCase() : 'S',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shop details page
// ─────────────────────────────────────────────────────────────
class _ShopDetailsPage extends StatelessWidget {
  const _ShopDetailsPage({
    required this.shop,
    required this.reviews,
    required this.onWriteReview,
  });

  final ShopDetails shop;
  final List<StructuredReview> reviews;
  final Future<void> Function(BuildContext, ShopDetails) onWriteReview;

  void _showFeedbackDetails(BuildContext context, StructuredReview review) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          review.overallRating >= i + 1 ? Icons.star_rounded : Icons.star_border_rounded,
                          color: const Color(0xFFFFD700),
                          size: 20,
                        )),
                        const SizedBox(width: 8),
                        Text(
                          '${review.overallRating.toStringAsFixed(1)} / 5.0',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Rating Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _BreakdownCard(
                items: [
                  _BreakdownItem(Icons.room_service_outlined, 'Service', review.service, const Color(0xFF0F65FF)),
                  _BreakdownItem(Icons.cleaning_services_outlined, 'Cleanliness', review.cleanliness, const Color(0xFF10B981)),
                  _BreakdownItem(Icons.support_agent_outlined, 'Staff Behavior', review.staffBehavior, const Color(0xFF6E3AFA)),
                  _BreakdownItem(Icons.verified_outlined, 'Product Quality', review.productQuality, const Color(0xFFF59E0B)),
                  _BreakdownItem(Icons.category_outlined, 'Variety', review.variety, const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5EAF3)),
                ),
                child: Text(
                  review.feedback,
                  style: const TextStyle(color: Color(0xFF4A5568), fontSize: 15, height: 1.6),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopImage() {
    if (shop.imageUrl.isEmpty) return const SizedBox.shrink();
    Widget img;
    if (shop.imageUrl.startsWith('http')) {
      img = Image.network(shop.imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover);
    } else {
      try {
        img = Image.memory(base64Decode(shop.imageUrl), height: 200, width: double.infinity, fit: BoxFit.cover);
      } catch (_) {
        return const SizedBox.shrink();
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: img,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildShopImage(),
          if (shop.imageUrl.isNotEmpty) const SizedBox(height: 16),
          Text(shop.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 15, color: Colors.black54),
            const SizedBox(width: 4),
            Text(shop.location, style: const TextStyle(color: Colors.black54)),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ...List.generate(5, (i) => Icon(
                  shop.averageRating >= i + 1 ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFFFB300),
                  size: 20,
                )),
                const SizedBox(width: 10),
                Text(
                  '${shop.averageRating.toStringAsFixed(1)} (${shop.reviewsCount} reviews)',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Rating Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _BreakdownCard(
            items: [
              _BreakdownItem(Icons.room_service_outlined, 'Service', shop.ratingBreakdown['service'] ?? 0, const Color(0xFF0F65FF)),
              _BreakdownItem(Icons.cleaning_services_outlined, 'Cleanliness', shop.ratingBreakdown['cleanliness'] ?? 0, const Color(0xFF10B981)),
              _BreakdownItem(Icons.support_agent_outlined, 'Staff Behavior', shop.ratingBreakdown['staffBehavior'] ?? 0, const Color(0xFF6E3AFA)),
              _BreakdownItem(Icons.verified_outlined, 'Product Quality', shop.ratingBreakdown['productQuality'] ?? 0, const Color(0xFFF59E0B)),
              _BreakdownItem(Icons.category_outlined, 'Variety', shop.ratingBreakdown['variety'] ?? 0, const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('Recent Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${reviews.length} reviews',
                  style: const TextStyle(color: Color(0xFF0F65FF), fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            const Text('No feedback yet. Be the first to review!', style: TextStyle(color: Colors.black54))
          else
            ...reviews.take(5).map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _showFeedbackDetails(context, review),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5EAF3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(review.userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                review.feedback,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF0F65FF)),
                            Text(
                              review.overallRating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F65FF)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onWriteReview(context, shop),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Write a Review'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem {
  const _BreakdownItem(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final double value;
  final Color color;
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.items});
  final List<_BreakdownItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(item.icon, size: 16, color: item.color),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w500))),
                Row(
                  children: [
                    ...List.generate(5, (i) => Icon(
                      item.value >= i + 1 ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFFB300),
                      size: 14,
                    )),
                    const SizedBox(width: 6),
                    Text(
                      item.value.toStringAsFixed(1),
                      style: TextStyle(fontWeight: FontWeight.w700, color: item.color, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Manual review submission page
// ─────────────────────────────────────────────────────────────
class _ManualReviewPage extends StatefulWidget {
  const _ManualReviewPage({required this.shop});
  final ShopDetails shop;

  @override
  State<_ManualReviewPage> createState() => _ManualReviewPageState();
}

class _ManualReviewPageState extends State<_ManualReviewPage> {
  final _feedbackController = TextEditingController();
  double _service = 4;
  double _cleanliness = 4;
  double _staffBehavior = 4;
  double _productQuality = 4;
  double _variety = 4;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please write your feedback')));
      return;
    }
    setState(() => _isSubmitting = true);
    final user = AppSession.currentUser;
    final ok = await FirebaseService.submitStructuredReview(
      shopId: widget.shop.id,
      userId: user?.id ?? 'guest_user',
      userName: user?.name ?? 'Guest User',
      service: _service,
      cleanliness: _cleanliness,
      staffBehavior: _staffBehavior,
      productQuality: _productQuality,
      variety: _variety,
      feedback: feedback,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review: ${widget.shop.name}'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.shop.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                      Text(widget.shop.location,
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5EAF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rate Each Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Slide to rate from 1 to 5', style: TextStyle(color: Colors.black45, fontSize: 12)),
                const SizedBox(height: 16),
                _RatingSlider(
                  icon: Icons.room_service_outlined,
                  label: 'Service',
                  color: const Color(0xFF0F65FF),
                  value: _service,
                  onChanged: (v) => setState(() => _service = v),
                ),
                _RatingSlider(
                  icon: Icons.cleaning_services_outlined,
                  label: 'Cleanliness',
                  color: const Color(0xFF10B981),
                  value: _cleanliness,
                  onChanged: (v) => setState(() => _cleanliness = v),
                ),
                _RatingSlider(
                  icon: Icons.support_agent_outlined,
                  label: 'Staff Behavior',
                  color: const Color(0xFF6E3AFA),
                  value: _staffBehavior,
                  onChanged: (v) => setState(() => _staffBehavior = v),
                ),
                _RatingSlider(
                  icon: Icons.verified_outlined,
                  label: 'Product Quality',
                  color: const Color(0xFFF59E0B),
                  value: _productQuality,
                  onChanged: (v) => setState(() => _productQuality = v),
                ),
                _RatingSlider(
                  icon: Icons.category_outlined,
                  label: 'Variety',
                  color: const Color(0xFFEF4444),
                  value: _variety,
                  onChanged: (v) => setState(() => _variety = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5EAF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: _feedbackController,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience about this shop...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Color(0xFFDDE3EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Color(0xFFDDE3EF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Color(0xFF0F65FF), width: 1.5),
                    ),
                    filled: true,
                    fillColor: Color(0xFFF8F9FF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: const Color(0xFF0F65FF),
              ),
              child: Text(
                _isSubmitting ? 'Submitting...' : 'Submit Review',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _RatingSlider extends StatelessWidget {
  const _RatingSlider({
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    thumbColor: color,
                    inactiveTrackColor: color.withOpacity(0.15),
                    overlayColor: color.withOpacity(0.1),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: value,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    onChanged: onChanged,
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
