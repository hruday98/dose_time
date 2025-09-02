import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:logger/logger.dart';
import '../core/constants/app_constants.dart';
import '../core/models/prescription_model.dart';
import '../core/models/medication_log_model.dart';
import '../core/utils/date_time_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final Logger _logger = Logger();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeLocalNotifications();
      await _initializePushNotifications();
      _isInitialized = true;
      _logger.i('Notification service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize notification service: $e');
      throw 'Failed to initialize notifications';
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // Request permissions for iOS
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Initialize push notifications
  Future<void> _initializePushNotifications() async {
    // Request permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    _logger.i('Push notification permission status: ${settings.authorizationStatus}');

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    _logger.i('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tapped when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTapped);

    // Handle notification when app is terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTapped(initialMessage);
    }
  }

  /// Handle foreground push messages
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Received foreground message: ${message.messageId}');
    
    // Show local notification for foreground messages
    _showLocalNotificationFromRemote(message);
  }

  /// Handle notification tapped
  void _handleNotificationTapped(RemoteMessage message) {
    _logger.i('Notification tapped: ${message.messageId}');
    
    final data = message.data;
    final type = data['type'];
    
    switch (type) {
      case 'medication_reminder':
        // Navigate to medication detail or log screen
        break;
      case 'prescription_created':
        // Navigate to prescription list
        break;
      case 'overdue_reminder':
        // Navigate to overdue medications
        break;
    }
  }

  /// Handle local notification tapped
  void _onNotificationTapped(NotificationResponse response) {
    _logger.i('Local notification tapped: ${response.id}');
    
    if (response.payload != null) {
      final payload = jsonDecode(response.payload!);
      final type = payload['type'];
      
      switch (type) {
        case 'medication_reminder':
          // Navigate to medication action screen
          break;
        case 'overdue_medication':
          // Navigate to overdue medications
          break;
      }
    }
  }

  /// Schedule medication reminders for a prescription
  Future<void> scheduleMedicationReminders(PrescriptionModel prescription) async {
    try {
      _logger.i('Scheduling reminders for prescription: ${prescription.id}');
      
      // Cancel existing reminders for this prescription
      await cancelMedicationReminders(prescription.id);
      
      final startDate = prescription.startDate;
      final endDate = prescription.endDate ?? startDate.add(const Duration(days: 30));
      
      for (final reminderTime in prescription.reminderTimes) {
        await _scheduleReminderSeries(
          prescription,
          reminderTime,
          startDate,
          endDate,
        );
      }
      
      _logger.i('Scheduled ${prescription.reminderTimes.length} reminder series for prescription ${prescription.id}');
    } catch (e) {
      _logger.e('Failed to schedule medication reminders: $e');
      throw 'Failed to schedule reminders';
    }
  }

  /// Schedule a series of reminders for a specific time
  Future<void> _scheduleReminderSeries(
    PrescriptionModel prescription,
    String reminderTime,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final timeParts = reminderTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day, hour, minute);
    
    // Skip if the first reminder time has already passed today
    if (currentDate.isBefore(DateTime.now())) {
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    int notificationId = _generateNotificationId(prescription.id, reminderTime);
    int dayCount = 0;
    const maxNotifications = 100; // Limit to prevent too many notifications
    
    while (currentDate.isBefore(endDate) && dayCount < maxNotifications) {
      // Check if this day should have a reminder based on frequency
      if (_shouldScheduleForDay(prescription.frequency, dayCount)) {
        await _scheduleIndividualReminder(
          notificationId + dayCount,
          prescription,
          currentDate,
          reminderTime,
        );
      }
      
      currentDate = currentDate.add(const Duration(days: 1));
      dayCount++;
    }
  }

  /// Check if reminder should be scheduled for a specific day based on frequency
  bool _shouldScheduleForDay(DosageFrequency frequency, int dayCount) {
    switch (frequency) {
      case DosageFrequency.everyOtherDay:
        return dayCount % 2 == 0;
      case DosageFrequency.weekly:
        return dayCount % 7 == 0;
      case DosageFrequency.asNeeded:
        return false; // Don't schedule automatic reminders for PRN
      default:
        return true; // Daily frequencies
    }
  }

  /// Schedule an individual reminder
  Future<void> _scheduleIndividualReminder(
    int notificationId,
    PrescriptionModel prescription,
    DateTime scheduledDate,
    String reminderTime,
  ) async {
    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
    
    final payload = jsonEncode({
      'type': 'medication_reminder',
      'prescriptionId': prescription.id,
      'scheduledTime': scheduledDate.toIso8601String(),
      'reminderTime': reminderTime,
    });

    await _localNotifications.zonedSchedule(
      notificationId,
      '💊 Medication Reminder',
      '${prescription.medicationName} - ${prescription.dosage}\nTap to mark as taken',
      scheduledTZ,
      _createNotificationDetails(prescription),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Create notification details
  NotificationDetails _createNotificationDetails(PrescriptionModel prescription) {
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('medication_reminder'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      actions: [
        AndroidNotificationAction(
          'mark_taken',
          'Mark as Taken',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'skip_dose',
          'Skip This Dose',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'medication_reminder',
      interruptionLevel: InterruptionLevel.active,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Cancel medication reminders for a prescription
  Future<void> cancelMedicationReminders(String prescriptionId) async {
    try {
      _logger.i('Cancelling reminders for prescription: $prescriptionId');
      
      // Get all pending notifications
      final pendingNotifications = await _localNotifications.pendingNotificationRequests();
      
      // Find and cancel notifications for this prescription
      for (final notification in pendingNotifications) {
        if (notification.payload != null) {
          try {
            final payload = jsonDecode(notification.payload!);
            if (payload['prescriptionId'] == prescriptionId) {
              await _localNotifications.cancel(notification.id);
            }
          } catch (e) {
            // Ignore payload decode errors
          }
        }
      }
      
      _logger.i('Cancelled reminders for prescription: $prescriptionId');
    } catch (e) {
      _logger.e('Failed to cancel medication reminders: $e');
    }
  }

  /// Send immediate notification
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
    NotificationDetails? notificationDetails,
  }) async {
    final details = notificationDetails ?? _createDefaultNotificationDetails();
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Create default notification details
  NotificationDetails _createDefaultNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Show local notification from remote message
  void _showLocalNotificationFromRemote(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showImmediateNotification(
        title: notification.title ?? 'DoseTime',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Schedule overdue medication notification
  Future<void> scheduleOverdueNotification(
    MedicationLogModel overdueLog,
    PrescriptionModel prescription,
  ) async {
    final payload = jsonEncode({
      'type': 'overdue_medication',
      'logId': overdueLog.id,
      'prescriptionId': prescription.id,
    });

    await showImmediateNotification(
      title: '⚠️ Overdue Medication',
      body: '${prescription.medicationName} was due at ${DateTimeUtils.formatTime(overdueLog.scheduledDateTime)}',
      payload: payload,
    );
  }

  /// Get FCM token for push notifications
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      _logger.e('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _logger.i('Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _logger.i('Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Generate unique notification ID
  int _generateNotificationId(String prescriptionId, String reminderTime) {
    final combined = '$prescriptionId-$reminderTime';
    return combined.hashCode.abs();
  }

  /// Get pending notification count
  Future<int> getPendingNotificationCount() async {
    final pendingNotifications = await _localNotifications.pendingNotificationRequests();
    return pendingNotifications.length;
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    _logger.i('Cancelled all notifications');
  }

  /// Test notification (for development)
  Future<void> showTestNotification() async {
    await showImmediateNotification(
      title: '🧪 Test Notification',
      body: 'This is a test notification from DoseTime',
      payload: jsonEncode({'type': 'test'}),
    );
  }

  /// Dispose resources
  void dispose() {
    // Clean up resources if needed
  }
}
