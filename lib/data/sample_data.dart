import 'package:flutter/material.dart';

class StoreInfo {
  const StoreInfo({
    required this.name,
    required this.rating,
    required this.color,
    required this.category,
  });

  final String name;
  final double rating;
  final Color color;
  final String category;

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      name: json['name'] as String? ?? 'Unknown Store',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      color: Color((json['color'] as num?)?.toInt() ?? 0xFF4C6FFF),
      category: json['category'] as String? ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rating': rating,
      'color': color.toARGB32(),
      'category': category,
    };
  }
}

class ReviewEntry {
  const ReviewEntry({
    required this.user,
    required this.timeAgo,
    required this.rating,
    required this.title,
    required this.detail,
  });

  final String user;
  final String timeAgo;
  final double rating;
  final String title;
  final String detail;

  factory ReviewEntry.fromJson(Map<String, dynamic> json) {
    return ReviewEntry(
      user: json['user'] as String? ?? 'Anonymous',
      timeAgo: json['timeAgo'] as String? ?? 'just now',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      title: json['title'] as String? ?? 'Untitled review',
      detail: json['detail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'timeAgo': timeAgo,
      'rating': rating,
      'title': title,
      'detail': detail,
    };
  }
}

const List<StoreInfo> storeData = [
  StoreInfo(
    name: 'Urban Cart',
    rating: 4.9,
    color: Color(0xFF4C6FFF),
    category: 'Groceries',
  ),
  StoreInfo(
    name: 'Daily Harvest',
    rating: 4.7,
    color: Color(0xFFFFB74D),
    category: 'Organic',
  ),
  StoreInfo(
    name: 'Eco Choice',
    rating: 4.8,
    color: Color(0xFF66BB6A),
    category: 'Sustainable',
  ),
];

const List<ReviewEntry> reviewData = [
  ReviewEntry(
    user: 'Julia Mendes',
    timeAgo: '2 hrs ago',
    rating: 4.5,
    title: 'Freshest berries!',
    detail:
        'Loved the freshness. Packaging can improve but overall a great buy.',
  ),
  ReviewEntry(
    user: 'Nathan Vang',
    timeAgo: '5 hrs ago',
    rating: 4.8,
    title: 'Coffee beans worth the hype',
    detail:
        'Bold flavor and ethical sourcing. Would recommend grinding right before brewing.',
  ),
  ReviewEntry(
    user: 'Georgia Lim',
    timeAgo: '1 day ago',
    rating: 4.2,
    title: 'Eco detergent review',
    detail: 'Gentle on fabrics and skin. Need a little more product per wash.',
  ),
];
