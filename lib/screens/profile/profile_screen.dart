import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/sample_data.dart';
import 'package:flutter_application_1/data/user_profile.dart';
import 'package:flutter_application_1/screens/auth/auth_landing_screen.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/services/app_session.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/review_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _latestUser;

  UserProfile? get _user => _latestUser ?? AppSession.currentUser;

  @override
  void initState() {
    super.initState();
    _refreshUserProfile();
  }

  Future<void> _refreshUserProfile() async {
    final sessionUser = AppSession.currentUser;
    if (sessionUser == null) return;

    final updatedUser = await FirebaseService.fetchUserById(sessionUser.id);
    if (!mounted || updatedUser == null) return;

    AppSession.setUser(updatedUser);
    setState(() => _latestUser = updatedUser);
  }

  Future<void> _showPointRedeemRequestDialog() async {
    final user = _user;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    final pointsController = TextEditingController();
    final noteController = TextEditingController();

    final sent = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Redeem Points Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Available Points: ${user.points}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Request will be sent to admin@email.com and appear in admin dashboard.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Redeem Points',
                    hintText: 'Example: 50',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'Bkash withdrawal request',
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
                final points = int.tryParse(pointsController.text.trim());
                if (points == null || points <= 0 || points > user.points) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter valid points within available balance',
                        ),
                      ),
                    );
                  }
                  return;
                }

                final ok = await FirebaseService.submitPointRedeemRequest(
                  userId: user.id,
                  points: points,
                  note: noteController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.of(context).pop(ok);
                }
              },
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );

    pointsController.dispose();
    noteController.dispose();

    if (sent == null) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Request sent to admin and added to admin dashboard'
              : 'Could not submit request',
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseService.logout();
    AppSession.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthLandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = _user?.points ?? 0;
    final premiumActive = points > 50;
    final displayName = _user?.name ?? 'John Doe';
    final displayEmail = _user?.email ?? 'john.doe@email.com';
    final avatarText = displayName.isNotEmpty
        ? displayName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join()
        : 'JD';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () => _logout(context),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUserProfile,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFE0E7FF),
                    child: Text(
                      avatarText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F65FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _StatRow(user: _user),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MembershipCard(isPremium: premiumActive, points: points),
            const SizedBox(height: 16),
            _RedeemRequestCard(onRequestTap: _showPointRedeemRequestDialog),
            const SizedBox(height: 24),
            const Text(
              'Your Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...reviewData.take(3).map((review) => ReviewTile(review: review)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F65FF), Color(0xFF4BB0FF)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Achievements',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  _AchievementRow(
                    title: 'Top Reviewer',
                    subtitle: '50+ reviews submitted',
                  ),
                  SizedBox(height: 12),
                  _AchievementRow(
                    title: 'Helpful Reviewer',
                    subtitle: '100+ helpful votes',
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

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.isPremium, required this.points});

  final bool isPremium;
  final int points;

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F65FF), Color(0xFF4BB0FF)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Premium profile active • Your reviews appear first and badges update in real time.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E5F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium profile inactive',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Premium becomes active when points are greater than 50. Your current points: $points',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Earn more points'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedeemRequestCard extends StatelessWidget {
  const _RedeemRequestCard({required this.onRequestTap});

  final VoidCallback onRequestTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E5F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need to redeem your points?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a redeem request to admin. Admin will review it from dashboard and approve or reject.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRequestTap,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Request Redeem'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.user});

  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    const stats = [
      {'label': 'Total Reviews', 'key': 'totalReviews'},
      {'label': 'Points', 'key': 'points'},
      {'label': 'Rank', 'key': 'rank'},
    ];

    final values = {
      'totalReviews': '${user?.totalReviews ?? 47}',
      'points': '${user?.points ?? 0}',
      'rank': user?.rank ?? '#234',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stats
          .map(
            (stat) => Column(
              children: [
                Text(
                  values[stat['key']]!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['label']!,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.emoji_events, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }
}
