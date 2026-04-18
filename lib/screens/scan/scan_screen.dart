import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/shop_models.dart';
import 'package:flutter_application_1/services/app_session.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _codeController = TextEditingController();
  final _manualSearchController = TextEditingController();
  Timer? _manualSearchDebounce;
  List<ShopDetails> _manualSearchResults = const [];
  bool _isSearching = false;
  bool _isManualSearching = false;
  bool _manualSearchTriggered = false;

  @override
  void dispose() {
    _manualSearchDebounce?.cancel();
    _codeController.dispose();
    _manualSearchController.dispose();
    super.dispose();
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

  Future<void> _openManualReviewPage(
    BuildContext hostContext,
    ShopDetails shop,
  ) async {
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
      appBar: AppBar(title: const Text('Scan Or Search'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E5F2)),
            ),
            child: Column(
              children: [
                const Text(
                  'Scan Code Search',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You can still scan barcode/QR or enter the code manually.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode / QR code',
                    hintText: 'Example: SHOP-1001 or QR-1001',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _searchShop,
                    child: Text(_isSearching ? 'Searching...' : 'Find By Code'),
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
              border: Border.all(color: const Color(0xFFE0E5F2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search Shop Without Scan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Search by shop name, location, barcode, or QR code. Then open details and submit review manually.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Live suggestions appear while typing.',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
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
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isManualSearching ? null : _searchShopManually,
                    icon: const Icon(Icons.search),
                    label: Text(
                      _isManualSearching ? 'Searching...' : 'Search Shop',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_manualSearchTriggered && _manualSearchResults.isEmpty)
                  const Text(
                    'No shop found for this query.',
                    style: TextStyle(color: Colors.black54),
                  )
                else
                  ..._manualSearchResults.map(
                    (shop) => Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.storefront_outlined),
                        title: Text(shop.name),
                        subtitle: Text(
                          '${shop.location}\nRating ${shop.averageRating.toStringAsFixed(1)} • ${shop.reviewsCount} reviews',
                        ),
                        isThreeLine: true,
                        trailing: TextButton(
                          onPressed: () => _openShopDetails(shop),
                          child: const Text('View'),
                        ),
                      ),
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

class _ShopDetailsPage extends StatelessWidget {
  const _ShopDetailsPage({
    required this.shop,
    required this.reviews,
    required this.onWriteReview,
  });

  final ShopDetails shop;
  final List<StructuredReview> reviews;
  final Future<void> Function(BuildContext hostContext, ShopDetails shop)
  onWriteReview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shop.name), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            shop.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(shop.location, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFB300)),
                const SizedBox(width: 8),
                Text(
                  '${shop.averageRating.toStringAsFixed(1)} (${shop.reviewsCount} reviews)',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rating Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Service ${shop.ratingBreakdown['service']?.toStringAsFixed(1) ?? '0.0'} • '
            'Cleanliness ${shop.ratingBreakdown['cleanliness']?.toStringAsFixed(1) ?? '0.0'} • '
            'Staff ${shop.ratingBreakdown['staffBehavior']?.toStringAsFixed(1) ?? '0.0'} • '
            'Quality ${shop.ratingBreakdown['productQuality']?.toStringAsFixed(1) ?? '0.0'} • '
            'Variety ${shop.ratingBreakdown['variety']?.toStringAsFixed(1) ?? '0.0'}',
          ),
          const SizedBox(height: 16),
          const Text(
            'Recent Feedback',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (reviews.isEmpty)
            const Text('No feedback available yet.')
          else
            ...reviews
                .take(5)
                .map(
                  (review) => Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.reviews_outlined),
                      title: Text(review.userName),
                      subtitle: Text(review.feedback),
                    ),
                  ),
                ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onWriteReview(context, shop),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Write Review Manually'),
            ),
          ),
        ],
      ),
    );
  }
}

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please write feedback')));
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
      appBar: AppBar(title: Text('Review: ${widget.shop.name}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _RatingSlider(
            label: 'Service',
            value: _service,
            onChanged: (value) => setState(() => _service = value),
          ),
          _RatingSlider(
            label: 'Cleanliness',
            value: _cleanliness,
            onChanged: (value) => setState(() => _cleanliness = value),
          ),
          _RatingSlider(
            label: 'Staff Behavior',
            value: _staffBehavior,
            onChanged: (value) => setState(() => _staffBehavior = value),
          ),
          _RatingSlider(
            label: 'Product Quality',
            value: _productQuality,
            onChanged: (value) => setState(() => _productQuality = value),
          ),
          _RatingSlider(
            label: 'Variety',
            value: _variety,
            onChanged: (value) => setState(() => _variety = value),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Feedback',
              hintText: 'Share your experience',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Submitting...' : 'Submit Review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSlider extends StatelessWidget {
  const _RatingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}'),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 8,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
