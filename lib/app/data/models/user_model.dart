// lib/app/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, dynamic>? therapyPreferences;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    required this.createdAt,
    required this.lastActiveAt,
    this.therapyPreferences,
    this.isActive = true,
  });

  // Convert from Firestore document
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp).toDate(),
      therapyPreferences: data['therapyPreferences'],
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'therapyPreferences': therapyPreferences,
      'isActive': isActive,
    };
  }

  // Copy with updated fields
  UserModel copyWith({
    String? displayName,
    DateTime? lastActiveAt,
    Map<String, dynamic>? therapyPreferences,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      therapyPreferences: therapyPreferences ?? this.therapyPreferences,
      isActive: isActive ?? this.isActive,
    );
  }
}
