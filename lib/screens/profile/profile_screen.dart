import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/user_profile.dart';
import 'package:flutter_application_1/screens/auth/auth_landing_screen.dart';
import 'package:flutter_application_1/services/app_session.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/data/sample_data.dart';
import 'package:flutter_application_1/widgets/review_tile.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _latestUser;
  List<ReviewEntry> _userReviews = const [];
  bool _reviewsLoading = true;

  UserProfile? get _user => _latestUser ?? AppSession.currentUser;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await _refreshUserProfile();
    await _loadUserReviews();
  }

  Future<void> _refreshUserProfile() async {
    final sessionUser = AppSession.currentUser;
    if (sessionUser == null) return;
    final updatedUser = await FirebaseService.fetchUserById(sessionUser.id);
    if (!mounted || updatedUser == null) return;
    AppSession.setUser(updatedUser);
    setState(() => _latestUser = updatedUser);
  }

  Future<void> _loadUserReviews() async {
    final user = _user;
    if (!mounted) return;
    setState(() => _reviewsLoading = true);
    List<ReviewEntry> reviews;
    if (user != null) {
      reviews = await FirebaseService.fetchUserReviews(user.id);
    } else {
      reviews = reviewData;
    }
    if (!mounted) return;
    setState(() {
      _userReviews = reviews;
      _reviewsLoading = false;
    });
  }

  Future<void> _updateProfilePhoto() async {
    final user = _user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (photo == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading photo...')),
    );

    final bytes = await photo.readAsBytes();
    final encoded = base64Encode(bytes);
    final ok = await FirebaseService.updateUserAvatar(userId: user.id, avatarBase64: encoded);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update profile photo')),
      );
      return;
    }

    final refreshed = user.copyWith(avatarBase64: encoded);
    AppSession.setUser(refreshed);
    setState(() => _latestUser = refreshed);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo updated!')),
    );
  }

  Future<void> _showPointRedeemRequestDialog() async {
    final user = _user;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    final pointsController = TextEditingController();
    final noteController = TextEditingController();

    final sent = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Redeem Points', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Available: ${user.points} points',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Points to Redeem', hintText: 'e.g. 50'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'Bkash withdrawal'),
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
                      const SnackBar(content: Text('Enter valid points within available balance')),
                    );
                  }
                  return;
                }
                final ok = await FirebaseService.submitPointRedeemRequest(
                  userId: user.id,
                  points: points,
                  note: noteController.text.trim(),
                );
                if (context.mounted) Navigator.of(context).pop(ok);
              },
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );

    pointsController.dispose();
    noteController.dispose();
    if (sent == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sent ? 'Request sent to admin!' : 'Could not submit request')),
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
                        Text(review.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text('${review.user} • ${review.timeAgo}',
                            style: const TextStyle(color: Colors.white70)),
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
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                      review.detail,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF4A5568), height: 1.6),
                    ),
                  ),
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
    final points = _user?.points ?? 0;
    final premiumActive = points > 50;
    final displayName = _user?.name ?? 'Guest User';
    final displayEmail = _user?.email ?? '';
    final avatarBase64 = _user?.avatarBase64 ?? '';
    final avatarText = displayName.trim().split(RegExp(r'\s+')).take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        actions: [
          TextButton(
            onPressed: () => _logout(context),
            child: const Text('Logout', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile card with avatar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with edit button
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _updateProfilePhoto,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: avatarBase64.isEmpty
                                ? const LinearGradient(
                                    colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            image: avatarBase64.isNotEmpty
                                ? DecorationImage(
                                    image: MemoryImage(base64Decode(avatarBase64)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: const [
                              BoxShadow(color: Color(0x330F65FF), blurRadius: 16, offset: Offset(0, 6)),
                            ],
                          ),
                          child: avatarBase64.isEmpty
                              ? Center(
                                  child: Text(
                                    avatarText,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _updateProfilePhoto,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F1A33)),
                  ),
                  const SizedBox(height: 4),
                  Text(displayEmail, style: const TextStyle(color: Color(0xFF8A93A6), fontSize: 13)),
                  const SizedBox(height: 16),
                  // Upload photo button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _updateProfilePhoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Change Profile Photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F65FF),
                        side: const BorderSide(color: Color(0xFF0F65FF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Reviews', value: '${_user?.totalReviews ?? _userReviews.length}'),
                        _Divider(),
                        _StatItem(label: 'Points', value: '$points'),
                        _Divider(),
                        _StatItem(label: 'Rank', value: _user?.rank ?? '#--'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Membership card
            if (premiumActive)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x440F65FF), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Premium Active',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Your reviews appear first • Badges update in real-time',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE0E5F2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.workspace_premium_outlined, color: Color(0xFF6E3AFA)),
                        SizedBox(width: 10),
                        Text('Premium Inactive', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Earn more than 50 points to activate premium. Current: $points pts',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (points / 50).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFE0E5F2),
                      color: const Color(0xFF0F65FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Redeem card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0E5F2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.redeem_outlined, color: Color(0xFF0F65FF)),
                      SizedBox(width: 10),
                      Text('Redeem Points', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Send a request to admin to redeem your earned points.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showPointRedeemRequestDialog,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Request Redeem'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // My Reviews section
            Row(
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
                const Text('My Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (!_reviewsLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_userReviews.length}',
                      style: const TextStyle(color: Color(0xFF0F65FF), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_reviewsLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF0F65FF)),
              ))
            else if (_userReviews.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE7EBF2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.rate_review_outlined, color: Color(0xFF0F65FF)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No reviews yet. Scan a shop and share your experience!',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._userReviews.map((review) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReviewTile(
                  review: review,
                  onTap: () => _showReviewDetails(review),
                ),
              )),
            const SizedBox(height: 24),

            // Achievements
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Color(0x440F65FF), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Achievements', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  _AchievementRow(
                    title: 'Top Reviewer',
                    subtitle: '50+ reviews submitted',
                    icon: Icons.emoji_events_rounded,
                    locked: ((_user?.totalReviews ?? 0) < 50),
                  ),
                  const SizedBox(height: 10),
                  _AchievementRow(
                    title: 'Helpful Reviewer',
                    subtitle: '100+ helpful votes',
                    icon: Icons.thumb_up_rounded,
                    locked: ((_user?.helpfulVotes ?? 0) < 100),
                  ),
                  const SizedBox(height: 10),
                  _AchievementRow(
                    title: 'Premium Member',
                    subtitle: 'Earned 50+ points',
                    icon: Icons.workspace_premium_rounded,
                    locked: !premiumActive,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: const Color(0xFFD1D9EF));
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F1A33))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF8A93A6), fontSize: 12)),
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(locked ? Icons.lock_outline_rounded : icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (!locked)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF6DFFB3), size: 20),
        ],
      ),
    );
  }
}
