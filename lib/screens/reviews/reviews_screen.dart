import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/sample_data.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/review_tile.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late Future<List<ReviewEntry>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = FirebaseService.fetchReviews();
  }

  Future<void> _refresh() async {
    setState(() {
      _reviewsFuture = FirebaseService.fetchReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReviewEntry>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final reviews = snapshot.data ?? reviewData;
        final avgRating = reviews.isEmpty
            ? 0.0
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Community Reviews'),
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
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _ReviewsSummaryCard(reviewCount: reviews.length, avgRating: avgRating),
                const SizedBox(height: 18),
                _RatingCategoryRow(),
                const SizedBox(height: 18),
                if (loading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF0F65FF)),
                  ))
                else if (reviews.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE7EBF2)),
                    ),
                    child: const Text(
                      'No community reviews yet.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  ...reviews.map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ReviewTile(
                        review: review,
                        elevated: true,
                        onTap: () => _showReviewDetails(context, review),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReviewDetails(BuildContext context, ReviewEntry review) {
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
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header gradient card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x440F65FF),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.person_outline, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(review.user, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.schedule_rounded, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(review.timeAgo, style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Star display with count
                        Row(
                          children: [
                            ...List.generate(5, (i) => Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(
                                review.rating >= i + 1
                                    ? Icons.star_rounded
                                    : review.rating >= i + 0.5
                                        ? Icons.star_half_rounded
                                        : Icons.star_border_rounded,
                                color: const Color(0xFFFFD700),
                                size: 24,
                              ),
                            )),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${review.rating.toStringAsFixed(1)} / 5.0',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Review details section
                  const Text(
                    'Review',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F1A33)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5EAF3)),
                    ),
                    child: Text(
                      review.detail,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4A5568),
                        height: 1.65,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Category overview with icons
                  const Text(
                    'Rating Categories',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F1A33)),
                  ),
                  const SizedBox(height: 12),
                  _ReviewCategoryGrid(rating: review.rating),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewCategoryGrid extends StatelessWidget {
  const _ReviewCategoryGrid({required this.rating});

  final double rating;

  static const List<Map<String, dynamic>> _categories = [
    {'icon': Icons.room_service_outlined, 'label': 'Service', 'color': Color(0xFF0F65FF)},
    {'icon': Icons.cleaning_services_outlined, 'label': 'Cleanliness', 'color': Color(0xFF10B981)},
    {'icon': Icons.support_agent_outlined, 'label': 'Staff', 'color': Color(0xFF6E3AFA)},
    {'icon': Icons.verified_outlined, 'label': 'Quality', 'color': Color(0xFFF59E0B)},
    {'icon': Icons.category_outlined, 'label': 'Variety', 'color': Color(0xFFEF4444)},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: _categories.map((cat) {
        final color = cat['color'] as Color;
        return Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cat['icon'] as IconData, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                cat['label'] as String,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RatingCategoryRow extends StatelessWidget {
  const _RatingCategoryRow();

  static const List<Map<String, dynamic>> _categories = [
    {'icon': Icons.room_service_outlined, 'label': 'Service', 'color': Color(0xFF0F65FF)},
    {'icon': Icons.cleaning_services_outlined, 'label': 'Cleanliness', 'color': Color(0xFF10B981)},
    {'icon': Icons.support_agent_outlined, 'label': 'Staff', 'color': Color(0xFF6E3AFA)},
    {'icon': Icons.verified_outlined, 'label': 'Quality', 'color': Color(0xFFF59E0B)},
    {'icon': Icons.category_outlined, 'label': 'Variety', 'color': Color(0xFFEF4444)},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Categories',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F1A33)),
        ),
        const SizedBox(height: 10),
        Row(
          children: _categories.map((cat) {
            final color = cat['color'] as Color;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(cat['icon'] as IconData, color: color, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ReviewsSummaryCard extends StatelessWidget {
  const _ReviewsSummaryCard({required this.reviewCount, required this.avgRating});

  final int reviewCount;
  final double avgRating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x440F65FF), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Community sentiment',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 6),
                Text(
                  'What shoppers say',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Star icons with rating
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                    avgRating >= i + 1
                        ? Icons.star_rounded
                        : avgRating >= i + 0.5
                            ? Icons.star_half_rounded
                            : Icons.star_border_rounded,
                    color: const Color(0xFFFFD700),
                    size: 18,
                  )),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$reviewCount reviews',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
