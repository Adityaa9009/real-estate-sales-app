import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String status;
  final String? assignedInsideSalesId;
  final String? assignedOutsideSalesId;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.status,
    this.assignedInsideSalesId,
    this.assignedOutsideSalesId,
  });

  factory Customer.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      status: data['status'] ?? 'unassigned',
      assignedInsideSalesId: data['assignedInsideSalesId'],
      assignedOutsideSalesId: data['assignedOutsideSalesId'],
    );
  }

  // for number masking.
  String get maskedPhone {
    if (phone.length <= 4) return phone;
    final last4 = phone.substring(phone.length - 4);
    return '*' * (phone.length - 4) + last4;
  }
}