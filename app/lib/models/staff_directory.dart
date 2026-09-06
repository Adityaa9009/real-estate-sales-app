import 'package:cloud_firestore/cloud_firestore.dart';
import 'employee.dart';

class StaffDirectoryEntry {
  final String id;
  final String name;
  final AppRole role;
  final bool active;

  const StaffDirectoryEntry({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
  });

  factory StaffDirectoryEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return StaffDirectoryEntry(
      id: doc.id,
      name: data['name'] as String? ?? 'Staff Member',
      role: AppRoleExtension.fromStringOrThrow(data['role'] as String?),
      active: data['active'] as bool? ?? true,
    );
  }

  factory StaffDirectoryEntry.fromMap(String id, Map<String, dynamic> data) {
    return StaffDirectoryEntry(
      id: id,
      name: data['name'] as String? ?? 'Staff Member',
      role: AppRoleExtension.fromStringOrThrow(data['role'] as String?),
      active: data['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'role': role.firestoreValue,
    'active': active,
  };
}
