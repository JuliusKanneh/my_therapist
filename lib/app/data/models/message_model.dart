// lib/app/data/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { user, ai, system }

enum MessageSentiment { positive, negative, neutral, crisis }

class MessageModel {
  final String id;
  final String userId;
  final String sessionId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageSentiment? sentiment;
  final bool isProcessed;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.sentiment,
    this.isProcessed = false,
    this.metadata,
  });

  // Convert from Firestore document
  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      sessionId: data['sessionId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.user,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      sentiment: data['sentiment'] != null
          ? MessageSentiment.values.firstWhere(
              (e) => e.name == data['sentiment'],
              orElse: () => MessageSentiment.neutral,
            )
          : null,
      isProcessed: data['isProcessed'] ?? false,
      metadata: data['metadata'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'sentiment': sentiment?.name,
      'isProcessed': isProcessed,
      'metadata': metadata,
    };
  }

  // Copy with updated fields
  MessageModel copyWith({
    String? content,
    MessageSentiment? sentiment,
    bool? isProcessed,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id,
      userId: userId,
      sessionId: sessionId,
      content: content ?? this.content,
      type: type,
      timestamp: timestamp,
      sentiment: sentiment ?? this.sentiment,
      isProcessed: isProcessed ?? this.isProcessed,
      metadata: metadata ?? this.metadata,
    );
  }
}
