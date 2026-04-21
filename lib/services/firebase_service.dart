import 'dart:convert';

import 'package:flutter_application_1/data/sample_data.dart';
import 'package:flutter_application_1/data/shop_models.dart';
import 'package:flutter_application_1/data/user_profile.dart';
import 'package:http/http.dart' as http;

class FirebaseService {
  FirebaseService._();

  static const String _baseUrl =
      'https://emon-8247b-default-rtdb.firebaseio.com';

  static Uri _uri(String path) => Uri.parse('$_baseUrl/$path.json');

  static Future<void> ensureSeedData() async {
    await _seedStoresIfNeeded();
    await _seedReviewsIfNeeded();
    await _seedShopsIfNeeded();
    await _seedStructuredReviewsIfNeeded();
    await _seedAdminUserIfNeeded();
  }

  static Future<void> _seedStoresIfNeeded() async {
    try {
      final response = await http.get(_uri('stores'));
      if (response.statusCode >= 400) return;
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.isNotEmpty) return;

      final payload = {
        for (var i = 0; i < storeData.length; i++)
          'store_$i': storeData[i].toJson(),
      };
      await http.patch(
        _uri('stores'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (_) {
      // Keep app usable offline by falling back to sample data in UI.
    }
  }

  static Future<void> _seedReviewsIfNeeded() async {
    try {
      final response = await http.get(_uri('reviews'));
      if (response.statusCode >= 400) return;
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.isNotEmpty) return;

      final payload = {
        for (var i = 0; i < reviewData.length; i++)
          'review_$i': reviewData[i].toJson(),
      };
      await http.patch(
        _uri('reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (_) {
      // Keep app usable offline by falling back to sample data in UI.
    }
  }

  static Future<void> _seedAdminUserIfNeeded() async {
    try {
      final response = await http.get(_uri('users/admin'));
      if (response.statusCode < 400 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final email = decoded['email'] as String?;
          final isAdmin = decoded['isAdmin'] as bool? ?? false;
          if (email?.toLowerCase() == 'admin@email.com' && isAdmin) {
            return;
          }
        }
      }

      await http.put(
        _uri('users/admin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'Admin',
          'email': 'admin@email.com',
          'password': '123456',
          'avatarBase64': '',
          'points': 0,
          'isPremium': true,
          'isAdmin': true,
          'totalReviews': 0,
          'helpfulVotes': 0,
          'rank': '#1',
        }),
      );
    } catch (_) {
      // Keep app usable even if admin seeding fails; login still checks live data.
    }
  }

  static Future<void> _seedShopsIfNeeded() async {
    try {
      final response = await http.get(_uri('shops'));
      if (response.statusCode >= 400) return;
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.isNotEmpty) return;

      final payload = {
        'shop_1': {
          'name': 'Urban Cart',
          'location': 'Downtown, Dhaka',
          'imageUrl': '',
          'barcode': 'SHOP-1001',
          'qrCode': 'QR-1001',
          'averageRating': 4.7,
          'reviewsCount': 2,
          'ratingBreakdown': {
            'service': 4.8,
            'cleanliness': 4.6,
            'staffBehavior': 4.7,
            'productQuality': 4.8,
            'variety': 4.5,
          },
        },
        'shop_2': {
          'name': 'Daily Harvest',
          'location': 'Gulshan, Dhaka',
          'imageUrl': '',
          'barcode': 'SHOP-1002',
          'qrCode': 'QR-1002',
          'averageRating': 4.5,
          'reviewsCount': 1,
          'ratingBreakdown': {
            'service': 4.5,
            'cleanliness': 4.4,
            'staffBehavior': 4.5,
            'productQuality': 4.6,
            'variety': 4.3,
          },
        },
        'shop_3': {
          'name': 'Eco Choice',
          'location': 'Uttara, Dhaka',
          'imageUrl': '',
          'barcode': 'SHOP-1003',
          'qrCode': 'QR-1003',
          'averageRating': 4.8,
          'reviewsCount': 1,
          'ratingBreakdown': {
            'service': 4.9,
            'cleanliness': 4.8,
            'staffBehavior': 4.7,
            'productQuality': 4.9,
            'variety': 4.7,
          },
        },
      };

      await http.patch(
        _uri('shops'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (_) {
      // Keep app usable offline by falling back to in-memory defaults.
    }
  }

  static Future<void> _seedStructuredReviewsIfNeeded() async {
    try {
      final response = await http.get(_uri('structured_reviews'));
      if (response.statusCode >= 400) return;
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.isNotEmpty) return;

      final now = DateTime.now();
      final payload = {
        'sr_1': {
          'shopId': 'shop_1',
          'userId': 'seed_user_1',
          'userName': 'Julia Mendes',
          'service': 4.8,
          'cleanliness': 4.6,
          'staffBehavior': 4.7,
          'productQuality': 4.9,
          'variety': 4.5,
          'overallRating': 4.7,
          'feedback': 'Great quality and friendly service.',
          'status': 'approved',
          'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
        'sr_2': {
          'shopId': 'shop_2',
          'userId': 'seed_user_2',
          'userName': 'Nathan Vang',
          'service': 4.5,
          'cleanliness': 4.4,
          'staffBehavior': 4.5,
          'productQuality': 4.6,
          'variety': 4.3,
          'overallRating': 4.5,
          'feedback': 'Consistent quality. Could improve variety.',
          'status': 'approved',
          'createdAt': now.subtract(const Duration(hours: 8)).toIso8601String(),
        },
      };

      await http.patch(
        _uri('structured_reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (_) {
      // Keep app usable offline by falling back to no review list.
    }
  }

  static Future<List<StoreInfo>> fetchStores() async {
    try {
      final response = await http.get(_uri('stores'));
      if (response.statusCode >= 400) return storeData;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return storeData;

      return decoded.entries
          .where((entry) => entry.value is Map)
          .map(
            (entry) => StoreInfo.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            ),
          )
          .toList();
    } catch (_) {
      return storeData;
    }
  }

  static Future<List<ReviewEntry>> fetchReviews() async {
    try {
      final response = await http.get(_uri('reviews'));
      if (response.statusCode >= 400) return reviewData;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return reviewData;

      return decoded.entries
          .where((entry) => entry.value is Map)
          .map(
            (entry) => ReviewEntry.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            ),
          )
          .toList();
    } catch (_) {
      return reviewData;
    }
  }

  static Future<List<ShopDetails>> fetchShops() async {
    try {
      await _seedShopsIfNeeded();
      final response = await http.get(_uri('shops'));
      if (response.statusCode >= 400) return const [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return const [];

      return decoded.entries
          .where((entry) => entry.value is Map)
          .map(
            (entry) => ShopDetails.fromJson(
              entry.key,
              Map<String, dynamic>.from(entry.value as Map),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<ShopDetails?> fetchShopByScanCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final shops = await fetchShops();

    for (final shop in shops) {
      final barcodeMatches = shop.barcode.trim().toUpperCase() == normalized;
      final qrMatches = shop.qrCode.trim().toUpperCase() == normalized;
      if (barcodeMatches || qrMatches) {
        return shop;
      }
    }

    return null;
  }

  static Future<List<ShopDetails>> searchShops(String query) async {
    final normalized = query.trim().toLowerCase();
    final shops = await fetchShops();
    if (normalized.isEmpty) return shops;

    return shops.where((shop) {
      return shop.name.toLowerCase().contains(normalized) ||
          shop.location.toLowerCase().contains(normalized) ||
          shop.barcode.toLowerCase().contains(normalized) ||
          shop.qrCode.toLowerCase().contains(normalized);
    }).toList();
  }

  static Future<List<StructuredReview>> fetchStructuredReviews(
    String shopId,
  ) async {
    try {
      await _seedStructuredReviewsIfNeeded();
      final response = await http.get(_uri('structured_reviews'));
      if (response.statusCode >= 400) return const [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return const [];

      return decoded.entries
          .where((entry) => entry.value is Map)
          .map(
            (entry) => StructuredReview.fromJson(
              entry.key,
              Map<String, dynamic>.from(entry.value as Map),
            ),
          )
          .where((review) => review.shopId == shopId)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<StructuredReview>> fetchPendingStructuredReviews() async {
    try {
      final decoded = await _fetchStructuredReviewsMap();
      final reviews = decoded.entries
          .where((entry) => entry.value is Map)
          .map(
            (entry) => StructuredReview.fromJson(
              entry.key,
              Map<String, dynamic>.from(entry.value as Map),
            ),
          )
          .where((review) => review.status == 'pending')
          .toList();

      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    } catch (_) {
      return const [];
    }
  }

  static Future<List<ReviewEntry>> fetchUserReviews(String userId) async {
    try {
      if (userId.trim().isEmpty) return const [];
      final decoded = await _fetchStructuredReviewsMap();
      final shops = await fetchShops();
      final shopMap = {for (final shop in shops) shop.id: shop};

      final reviews = decoded.entries
          .where((entry) => entry.value is Map)
          .map(
            (entry) => StructuredReview.fromJson(
              entry.key,
              Map<String, dynamic>.from(entry.value as Map),
            ),
          )
          .where((review) => review.userId == userId)
          .toList();

      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reviews.map((review) {
        final shopName = shopMap[review.shopId]?.name ?? 'Shop review';
        return ReviewEntry(
          user: review.userName,
          timeAgo: _formatTimeAgo(review.createdAt),
          rating: review.overallRating,
          title: shopName,
          detail: review.feedback,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> submitStructuredReview({
    required String shopId,
    required String userId,
    required String userName,
    required double service,
    required double cleanliness,
    required double staffBehavior,
    required double productQuality,
    required double variety,
    required String feedback,
  }) async {
    try {
      final overall =
          (service + cleanliness + staffBehavior + productQuality + variety) /
          5;

      final payload = {
        'shopId': shopId,
        'userId': userId,
        'userName': userName,
        'service': service,
        'cleanliness': cleanliness,
        'staffBehavior': staffBehavior,
        'productQuality': productQuality,
        'variety': variety,
        'overallRating': double.parse(overall.toStringAsFixed(2)),
        'feedback': feedback,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        _uri('structured_reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      return response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> moderateReview({
    required String reviewId,
    required bool approve,
  }) async {
    try {
      final response = await http.patch(
        _uri('structured_reviews/$reviewId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': approve ? 'approved' : 'rejected'}),
      );
      if (response.statusCode >= 400) return false;

      final reviewResponse = await http.get(
        _uri('structured_reviews/$reviewId'),
      );
      if (reviewResponse.statusCode >= 400 || reviewResponse.body == 'null') {
        return true;
      }
      final reviewRaw = jsonDecode(reviewResponse.body);
      if (reviewRaw is! Map) return true;
      final review = Map<String, dynamic>.from(reviewRaw);
      final shopId = review['shopId'] as String?;
      if (shopId != null && shopId.isNotEmpty) {
        await _updateShopAggregates(shopId);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, int>> fetchDashboardStats() async {
    try {
      final users = await _fetchUsersMap();
      final reviews = await _fetchStructuredReviewsMap();
      final shopsResponse = await http.get(_uri('shops'));
      final shopsRaw = shopsResponse.statusCode < 400
          ? jsonDecode(shopsResponse.body)
          : null;
      final shopsCount = shopsRaw is Map ? shopsRaw.length : 0;

      final approvedReviews = reviews.values.where((raw) {
        if (raw is! Map) return false;
        return (raw['status'] as String? ?? 'approved') == 'approved';
      }).length;

      return {
        'totalUsers': users.length,
        'totalReviews': reviews.length,
        'approvedReviews': approvedReviews,
        'totalShops': shopsCount,
      };
    } catch (_) {
      return {
        'totalUsers': 0,
        'totalReviews': 0,
        'approvedReviews': 0,
        'totalShops': 0,
      };
    }
  }

  static Future<List<UserProfile>> fetchUsers() async {
    try {
      final users = await _fetchUsersMap();
      return users.entries
          .where((entry) => entry.value is Map)
          .map(
            (entry) => UserProfile.fromJson(
              entry.key,
              Map<String, dynamic>.from(entry.value as Map),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<UserProfile?> fetchUserById(String userId) async {
    try {
      if (userId.trim().isEmpty) return null;
      final response = await http.get(_uri('users/$userId'));
      if (response.statusCode >= 400 || response.body == 'null') return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;

      return UserProfile.fromJson(userId, Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> addRestaurant({
    required String name,
    required String location,
    required String barcode,
    required String qrCode,
    String imageUrl = '',
  }) async {
    try {
      final shops = await fetchShops();
      final normalizedBarcode = barcode.trim().toUpperCase();
      final normalizedQrCode = qrCode.trim().toUpperCase();

      final duplicate = shops.any((shop) {
        return shop.barcode.trim().toUpperCase() == normalizedBarcode ||
            shop.qrCode.trim().toUpperCase() == normalizedQrCode;
      });
      if (duplicate) return false;

      final payload = {
        'name': name.trim(),
        'location': location.trim(),
        'imageUrl': imageUrl.trim(),
        'barcode': normalizedBarcode,
        'qrCode': normalizedQrCode,
        'averageRating': 0,
        'reviewsCount': 0,
        'ratingBreakdown': {
          'service': 0,
          'cleanliness': 0,
          'staffBehavior': 0,
          'productQuality': 0,
          'variety': 0,
        },
      };

      final response = await http.post(
        _uri('shops'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> awardPointsToUser({
    required String userId,
    required int points,
    required String reason,
    String adminId = 'admin',
  }) async {
    try {
      if (points <= 0) return false;
      final userResponse = await http.get(_uri('users/$userId'));
      if (userResponse.statusCode >= 400 || userResponse.body == 'null') {
        return false;
      }

      final userRaw = jsonDecode(userResponse.body);
      if (userRaw is! Map) return false;
      final user = Map<String, dynamic>.from(userRaw);
      final currentPoints = (user['points'] as num?)?.toInt() ?? 0;
      final updatedPoints = currentPoints + points;

      final updateResponse = await http.patch(
        _uri('users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'points': updatedPoints,
          'isPremium': updatedPoints > 50,
        }),
      );
      if (updateResponse.statusCode >= 400) return false;

      await http.post(
        _uri('points_transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'adminId': adminId,
          'points': points,
          'reason': reason,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> submitPointRedeemRequest({
    required String userId,
    required int points,
    String note = '',
    String adminEmail = 'admin@email.com',
  }) async {
    try {
      if (points <= 0) return false;

      final userResponse = await http.get(_uri('users/$userId'));
      if (userResponse.statusCode >= 400 || userResponse.body == 'null') {
        return false;
      }

      final userRaw = jsonDecode(userResponse.body);
      if (userRaw is! Map) return false;
      final user = Map<String, dynamic>.from(userRaw);
      final currentPoints = (user['points'] as num?)?.toInt() ?? 0;
      if (points > currentPoints) return false;

      final response = await http.post(
        _uri('point_redeem_requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userName': user['name'] as String? ?? 'Unknown User',
          'userEmail': user['email'] as String? ?? '',
          'requestedPoints': points,
          'note': note,
          'adminEmail': adminEmail,
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPointRedeemRequests() async {
    try {
      final response = await http.get(_uri('point_redeem_requests'));
      if (response.statusCode >= 400) return const [];

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return const [];

      final requests = decoded.entries.where((entry) => entry.value is Map).map(
        (entry) {
          final raw = Map<String, dynamic>.from(entry.value as Map);
          return {
            'id': entry.key,
            'userId': raw['userId'] as String? ?? '',
            'userName': raw['userName'] as String? ?? 'Unknown User',
            'userEmail': raw['userEmail'] as String? ?? '',
            'requestedPoints': (raw['requestedPoints'] as num?)?.toInt() ?? 0,
            'note': raw['note'] as String? ?? '',
            'adminEmail': raw['adminEmail'] as String? ?? 'admin@email.com',
            'status': raw['status'] as String? ?? 'pending',
            'createdAt': raw['createdAt'] as String? ?? '',
            'processedAt': raw['processedAt'] as String? ?? '',
            'processedBy': raw['processedBy'] as String? ?? '',
            'adminNote': raw['adminNote'] as String? ?? '',
          };
        },
      ).toList();

      requests.sort((a, b) {
        final aPending = (a['status'] as String? ?? '') == 'pending';
        final bPending = (b['status'] as String? ?? '') == 'pending';
        if (aPending != bPending) {
          return aPending ? -1 : 1;
        }

        final aTime = DateTime.tryParse(a['createdAt'] as String? ?? '');
        final bTime = DateTime.tryParse(b['createdAt'] as String? ?? '');
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return requests;
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> processPointRedeemRequest({
    required String requestId,
    required bool approve,
    String adminId = 'admin',
    String adminNote = '',
  }) async {
    try {
      final requestResponse = await http.get(
        _uri('point_redeem_requests/$requestId'),
      );
      if (requestResponse.statusCode >= 400 || requestResponse.body == 'null') {
        return false;
      }

      final requestRaw = jsonDecode(requestResponse.body);
      if (requestRaw is! Map) return false;
      final request = Map<String, dynamic>.from(requestRaw);
      final status = request['status'] as String? ?? 'pending';
      if (status != 'pending') return false;

      final userId = request['userId'] as String? ?? '';
      final points = (request['requestedPoints'] as num?)?.toInt() ?? 0;
      if (userId.isEmpty || points <= 0) return false;

      if (approve) {
        final userResponse = await http.get(_uri('users/$userId'));
        if (userResponse.statusCode >= 400 || userResponse.body == 'null') {
          return false;
        }

        final userRaw = jsonDecode(userResponse.body);
        if (userRaw is! Map) return false;
        final user = Map<String, dynamic>.from(userRaw);
        final currentPoints = (user['points'] as num?)?.toInt() ?? 0;
        if (currentPoints < points) return false;

        final updatedPoints = currentPoints - points;
        final updateResponse = await http.patch(
          _uri('users/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'points': updatedPoints,
            'isPremium': updatedPoints > 50,
          }),
        );
        if (updateResponse.statusCode >= 400) return false;

        await http.post(
          _uri('points_transactions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'adminId': adminId,
            'points': -points,
            'reason': adminNote.isEmpty
                ? 'Points redeemed by user'
                : 'Points redeemed by user: $adminNote',
            'createdAt': DateTime.now().toIso8601String(),
          }),
        );
      }

      final requestUpdateResponse = await http.patch(
        _uri('point_redeem_requests/$requestId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': approve ? 'approved' : 'rejected',
          'processedAt': DateTime.now().toIso8601String(),
          'processedBy': adminId,
          'adminNote': adminNote,
        }),
      );

      return requestUpdateResponse.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _updateShopAggregates(String shopId) async {
    final reviews = await fetchStructuredReviews(shopId);
    final approved = reviews.where((review) => review.status == 'approved');

    if (approved.isEmpty) {
      await http.patch(
        _uri('shops/$shopId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'averageRating': 0,
          'reviewsCount': 0,
          'ratingBreakdown': {
            'service': 0,
            'cleanliness': 0,
            'staffBehavior': 0,
            'productQuality': 0,
            'variety': 0,
          },
        }),
      );
      return;
    }

    final approvedList = approved.toList();
    double sumService = 0;
    double sumCleanliness = 0;
    double sumStaffBehavior = 0;
    double sumProductQuality = 0;
    double sumVariety = 0;
    double sumOverall = 0;

    for (final review in approvedList) {
      sumService += review.service;
      sumCleanliness += review.cleanliness;
      sumStaffBehavior += review.staffBehavior;
      sumProductQuality += review.productQuality;
      sumVariety += review.variety;
      sumOverall += review.overallRating;
    }

    final count = approvedList.length;
    final payload = {
      'averageRating': double.parse((sumOverall / count).toStringAsFixed(2)),
      'reviewsCount': count,
      'ratingBreakdown': {
        'service': double.parse((sumService / count).toStringAsFixed(2)),
        'cleanliness': double.parse(
          (sumCleanliness / count).toStringAsFixed(2),
        ),
        'staffBehavior': double.parse(
          (sumStaffBehavior / count).toStringAsFixed(2),
        ),
        'productQuality': double.parse(
          (sumProductQuality / count).toStringAsFixed(2),
        ),
        'variety': double.parse((sumVariety / count).toStringAsFixed(2)),
      },
    };

    await http.patch(
      _uri('shops/$shopId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  static Future<UserProfile?> login({
    required String email,
    required String password,
    required bool adminMode,
  }) async {
    try {
      await _seedAdminUserIfNeeded();
      final response = await http.get(_uri('users'));
      if (response.statusCode >= 400) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;

      for (final entry in decoded.entries) {
        if (entry.value is! Map) continue;
        final user = UserProfile.fromJson(
          entry.key,
          Map<String, dynamic>.from(entry.value as Map),
        );
        final emailMatches = user.email.toLowerCase() == email.toLowerCase();
        final passwordMatches = user.password == password;
        final roleMatches = adminMode ? user.isAdmin : !user.isAdmin;

        if (emailMatches && passwordMatches && roleMatches) {
          return user;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<UserProfile?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final existingUsers = await _fetchUsersMap();
      final hasDuplicate = existingUsers.values.any((userRaw) {
        if (userRaw is! Map) return false;
        final user = Map<String, dynamic>.from(userRaw);
        return (user['email'] as String? ?? '').toLowerCase() ==
            email.toLowerCase();
      });
      if (hasDuplicate) {
        return null;
      }

      final payload = {
        'name': name,
        'email': email,
        'password': password,
        'avatarBase64': '',
        'points': 0,
        'isPremium': false,
        'isAdmin': false,
        'totalReviews': 0,
        'helpfulVotes': 0,
        'rank': '#999',
      };

      final response = await http.post(
        _uri('users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 400) return null;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final id = decoded['name'] as String?;
      if (id == null || id.isEmpty) return null;

      return UserProfile.fromJson(id, payload);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateUserAvatar({
    required String userId,
    required String avatarBase64,
  }) async {
    try {
      if (userId.trim().isEmpty) return false;
      final response = await http.patch(
        _uri('users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'avatarBase64': avatarBase64}),
      );
      return response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logout() async {
    return;
  }

  static Future<Map<String, dynamic>> _fetchUsersMap() async {
    final response = await http.get(_uri('users'));
    if (response.statusCode >= 400) return {};
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return {};
    return Map<String, dynamic>.from(decoded);
  }

  static Future<Map<String, dynamic>> _fetchStructuredReviewsMap() async {
    final response = await http.get(_uri('structured_reviews'));
    if (response.statusCode >= 400) return {};
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return {};
    return Map<String, dynamic>.from(decoded);
  }

  static String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 4) return '$weeks weeks ago';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '$months months ago';
    final years = (diff.inDays / 365).floor();
    return '$years years ago';
  }
}
