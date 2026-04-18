import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/sample_data.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
            title: const Text('Admin Dashboard'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatCard(
                      label: 'Active Users',
                      value: '${reviews.length}',
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      label: 'Reviews Today',
                      value: '${reviews.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pending Approvals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (_, index) {
                      final review = reviews[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0x260F65FF),
                            child: Text(review.user[0]),
                          ),
                          title: Text(review.title),
                          subtitle: Text('${review.user} • ${review.timeAgo}'),
                          trailing: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
