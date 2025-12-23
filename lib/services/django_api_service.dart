import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../core/constants/app_constants.dart';

final loggerProvider = Provider((_) => Logger());

final dioProvider = Provider((ref) {
  const String baseUrl = String.fromEnvironment(
    'DJANGO_API_URL',
    defaultValue: 'http://127.0.0.1:8000/api/',
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptor for token management
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getStoredToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired, trigger refresh or logout
          _handleUnauthorized();
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});

/// Django API Service
/// Handles all HTTP communication with Django REST API
class DjangoApiService {
  final Dio dio;
  final Logger logger;

  DjangoApiService({
    required this.dio,
    required this.logger,
  });

  // ==================== AUTHENTICATION ====================

  /// Register a new user
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    try {
      final response = await dio.post(
        'core/register/',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'role': role,
          'phone_number': phoneNumber,
        },
      );
      logger.i('User registered successfully');
      return response.data;
    } on DioException catch (e) {
      logger.e('Registration error: ${e.message}');
      rethrow;
    }
  }

  /// Login user and get JWT tokens
  Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '../auth/token/',
        data: {
          'username': username,
          'password': password,
        },
      );
      logger.i('User logged in successfully');
      return response.data;
    } on DioException catch (e) {
      logger.e('Login error: ${e.message}');
      rethrow;
    }
  }

  /// Refresh JWT access token
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await dio.post(
        '../auth/token/refresh/',
        data: {
          'refresh': refreshToken,
        },
      );
      logger.i('Token refreshed successfully');
      return response.data;
    } on DioException catch (e) {
      logger.e('Token refresh error: ${e.message}');
      rethrow;
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await dio.get('core/users/me/');
      logger.i('User profile fetched');
      return response.data;
    } on DioException catch (e) {
      logger.e('Get user error: ${e.message}');
      rethrow;
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? email,
    String? phoneNumber,
    String? profileImage,
    String? role,
  }) async {
    try {
      final response = await dio.patch(
        'core/users/$userId/',
        data: {
          if (email != null) 'email': email,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (profileImage != null) 'profile_image': profileImage,
          if (role != null) 'role': role,
        },
      );
      logger.i('User profile updated');
      return response.data;
    } on DioException catch (e) {
      logger.e('Update user error: ${e.message}');
      rethrow;
    }
  }

  // ==================== PRESCRIPTIONS ====================

  /// Get all prescriptions for current user
  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    try {
      final response = await dio.get('meds/prescriptions/');
      logger.i('Prescriptions fetched');
      return List<Map<String, dynamic>>.from(response.data is List ? response.data : response.data['results']);
    } on DioException catch (e) {
      logger.e('Get prescriptions error: ${e.message}');
      rethrow;
    }
  }

  /// Get single prescription
  Future<Map<String, dynamic>> getPrescription(String prescriptionId) async {
    try {
      final response = await dio.get('meds/prescriptions/$prescriptionId/');
      logger.i('Prescription fetched');
      return response.data;
    } on DioException catch (e) {
      logger.e('Get prescription error: ${e.message}');
      rethrow;
    }
  }

  /// Create new prescription
  Future<Map<String, dynamic>> createPrescription({
    required String medicationName,
    required String dosage,
    required String medicationType,
    required String frequency,
    required List<String> reminderTimes,
    required DateTime startDate,
    DateTime? endDate,
    String? instructions,
    String? notes,
    String? doctorId,
  }) async {
    try {
      final response = await dio.post(
        'meds/prescriptions/',
        data: {
          'medication_name': medicationName,
          'dosage': dosage,
          'medication_type': medicationType,
          'frequency': frequency,
          'reminder_times': reminderTimes,
          'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
          if (instructions != null) 'instructions': instructions,
          if (notes != null) 'notes': notes,
          if (doctorId != null) 'doctor_id': doctorId,
          'is_active': true,
        },
      );
      logger.i('Prescription created');
      return response.data;
    } on DioException catch (e) {
      logger.e('Create prescription error: ${e.message}');
      rethrow;
    }
  }

  /// Update prescription
  Future<Map<String, dynamic>> updatePrescription({
    required String prescriptionId,
    String? medicationName,
    String? dosage,
    String? frequency,
    List<String>? reminderTimes,
    DateTime? endDate,
    bool? isActive,
  }) async {
    try {
      final response = await dio.patch(
        'meds/prescriptions/$prescriptionId/',
        data: {
          if (medicationName != null) 'medication_name': medicationName,
          if (dosage != null) 'dosage': dosage,
          if (frequency != null) 'frequency': frequency,
          if (reminderTimes != null) 'reminder_times': reminderTimes,
          if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
          if (isActive != null) 'is_active': isActive,
        },
      );
      logger.i('Prescription updated');
      return response.data;
    } on DioException catch (e) {
      logger.e('Update prescription error: ${e.message}');
      rethrow;
    }
  }

  /// Delete prescription
  Future<void> deletePrescription(String prescriptionId) async {
    try {
      await dio.delete('meds/prescriptions/$prescriptionId/');
      logger.i('Prescription deleted');
    } on DioException catch (e) {
      logger.e('Delete prescription error: ${e.message}');
      rethrow;
    }
  }

  // ==================== MEDICATION LOGS ====================

  /// Get medication logs with optional prescription filter
  Future<List<Map<String, dynamic>>> getMedicationLogs({
    String? prescriptionId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (prescriptionId != null) {
        params['prescription_id'] = prescriptionId;
      }

      final response = await dio.get('meds/logs/', queryParameters: params);
      logger.i('Medication logs fetched');
      return List<Map<String, dynamic>>.from(response.data is List ? response.data : response.data['results']);
    } on DioException catch (e) {
      logger.e('Get medication logs error: ${e.message}');
      rethrow;
    }
  }

  /// Mark medication as taken
  Future<Map<String, dynamic>> markMedicationTaken({
    required String logId,
    String? notes,
  }) async {
    try {
      final response = await dio.post(
        'meds/logs/$logId/mark_taken/',
        data: {
          'is_taken': true,
          if (notes != null) 'notes': notes,
        },
      );
      logger.i('Medication marked as taken');
      return response.data;
    } on DioException catch (e) {
      logger.e('Mark taken error: ${e.message}');
      rethrow;
    }
  }

  /// Create medication log entry
  Future<Map<String, dynamic>> createMedicationLog({
    required String prescriptionId,
    required DateTime takenAt,
    required bool isTaken,
    String? notes,
  }) async {
    try {
      final response = await dio.post(
        'meds/logs/',
        data: {
          'prescription_id': prescriptionId,
          'taken_at': takenAt.toIso8601String(),
          'is_taken': isTaken,
          if (notes != null) 'notes': notes,
        },
      );
      logger.i('Medication log created');
      return response.data;
    } on DioException catch (e) {
      logger.e('Create log error: ${e.message}');
      rethrow;
    }
  }

  // ==================== NOTIFICATION PREFERENCES ====================

  /// Get notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final response = await dio.get('notifications/prefs/');
      logger.i('Notification preferences fetched');
      return response.data is Map ? response.data : response.data is List && response.data.isNotEmpty ? response.data[0] : {};
    } on DioException catch (e) {
      logger.e('Get notification prefs error: ${e.message}');
      rethrow;
    }
  }

  /// Update notification preferences
  Future<Map<String, dynamic>> updateNotificationPreferences({
    required bool enableMedicationReminders,
    required bool enableDailySummary,
    required String quietHoursStart,
    required String quietHoursEnd,
    List<String>? channels,
  }) async {
    try {
      final response = await dio.patch(
        'notifications/prefs/',
        data: {
          'enable_medication_reminders': enableMedicationReminders,
          'enable_daily_summary': enableDailySummary,
          'quiet_hours_start': quietHoursStart,
          'quiet_hours_end': quietHoursEnd,
          if (channels != null) 'channels': channels,
        },
      );
      logger.i('Notification preferences updated');
      return response.data;
    } on DioException catch (e) {
      logger.e('Update notification prefs error: ${e.message}');
      rethrow;
    }
  }

  // ==================== HEALTH CHECK ====================

  /// Check API connectivity
  Future<bool> healthCheck() async {
    try {
      final response = await dio.get('../');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// Helper function to get stored token
Future<String?> _getStoredToken() async {
  // Implementation will use shared_preferences
  // Placeholder for now
  return null;
}

// Helper function to handle unauthorized responses
void _handleUnauthorized() {
  // Implementation will trigger logout
  // Placeholder for now
}

/// Provider for Django API Service
final djangoApiServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final logger = ref.watch(loggerProvider);
  return DjangoApiService(dio: dio, logger: logger);
});
