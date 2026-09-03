/// Mirrors the `employees` collection defined in docs/DATABASE_SCHEMA.md
/// Field names must stay identical to the schema so integration with the
/// real Firebase backend later is a drop-in swap.
class Employee {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // admin | executive | inside_sales | outside_sales
  final String? profileImageUrl;
  final bool active;
  final DateTime createdAt;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImageUrl,
    this.active = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      role: map['role'] as String,
      profileImageUrl: map['profileImageUrl'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Human readable label used in the UI (e.g. "Inside Sales")
  String get roleLabel {
    switch (role) {
      case 'inside_sales':
        return 'Inside Sales';
      case 'outside_sales':
        return 'Outside Sales';
      case 'admin':
        return 'Admin';
      case 'executive':
        return 'Executive';
      default:
        return role;
    }
  }
}
