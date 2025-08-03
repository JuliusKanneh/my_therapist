// lib/app/data/models/therapy_session_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { active, completed, paused }

class TherapySessionModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionStatus status;
  final String? summary;
  final List<String> topics;
  final double? moodBefore;
  final double? moodAfter;
  final int messageCount;
  final Map<String, dynamic>? insights;

  TherapySessionModel({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.summary,
    required this.topics,
    this.moodBefore,
    this.moodAfter,
    this.messageCount = 0,
    this.insights,
  });

  // Convert from Firestore document
  factory TherapySessionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TherapySessionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SessionStatus.active,
      ),
      summary: data['summary'],
      topics: List<String>.from(data['topics'] ?? []),
      moodBefore: data['moodBefore']?.toDouble(),
      moodAfter: data['moodAfter']?.toDouble(),
      messageCount: data['messageCount'] ?? 0,
      insights: data['insights'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status.name,
      'summary': summary,
      'topics': topics,
      'moodBefore': moodBefore,
      'moodAfter': moodAfter,
      'messageCount': messageCount,
      'insights': insights,
    };
  }

  // Copy with updated fields
  TherapySessionModel copyWith({
    DateTime? endTime,
    SessionStatus? status,
    String? summary,
    List<String>? topics,
    double? moodBefore,
    double? moodAfter,
    int? messageCount,
    Map<String, dynamic>? insights,
  }) {
    return TherapySessionModel(
      id: id,
      userId: userId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      topics: topics ?? this.topics,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      messageCount: messageCount ?? this.messageCount,
      insights: insights ?? this.insights,
    );
  }

  // Calculate session duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  // Check if session is active
  bool get isActive => status == SessionStatus.active;
}
