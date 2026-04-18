class ShopDetails {
  const ShopDetails({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.barcode,
    required this.qrCode,
    required this.averageRating,
    required this.reviewsCount,
    required this.ratingBreakdown,
  });

  final String id;
  final String name;
  final String location;
  final String imageUrl;
  final String barcode;
  final String qrCode;
  final double averageRating;
  final int reviewsCount;
  final Map<String, double> ratingBreakdown;

  factory ShopDetails.fromJson(String id, Map<String, dynamic> json) {
    final breakdownRaw = json['ratingBreakdown'];
    final breakdown = <String, double>{
      'service': 0,
      'cleanliness': 0,
      'staffBehavior': 0,
      'productQuality': 0,
      'variety': 0,
    };

    if (breakdownRaw is Map) {
      for (final entry in breakdownRaw.entries) {
        breakdown[entry.key.toString()] =
            (entry.value as num?)?.toDouble() ?? 0;
      }
    }

    return ShopDetails(
      id: id,
      name: json['name'] as String? ?? 'Unknown Shop',
      location: json['location'] as String? ?? 'Unknown location',
      imageUrl: json['imageUrl'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      qrCode: json['qrCode'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      ratingBreakdown: breakdown,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'imageUrl': imageUrl,
      'barcode': barcode,
      'qrCode': qrCode,
      'averageRating': averageRating,
      'reviewsCount': reviewsCount,
      'ratingBreakdown': ratingBreakdown,
    };
  }
}

class StructuredReview {
  const StructuredReview({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.userName,
    required this.service,
    required this.cleanliness,
    required this.staffBehavior,
    required this.productQuality,
    required this.variety,
    required this.overallRating,
    required this.feedback,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String shopId;
  final String userId;
  final String userName;
  final double service;
  final double cleanliness;
  final double staffBehavior;
  final double productQuality;
  final double variety;
  final double overallRating;
  final String feedback;
  final String status;
  final DateTime createdAt;

  factory StructuredReview.fromJson(String id, Map<String, dynamic> json) {
    return StructuredReview(
      id: id,
      shopId: json['shopId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Anonymous',
      service: (json['service'] as num?)?.toDouble() ?? 0,
      cleanliness: (json['cleanliness'] as num?)?.toDouble() ?? 0,
      staffBehavior: (json['staffBehavior'] as num?)?.toDouble() ?? 0,
      productQuality: (json['productQuality'] as num?)?.toDouble() ?? 0,
      variety: (json['variety'] as num?)?.toDouble() ?? 0,
      overallRating: (json['overallRating'] as num?)?.toDouble() ?? 0,
      feedback: json['feedback'] as String? ?? '',
      status: json['status'] as String? ?? 'approved',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'userId': userId,
      'userName': userName,
      'service': service,
      'cleanliness': cleanliness,
      'staffBehavior': staffBehavior,
      'productQuality': productQuality,
      'variety': variety,
      'overallRating': overallRating,
      'feedback': feedback,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
