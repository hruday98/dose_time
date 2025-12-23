import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import './django_api_service.dart';

class NotificationPreferenceService {
  final DjangoApiService apiService;
  final Logger logger;

  NotificationPreferenceService({
    required this.apiService,
    required this.logger,
  });

  // Get notification preferences
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final prefs = await apiService.getNotificationPreferences();
      logger.i('Fetched notification preferences');
      return prefs;
    } catch (e) {
      logger.e('Error fetching notification preferences: $e');
      rethrow;
    }
  }

  // Update notification preferences
  Future<Map<String, dynamic>> updatePreferences({
    required bool enableMedicationReminders,
    required bool enableDailySummary,
    required String quietHoursStart,
    required String quietHoursEnd,
    List<String>? channels,
  }) async {
    try {
      final updated = await apiService.updateNotificationPreferences(
        enableMedicationReminders: enableMedicationReminders,
        enableDailySummary: enableDailySummary,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
        channels: channels,
      );
      logger.i('Updated notification preferences');
      return updated;
    } catch (e) {
      logger.e('Error updating notification preferences: $e');
      rethrow;
    }
  }
}

/// Provider for NotificationPreferenceService
final notificationPreferenceServiceProvider = Provider((ref) {
  final apiService = ref.watch(djangoApiServiceProvider);
  final logger = ref.watch(loggerProvider);
  return NotificationPreferenceService(apiService: apiService, logger: logger);
});

/// Provider for notification preferences
final notificationPreferencesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(notificationPreferenceServiceProvider);
  return service.getPreferences();
});
