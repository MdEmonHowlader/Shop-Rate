import 'dart:convert';

import 'package:flutter_application_1/data/sample_data.dart';
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

  static Future<UserProfile?> login({
    required String email,
    required String password,
    required bool adminMode,
  }) async {
    try {
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
        'isPremium': true,
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
}
