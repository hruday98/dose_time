import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/prescription_model.dart';
import '../../../core/utils/utils.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../providers/dashboard_providers.dart';

class MedicationTimeline extends ConsumerWidget {
  final List<MedicationLog> logs;

  const MedicationTimeline({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedLogs = List<MedicationLog>.from(logs)
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    return Column(
      children: [
        ...sortedLogs.asMap().entries.map((entry) {
          final index = entry.key;
          final log = entry.value;
          final isLast = index == sortedLogs.length - 1;
          
          return MedicationTimelineItem(
            log: log,
            isLast: isLast,
          );
        }),
      ],
    );
  }
}

class MedicationTimelineItem extends ConsumerWidget {
  final MedicationLog log;
  final bool isLast;

  const MedicationTimelineItem({
    super.key,
    required this.log,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationAction = ref.watch(medicationActionProvider);
    final statusColor = ColorUtils.getMedicationStatusColor(log.status.name);
    final scheduledTime = log.scheduledTime.toDate();
    final isOverdue = log.isOverdue;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getStatusIcon(log.status),
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          
          // Medication card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppConstants.paddingMedium,
              ),
              child: Card(
                elevation: 1,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateTimeUtils.formatTime(scheduledTime.toTimeOfDay()),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isOverdue ? Colors.red : null,
                                  ),
                                ),
                                Text(
                                  'Medication Name', // Replace with actual medication name
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  'Dosage info', // Replace with actual dosage
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingSmall,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              log.status.displayName,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Notes
                      if (log.notes != null) ...[
                        const SizedBox(height: AppConstants.paddingSmall),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppConstants.paddingSmall),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                          ),
                          child: Text(
                            log.notes!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                      
                      // Action buttons
                      if (log.status == MedicationStatus.upcoming || log.status == MedicationStatus.overdue) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: medicationAction.isLoading ? null : () => _skipMedication(ref, log),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Skip'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.paddingSmall,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppConstants.paddingSmall),
                            if (log.status == MedicationStatus.upcoming) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: medicationAction.isLoading ? null : () => _snoozeMedication(ref, log),
                                  icon: const Icon(Icons.snooze, size: 16),
                                  label: const Text('Snooze'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppConstants.paddingSmall,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppConstants.paddingSmall),
                            ],
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: medicationAction.isLoading ? null : () => _markTaken(ref, log),
                                icon: medicationAction.isLoading 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.check, size: 16),
                                label: const Text('Taken'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.paddingSmall,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Taken time
                      if (log.takenTime != null) ...[
                        const SizedBox(height: AppConstants.paddingSmall),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Taken at ${DateTimeUtils.formatTime(log.takenTime!.toTimeOfDay())}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return Icons.check;
      case MedicationStatus.missed:
        return Icons.close;
      case MedicationStatus.skipped:
        return Icons.remove;
      case MedicationStatus.overdue:
        return Icons.warning;
      case MedicationStatus.upcoming:
        return Icons.schedule;
    }
  }

  void _markTaken(WidgetRef ref, MedicationLog log) {
    ref.read(medicationActionProvider.notifier).markMedicationTaken(log);
  }

  void _skipMedication(WidgetRef ref, MedicationLog log) {
    ref.read(medicationActionProvider.notifier).skipMedication(log, reason: 'Skipped by user');
  }

  void _snoozeMedication(WidgetRef ref, MedicationLog log) {
    ref.read(medicationActionProvider.notifier).snoozeMedication(log, AppConstants.snoozeMinutes);
  }
}
