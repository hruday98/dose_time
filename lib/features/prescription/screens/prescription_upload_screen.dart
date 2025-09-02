import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elderly_button.dart';
import '../../../core/widgets/elderly_text_field.dart';
import '../../../core/widgets/elderly_dropdown.dart';
import '../../../core/widgets/elderly_time_picker.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/error_widget.dart' as custom;
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../providers/prescription_providers.dart';
import '../../../providers/auth_providers.dart';

class PrescriptionUploadScreen extends ConsumerStatefulWidget {
  const PrescriptionUploadScreen({super.key});

  @override
  ConsumerState<PrescriptionUploadScreen> createState() => _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends ConsumerState<PrescriptionUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrTextExtractionProvider);
    final formState = ref.watch(prescriptionFormProvider);
    final prescriptionState = ref.watch(prescriptionManagementProvider);
    final user = ref.watch(userModelProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Prescription',
          style: AppTextStyles.headlineLarge,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (ocrState is OCRExtractionSuccess)
            TextButton(
              onPressed: () => _resetOCR(ref),
              child: Text(
                'Reset',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: prescriptionState.isLoading,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCaptureSection(ocrState),
                const SizedBox(height: AppSizes.spacingLarge),
                _buildExtractedTextSection(ocrState),
                const SizedBox(height: AppSizes.spacingLarge),
                _buildPrescriptionForm(formState),
                const SizedBox(height: AppSizes.spacingXLarge),
                _buildActionButtons(formState, user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCaptureSection(OCRExtractionState ocrState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capture Prescription',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            
            if (ocrState is OCRExtractionLoading) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSizes.spacingMedium),
                    Text(
                      'Processing prescription image...',
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
            ] else if (ocrState is OCRExtractionSuccess) ...[
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    child: Image.file(
                      File(ocrState.imagePath),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image processed successfully!',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingSmall),
                        Text(
                          'Extracted ${ocrState.extractedText.length} characters',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (ocrState.parsedPrescription != null)
                          Text(
                            'Found: ${ocrState.parsedPrescription!.medicationName}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else if (ocrState is OCRExtractionError) ...[
              custom.ErrorWidget(
                message: ocrState.message,
                onRetry: () => _resetOCR(ref),
              ),
            ] else ...[
              Text(
                'Take a photo or select from gallery to automatically extract prescription information.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSizes.spacingMedium),
              Row(
                children: [
                  Expanded(
                    child: ElderlyButton(
                      text: 'Camera',
                      icon: Icons.camera_alt,
                      onPressed: () => _captureFromCamera(ref),
                      variant: ElderlyButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingMedium),
                  Expanded(
                    child: ElderlyButton(
                      text: 'Gallery',
                      icon: Icons.photo_library,
                      onPressed: () => _captureFromGallery(ref),
                      variant: ElderlyButtonVariant.secondary,
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

  Widget _buildExtractedTextSection(OCRExtractionState ocrState) {
    if (ocrState is! OCRExtractionSuccess || ocrState.extractedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Extracted Text',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: AppColors.outline.withOpacity(0.5)),
              ),
              child: Text(
                ocrState.extractedText,
                style: AppTextStyles.bodyMedium,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (ocrState.parsedPrescription != null) ...[
              const SizedBox(height: AppSizes.spacingMedium),
              ElderlyButton(
                text: 'Use Extracted Information',
                icon: Icons.auto_fix_high,
                onPressed: () => _loadParsedPrescription(ref, ocrState.parsedPrescription!),
                variant: ElderlyButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionForm(PrescriptionFormState formState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prescription Details',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Medication Name
            ElderlyTextField(
              label: 'Medication Name *',
              hintText: 'Enter medication name',
              initialValue: formState.medicationName,
              onChanged: (value) => ref.read(prescriptionFormProvider.notifier).updateMedicationName(value),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Dosage
            ElderlyTextField(
              label: 'Dosage *',
              hintText: 'e.g., 500mg, 5ml, 1 tablet',
              initialValue: formState.dosage,
              onChanged: (value) => ref.read(prescriptionFormProvider.notifier).updateDosage(value),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter dosage';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Medication Type
            ElderlyDropdown<MedicationType>(
              label: 'Type',
              value: formState.medicationType,
              items: MedicationType.values.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.displayName, style: AppTextStyles.bodyLarge),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(prescriptionFormProvider.notifier).updateMedicationType(value);
                }
              },
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Frequency
            ElderlyDropdown<DosageFrequency>(
              label: 'Frequency',
              value: formState.frequency,
              items: DosageFrequency.values.map((freq) => DropdownMenuItem(
                value: freq,
                child: Text(freq.displayName, style: AppTextStyles.bodyLarge),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(prescriptionFormProvider.notifier).updateFrequency(value);
                  _updateReminderTimesForFrequency(ref, value);
                }
              },
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Reminder Times
            _buildReminderTimesSection(formState),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Start Date
            _buildDateSelector(
              label: 'Start Date',
              date: formState.startDate,
              onDateSelected: (date) => ref.read(prescriptionFormProvider.notifier).updateStartDate(date),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // End Date (Optional)
            _buildDateSelector(
              label: 'End Date (Optional)',
              date: formState.endDate,
              onDateSelected: (date) => ref.read(prescriptionFormProvider.notifier).updateEndDate(date),
              isOptional: true,
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Instructions
            ElderlyTextField(
              label: 'Instructions (Optional)',
              hintText: 'e.g., Take with food, Before meals',
              initialValue: formState.instructions ?? '',
              onChanged: (value) => ref.read(prescriptionFormProvider.notifier).updateInstructions(value.isEmpty ? null : value),
              maxLines: 3,
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            
            // Notes
            ElderlyTextField(
              label: 'Notes (Optional)',
              hintText: 'Additional notes or comments',
              initialValue: formState.notes ?? '',
              onChanged: (value) => ref.read(prescriptionFormProvider.notifier).updateNotes(value.isEmpty ? null : value),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTimesSection(PrescriptionFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder Times *',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        ...formState.reminderTimes.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
            child: Row(
              children: [
                Expanded(
                  child: ElderlyTimePicker(
                    label: 'Time ${index + 1}',
                    time: time,
                    onTimeChanged: (newTime) => _updateReminderTime(ref, index, newTime),
                  ),
                ),
                if (formState.reminderTimes.length > 1) ...[
                  const SizedBox(width: AppSizes.spacingMedium),
                  IconButton(
                    onPressed: () => _removeReminderTime(ref, index),
                    icon: const Icon(Icons.remove_circle, color: AppColors.error),
                    iconSize: AppSizes.iconLarge,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        if (formState.reminderTimes.length < 4)
          ElderlyButton(
            text: 'Add Time',
            icon: Icons.add,
            onPressed: () => _addReminderTime(ref),
            variant: ElderlyButtonVariant.secondary,
          ),
      ],
    );
  }

  Widget _buildDateSelector({
    required String label,
    DateTime? date,
    required Function(DateTime) onDateSelected,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMedium),
        ElderlyButton(
          text: date != null ? DateTimeUtils.formatDate(date) : 'Select Date',
          icon: Icons.calendar_today,
          onPressed: () => _selectDate(context, date, onDateSelected),
          variant: ElderlyButtonVariant.secondary,
        ),
        if (isOptional && date != null) ...[
          const SizedBox(height: AppSizes.spacingSmall),
          TextButton(
            onPressed: () => onDateSelected(DateTime.now()),
            child: Text(
              'Clear Date',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(PrescriptionFormState formState, user) {
    if (user == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: ElderlyButton(
            text: 'Cancel',
            onPressed: () => context.pop(),
            variant: ElderlyButtonVariant.secondary,
          ),
        ),
        const SizedBox(width: AppSizes.spacingMedium),
        Expanded(
          child: ElderlyButton(
            text: 'Save Prescription',
            icon: Icons.save,
            onPressed: formState.isValid ? () => _savePrescription(ref, user.id) : null,
            variant: ElderlyButtonVariant.primary,
          ),
        ),
      ],
    );
  }

  // Helper methods
  void _captureFromCamera(WidgetRef ref) {
    ref.read(ocrTextExtractionProvider.notifier).pickImageFromCamera();
  }

  void _captureFromGallery(WidgetRef ref) {
    ref.read(ocrTextExtractionProvider.notifier).pickImageFromGallery();
  }

  void _resetOCR(WidgetRef ref) {
    ref.read(ocrTextExtractionProvider.notifier).reset();
    ref.read(prescriptionFormProvider.notifier).reset();
  }

  void _loadParsedPrescription(WidgetRef ref, parsed) {
    ref.read(prescriptionFormProvider.notifier).loadFromParsedPrescription(parsed);
    // Scroll to form section
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        400,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _updateReminderTimesForFrequency(WidgetRef ref, DosageFrequency frequency) {
    List<String> defaultTimes;
    switch (frequency) {
      case DosageFrequency.onceDaily:
        defaultTimes = ['08:00'];
        break;
      case DosageFrequency.twiceDaily:
        defaultTimes = ['08:00', '20:00'];
        break;
      case DosageFrequency.threeTimesDaily:
        defaultTimes = ['08:00', '14:00', '20:00'];
        break;
      case DosageFrequency.fourTimesDaily:
        defaultTimes = ['06:00', '12:00', '18:00', '22:00'];
        break;
      default:
        defaultTimes = ['08:00'];
    }
    
    ref.read(prescriptionFormProvider.notifier).updateReminderTimes(defaultTimes);
  }

  void _updateReminderTime(WidgetRef ref, int index, String newTime) {
    final currentTimes = ref.read(prescriptionFormProvider).reminderTimes;
    final updatedTimes = List<String>.from(currentTimes);
    updatedTimes[index] = newTime;
    ref.read(prescriptionFormProvider.notifier).updateReminderTimes(updatedTimes);
  }

  void _addReminderTime(WidgetRef ref) {
    final currentTimes = ref.read(prescriptionFormProvider).reminderTimes;
    final newTimes = [...currentTimes, '12:00'];
    ref.read(prescriptionFormProvider.notifier).updateReminderTimes(newTimes);
  }

  void _removeReminderTime(WidgetRef ref, int index) {
    final currentTimes = ref.read(prescriptionFormProvider).reminderTimes;
    if (currentTimes.length > 1) {
      final updatedTimes = List<String>.from(currentTimes);
      updatedTimes.removeAt(index);
      ref.read(prescriptionFormProvider.notifier).updateReminderTimes(updatedTimes);
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? currentDate,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _savePrescription(WidgetRef ref, String userId) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final formNotifier = ref.read(prescriptionFormProvider.notifier);
      final prescription = formNotifier.toPrescription(
        userId, // patientId
        null, // doctorId - can be set if prescription is created by doctor
      );

      await ref.read(prescriptionManagementProvider.notifier).createPrescription(prescription);

      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          'Prescription saved successfully!',
          type: SnackBarType.success,
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          'Failed to save prescription: $error',
          type: SnackBarType.error,
        );
      }
    }
  }
}
