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
  bool _isSearching = false;

  @override
  void dispose() {
    _codeController.dispose();
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

    final reviews = await FirebaseService.fetchStructuredReviews(shop.id);
    if (!mounted) return;
    _showShopDetails(shop, reviews);
  }

  void _showShopDetails(ShopDetails shop, List<StructuredReview> reviews) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shop.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                shop.location,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFB300)),
                  const SizedBox(width: 6),
                  Text(
                    '${shop.averageRating.toStringAsFixed(1)} (${shop.reviewsCount} reviews)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Service ${shop.ratingBreakdown['service']?.toStringAsFixed(1) ?? '0.0'} • '
                'Cleanliness ${shop.ratingBreakdown['cleanliness']?.toStringAsFixed(1) ?? '0.0'} • '
                'Staff ${shop.ratingBreakdown['staffBehavior']?.toStringAsFixed(1) ?? '0.0'}',
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recent Feedback',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (reviews.isEmpty)
                const Text('No feedback available yet.')
              else
                ...reviews
                    .take(2)
                    .map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('- ${review.userName}: ${review.feedback}'),
                      ),
                    ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showManualReviewDialog(shop);
                  },
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Write Review Manually'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showManualReviewDialog(ShopDetails shop) async {
    final feedbackController = TextEditingController();
    double service = 4;
    double cleanliness = 4;
    double staffBehavior = 4;
    double productQuality = 4;
    double variety = 4;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text('Review: ${shop.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RatingSlider(
                      label: 'Service',
                      value: service,
                      onChanged: (value) =>
                          setLocalState(() => service = value),
                    ),
                    _RatingSlider(
                      label: 'Cleanliness',
                      value: cleanliness,
                      onChanged: (value) =>
                          setLocalState(() => cleanliness = value),
                    ),
                    _RatingSlider(
                      label: 'Staff Behavior',
                      value: staffBehavior,
                      onChanged: (value) =>
                          setLocalState(() => staffBehavior = value),
                    ),
                    _RatingSlider(
                      label: 'Product Quality',
                      value: productQuality,
                      onChanged: (value) =>
                          setLocalState(() => productQuality = value),
                    ),
                    _RatingSlider(
                      label: 'Variety',
                      value: variety,
                      onChanged: (value) =>
                          setLocalState(() => variety = value),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Feedback',
                        hintText: 'Share your experience',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final feedback = feedbackController.text.trim();
                    if (feedback.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please write feedback'),
                          ),
                        );
                      }
                      return;
                    }

                    final user = AppSession.currentUser;
                    final ok = await FirebaseService.submitStructuredReview(
                      shopId: shop.id,
                      userId: user?.id ?? 'guest_user',
                      userName: user?.name ?? 'Guest User',
                      service: service,
                      cleanliness: cleanliness,
                      staffBehavior: staffBehavior,
                      productQuality: productQuality,
                      variety: variety,
                      feedback: feedback,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop(ok);
                    }
                  },
                  child: const Text('Submit Review'),
                ),
              ],
            );
          },
        );
      },
    );

    feedbackController.dispose();

    if (!mounted || submitted == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
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
      appBar: AppBar(title: const Text('Scan'), centerTitle: true),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF0F65FF),
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Position the barcode within the frame',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Make sure the barcode is clearly visible',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode / QR code',
                      hintText: 'Try SHOP-1001 or QR-1001',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSearching ? null : _searchShop,
                      child: Text(_isSearching ? 'Searching...' : 'Find Shop'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
