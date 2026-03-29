import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/sample_data.dart';
import 'package:flutter_application_1/widgets/review_tile.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Reviews'), centerTitle: true),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          final review = reviewData[index % reviewData.length];
          return ReviewTile(review: review, elevated: true);
        },
        separatorBuilder: (context, _) => const SizedBox(height: 16),
        itemCount: 8,
      ),
    );
  }
}
