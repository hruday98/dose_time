import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import './django_api_service.dart';

class MedicationLogService {
  final DjangoApiService apiService;
  final Logger logger;

  MedicationLogService({
    required this.apiService,
    required this.logger,
  });

  // Get medication logs with optional prescription filter
  Future<List<Map<String, dynamic>>> getMedicationLogs({
    String? prescriptionId,
  }) async {
    try {
      final logs = await apiService.getMedicationLogs(
        prescriptionId: prescriptionId,
      );
      logger.i('Fetched ${logs.length} medication logs');
      return logs;
    } catch (e) {
      logger.e('Error fetching medication logs: $e');
      rethrow;
    }
  }

  // Mark medication as taken
  Future<Map<String, dynamic>> markTaken({
    required String logId,
    String? notes,
  }) async {
    try {
      final result = await apiService.markMedicationTaken(
        logId: logId,
        notes: notes,
      );
      logger.i('Marked medication as taken: $logId');
      return result;
    } catch (e) {
      logger.e('Error marking medication taken: $e');
      rethrow;
    }
  }

  // Create medication log
  Future<Map<String, dynamic>> createLog({
    required String prescriptionId,
    required DateTime takenAt,
    required bool isTaken,
    String? notes,
  }) async {
    try {
      final log = await apiService.createMedicationLog(
        prescriptionId: prescriptionId,
        takenAt: takenAt,
        isTaken: isTaken,
        notes: notes,
      );
      logger.i('Created medication log for prescription: $prescriptionId');
      return log;
    } catch (e) {
      logger.e('Error creating medication log: $e');
      rethrow;
    }
  }
}

/// Provider for MedicationLogService
final medicationLogServiceProvider = Provider((ref) {
  final apiService = ref.watch(djangoApiServiceProvider);
  final logger = ref.watch(loggerProvider);
  return MedicationLogService(apiService: apiService, logger: logger);
});

/// Provider for fetching medication logs
final medicationLogsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, prescriptionId) async {
  final service = ref.watch(medicationLogServiceProvider);
  return service.getMedicationLogs(prescriptionId: prescriptionId);
});
