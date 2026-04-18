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
  late final Future<List<ReviewEntry>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = FirebaseService.fetchReviews();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReviewEntry>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? reviewData;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Community Reviews'),
            centerTitle: true,
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final review = reviews[index % reviews.length];
              return ReviewTile(review: review, elevated: true);
            },
            separatorBuilder: (context, _) => const SizedBox(height: 16),
            itemCount: reviews.length < 8 ? reviews.length : 8,
          ),
        );
      },
    );
  }
}
