class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.isPremium,
    required this.isAdmin,
    required this.totalReviews,
    required this.helpfulVotes,
    required this.rank,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final bool isPremium;
  final bool isAdmin;
  final int totalReviews;
  final int helpfulVotes;
  final String rank;

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    bool? isPremium,
    bool? isAdmin,
    int? totalReviews,
    int? helpfulVotes,
    String? rank,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      isPremium: isPremium ?? this.isPremium,
      isAdmin: isAdmin ?? this.isAdmin,
      totalReviews: totalReviews ?? this.totalReviews,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      rank: rank ?? this.rank,
    );
  }

  factory UserProfile.fromJson(String id, Map<String, dynamic> json) {
    return UserProfile(
      id: id,
      name: json['name'] as String? ?? 'Unknown User',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      isPremium: json['isPremium'] as bool? ?? false,
      isAdmin: json['isAdmin'] as bool? ?? false,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      helpfulVotes: (json['helpfulVotes'] as num?)?.toInt() ?? 0,
      rank: json['rank'] as String? ?? '#-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'isPremium': isPremium,
      'isAdmin': isAdmin,
      'totalReviews': totalReviews,
      'helpfulVotes': helpfulVotes,
      'rank': rank,
    };
  }
}
