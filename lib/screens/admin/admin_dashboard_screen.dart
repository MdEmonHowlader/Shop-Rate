import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/shop_models.dart';
import 'package:flutter_application_1/data/user_profile.dart';
import 'package:flutter_application_1/screens/auth/auth_landing_screen.dart';
import 'package:flutter_application_1/services/app_session.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<List<StructuredReview>> _pendingReviewsFuture;
  late Future<Map<String, int>> _statsFuture;
  late Future<List<Map<String, dynamic>>> _redeemRequestsFuture;
  late Future<List<UserProfile>> _usersFuture;
  late Future<List<ShopDetails>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _pendingReviewsFuture = FirebaseService.fetchPendingStructuredReviews();
    _statsFuture = FirebaseService.fetchDashboardStats();
    _redeemRequestsFuture = FirebaseService.fetchPointRedeemRequests();
    _usersFuture = FirebaseService.fetchUsers();
    _shopsFuture = FirebaseService.fetchShops();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;
    await FirebaseService.logout();
    AppSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthLandingScreen()),
      (route) => false,
    );
  }

  Future<void> _handleRedeemRequestAction({
    required String requestId,
    required bool approve,
  }) async {
    final ok = await FirebaseService.processPointRedeemRequest(
      requestId: requestId,
      approve: approve,
      adminId: AppSession.currentUser?.id ?? 'admin',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? approve ? 'Request approved' : 'Request rejected'
          : 'Could not process request'),
    ));
    if (ok) setState(_reload);
  }

  Future<void> _handleReviewModeration({
    required StructuredReview review,
    required bool approve,
  }) async {
    final ok = await FirebaseService.moderateReview(reviewId: review.id, approve: approve);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? approve ? 'Review approved' : 'Review rejected'
          : 'Could not update review'),
    ));
    if (ok) setState(_reload);
  }

  Future<void> _showAddRestaurantDialog() async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final barcodeController = TextEditingController();
    final qrCodeController = TextEditingController();
    XFile? pickedImage;
    String? imageBase64;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Add Restaurant', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image picker section
                      const Text('Restaurant Image', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 70,
                            maxWidth: 800,
                          );
                          if (img != null) {
                            final bytes = await img.readAsBytes();
                            setLocalState(() {
                              pickedImage = img;
                              imageBase64 = base64Encode(bytes);
                            });
                          }
                        },
                        child: Container(
                          height: 130,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: pickedImage != null
                                  ? const Color(0xFF0F65FF)
                                  : const Color(0xFFDDE3EF),
                              width: pickedImage != null ? 2 : 1,
                            ),
                          ),
                          child: pickedImage != null && imageBase64 != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(
                                        base64Decode(imageBase64!),
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.edit, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        color: Color(0xFF0F65FF), size: 36),
                                    SizedBox(height: 8),
                                    Text('Tap to add image',
                                        style: TextStyle(color: Color(0xFF0F65FF), fontWeight: FontWeight.w600)),
                                    SizedBox(height: 2),
                                    Text('JPEG / PNG supported',
                                        style: TextStyle(color: Colors.black45, fontSize: 11)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Restaurant Name *',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location *',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode *',
                          prefixIcon: Icon(Icons.qr_code_2_rounded),
                          hintText: 'e.g. SHOP-1001',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: qrCodeController,
                        decoration: const InputDecoration(
                          labelText: 'QR Code *',
                          prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                          hintText: 'e.g. QR-1001',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Save'),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final location = locationController.text.trim();
                    final barcode = barcodeController.text.trim();
                    final qrCode = qrCodeController.text.trim();

                    if (name.isEmpty || location.isEmpty || barcode.isEmpty || qrCode.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All fields marked * are required')),
                        );
                      }
                      return;
                    }

                    final ok = await FirebaseService.addRestaurant(
                      name: name,
                      location: location,
                      barcode: barcode,
                      qrCode: qrCode,
                      imageUrl: imageBase64 ?? '',
                    );

                    if (context.mounted) Navigator.of(context).pop(ok);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    locationController.dispose();
    barcodeController.dispose();
    qrCodeController.dispose();

    if (created == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(created
          ? 'Restaurant added successfully!'
          : 'Could not add restaurant (duplicate code or error)'),
    ));
    if (created) setState(_reload);
  }

  Future<void> _showAwardPointsDialog({UserProfile? initialUser}) async {
    final users = await FirebaseService.fetchUsers();
    if (!mounted) return;
    if (users.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No users found')));
      return;
    }

    final pointsController = TextEditingController();
    final reasonController = TextEditingController();
    UserProfile selectedUser = initialUser ?? users.first;

    final awarded = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Award Points', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                    initialValue: selectedUser.id,
                  decoration: const InputDecoration(labelText: 'User'),
                  items: users.map((u) => DropdownMenuItem(
                    value: u.id,
                    child: Text('${u.name} (${u.email})'),
                  )).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setLocalState(() => selectedUser = users.firstWhere((u) => u.id == v));
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Points'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Good quality rating and feedback',
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
                final reason = reasonController.text.trim();
                if (points == null || points <= 0 || reason.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter valid points and reason')),
                    );
                  }
                  return;
                }
                final ok = await FirebaseService.awardPointsToUser(
                  userId: selectedUser.id,
                  points: points,
                  reason: reason,
                );
                if (context.mounted) Navigator.of(context).pop(ok);
              },
              child: const Text('Award'),
            ),
          ],
        ),
      ),
    );

    pointsController.dispose();
    reasonController.dispose();
    if (awarded == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(awarded ? 'Points awarded!' : 'Could not award points'),
    ));
    if (awarded) setState(_reload);
  }

  Future<void> _showRestaurantsDialog() async {
    final shops = await FirebaseService.fetchShops();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('All Restaurants', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 460,
          child: shops.isEmpty
              ? const Text('No restaurants found')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: shops.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (_, i) => _RestaurantListTile(shop: shops[i]),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        _pendingReviewsFuture,
        _statsFuture,
        _redeemRequestsFuture,
        _usersFuture,
        _shopsFuture,
      ]),
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;

        final pendingReviews = snapshot.data != null
            ? snapshot.data![0] as List<StructuredReview>
            : const <StructuredReview>[];
        final stats = snapshot.data != null
            ? snapshot.data![1] as Map<String, int>
            : const {'totalUsers': 0, 'totalReviews': 0, 'approvedReviews': 0, 'totalShops': 0};
        final redeemRequests = snapshot.data != null
            ? snapshot.data![2] as List<Map<String, dynamic>>
            : const <Map<String, dynamic>>[];
        final users = snapshot.data != null
            ? snapshot.data![3] as List<UserProfile>
            : const <UserProfile>[];
        final shops = snapshot.data != null
            ? snapshot.data![4] as List<ShopDetails>
            : const <ShopDetails>[];

        final nonAdminUsers = users.where((u) => !u.isAdmin).toList();
        final shopMap = {for (final s in shops) s.id: s};

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
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
              _AppBarButton(
                icon: Icons.storefront_outlined,
                tooltip: 'Add restaurant',
                onTap: _showAddRestaurantDialog,
              ),
              _AppBarButton(
                icon: Icons.workspace_premium_outlined,
                tooltip: 'Award points',
                onTap: _showAwardPointsDialog,
              ),
              _AppBarButton(
                icon: Icons.list_alt_outlined,
                tooltip: 'View restaurants',
                onTap: _showRestaurantsDialog,
              ),
              _AppBarButton(
                icon: Icons.logout_rounded,
                tooltip: 'Logout',
                onTap: _logout,
              ),
            ],
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F65FF)))
              : RefreshIndicator(
                  onRefresh: () async => setState(_reload),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Stats cards
                      Row(
                        children: [
                          _StatCard(label: 'Total Users', value: '${stats['totalUsers']}', icon: Icons.people_alt_rounded, color: const Color(0xFF0F65FF)),
                          const SizedBox(width: 14),
                          _StatCard(label: 'Approved Reviews', value: '${stats['approvedReviews']}', icon: Icons.rate_review_rounded, color: const Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _StatCard(label: 'Total Shops', value: '${stats['totalShops']}', icon: Icons.storefront_rounded, color: const Color(0xFF6E3AFA)),
                          const SizedBox(width: 14),
                          _StatCard(label: 'Pending Reviews', value: '${pendingReviews.length}', icon: Icons.pending_actions_rounded, color: const Color(0xFFF59E0B)),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Pending Approvals — DYNAMIC
                      _SectionHeader(
                        title: 'Pending Approvals',
                        count: pendingReviews.length,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 12),
                      if (pendingReviews.isEmpty)
                        _EmptyCard(
                          icon: Icons.check_circle_outline_rounded,
                          message: 'All reviews have been moderated.',
                          color: const Color(0xFF10B981),
                        )
                      else
                        ...pendingReviews.map((review) {
                          final shopName = shopMap[review.shopId]?.name ?? 'Unknown Shop';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PendingReviewCard(
                              review: review,
                              shopName: shopName,
                              onApprove: () => _handleReviewModeration(review: review, approve: true),
                              onReject: () => _handleReviewModeration(review: review, approve: false),
                            ),
                          );
                        }),
                      const SizedBox(height: 28),

                      // Point Redeem Requests
                      _SectionHeader(
                        title: 'Point Redeem Requests',
                        count: redeemRequests.where((r) => r['status'] == 'pending').length,
                        color: const Color(0xFF0F65FF),
                      ),
                      const SizedBox(height: 12),
                      if (redeemRequests.isEmpty)
                        _EmptyCard(
                          icon: Icons.redeem_outlined,
                          message: 'No redeem requests yet.',
                          color: const Color(0xFF0F65FF),
                        )
                      else
                        ...redeemRequests.map((request) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RedeemRequestTile(
                            request: request,
                            onApprove: () => _handleRedeemRequestAction(
                              requestId: request['id'] as String,
                              approve: true,
                            ),
                            onReject: () => _handleRedeemRequestAction(
                              requestId: request['id'] as String,
                              approve: false,
                            ),
                          ),
                        )),
                      const SizedBox(height: 28),

                      // Users & Premium
                      _SectionHeader(
                        title: 'Users & Premium Status',
                        count: nonAdminUsers.length,
                        color: const Color(0xFF6E3AFA),
                      ),
                      const SizedBox(height: 12),
                      if (nonAdminUsers.isEmpty)
                        _EmptyCard(
                          icon: Icons.people_outline_rounded,
                          message: 'No users found.',
                          color: const Color(0xFF6E3AFA),
                        )
                      else
                        ...nonAdminUsers.map((user) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _UserPremiumTile(
                            user: user,
                            onSendPoints: () => _showAwardPointsDialog(initialUser: user),
                          ),
                        )),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      tooltip: tooltip,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count, required this.color});
  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message, required this.color});
  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF6B7280)))),
        ],
      ),
    );
  }
}

