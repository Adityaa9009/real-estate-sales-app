import 'package:firebase_storage/firebase_storage.dart';

enum StorageAvailabilityStatus {
  ready,
  unprovisioned,
  unauthorized,
  networkError,
}

class StorageCheckResult {
  final StorageAvailabilityStatus status;
  final String message;
  final dynamic error;

  const StorageCheckResult({
    required this.status,
    required this.message,
    this.error,
  });

  bool get isReady => status == StorageAvailabilityStatus.ready;
  bool get isUnprovisioned => status == StorageAvailabilityStatus.unprovisioned;
  bool get isUnauthorized => status == StorageAvailabilityStatus.unauthorized;
  bool get isNetworkError => status == StorageAvailabilityStatus.networkError;
}

/// Abstract probe delegate for testability without production mutable state
abstract class StorageProbeDelegate {
  Future<void> probePath(String path);
}

class FirebaseStorageProbeDelegate implements StorageProbeDelegate {
  final FirebaseStorage storage;
  FirebaseStorageProbeDelegate({FirebaseStorage? storage})
      : storage = storage ?? FirebaseStorage.instance;

  @override
  Future<void> probePath(String path) async {
    await storage.ref(path).getMetadata();
  }
}

class StorageAvailabilityService {
  final StorageProbeDelegate _delegate;

  StorageAvailabilityService({StorageProbeDelegate? delegate})
      : _delegate = delegate ?? FirebaseStorageProbeDelegate();

  static StorageCheckResult? _cachedResult;

  /// Returns the most recent check result, or null if not yet checked
  static StorageCheckResult? get cachedResult => _cachedResult;

  /// Quick check whether Storage was verified as ready
  static bool get isReady => _cachedResult?.isReady ?? false;

  /// Evaluates Firebase Storage readiness for the current user and context.
  /// If [visitId] is provided, probes the visit's authorized storage path.
  /// Otherwise, probes the employee '_healthcheck/probe' path.
  Future<StorageCheckResult> checkAvailability({
    String? visitId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedResult != null) {
      return _cachedResult!;
    }

    final probePath = visitId != null
        ? 'visits/$visitId/_probe'
        : '_healthcheck/probe';

    try {
      await _delegate.probePath(probePath);
      final result = const StorageCheckResult(
        status: StorageAvailabilityStatus.ready,
        message: 'Firebase Storage is reachable and ready.',
      );
      _cachedResult = result;
      return result;
    } on FirebaseException catch (e) {
      final code = e.code.toLowerCase();
      final msg = (e.message ?? '').toLowerCase();

      // object-not-found means bucket exists and rules permitted the probe!
      if (code == 'object-not-found') {
        final result = const StorageCheckResult(
          status: StorageAvailabilityStatus.ready,
          message: 'Firebase Storage is provisioned and authorized.',
        );
        _cachedResult = result;
        return result;
      }

      // Explicit permission denied by security rules
      if (code == 'permission-denied' || code == 'unauthorized') {
        final result = StorageCheckResult(
          status: StorageAvailabilityStatus.unauthorized,
          message:
              'Firebase Storage is configured, but current user is not authorized for this action.',
          error: e,
        );
        _cachedResult = result;
        return result;
      }

      // Network connection issues
      if (code == 'network-request-failed' ||
          code == 'timeout' ||
          msg.contains('network') ||
          msg.contains('socket')) {
        final result = StorageCheckResult(
          status: StorageAvailabilityStatus.networkError,
          message: 'Network connection failed while checking Cloud Storage.',
          error: e,
        );
        return result; // do not cache transient network errors
      }

      // Unprovisioned bucket, missing project, or billing required
      if (code == 'bucket-not-found' ||
          code == 'project-not-found' ||
          msg.contains('not found') ||
          msg.contains('billing') ||
          msg.contains('unregistered') ||
          msg.contains('no such bucket')) {
        final result = StorageCheckResult(
          status: StorageAvailabilityStatus.unprovisioned,
          message:
              'Firebase Cloud Storage is not enabled on this project. Blaze plan configuration required.',
          error: e,
        );
        _cachedResult = result;
        return result;
      }

      // Default to unprovisioned for unknown setup errors
      final result = StorageCheckResult(
        status: StorageAvailabilityStatus.unprovisioned,
        message:
            'Firebase Storage is unconfigured: ${e.message ?? e.code}',
        error: e,
      );
      _cachedResult = result;
      return result;
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('network') || str.contains('socket') || str.contains('connection')) {
        return StorageCheckResult(
          status: StorageAvailabilityStatus.networkError,
          message: 'Network connection failed while checking Cloud Storage.',
          error: e,
        );
      }
      final result = StorageCheckResult(
        status: StorageAvailabilityStatus.unprovisioned,
        message: 'Firebase Storage unavailable: $e',
        error: e,
      );
      _cachedResult = result;
      return result;
    }
  }

  /// Convenience static check using default delegate
  static Future<StorageCheckResult> check({
    String? visitId,
    bool forceRefresh = false,
  }) {
    return StorageAvailabilityService().checkAvailability(
      visitId: visitId,
      forceRefresh: forceRefresh,
    );
  }

  /// Clears cached check state (e.g. on logout or between tests)
  static void clearCache() {
    _cachedResult = null;
  }
}
