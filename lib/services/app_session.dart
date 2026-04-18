import 'package:flutter_application_1/data/user_profile.dart';

class AppSession {
  AppSession._();

  static UserProfile? currentUser;

  static bool get isLoggedIn => currentUser != null;
  static bool get isPremium => (currentUser?.points ?? 0) > 50;
  static bool get isAdmin => currentUser?.isAdmin ?? false;

  static void setUser(UserProfile user) {
    currentUser = user;
  }

  static void clear() {
    currentUser = null;
  }
}
