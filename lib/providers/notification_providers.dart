import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../core/models/prescription_model.dart';
import '../core/models/medication_log_model.dart';

// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Notification Permission State Provider
final notificationPermissionProvider = StateNotifierProvider<NotificationPermissionNotifier, NotificationPermissionState>((ref) {
  return NotificationPermissionNotifier(ref);
});

class NotificationPermissionNotifier extends StateNotifier<NotificationPermissionState> {
  final Ref _ref;
  
  NotificationPermissionNotifier(this._ref) : super(const NotificationPermissionState.unknown());

  NotificationService get _notificationService => _ref.read(notificationServiceProvider);

  Future<void> initialize() async {
    state = const NotificationPermissionState.loading();
    
    try {
      await _notificationService.initialize();
      state = const NotificationPermissionState.granted();
    } catch (e) {
      state = NotificationPermissionState.denied(e.toString());
    }
  }

  Future<void> requestPermission() async {
    state = const NotificationPermissionState.loading();
    
    try {
      await _notificationService.initialize();
      state = const NotificationPermissionState.granted();
    } catch (e) {
      state = NotificationPermissionState.denied(e.toString());
    }
  }

  Future<String?> getFCMToken() async {
    return await _notificationService.getFCMToken();
  }

  Future<void> showTestNotification() async {
    await _notificationService.showTestNotification();
  }
}

// Notification Permission State
sealed class NotificationPermissionState {
  const NotificationPermissionState();
  
  const factory NotificationPermissionState.unknown() = NotificationPermissionUnknown;
  const factory NotificationPermissionState.loading() = NotificationPermissionLoading;
  const factory NotificationPermissionState.granted() = NotificationPermissionGranted;
  const factory NotificationPermissionState.denied(String reason) = NotificationPermissionDenied;
}

class NotificationPermissionUnknown extends NotificationPermissionState {
  const NotificationPermissionUnknown();
}

class NotificationPermissionLoading extends NotificationPermissionState {
  const NotificationPermissionLoading();
}

class NotificationPermissionGranted extends NotificationPermissionState {
  const NotificationPermissionGranted();
}

class NotificationPermissionDenied extends NotificationPermissionState {
  final String reason;
  const NotificationPermissionDenied(this.reason);
}

// Medication Reminder Management Provider
final medicationReminderProvider = StateNotifierProvider<MedicationReminderNotifier, AsyncValue<void>>((ref) {
  return MedicationReminderNotifier(ref);
});

class MedicationReminderNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  
  MedicationReminderNotifier(this._ref) : super(const AsyncValue.data(null));

  NotificationService get _notificationService => _ref.read(notificationServiceProvider);

  Future<void> scheduleReminders(PrescriptionModel prescription) async {
    state = const AsyncValue.loading();
    
    try {
      await _notificationService.scheduleMedicationReminders(prescription);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cancelReminders(String prescriptionId) async {
    state = const AsyncValue.loading();
    
    try {
      await _notificationService.cancelMedicationReminders(prescriptionId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> scheduleOverdueNotification(
    MedicationLogModel overdueLog,
    PrescriptionModel prescription,
  ) async {
    try {
      await _notificationService.scheduleOverdueNotification(overdueLog, prescription);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notificationService.showImmediateNotification(
        title: title,
        body: body,
        payload: payload,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<int> getPendingNotificationCount() async {
    return await _notificationService.getPendingNotificationCount();
  }

  Future<void> cancelAllNotifications() async {
    state = const AsyncValue.loading();
    
    try {
      await _notificationService.cancelAllNotifications();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Notification Settings Provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsNotifier extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsNotifier() : super(NotificationSettingsState.defaultSettings());

  void updateMedicationRemindersEnabled(bool enabled) {
    state = state.copyWith(medicationRemindersEnabled: enabled);
  }

  void updateOverdueRemindersEnabled(bool enabled) {
    state = state.copyWith(overdueRemindersEnabled: enabled);
  }

  void updateSoundEnabled(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
  }

  void updateVibrationEnabled(bool enabled) {
    state = state.copyWith(vibrationEnabled: enabled);
  }

  void updateReminderAdvanceTime(int minutes) {
    state = state.copyWith(reminderAdvanceTimeMinutes: minutes);
  }

  void updateQuietHoursEnabled(bool enabled) {
    state = state.copyWith(quietHoursEnabled: enabled);
  }

  void updateQuietHoursStart(String time) {
    state = state.copyWith(quietHoursStart: time);
  }

  void updateQuietHoursEnd(String time) {
    state = state.copyWith(quietHoursEnd: time);
  }

  void reset() {
    state = NotificationSettingsState.defaultSettings();
  }
}

class NotificationSettingsState {
  final bool medicationRemindersEnabled;
  final bool overdueRemindersEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int reminderAdvanceTimeMinutes;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  const NotificationSettingsState({
    required this.medicationRemindersEnabled,
    required this.overdueRemindersEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.reminderAdvanceTimeMinutes,
    required this.quietHoursEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
  });

  factory NotificationSettingsState.defaultSettings() {
    return const NotificationSettingsState(
      medicationRemindersEnabled: true,
      overdueRemindersEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      reminderAdvanceTimeMinutes: 0,
      quietHoursEnabled: false,
      quietHoursStart: '22:00',
      quietHoursEnd: '07:00',
    );
  }

  NotificationSettingsState copyWith({
    bool? medicationRemindersEnabled,
    bool? overdueRemindersEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? reminderAdvanceTimeMinutes,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationSettingsState(
      medicationRemindersEnabled: medicationRemindersEnabled ?? this.medicationRemindersEnabled,
      overdueRemindersEnabled: overdueRemindersEnabled ?? this.overdueRemindersEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      reminderAdvanceTimeMinutes: reminderAdvanceTimeMinutes ?? this.reminderAdvanceTimeMinutes,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}

// FCM Token Provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  return await notificationService.getFCMToken();
});

// Pending Notification Count Provider
final pendingNotificationCountProvider = FutureProvider<int>((ref) async {
  final notificationService = ref.read(notificationServiceProvider);
  return await notificationService.getPendingNotificationCount();
});
