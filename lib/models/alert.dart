import 'package:cloud_firestore/cloud_firestore.dart';

class Alert {
  final String id;
  final String userId;
  final String message;
  final String type; // e.g., 'order_update', 'promotion', 'system'
  final bool isRead;
  final Timestamp timestamp;

  Alert({
    required this.id,
    required this.userId,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.timestamp,
  });

  factory Alert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Alert(
      id: doc.id,
      userId: data['userId'] as String,
      message: data['message'] as String,
      type: data['type'] as String,
      isRead: data['isRead'] as bool? ?? false,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'message': message,
      'type': type,
      'isRead': isRead,
      'timestamp': timestamp,
    };
  }

  Alert copyWith({
    String? id,
    String? userId,
    String? message,
    String? type,
    bool? isRead,
    Timestamp? timestamp,
  }) {
    return Alert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}