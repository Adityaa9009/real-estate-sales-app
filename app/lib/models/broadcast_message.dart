import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastMessage {
  final String id;
  final String title;
  final String message;
  final String createdBy;
  final List<String> targetRoles;
  final DateTime createdAt;

  const BroadcastMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.createdBy,
    required this.targetRoles,
    required this.createdAt,
  });

  factory BroadcastMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BroadcastMessage(
      id: doc.id,
      title: data['title'] as String? ?? 'Company Update',
      message: data['message'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? 'Admin',
      targetRoles: List<String>.from(data['targetRoles'] as List? ?? ['inside_sales', 'outside_sales', 'executive']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'message': message,
    'createdBy': createdBy,
    'targetRoles': targetRoles,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
