import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import './django_api_service.dart';

class PrescriptionService {
  final DjangoApiService apiService;
  final Logger logger;

  PrescriptionService({
    required this.apiService,
    required this.logger,
  });

  // Get all prescriptions
  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    try {
      final prescriptions = await apiService.getPrescriptions();
      logger.i('Fetched ${prescriptions.length} prescriptions');
      return prescriptions;
    } catch (e) {
      logger.e('Error fetching prescriptions: $e');
      rethrow;
    }
  }

  // Get single prescription
  Future<Map<String, dynamic>> getPrescription(String prescriptionId) async {
    try {
      final prescription = await apiService.getPrescription(prescriptionId);
      logger.i('Fetched prescription: $prescriptionId');
      return prescription;
    } catch (e) {
      logger.e('Error fetching prescription: $e');
      rethrow;
    }
  }

  // Create prescription
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
      final prescription = await apiService.createPrescription(
        medicationName: medicationName,
        dosage: dosage,
        medicationType: medicationType,
        frequency: frequency,
        reminderTimes: reminderTimes,
        startDate: startDate,
        endDate: endDate,
        instructions: instructions,
        notes: notes,
        doctorId: doctorId,
      );
      logger.i('Created prescription: $medicationName');
      return prescription;
    } catch (e) {
      logger.e('Error creating prescription: $e');
      rethrow;
    }
  }

  // Update prescription
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
      final prescription = await apiService.updatePrescription(
        prescriptionId: prescriptionId,
        medicationName: medicationName,
        dosage: dosage,
        frequency: frequency,
        reminderTimes: reminderTimes,
        endDate: endDate,
        isActive: isActive,
      );
      logger.i('Updated prescription: $prescriptionId');
      return prescription;
    } catch (e) {
      logger.e('Error updating prescription: $e');
      rethrow;
    }
  }

  // Delete prescription
  Future<void> deletePrescription(String prescriptionId) async {
    try {
      await apiService.deletePrescription(prescriptionId);
      logger.i('Deleted prescription: $prescriptionId');
    } catch (e) {
      logger.e('Error deleting prescription: $e');
      rethrow;
    }
  }
}

/// Provider for PrescriptionService
final prescriptionServiceProvider = Provider((ref) {
  final apiService = ref.watch(djangoApiServiceProvider);
  final logger = ref.watch(loggerProvider);
  return PrescriptionService(apiService: apiService, logger: logger);
});

/// Provider for fetching all prescriptions
final prescriptionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(prescriptionServiceProvider);
  return service.getPrescriptions();
});
