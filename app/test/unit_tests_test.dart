import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_sales_app/models/employee.dart';
import 'package:real_estate_sales_app/models/customer.dart';
import 'package:real_estate_sales_app/models/visit.dart';
import 'package:real_estate_sales_app/models/attendance.dart';
import 'package:real_estate_sales_app/models/customer_assignment.dart';
import 'package:real_estate_sales_app/services/call_service.dart';
import 'package:real_estate_sales_app/services/location_service.dart';
import 'package:real_estate_sales_app/services/database_service.dart';
import 'package:real_estate_sales_app/services/storage_availability_service.dart';

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

  group('StorageAvailabilityService tests', () {
    tearDown(() {
      StorageAvailabilityService.setMockAvailability(null);
    });

    test('cachedStatus returns false when cache is empty', () {
      StorageAvailabilityService.setMockAvailability(null);
      expect(StorageAvailabilityService.cachedStatus, isFalse);
    });

    test('cachedStatus returns true when mock availability is set to true', () {
      StorageAvailabilityService.setMockAvailability(true);
      expect(StorageAvailabilityService.cachedStatus, isTrue);
    });

    test('cachedStatus returns false when mock availability is set to false', () {
      StorageAvailabilityService.setMockAvailability(false);
      expect(StorageAvailabilityService.cachedStatus, isFalse);
    });
  });
}
