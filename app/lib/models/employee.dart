import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AppRole { admin, executive, insideSales, outsideSales }

extension AppRoleExtension on AppRole {
  String get firestoreValue => switch (this) {
    AppRole.admin => 'admin',
    AppRole.executive => 'executive',
    AppRole.insideSales => 'inside_sales',
    AppRole.outsideSales => 'outside_sales',
  };

  String get label => switch (this) {
    AppRole.admin => 'Admin',
    AppRole.executive => 'Executive',
    AppRole.insideSales => 'Inside Sales',
    AppRole.outsideSales => 'Outside Sales',
  };

  Color get color => switch (this) {
    AppRole.admin => const Color(0xFFEF4444),
    AppRole.executive => const Color(0xFF8B5CF6),
    AppRole.insideSales => const Color(0xFF3B82F6),
    AppRole.outsideSales => const Color(0xFF10B981),
  };

  IconData get icon => switch (this) {
    AppRole.admin => Icons.admin_panel_settings_rounded,
    AppRole.executive => Icons.manage_accounts_rounded,
    AppRole.insideSales => Icons.headset_mic_rounded,
    AppRole.outsideSales => Icons.directions_walk_rounded,
  };

  static AppRole? fromString(String? value) => switch (value) {
    'admin' => AppRole.admin,
    'executive' => AppRole.executive,
    'inside_sales' => AppRole.insideSales,
    'outside_sales' => AppRole.outsideSales,
    _ => null,
  };
}

class Employee {
  final String id;
  final String name;
  final String email;
  final String phone;
  final AppRole role;
  final String? profileImageUrl;
  final bool active;
  final DateTime? createdAt;
  final String? dob;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImageUrl,
    this.active = true,
    this.createdAt,
    this.dob,
  });

  factory Employee.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final roleStr = data['role'] as String?;
    final role = AppRoleExtension.fromString(roleStr) ?? AppRole.insideSales;
    final createdTimestamp = data['createdAt'] as Timestamp?;

    return Employee(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Employee',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: role,
      profileImageUrl: data['profileImageUrl'] as String?,
      active: data['active'] as bool? ?? true,
      createdAt: createdTimestamp?.toDate(),
      dob: data['dob'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.firestoreValue,
    'profileImageUrl': profileImageUrl,
    'active': active,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    if (dob != null) 'dob': dob,
  };
}
