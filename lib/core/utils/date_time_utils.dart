/// DateTimeUtils provides utility functions for date and time operations
class DateTimeUtils {
  /// Converts a DateTime to a time-only string in HH:mm format
  static String timeOnly(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Converts a time string (HH:mm) to minutes since midnight
  static int timeStringToMinutes(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  /// Converts minutes since midnight to HH:mm format
  static String minutesToTimeString(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Checks if a time string is between two other time strings
  static bool isTimeBetween(String timeToCheck, String startTime, String endTime) {
    final checkMinutes = timeStringToMinutes(timeToCheck);
    final startMinutes = timeStringToMinutes(startTime);
    final endMinutes = timeStringToMinutes(endTime);

    if (startMinutes <= endMinutes) {
      return checkMinutes >= startMinutes && checkMinutes <= endMinutes;
    } else {
      return checkMinutes >= startMinutes || checkMinutes <= endMinutes;
    }
  }

  /// Gets the difference in days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Checks if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Checks if a date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  /// Converts DateTime to Firebase Timestamp format
  static String toFirestoreTimestamp(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Converts ISO 8601 string to DateTime
  static DateTime fromFirestoreTimestamp(String timestamp) {
    return DateTime.parse(timestamp);
  }

  /// Formats a DateTime for display (e.g., "Dec 21, 2025")
  static String formatForDisplay(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  /// Formats a DateTime with time for display (e.g., "Dec 21, 2025 3:45 PM")
  static String formatWithTimeForDisplay(DateTime dateTime) {
    final date = formatForDisplay(dateTime);
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$date ${hour}:$minute $period';
  }
}
