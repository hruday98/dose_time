import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../core/models/user_model.dart';
import '../core/models/prescription_model.dart';
import '../core/models/medication_log_model.dart';
import '../core/constants/app_constants.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  final Logger _logger = Logger();
  
  // Lazy-loaded boxes
  Box<UserModel>? _userBox;
  Box<PrescriptionModel>? _prescriptionsBox;
  Box<MedicationLogModel>? _medicationLogsBox;
  Box<Map<dynamic, dynamic>>? _settingsBox;

  // Initialize Hive and register adapters
  Future<void> initialize() async {
    try {
      // Register Hive adapters
      _registerAdapters();
      
      // Open boxes
      await _openBoxes();
      
      _logger.i('Local database initialized successfully');
    } catch (e) {
      _logger.e('Error initializing local database: $e');
      rethrow;
    }
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PrescriptionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MedicationLogAdapter());
    }
  }

  Future<void> _openBoxes() async {
    _userBox = await Hive.openBox<UserModel>(AppConstants.userBoxName);
    _prescriptionsBox = await Hive.openBox<PrescriptionModel>(AppConstants.prescriptionsBoxName);
    _medicationLogsBox = await Hive.openBox<MedicationLogModel>(AppConstants.medicationLogsBoxName);
    _settingsBox = await Hive.openBox<Map<dynamic, dynamic>>(AppConstants.settingsBoxName);
  }

  // User operations
  Future<void> saveUser(UserModel user) async {
    try {
      await _userBox!.put(user.id, user);
      _logger.i('User saved to local database: ${user.id}');
    } catch (e) {
      _logger.e('Error saving user to local database: $e');
      throw 'Failed to save user locally';
    }
  }

  UserModel? getUser(String userId) {
    try {
      return _userBox!.get(userId);
    } catch (e) {
      _logger.e('Error getting user from local database: $e');
      return null;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _userBox!.delete(userId);
      _logger.i('User deleted from local database: $userId');
    } catch (e) {
      _logger.e('Error deleting user from local database: $e');
      throw 'Failed to delete user locally';
    }
  }

  // Prescription operations
  Future<void> savePrescription(PrescriptionModel prescription) async {
    try {
      await _prescriptionsBox!.put(prescription.id, prescription);
      _logger.i('Prescription saved to local database: ${prescription.id}');
    } catch (e) {
      _logger.e('Error saving prescription to local database: $e');
      throw 'Failed to save prescription locally';
    }
  }

  Future<void> savePrescriptions(List<PrescriptionModel> prescriptions) async {
    try {
      final Map<String, PrescriptionModel> prescriptionMap = {
        for (final prescription in prescriptions) prescription.id: prescription
      };
      await _prescriptionsBox!.putAll(prescriptionMap);
      _logger.i('${prescriptions.length} prescriptions saved to local database');
    } catch (e) {
      _logger.e('Error saving prescriptions to local database: $e');
      throw 'Failed to save prescriptions locally';
    }
  }

  List<PrescriptionModel> getUserPrescriptions(String userId) {
    try {
      return _prescriptionsBox!.values
          .where((prescription) => prescription.patientId == userId && prescription.isActive)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _logger.e('Error getting user prescriptions from local database: $e');
      return [];
    }
  }

  PrescriptionModel? getPrescription(String prescriptionId) {
    try {
      return _prescriptionsBox!.get(prescriptionId);
    } catch (e) {
      _logger.e('Error getting prescription from local database: $e');
      return null;
    }
  }

  Future<void> deletePrescription(String prescriptionId) async {
    try {
      await _prescriptionsBox!.delete(prescriptionId);
      _logger.i('Prescription deleted from local database: $prescriptionId');
    } catch (e) {
      _logger.e('Error deleting prescription from local database: $e');
      throw 'Failed to delete prescription locally';
    }
  }

  // Medication log operations
  Future<void> saveMedicationLog(MedicationLogModel log) async {
    try {
      await _medicationLogsBox!.put(log.id, log);
      _logger.i('Medication log saved to local database: ${log.id}');
    } catch (e) {
      _logger.e('Error saving medication log to local database: $e');
      throw 'Failed to save medication log locally';
    }
  }

  Future<void> saveMedicationLogs(List<MedicationLogModel> logs) async {
    try {
      final Map<String, MedicationLogModel> logMap = {
        for (final log in logs) log.id: log
      };
      await _medicationLogsBox!.putAll(logMap);
      _logger.i('${logs.length} medication logs saved to local database');
    } catch (e) {
      _logger.e('Error saving medication logs to local database: $e');
      throw 'Failed to save medication logs locally';
    }
  }

  List<MedicationLogModel> getMedicationLogs({
    required String patientId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      var logs = _medicationLogsBox!.values
          .where((log) => log.patientId == patientId);

      if (startDate != null) {
        logs = logs.where((log) => log.takenAt.isAfter(startDate) || 
                                   log.takenAt.isAtSameMomentAs(startDate));
      }

      if (endDate != null) {
        logs = logs.where((log) => log.takenAt.isBefore(endDate) || 
                                   log.takenAt.isAtSameMomentAs(endDate));
      }

      return logs.toList()
        ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    } catch (e) {
      _logger.e('Error getting medication logs from local database: $e');
      return [];
    }
  }

  List<MedicationLogModel> getTodaysMedicationLogs(String patientId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    return getMedicationLogs(
      patientId: patientId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  MedicationLogModel? getMedicationLog(String logId) {
    try {
      return _medicationLogsBox!.get(logId);
    } catch (e) {
      _logger.e('Error getting medication log from local database: $e');
      return null;
    }
  }

  Future<void> deleteMedicationLog(String logId) async {
    try {
      await _medicationLogsBox!.delete(logId);
      _logger.i('Medication log deleted from local database: $logId');
    } catch (e) {
      _logger.e('Error deleting medication log from local database: $e');
      throw 'Failed to delete medication log locally';
    }
  }

  // Settings operations
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settingsBox!.put(key, {'value': value, 'updatedAt': DateTime.now()});
      _logger.i('Setting saved: $key');
    } catch (e) {
      _logger.e('Error saving setting: $e');
      throw 'Failed to save setting locally';
    }
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      final settingData = _settingsBox!.get(key);
      if (settingData != null && settingData['value'] != null) {
        return settingData['value'] as T;
      }
      return defaultValue;
    } catch (e) {
      _logger.e('Error getting setting: $e');
      return defaultValue;
    }
  }

  Future<void> deleteSetting(String key) async {
    try {
      await _settingsBox!.delete(key);
      _logger.i('Setting deleted: $key');
    } catch (e) {
      _logger.e('Error deleting setting: $e');
      throw 'Failed to delete setting locally';
    }
  }

  // Utility methods
  Future<void> clearAllData() async {
    try {
      await Future.wait([
        _userBox!.clear(),
        _prescriptionsBox!.clear(),
        _medicationLogsBox!.clear(),
        _settingsBox!.clear(),
      ]);
      _logger.i('All local data cleared');
    } catch (e) {
      _logger.e('Error clearing local data: $e');
      throw 'Failed to clear local data';
    }
  }

  Future<void> closeBoxes() async {
    try {
      await Future.wait([
        _userBox?.close() ?? Future.value(),
        _prescriptionsBox?.close() ?? Future.value(),
        _medicationLogsBox?.close() ?? Future.value(),
        _settingsBox?.close() ?? Future.value(),
      ]);
      _logger.i('All boxes closed');
    } catch (e) {
      _logger.e('Error closing boxes: $e');
    }
  }

  // Sync status tracking
  Future<void> markForSync(String itemId, String itemType) async {
    try {
      await saveSetting('sync_${itemType}_$itemId', {
        'needsSync': true,
        'lastAttempt': null,
        'attempts': 0,
      });
    } catch (e) {
      _logger.e('Error marking item for sync: $e');
    }
  }

  List<String> getItemsNeedingSync(String itemType) {
    try {
      final allSettings = _settingsBox!.keys
          .where((key) => key.toString().startsWith('sync_${itemType}_'))
          .toList();
      
      final needsSync = <String>[];
      for (final key in allSettings) {
        final syncData = getSetting<Map<dynamic, dynamic>>(key.toString());
        if (syncData != null && syncData['needsSync'] == true) {
          final itemId = key.toString().replaceFirst('sync_${itemType}_', '');
          needsSync.add(itemId);
        }
      }
      
      return needsSync;
    } catch (e) {
      _logger.e('Error getting items needing sync: $e');
      return [];
    }
  }
}
