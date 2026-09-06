import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:real_estate_sales_app/models/employee.dart';
import 'package:real_estate_sales_app/models/customer.dart';
import 'package:real_estate_sales_app/models/visit.dart';
import 'package:real_estate_sales_app/models/attendance.dart';
import 'package:real_estate_sales_app/models/customer_assignment.dart';
import 'package:real_estate_sales_app/models/staff_directory.dart';
import 'package:real_estate_sales_app/services/call_service.dart';
import 'package:real_estate_sales_app/services/location_service.dart';
import 'package:real_estate_sales_app/services/database_service.dart';
import 'package:real_estate_sales_app/services/storage_availability_service.dart';

class FakeStorageProbeDelegate implements StorageProbeDelegate {
  final Future<void> Function(String path) onProbe;
  FakeStorageProbeDelegate(this.onProbe);

  @override
  Future<void> probePath(String path) => onProbe(path);
}

void main() {
  group('AppRole fail-closed tests', () {
    test('parses valid roles correctly', () {
      expect(AppRoleExtension.fromString('admin'), AppRole.admin);
      expect(AppRoleExtension.fromString('executive'), AppRole.executive);
      expect(AppRoleExtension.fromString('inside_sales'), AppRole.insideSales);
      expect(
        AppRoleExtension.fromString('outside_sales'),
        AppRole.outsideSales,
      );
    });

    test('fails closed with FormatException on invalid role string', () {
      expect(
        () => AppRoleExtension.fromStringOrThrow('super_user'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AppRoleExtension.fromStringOrThrow('guest'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AppRoleExtension.fromStringOrThrow('manager'),
        throwsA(isA<FormatException>()),
      );
    });

    test('fails closed with FormatException on null or empty role string', () {
      expect(
        () => AppRoleExtension.fromStringOrThrow(null),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AppRoleExtension.fromStringOrThrow(''),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AppRoleExtension.fromStringOrThrow('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('Employee.fromMap fails closed when role is missing or invalid', () {
      expect(
        () => Employee.fromMap('emp-bad', {
          'name': 'Hacker',
          'email': 'hacker@evil.com',
          'phone': '1234567890',
          'role': 'superadmin',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Employee registration and validation tests', () {
    test('registerNewEmployee rejects password under 6 characters', () {
      expect(
        () => DatabaseService.registerNewEmployee(
          name: 'Test User',
          email: 'test@example.com',
          password: '12345',
          phone: '9999999999',
          role: AppRole.insideSales,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('registerNewEmployee rejects empty password', () {
      expect(
        () => DatabaseService.registerNewEmployee(
          name: 'Test User',
          email: 'test@example.com',
          password: '   ',
          phone: '9999999999',
          role: AppRole.insideSales,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Customer privacy and schema tests', () {
    test('toFirestore includes id and excludes raw phone', () {
      final customer = Customer(
        id: 'cust-999',
        name: 'Rahul Sharma',
        maskedPhone: '******4285',
        assignedInsideSalesId: 'inside-1',
        assignedInsideSalesName: 'Priya',
        status: CustomerStatus.assignedToInsideSales,
        budget: '75 Lakhs',
        propertyNotes: '3BHK in Gurgaon',
      );

      final firestoreMap = customer.toFirestore();

      // Rule requires request.resource.data.id == customerId
      expect(firestoreMap['id'], 'cust-999');
      // Rule strictly denies raw phone in customer document
      expect(firestoreMap.containsKey('phone'), isFalse);
      expect(firestoreMap.containsKey('customerPhone'), isFalse);
      expect(firestoreMap['maskedPhone'], '******4285');
      expect(firestoreMap['status'], 'assigned_to_inside_sales');
      expect(firestoreMap['budget'], '75 Lakhs');
    });

    test('CustomerStatus handles all valid enum states', () {
      expect(
        CustomerStatus.fromString('assigned_to_inside_sales'),
        CustomerStatus.assignedToInsideSales,
      );
      expect(
        CustomerStatus.fromString('interested'),
        CustomerStatus.interested,
      );
      expect(
        CustomerStatus.fromString('not_interested'),
        CustomerStatus.notInterested,
      );
      expect(
        CustomerStatus.fromString('visit_scheduled'),
        CustomerStatus.visitScheduled,
      );
      expect(
        CustomerStatus.fromString('visit_in_progress'),
        CustomerStatus.visitInProgress,
      );
      expect(
        CustomerStatus.fromString('visit_completed'),
        CustomerStatus.visitCompleted,
      );
    });
  });

  group('Visit privacy and atomic schema tests', () {
    test('toFirestore includes id and excludes raw phone/customerPhone', () {
      final now = DateTime.now();
      final visit = Visit(
        id: 'visit-456',
        customerId: 'cust-999',
        customerName: 'Rahul Sharma',
        maskedPhone: '******4285',
        insideSalesId: 'inside-1',
        insideSalesName: 'Priya',
        outsideSalesId: 'outside-2',
        outsideSalesName: 'Vikram',
        scheduledAt: now,
        status: VisitStatus.visitScheduled,
      );

      final map = visit.toFirestore();

      // Stored id requirement
      expect(map['id'], 'visit-456');
      // Universal raw phone prohibition on root visit document
      expect(map.containsKey('phone'), isFalse);
      expect(map.containsKey('customerPhone'), isFalse);
      expect(map['maskedPhone'], '******4285');
      // Security rule keys
      expect(map['customerId'], 'cust-999');
      expect(map['insideSalesId'], 'inside-1');
      expect(map['outsideSalesId'], 'outside-2');
      expect(map['status'], 'visit_scheduled');
    });

    test('VisitStatus correctly maps firestore strings', () {
      expect(
        VisitStatus.fromString('visit_scheduled'),
        VisitStatus.visitScheduled,
      );
      expect(
        VisitStatus.fromString('visit_in_progress'),
        VisitStatus.visitInProgress,
      );
      expect(
        VisitStatus.fromString('visit_completed'),
        VisitStatus.visitCompleted,
      );
      expect(
        VisitStatus.fromString('unknown'),
        VisitStatus.visitScheduled,
      ); // fallback safe
    });

    test('maskPhoneNumber helper produces correct masking', () {
      expect(Visit.maskPhoneNumber('9876543210'), '******3210');
      expect(Visit.maskPhoneNumber('9811122233'), '******2233');
      expect(Visit.maskPhoneNumber('123'), '123');
      expect(Visit.maskPhoneNumber(''), '');
      expect(Visit.maskPhoneNumber(null), '');
    });
  });

  group('CallService masking tests', () {
    test('maskPhone keeps only last 4 digits', () {
      expect(CallService.maskPhone('+91 9876543210'), '**********3210');
      expect(CallService.maskPhone('9876544285'), '******4285');
      expect(CallService.maskPhone('4285'), '4285');
      expect(CallService.maskPhone(''), '');
    });
  });

  group('CustomerAssignment schema compliance tests', () {
    test('toFirestore strictly contains only permitted rule keys', () {
      final assign = CustomerAssignment(
        id: 'assign-1',
        customerId: 'cust-1',
        insideSalesId: 'inside-1',
        assignedBy: 'exec-1',
        status: 'assigned_to_inside_sales',
      );

      final map = assign.toFirestore();
      expect(map.containsKey('customerId'), isTrue);
      expect(map.containsKey('insideSalesId'), isTrue);
      expect(map.containsKey('assignedBy'), isTrue);
      expect(map.containsKey('status'), isTrue);
      expect(map.containsKey('createdAt'), isTrue);
      // No extra unexpected keys that would fail strict rule validation
      expect(map.containsKey('customerPhone'), isFalse);
    });
  });

  group('Attendance fail-closed logging tests', () {
    test(
      'attendance serializes without null keys and preserves failureReason',
      () {
        final att = Attendance(
          id: 'att-1',
          employeeId: 'emp-1',
          employeeName: 'Rohan',
          employeeEmail: 'rohan@estate.com',
          loginAt: DateTime.now(),
          loginAllowed: false,
          distanceMeters: 450.0,
          failureReason: 'geofence_exceeded',
        );

        final map = att.toFirestore();
        expect(map['employeeId'], 'emp-1');
        expect(map['loginAllowed'], isFalse);
        expect(map['distanceMeters'], 450.0);
        expect(map['failureReason'], 'geofence_exceeded');
        expect(map.containsKey('loginLatitude'), isFalse);
        expect(map.containsKey('loginLongitude'), isFalse);
      },
    );
  });

  group('LocationService fail-closed reasons', () {
    test('GeofenceFailureReason has defined error codes', () {
      expect(GeofenceFailureReason.gpsDisabled.code, 'gps_disabled');
      expect(GeofenceFailureReason.permissionDenied.code, 'permission_denied');
      expect(
        GeofenceFailureReason.permissionDeniedForever.code,
        'permission_denied_forever',
      );
      expect(GeofenceFailureReason.timeout.code, 'timeout');
      expect(GeofenceFailureReason.locationError.code, 'location_error');
    });

    test('GeofenceCheckResult constructs correctly with distance and failure reason', () {
      const failedResult = GeofenceCheckResult(
        isInside: false,
        distanceMeters: 350.0,
        message: 'Office geofence exceeded',
        failureReason: GeofenceFailureReason.permissionDenied,
      );

      expect(failedResult.isInside, isFalse);
      expect(failedResult.distanceMeters, 350.0);
      expect(
        failedResult.failureReason,
        GeofenceFailureReason.permissionDenied,
      );
    });
  });

  group('CustomerPhoneMigrationReport tests', () {
    test('Migration report tracks successes, failures, and counts', () {
      const report = CustomerPhoneMigrationReport(
        totalCustomers: 12,
        migratedCustomers: 12,
        failedCustomers: 0,
        totalVisits: 6,
        migratedVisits: 5,
        failedVisits: 1,
        errors: ['Visit visit-9 failed to commit'],
      );

      expect(report.totalCustomers, 12);
      expect(report.migratedCustomers, 12);
      expect(report.failedCustomers, 0);
      expect(report.totalVisits, 6);
      expect(report.migratedVisits, 5);
      expect(report.failedVisits, 1);
      expect(report.errors.length, 1);

      final summary = report.toString();
      expect(summary.contains('12/12 migrated'), isTrue);
      expect(summary.contains('5/6 migrated'), isTrue);
      expect(summary.contains('errors: 1'), isTrue);
    });
  });

  group('StaffDirectoryEntry serialization and validation tests', () {
    test('serializes to Firestore map correctly', () {
      const entry = StaffDirectoryEntry(
        id: 'outside-1',
        name: 'Rahul Sharma',
        role: AppRole.outsideSales,
        active: true,
      );

      final map = entry.toFirestore();
      expect(map['id'], 'outside-1');
      expect(map['name'], 'Rahul Sharma');
      expect(map['role'], 'outside_sales');
      expect(map['active'], isTrue);
      // Ensure no PII like phone, email, or dob is included
      expect(map.containsKey('phone'), isFalse);
      expect(map.containsKey('email'), isFalse);
      expect(map.containsKey('dob'), isFalse);
    });

    test('deserializes from Map correctly', () {
      final entry = StaffDirectoryEntry.fromMap('inside-1', {
        'name': 'Priya Singh',
        'role': 'inside_sales',
        'active': true,
      });

      expect(entry.id, 'inside-1');
      expect(entry.name, 'Priya Singh');
      expect(entry.role, AppRole.insideSales);
      expect(entry.active, isTrue);
    });

    test('fails closed when role is missing or invalid', () {
      expect(
        () => StaffDirectoryEntry.fromMap('bad-1', {
          'name': 'Invalid Role',
          'role': 'super_admin',
          'active': true,
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => StaffDirectoryEntry.fromMap('bad-2', {
          'name': 'Missing Role',
          'active': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('StaffDirectoryMigrationReport tests', () {
    test('tracks totals, migrated, existed, failed and errors', () {
      const report = StaffDirectoryMigrationReport(
        totalEmployees: 10,
        migrated: 6,
        alreadyExisted: 3,
        failed: 1,
        errors: ['Failed for employee emp-9: network timeout'],
      );

      expect(report.totalEmployees, 10);
      expect(report.migrated, 6);
      expect(report.alreadyExisted, 3);
      expect(report.failed, 1);
      expect(report.errors.length, 1);
      expect(report.toString().contains('total=10'), isTrue);
      expect(report.toString().contains('migrated=6'), isTrue);
      expect(report.toString().contains('alreadyExisted=3'), isTrue);
      expect(report.toString().contains('failed=1'), isTrue);
    });
  });

  group('StorageAvailabilityService tests', () {
    setUp(() {
      StorageAvailabilityService.clearCache();
    });

    tearDown(() {
      StorageAvailabilityService.clearCache();
    });

    test('returns ready when probe succeeds', () async {
      final service = StorageAvailabilityService(
        delegate: FakeStorageProbeDelegate((path) async {
          expect(path, '_healthcheck/probe');
        }),
      );

      final result = await service.checkAvailability();
      expect(result.status, StorageAvailabilityStatus.ready);
      expect(result.isReady, isTrue);
      expect(result.isUnauthorized, isFalse);
      expect(result.isUnprovisioned, isFalse);
      expect(StorageAvailabilityService.isReady, isTrue);
    });

    test('returns ready when probe throws object-not-found (bucket exists & authorized)', () async {
      final service = StorageAvailabilityService(
        delegate: FakeStorageProbeDelegate((path) async {
          throw FirebaseException(plugin: 'storage', code: 'object-not-found');
        }),
      );

      final result = await service.checkAvailability();
      expect(result.status, StorageAvailabilityStatus.ready);
      expect(result.isReady, isTrue);
      expect(StorageAvailabilityService.isReady, isTrue);
    });

    test('probes visit-specific path when visitId provided', () async {
      String? probedPath;
      final service = StorageAvailabilityService(
        delegate: FakeStorageProbeDelegate((path) async {
          probedPath = path;
        }),
      );

      final result = await service.checkAvailability(visitId: 'visit-123');
      expect(probedPath, 'visits/visit-123/_probe');
      expect(result.isReady, isTrue);
    });

    test('returns unauthorized when probe throws permission-denied', () async {
      final service = StorageAvailabilityService(
        delegate: FakeStorageProbeDelegate((path) async {
          throw FirebaseException(plugin: 'storage', code: 'permission-denied');
        }),
      );

      final result = await service.checkAvailability();
      expect(result.status, StorageAvailabilityStatus.unauthorized);
      expect(result.isUnauthorized, isTrue);
      expect(result.isReady, isFalse);
      expect(StorageAvailabilityService.isReady, isFalse);
    });

    test('returns unprovisioned when probe throws bucket-not-found or project-not-found', () async {
      final service = StorageAvailabilityService(
        delegate: FakeStorageProbeDelegate((path) async {
          throw FirebaseException(plugin: 'storage', code: 'bucket-not-found');
        }),
      );

      final result = await service.checkAvailability();
      expect(result.status, StorageAvailabilityStatus.unprovisioned);
      expect(result.isUnprovisioned, isTrue);
      expect(result.isReady, isFalse);
      expect(result.message.contains('Blaze plan configuration required'), isTrue);
    });

    test('returns networkError when probe throws network error', () async {
      final service = StorageAvailabilityService(
        delegate: FakeStorageProbeDelegate((path) async {
          throw FirebaseException(plugin: 'storage', code: 'network-request-failed');
        }),
      );

      final result = await service.checkAvailability();
      expect(result.status, StorageAvailabilityStatus.networkError);
      expect(result.isNetworkError, isTrue);
      expect(result.isReady, isFalse);
      // Network error is transient and should not be cached
      expect(StorageAvailabilityService.cachedResult, isNull);
    });

    test('caches non-transient result unless forceRefresh is true', () async {
      int probeCount = 0;
      final service = StorageAvailabilityService(
        delegate: FakeStorageProbeDelegate((path) async {
          probeCount++;
        }),
      );

      await service.checkAvailability();
      expect(probeCount, 1);

      await service.checkAvailability();
      expect(probeCount, 1); // cached

      await service.checkAvailability(forceRefresh: true);
      expect(probeCount, 2); // refreshed
    });
  });
}
