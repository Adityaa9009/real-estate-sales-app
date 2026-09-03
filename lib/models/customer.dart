/// Mirrors the `customers` collection defined in docs/DATABASE_SCHEMA.md
class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String status; // see status lifecycle in schema doc
  final String? assignedInsideSalesId;
  final String? assignedOutsideSalesId;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.status = 'unassigned',
    this.assignedInsideSalesId,
    this.assignedOutsideSalesId,
    required this.createdAt,
  });

  Customer copyWith({
    String? status,
    String? assignedInsideSalesId,
    String? assignedOutsideSalesId,
  }) {
    return Customer(
      id: id,
      name: name,
      phone: phone,
      email: email,
      status: status ?? this.status,
      assignedInsideSalesId:
          assignedInsideSalesId ?? this.assignedInsideSalesId,
      assignedOutsideSalesId:
          assignedOutsideSalesId ?? this.assignedOutsideSalesId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'status': status,
      'assignedInsideSalesId': assignedInsideSalesId,
      'assignedOutsideSalesId': assignedOutsideSalesId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      status: map['status'] as String? ?? 'unassigned',
      assignedInsideSalesId: map['assignedInsideSalesId'] as String?,
      assignedOutsideSalesId: map['assignedOutsideSalesId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