class _PendingReviewCard extends StatelessWidget {
  const _PendingReviewCard({
    required this.review,
    required this.shopName,
    required this.onApprove,
    required this.onReject,
  });

  final StructuredReview review;
  final String shopName;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE082)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shopName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(
                      '${review.userName}  •  ${review.overallRating.toStringAsFixed(1)} ⭐',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ],
          ),
          if (review.feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.feedback,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF4A5568), fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestaurantListTile extends StatelessWidget {
  const _RestaurantListTile({required this.shop});
  final ShopDetails shop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _shopImage(shop),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shop.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(shop.location, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              Text(
                'Code: ${shop.barcode} / ${shop.qrCode}',
                style: const TextStyle(color: Colors.black38, fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                const SizedBox(width: 3),
                Text(shop.averageRating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            Text('${shop.reviewsCount} reviews',
                style: const TextStyle(color: Colors.black45, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _shopImage(ShopDetails shop) {
    if (shop.imageUrl.isNotEmpty) {
      if (shop.imageUrl.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(shop.imageUrl, width: 44, height: 44, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder()),
        );
      } else {
        try {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(base64Decode(shop.imageUrl), width: 44, height: 44, fit: BoxFit.cover),
          );
        } catch (_) {}
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F65FF), Color(0xFF6E3AFA)]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          shop.name.isNotEmpty ? shop.name[0].toUpperCase() : 'S',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _RedeemRequestTile extends StatelessWidget {
  const _RedeemRequestTile({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final userName = request['userName'] as String? ?? 'Unknown';
    final userEmail = request['userEmail'] as String? ?? '';
    final points = request['requestedPoints'] as int? ?? 0;
    final note = request['note'] as String? ?? '';
    final status = request['status'] as String? ?? 'pending';
    final isPending = status == 'pending';

    Color statusColor;
    Color statusBg;
    if (status == 'approved') {
      statusColor = const Color(0xFF10B981);
      statusBg = const Color(0xFFD1FAE5);
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusBg = const Color(0xFFFFE4E4);
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusBg = const Color(0xFFFFF3CD);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$userName ($userEmail)',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('$points points requested',
                        style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Note: $note', style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UserPremiumTile extends StatelessWidget {
  const _UserPremiumTile({required this.user, required this.onSendPoints});
  final UserProfile user;
  final VoidCallback onSendPoints;

  @override
  Widget build(BuildContext context) {
    final premium = user.points > 50;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: premium
                    ? [const Color(0xFF0F65FF), const Color(0xFF6E3AFA)]
                    : [const Color(0xFF9CA3AF), const Color(0xFFD1D5DB)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.name} (${user.email})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  'Points: ${user.points}  •  ${premium ? '⭐ Premium' : 'Standard'}',
                  style: TextStyle(
                    color: premium ? const Color(0xFF0F65FF) : Colors.black45,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onSendPoints,
            icon: const Icon(Icons.send_rounded, size: 14),
            label: const Text('Award', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
