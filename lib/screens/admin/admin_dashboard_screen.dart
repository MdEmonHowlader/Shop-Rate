import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/sample_data.dart';
import 'package:flutter_application_1/data/shop_models.dart';
import 'package:flutter_application_1/data/user_profile.dart';
import 'package:flutter_application_1/screens/auth/auth_landing_screen.dart';
import 'package:flutter_application_1/services/app_session.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<List<ReviewEntry>> _reviewsFuture;
  late Future<Map<String, int>> _statsFuture;
  late Future<List<Map<String, dynamic>>> _redeemRequestsFuture;
  late Future<List<UserProfile>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _reviewsFuture = FirebaseService.fetchReviews();
    _statsFuture = FirebaseService.fetchDashboardStats();
    _redeemRequestsFuture = FirebaseService.fetchPointRedeemRequests();
    _usersFuture = FirebaseService.fetchUsers();
  }

  Future<void> _logout() async {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? approve
                    ? 'Redeem request approved'
                    : 'Redeem request rejected'
              : 'Could not process redeem request',
        ),
      ),
    );

    if (ok) {
      setState(_reload);
    }
  }

  Future<void> _showAddRestaurantDialog() async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final barcodeController = TextEditingController();
    final qrCodeController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Restaurant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(labelText: 'Barcode'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: qrCodeController,
                  decoration: const InputDecoration(labelText: 'QR Code'),
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
                final name = nameController.text.trim();
                final location = locationController.text.trim();
                final barcode = barcodeController.text.trim();
                final qrCode = qrCodeController.text.trim();

                if (name.isEmpty ||
                    location.isEmpty ||
                    barcode.isEmpty ||
                    qrCode.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All fields are required')),
                    );
                  }
                  return;
                }

                final ok = await FirebaseService.addRestaurant(
                  name: name,
                  location: location,
                  barcode: barcode,
                  qrCode: qrCode,
                );

                if (context.mounted) {
                  Navigator.of(context).pop(ok);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    locationController.dispose();
    barcodeController.dispose();
    qrCodeController.dispose();

    if (created == null) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? 'Restaurant added successfully'
              : 'Could not add restaurant (duplicate barcode/QR or API issue)',
        ),
      ),
    );

    if (created) {
      setState(_reload);
    }
  }

  Future<void> _showAwardPointsDialog({UserProfile? initialUser}) async {
    final users = await FirebaseService.fetchUsers();
    if (!mounted) return;

    if (users.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No users found to reward')));
      return;
    }

    final pointsController = TextEditingController();
    final reasonController = TextEditingController();
    UserProfile selectedUser = initialUser ?? users.first;

    final awarded = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Award Points'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedUser.id,
                      decoration: const InputDecoration(labelText: 'User'),
                      items: users
                          .map(
                            (user) => DropdownMenuItem<String>(
                              value: user.id,
                              child: Text('${user.name} (${user.email})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final found = users.firstWhere(
                          (user) => user.id == value,
                        );
                        setLocalState(() => selectedUser = found);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Points'),
                    ),
                    const SizedBox(height: 8),
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
                          const SnackBar(
                            content: Text('Enter valid points and reason'),
                          ),
                        );
                      }
                      return;
                    }

                    final ok = await FirebaseService.awardPointsToUser(
                      userId: selectedUser.id,
                      points: points,
                      reason: reason,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop(ok);
                    }
                  },
                  child: const Text('Award'),
                ),
              ],
            );
          },
        );
      },
    );

    pointsController.dispose();
    reasonController.dispose();

    if (awarded == null) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          awarded ? 'Points awarded successfully' : 'Could not award points',
        ),
      ),
    );

    if (awarded) {
      setState(_reload);
    }
  }

  Future<void> _showRestaurantsDialog() async {
    final shops = await FirebaseService.fetchShops();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restaurants'),
          content: SizedBox(
            width: 460,
            child: shops.isEmpty
                ? const Text('No restaurants found')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: shops.length,
                    separatorBuilder: (_, index) => const Divider(height: 16),
                    itemBuilder: (_, index) {
                      final shop = shops[index];
                      return _RestaurantListTile(shop: shop);
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        _reviewsFuture,
        _statsFuture,
        _redeemRequestsFuture,
        _usersFuture,
      ]),
      builder: (context, snapshot) {
        final reviews = snapshot.data != null
            ? snapshot.data![0] as List<ReviewEntry>
            : reviewData;
        final stats = snapshot.data != null
            ? snapshot.data![1] as Map<String, int>
            : const {
                'totalUsers': 0,
                'totalReviews': 0,
                'approvedReviews': 0,
                'totalShops': 0,
              };
        final redeemRequests = snapshot.data != null
            ? snapshot.data![2] as List<Map<String, dynamic>>
            : const <Map<String, dynamic>>[];
        final users = snapshot.data != null
            ? snapshot.data![3] as List<UserProfile>
            : const <UserProfile>[];
        final nonAdminUsers = users.where((user) => !user.isAdmin).toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: _showAddRestaurantDialog,
                icon: const Icon(Icons.storefront_outlined),
                tooltip: 'Add restaurant',
              ),
              IconButton(
                onPressed: _showAwardPointsDialog,
                icon: const Icon(Icons.workspace_premium_outlined),
                tooltip: 'Award points',
              ),
              IconButton(
                onPressed: _showRestaurantsDialog,
                icon: const Icon(Icons.list_alt_outlined),
                tooltip: 'View restaurants',
              ),
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              ),
            ],
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
                      value: '${stats['totalUsers']}',
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      label: 'Reviews Today',
                      value: '${stats['approvedReviews']}',
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Point Redeem Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (redeemRequests.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const ListTile(
                            title: Text('No redeem requests yet'),
                            subtitle: Text(
                              'When users request point redeem, they will appear here.',
                            ),
                          ),
                        )
                      else
                        ...redeemRequests.map(
                          (request) => _RedeemRequestTile(
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
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        'Users & Premium Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (nonAdminUsers.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const ListTile(title: Text('No users found')),
                        )
                      else
                        ...nonAdminUsers.map(
                          (user) => _UserPremiumTile(
                            user: user,
                            onSendPoints: () =>
                                _showAwardPointsDialog(initialUser: user),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        'Pending Approvals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...reviews.map((review) {
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
                            subtitle: Text(
                              '${review.user} • ${review.timeAgo}',
                            ),
                            trailing: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
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

class _RestaurantListTile extends StatelessWidget {
  const _RestaurantListTile({required this.shop});

  final ShopDetails shop;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        shop.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${shop.location}\nCode: ${shop.barcode} / ${shop.qrCode}',
      ),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Icon(Icons.star, color: Color(0xFFFFB300), size: 18),
          Text(
            shop.averageRating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
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
    final userName = request['userName'] as String? ?? 'Unknown User';
    final userEmail = request['userEmail'] as String? ?? '';
    final requestedPoints = request['requestedPoints'] as int? ?? 0;
    final note = request['note'] as String? ?? '';
    final adminEmail = request['adminEmail'] as String? ?? 'admin@email.com';
    final status = request['status'] as String? ?? 'pending';
    final isPending = status == 'pending';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$userName ($userEmail)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? const Color(0x1AFF9800)
                        : status == 'approved'
                        ? const Color(0x1A4CAF50)
                        : const Color(0x1AF44336),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: isPending
                          ? const Color(0xFFE08900)
                          : status == 'approved'
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Requested Points: $requestedPoints'),
            Text('Admin Email: $adminEmail'),
            if (note.isNotEmpty) Text('Note: $note'),
            if (isPending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
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
    final premiumActive = user.points > 50;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(
          '${user.name} (${user.email})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Points: ${user.points} • Premium: ${premiumActive ? 'Active' : 'Inactive'}',
        ),
        trailing: ElevatedButton.icon(
          onPressed: onSendPoints,
          icon: const Icon(Icons.send, size: 16),
          label: const Text('Send Points'),
        ),
      ),
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
