import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../core/models/prescription_model.dart';
import '../core/constants/app_constants.dart';
import '../services/firestore_service.dart';
import '../services/local_database_service.dart';
import '../services/ocr_service.dart';
import 'auth_providers.dart';
import 'notification_providers.dart';

// OCR Service Provider
final ocrServiceProvider = Provider<OCRService>((ref) => OCRService());

// Image Picker Provider
final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

// Prescription Management Provider
final prescriptionManagementProvider = StateNotifierProvider<PrescriptionManagementNotifier, AsyncValue<void>>((ref) {
  return PrescriptionManagementNotifier(ref);
});

class PrescriptionManagementNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  PrescriptionManagementNotifier(this._ref) : super(const AsyncValue.data(null));

  FirestoreService get _firestoreService => FirestoreService();
  LocalDatabaseService get _localDbService => LocalDatabaseService();
  OCRService get _ocrService => _ref.read(ocrServiceProvider);
  ImagePicker get _imagePicker => _ref.read(imagePickerProvider);

  Future<void> createPrescription(PrescriptionModel prescription) async {
    state = const AsyncValue.loading();
    
    try {
      // Create in Firestore
      await _firestoreService.createPrescription(prescription);
      
      // Save locally
      await _localDbService.savePrescription(prescription);
      
      // Schedule medication reminders
      await _ref.read(medicationReminderProvider.notifier).scheduleReminders(prescription);
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updatePrescription(PrescriptionModel prescription) async {
    state = const AsyncValue.loading();
    
    try {
      // Update in Firestore
      await _firestoreService.updatePrescription(prescription);
      
      // Update locally
      await _localDbService.savePrescription(prescription);
      
      // Reschedule medication reminders
      await _ref.read(medicationReminderProvider.notifier).scheduleReminders(prescription);
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deletePrescription(String prescriptionId) async {
    state = const AsyncValue.loading();
    
    try {
      // Cancel medication reminders
      await _ref.read(medicationReminderProvider.notifier).cancelReminders(prescriptionId);
      
      // Delete from Firestore
      await _firestoreService.deletePrescription(prescriptionId);
      
      // Delete locally
      await _localDbService.deletePrescription(prescriptionId);
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// OCR Text Extraction Provider
final ocrTextExtractionProvider = StateNotifierProvider<OCRTextExtractionNotifier, OCRExtractionState>((ref) {
  return OCRTextExtractionNotifier(ref);
});

class OCRTextExtractionNotifier extends StateNotifier<OCRExtractionState> {
  final Ref _ref;

  OCRTextExtractionNotifier(this._ref) : super(const OCRExtractionState.initial());

  OCRService get _ocrService => _ref.read(ocrServiceProvider);
  ImagePicker get _imagePicker => _ref.read(imagePickerProvider);

  Future<void> pickImageFromCamera() async {
    state = const OCRExtractionState.loading();
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        final extractedText = await _ocrService.extractTextFromImage(File(image.path));
        final prescription = await _ocrService.parsePrescriptionText(extractedText);
        
        state = OCRExtractionState.success(
          imagePath: image.path,
          extractedText: extractedText,
          parsedPrescription: prescription,
        );
      } else {
        state = const OCRExtractionState.cancelled();
      }
    } catch (error, stackTrace) {
      state = OCRExtractionState.error(error.toString());
    }
  }

  Future<void> pickImageFromGallery() async {
    state = const OCRExtractionState.loading();
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        final extractedText = await _ocrService.extractTextFromImage(File(image.path));
        final prescription = await _ocrService.parsePrescriptionText(extractedText);
        
        state = OCRExtractionState.success(
          imagePath: image.path,
          extractedText: extractedText,
          parsedPrescription: prescription,
        );
      } else {
        state = const OCRExtractionState.cancelled();
      }
    } catch (error, stackTrace) {
      state = OCRExtractionState.error(error.toString());
    }
  }

  void reset() {
    state = const OCRExtractionState.initial();
  }
}

// OCR Extraction State
sealed class OCRExtractionState {
  const OCRExtractionState();

  const factory OCRExtractionState.initial() = OCRExtractionInitial;
  const factory OCRExtractionState.loading() = OCRExtractionLoading;
  const factory OCRExtractionState.success({
    required String imagePath,
    required String extractedText,
    required ParsedPrescription? parsedPrescription,
  }) = OCRExtractionSuccess;
  const factory OCRExtractionState.error(String message) = OCRExtractionError;
  const factory OCRExtractionState.cancelled() = OCRExtractionCancelled;
}

class OCRExtractionInitial extends OCRExtractionState {
  const OCRExtractionInitial();
}

class OCRExtractionLoading extends OCRExtractionState {
  const OCRExtractionLoading();
}

class OCRExtractionSuccess extends OCRExtractionState {
  final String imagePath;
  final String extractedText;
  final ParsedPrescription? parsedPrescription;

  const OCRExtractionSuccess({
    required this.imagePath,
    required this.extractedText,
    required this.parsedPrescription,
  });
}

class OCRExtractionError extends OCRExtractionState {
  final String message;

  const OCRExtractionError(this.message);
}

class OCRExtractionCancelled extends OCRExtractionState {
  const OCRExtractionCancelled();
}

// Prescription Form State Provider
final prescriptionFormProvider = StateNotifierProvider<PrescriptionFormNotifier, PrescriptionFormState>((ref) {
  return PrescriptionFormNotifier();
});

class PrescriptionFormNotifier extends StateNotifier<PrescriptionFormState> {
  PrescriptionFormNotifier() : super(PrescriptionFormState.initial());

  void updateMedicationName(String name) {
    state = state.copyWith(medicationName: name);
  }

  void updateDosage(String dosage) {
    state = state.copyWith(dosage: dosage);
  }

  void updateMedicationType(MedicationType type) {
    state = state.copyWith(medicationType: type);
  }

  void updateFrequency(DosageFrequency frequency) {
    state = state.copyWith(frequency: frequency);
  }

  void updateReminderTimes(List<String> times) {
    state = state.copyWith(reminderTimes: times);
  }

  void updateStartDate(DateTime startDate) {
    state = state.copyWith(startDate: startDate);
  }

  void updateEndDate(DateTime? endDate) {
    state = state.copyWith(endDate: endDate);
  }

  void updateInstructions(String? instructions) {
    state = state.copyWith(instructions: instructions);
  }

  void updateNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void loadFromParsedPrescription(ParsedPrescription parsed) {
    state = state.copyWith(
      medicationName: parsed.medicationName,
      dosage: parsed.dosage,
      medicationType: parsed.type,
      frequency: parsed.frequency,
      instructions: parsed.instructions,
    );
  }

  void reset() {
    state = PrescriptionFormState.initial();
  }

  PrescriptionModel toPrescription(String patientId, String? doctorId) {
    const uuid = Uuid();
    final now = DateTime.now();

    return PrescriptionModel(
      id: uuid.v4(),
      patientId: patientId,
      doctorId: doctorId,
      medicationName: state.medicationName,
      dosage: state.dosage,
      type: state.medicationType,
      frequency: state.frequency,
      reminderTimes: state.reminderTimes,
      startDate: state.startDate,
      endDate: state.endDate,
      instructions: state.instructions,
      notes: state.notes,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class PrescriptionFormState {
  final String medicationName;
  final String dosage;
  final MedicationType medicationType;
  final DosageFrequency frequency;
  final List<String> reminderTimes;
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;
  final String? notes;

  const PrescriptionFormState({
    required this.medicationName,
    required this.dosage,
    required this.medicationType,
    required this.frequency,
    required this.reminderTimes,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.notes,
  });

  factory PrescriptionFormState.initial() {
    return PrescriptionFormState(
      medicationName: '',
      dosage: '',
      medicationType: MedicationType.tablet,
      frequency: DosageFrequency.onceDaily,
      reminderTimes: ['08:00'],
      startDate: DateTime.now(),
    );
  }

  PrescriptionFormState copyWith({
    String? medicationName,
    String? dosage,
    MedicationType? medicationType,
    DosageFrequency? frequency,
    List<String>? reminderTimes,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    String? notes,
  }) {
    return PrescriptionFormState(
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      medicationType: medicationType ?? this.medicationType,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
    );
  }

  bool get isValid {
    return medicationName.isNotEmpty &&
           dosage.isNotEmpty &&
           reminderTimes.isNotEmpty;
  }
}
