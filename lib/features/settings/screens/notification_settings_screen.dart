import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elderly_button.dart';
import '../../../core/widgets/elderly_time_picker.dart';
import '../../../core/utils/dialogs.dart';
import '../../../providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final notificationPermission = ref.watch(notificationPermissionProvider);
    final pendingCount = ref.watch(pendingNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: AppTextStyles.headlineLarge,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionSection(context, ref, notificationPermission),
            const SizedBox(height: AppSizes.spacingLarge),
            _buildMedicationRemindersSection(context, ref, notificationSettings),
            const SizedBox(height: AppSizes.spacingLarge),
            _buildNotificationPreferencesSection(context, ref, notificationSettings),
            const SizedBox(height: AppSizes.spacingLarge),
            _buildQuietHoursSection(context, ref, notificationSettings),
            const SizedBox(height: AppSizes.spacingLarge),
            _buildManagementSection(context, ref, pendingCount),
            const SizedBox(height: AppSizes.spacingLarge),
            _buildTestSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSection(BuildContext context, WidgetRef ref, NotificationPermissionState permissionState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Permission',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            
            ListTile(
              leading: Icon(
                _getPermissionIcon(permissionState),
                size: AppSizes.iconLarge,
                color: _getPermissionColor(permissionState),
              ),
              title: Text(
                _getPermissionTitle(permissionState),
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _getPermissionSubtitle(permissionState),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: permissionState is NotificationPermissionDenied
                  ? ElderlyButton(
                      label: 'Grant Permission',
                      onPressed: () => _requestPermission(context, ref),
                      variant: ElderlyButtonVariant.primary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationRemindersSection(BuildContext context, WidgetRef ref, NotificationSettingsState settings) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medication Reminders',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            
            SwitchListTile(
              title: Text(
                'Enable Medication Reminders',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                'Get notified when it\'s time to take your medication',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              value: settings.medicationRemindersEnabled,
              onChanged: (value) => ref.read(notificationSettingsProvider.notifier)
                  .updateMedicationRemindersEnabled(value),
              activeColor: AppColors.primary,
            ),
            
            const Divider(),
            
            SwitchListTile(
              title: Text(
                'Overdue Reminders',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                'Get notified about missed medications',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              value: settings.overdueRemindersEnabled,
              onChanged: settings.medicationRemindersEnabled
                  ? (value) => ref.read(notificationSettingsProvider.notifier)
                      .updateOverdueRemindersEnabled(value)
                  : null,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPreferencesSection(BuildContext context, WidgetRef ref, NotificationSettingsState settings) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Preferences',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            
            SwitchListTile(
              title: Text(
                'Sound',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                'Play sound when notifications arrive',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              value: settings.soundEnabled,
              onChanged: (value) => ref.read(notificationSettingsProvider.notifier)
                  .updateSoundEnabled(value),
              activeColor: AppColors.primary,
            ),
            
            const Divider(),
            
            SwitchListTile(
              title: Text(
                'Vibration',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                'Vibrate device when notifications arrive',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              value: settings.vibrationEnabled,
              onChanged: (value) => ref.read(notificationSettingsProvider.notifier)
                  .updateVibrationEnabled(value),
              activeColor: AppColors.primary,
            ),
            
            const Divider(),
            
            ListTile(
              title: Text(
                'Reminder Advance Time',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                'Remind me ${settings.reminderAdvanceTimeMinutes} minutes before scheduled time',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: DropdownButton<int>(
                value: settings.reminderAdvanceTimeMinutes,
                items: [0, 5, 10, 15, 30]
                    .map((minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text(
                            minutes == 0 ? 'On time' : '$minutes min before',
                            style: AppTextStyles.bodyLarge,
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(notificationSettingsProvider.notifier)
                        .updateReminderAdvanceTime(value);
                  }
                },
                underline: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSection(BuildContext context, WidgetRef ref, NotificationSettingsState settings) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiet Hours',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            
            SwitchListTile(
              title: Text(
                'Enable Quiet Hours',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                'Reduce notification sounds during specified hours',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              value: settings.quietHoursEnabled,
              onChanged: (value) => ref.read(notificationSettingsProvider.notifier)
                  .updateQuietHoursEnabled(value),
              activeColor: AppColors.primary,
            ),
            
            if (settings.quietHoursEnabled) ...[
              const Divider(),
              const SizedBox(height: AppSizes.spacingMedium),
              
              Row(
                children: [
                  Expanded(
                    child: ElderlyTimePicker(
                      label: 'Start Time',
                      initialTime: settings.quietHoursStart,
                      onTimeChanged: (time) => ref.read(notificationSettingsProvider.notifier)
                          .updateQuietHoursStart(time),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingMedium),
                  Expanded(
                    child: ElderlyTimePicker(
                      label: 'End Time',
                      initialTime: settings.quietHoursEnd,
                      onTimeChanged: (time) => ref.read(notificationSettingsProvider.notifier)
                          .updateQuietHoursEnd(time),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection(BuildContext context, WidgetRef ref, AsyncValue<int> pendingCount) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Management',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            
            ListTile(
              leading: const Icon(Icons.notifications, size: AppSizes.iconLarge),
              title: Text(
                'Pending Notifications',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                pendingCount.when(
                  data: (count) => '$count notifications scheduled',
                  loading: () => 'Loading...',
                  error: (_, __) => 'Error loading count',
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: pendingCount.when(
                data: (count) => count > 0 
                    ? ElderlyButton(
                        label: 'Clear All',
                        onPressed: () => _clearAllNotifications(context, ref),
                        variant: ElderlyButtonVariant.secondary,
                      )
                    : null,
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Notifications',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            
            ListTile(
              leading: const Icon(Icons.play_arrow, size: AppSizes.iconLarge),
              title: Text(
                'Send Test Notification',
                style: AppTextStyles.bodyLarge,
              ),
              subtitle: Text(
                'Test your notification settings',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: ElderlyButton(
                label: 'Test',
                onPressed: () => _sendTestNotification(context, ref),
                variant: ElderlyButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  IconData _getPermissionIcon(NotificationPermissionState state) {
    return switch (state) {
      NotificationPermissionGranted() => Icons.check_circle,
      NotificationPermissionDenied() => Icons.error,
      NotificationPermissionLoading() => Icons.hourglass_empty,
      _ => Icons.help_outline,
    };
  }

  Color _getPermissionColor(NotificationPermissionState state) {
    return switch (state) {
      NotificationPermissionGranted() => AppColors.success,
      NotificationPermissionDenied() => AppColors.error,
      NotificationPermissionLoading() => AppColors.warning,
      _ => AppColors.onSurface,
    };
  }

  String _getPermissionTitle(NotificationPermissionState state) {
    return switch (state) {
      NotificationPermissionGranted() => 'Notifications Enabled',
      NotificationPermissionDenied() => 'Notifications Disabled',
      NotificationPermissionLoading() => 'Checking Permissions...',
      _ => 'Permission Unknown',
    };
  }

  String _getPermissionSubtitle(NotificationPermissionState state) {
    return switch (state) {
      NotificationPermissionGranted() => 'You\'ll receive medication reminders',
      NotificationPermissionDenied() => 'Enable notifications to receive reminders',
      NotificationPermissionLoading() => 'Please wait...',
      _ => 'Tap to check notification permissions',
    };
  }

  Future<void> _requestPermission(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationPermissionProvider.notifier).requestPermission();
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          'Notification permission granted!',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          'Failed to grant permission: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _clearAllNotifications(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialogs.showConfirmationDialog(
      context,
      title: 'Clear All Notifications',
      content: 'Are you sure you want to cancel all scheduled notifications?',
      confirmText: 'Clear All',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await ref.read(medicationReminderProvider.notifier).cancelAllNotifications();
        if (context.mounted) {
          AppDialogs.showSnackBar(
            context,
            'All notifications cleared!',
            type: SnackBarType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppDialogs.showSnackBar(
            context,
            'Failed to clear notifications: $e',
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  Future<void> _sendTestNotification(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationPermissionProvider.notifier).showTestNotification();
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          'Test notification sent!',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          'Failed to send test notification: $e',
          type: SnackBarType.error,
        );
      }
    }
  }
}

