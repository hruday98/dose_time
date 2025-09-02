class AppConstants {
  // App Info
  static const String appName = 'DoseTime';
  static const String appVersion = '1.0.0';
  
  // User Roles
  static const String rolePatient = 'patient';
  static const String roleDoctor = 'doctor';
  static const String roleCaretaker = 'caretaker';
  
  // Hive Box Names
  static const String userBoxName = 'user_box';
  static const String prescriptionsBoxName = 'prescriptions_box';
  static const String medicationLogsBoxName = 'medication_logs_box';
  static const String settingsBoxName = 'settings_box';
  
  // Notification Channels
  static const String medicationChannelId = 'medication_reminders';
  static const String medicationChannelName = 'Medication Reminders';
  static const String medicationChannelDescription = 'Notifications for medication reminders';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String prescriptionsCollection = 'prescriptions';
  static const String medicationLogsCollection = 'medication_logs';
  static const String doctorsCollection = 'doctors';
  static const String caretakersCollection = 'caretakers';
  
  // Routes
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String dashboardRoute = '/dashboard';
  static const String prescriptionsRoute = '/prescriptions';
  static const String remindersRoute = '/reminders';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  
  // Time Constants
  static const int defaultReminderHour = 8; // 8 AM
  static const int defaultReminderMinute = 0;
  static const int snoozeMinutes = 10;
  
  // UI Constants
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Elderly-friendly UI
  static const double minTapTargetSize = 48.0;
  static const double largeFontSize = 18.0;
  static const double extraLargeFontSize = 24.0;
  static const double buttonHeight = 56.0;
}

enum UserRole {
  patient,
  doctor,
  caretaker;
  
  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.caretaker:
        return 'Caretaker';
    }
  }
}

enum MedicationType {
  tablet,
  capsule,
  liquid,
  injection,
  cream,
  inhaler,
  drops,
  patch;
  
  String get displayName {
    switch (this) {
      case MedicationType.tablet:
        return 'Tablet';
      case MedicationType.capsule:
        return 'Capsule';
      case MedicationType.liquid:
        return 'Liquid';
      case MedicationType.injection:
        return 'Injection';
      case MedicationType.cream:
        return 'Cream/Ointment';
      case MedicationType.inhaler:
        return 'Inhaler';
      case MedicationType.drops:
        return 'Drops';
      case MedicationType.patch:
        return 'Patch';
    }
  }
}

enum DosageFrequency {
  onceDaily,
  twiceDaily,
  threeTimesDaily,
  fourTimesDaily,
  everyOtherDay,
  weekly,
  asNeeded;
  
  String get displayName {
    switch (this) {
      case DosageFrequency.onceDaily:
        return 'Once daily';
      case DosageFrequency.twiceDaily:
        return 'Twice daily';
      case DosageFrequency.threeTimesDaily:
        return 'Three times daily';
      case DosageFrequency.fourTimesDaily:
        return 'Four times daily';
      case DosageFrequency.everyOtherDay:
        return 'Every other day';
      case DosageFrequency.weekly:
        return 'Weekly';
      case DosageFrequency.asNeeded:
        return 'As needed';
    }
  }
}
