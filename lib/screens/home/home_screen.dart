import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/sample_data.dart';
import 'package:flutter_application_1/data/shop_models.dart';
import 'package:flutter_application_1/services/app_session.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/review_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<_HomePayload> _payload;

  @override
  void initState() {
    super.initState();
    _payload = _load();
  }

  Future<_HomePayload> _load() async {
    final shops = await FirebaseService.fetchShops();
    final user = AppSession.currentUser;
    final userReviews = user != null
        ? await FirebaseService.fetchUserReviews(user.id)
        : await FirebaseService.fetchReviews();
    final allReviews = await FirebaseService.fetchReviews();

    // Sort shops by averageRating descending
    final sortedShops = [...shops]
      ..sort((a, b) => b.averageRating.compareTo(a.averageRating));

    return _HomePayload(
      shops: sortedShops,
      userReviews: userReviews.isEmpty ? allReviews : userReviews,
      allReviews: allReviews,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      // Re-trigger future by rebuilding
    });
  }

  void _showReviewDetails(ReviewEntry review) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(review.user, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 14),
                            const Icon(Icons.schedule_rounded, size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(review.timeAgo, style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                              review.rating >= i + 1 ? Icons.star_rounded : Icons.star_border_rounded,
                              color: const Color(0xFFFFD700),
                              size: 22,
                            )),
                            const SizedBox(width: 8),
                            Text(
                              '${review.rating.toStringAsFixed(1)} / 5.0',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Review Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1C1E)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    review.detail,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4A5568),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomePayload>(
      future: _payload,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final shops = snapshot.data?.shops ?? [];
        final userReviews = snapshot.data?.userReviews ?? reviewData;

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discover & Review',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'ShopRate',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F1A33)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Hero banner
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x440F65FF),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Scan Shop Barcode',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Rate your shopping experience',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 34),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Recent Reviews
                  _SectionHeader(title: 'Your Recent Reviews', onViewAll: () {}),
                  const SizedBox(height: 12),
                  if (loading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Color(0xFF0F65FF)),
                    ))
                  else if (userReviews.isEmpty)
                    _EmptyCard(
                      icon: Icons.rate_review_outlined,
                      message: 'No reviews yet. Scan a shop to get started!',
                    )
                  else
                    ...userReviews.take(3).map((review) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ReviewTile(
                        review: review,
                        onTap: () => _showReviewDetails(review),
                      ),
                    )),

                  const SizedBox(height: 28),

                  // Top Rated Nearby - vertical list sorted by rating
                  _SectionHeader(title: 'Top Rated Nearby', onViewAll: () {}),
                  const SizedBox(height: 4),
                  Text(
                    'Sorted by highest ratings',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  if (loading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Color(0xFF0F65FF)),
                    ))
                  else if (shops.isEmpty)
                    _EmptyCard(
                      icon: Icons.storefront_outlined,
                      message: 'No shops found nearby.',
                    )
                  else
                    ...shops.take(6).map((shop) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ShopListCard(shop: shop),
                    )),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomePayload {
  const _HomePayload({
    required this.shops,
    required this.userReviews,
    required this.allReviews,
  });

  final List<ShopDetails> shops;
  final List<ReviewEntry> userReviews;
  final List<ReviewEntry> allReviews;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F1A33)),
        ),
        const Spacer(),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'View all',
                style: TextStyle(color: Color(0xFF0F65FF), fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0F65FF), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(message, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _ShopListCard extends StatelessWidget {
  const _ShopListCard({required this.shop});

  final ShopDetails shop;

  @override
  Widget build(BuildContext context) {
    final rating = shop.averageRating;
    final ratingColor = rating >= 4.5
        ? const Color(0xFF10B981)
        : rating >= 4.0
            ? const Color(0xFF0F65FF)
            : const Color(0xFFFFB300);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EDF5)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _ShopAvatar(shop: shop, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F1A33)),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF8A93A6)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        shop.location,
                        style: const TextStyle(color: Color(0xFF8A93A6), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(5, (i) => Icon(
                      shop.averageRating >= i + 1
                          ? Icons.star_rounded
                          : shop.averageRating >= i + 0.5
                              ? Icons.star_half_rounded
                              : Icons.star_border_rounded,
                      color: const Color(0xFFFFB300),
                      size: 14,
                    )),
                    const SizedBox(width: 6),
                    Text(
                      shop.averageRating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F1A33)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${shop.reviewsCount} reviews)',
                      style: const TextStyle(color: Color(0xFF8A93A6), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ratingColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                color: ratingColor,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopAvatar extends StatelessWidget {
  const _ShopAvatar({required this.shop, this.size = 48});

  final ShopDetails shop;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (shop.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: SizedBox(
          width: size,
          height: size,
          child: shop.imageUrl.startsWith('http')
              ? Image.network(shop.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(size))
              : _base64Image(shop.imageUrl, size),
        ),
      );
    }
    return _placeholder(size);
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Text(
          shop.name.isNotEmpty ? shop.name[0].toUpperCase() : 'S',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  Widget _base64Image(String b64, double size) {
    try {
      final bytes = base64Decode(b64);
      return Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
    } catch (_) {
      return _placeholder(size);
    }
  }
}
