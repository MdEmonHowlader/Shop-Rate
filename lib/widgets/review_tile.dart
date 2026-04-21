import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/sample_data.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({
    super.key,
    required this.review,
    this.elevated = false,
    this.onTap,
  });

  final ReviewEntry review;
  final bool elevated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final userInitial = review.user.trim().isEmpty ? 'A' : review.user.trim().toUpperCase()[0];
    final ratingColor = review.rating >= 4.5
        ? const Color(0xFF10B981)
        : review.rating >= 4.0
            ? const Color(0xFF0F65FF)
            : const Color(0xFFFFB300);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEF0F8)),
            boxShadow: elevated
                ? const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Gradient avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.user,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF0F1A33),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 3),
                            Text(
                              review.timeAgo,
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Rating badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ratingColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: ratingColor, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ratingColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 5 star icons
              Row(
                children: List.generate(5, (i) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    review.rating >= i + 1
                        ? Icons.star_rounded
                        : review.rating >= i + 0.5
                            ? Icons.star_half_rounded
                            : Icons.star_border_rounded,
                    color: const Color(0xFFFFB300),
                    size: 15,
                  ),
                )),
              ),
              const SizedBox(height: 10),
              Text(
                review.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F1A33),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                review.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.4),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Text(
                      'Tap to view full review',
                      style: TextStyle(
                        color: Color(0xFF0F65FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F65FF), size: 14),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
