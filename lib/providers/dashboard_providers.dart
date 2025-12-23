import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/prescription_model.dart';
import '../core/models/medication_log_model.dart';
import '../services/firestore_service.dart';
import '../services/local_database_service.dart';
import 'auth_providers.dart';

// Prescriptions Provider
final prescriptionsProvider = StreamProvider<List<PrescriptionModel>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield [];
    return;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  yield* firestoreService.getUserPrescriptionsStream(user.id);
});

// Today's Medication Logs Provider
final todaysMedicationLogsProvider = StreamProvider<List<MedicationLog>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield [];
    return;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  yield* firestoreService.getTodaysMedicationLogsStream(user.id);
});

// Dashboard Stats Provider
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final todaysLogs = ref.watch(todaysMedicationLogsProvider).valueOrNull ?? [];
  
  final taken = todaysLogs.where((log) => log.status == MedicationStatus.taken).length;
  final missed = todaysLogs.where((log) => log.status == MedicationStatus.missed).length;
  final overdue = todaysLogs.where((log) => log.status == MedicationStatus.overdue).length;
  final upcoming = todaysLogs.where((log) => log.status == MedicationStatus.upcoming).length;
  final total = todaysLogs.length;
  
  return DashboardStats(
    totalToday: total,
    taken: taken,
    missed: missed,
    overdue: overdue,
    upcoming: upcoming,
    adherenceRate: total > 0 ? (taken / total * 100).round() : 0,
  );
});

// Upcoming Medications Provider (next 24 hours)
final upcomingMedicationsProvider = Provider<List<MedicationLog>>((ref) {
  final todaysLogs = ref.watch(todaysMedicationLogsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  
  return todaysLogs
      .where((log) => 
          log.status == MedicationStatus.upcoming &&
          log.scheduledTime.isAfter(now))
      .toList()
    ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
});

// Overdue Medications Provider
final overdueMedicationsProvider = Provider<List<MedicationLog>>((ref) {
  final todaysLogs = ref.watch(todaysMedicationLogsProvider).valueOrNull ?? [];
  
  return todaysLogs
      .where((log) => log.status == MedicationStatus.overdue || log.isOverdue)
      .toList()
    ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
});

// Medication Action Provider
final medicationActionProvider = StateNotifierProvider<MedicationActionNotifier, AsyncValue<void>>((ref) {
  return MedicationActionNotifier(ref);
});

class MedicationActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  MedicationActionNotifier(this._ref) : super(const AsyncValue.data(null));

  FirestoreService get _firestoreService => _ref.read(firestoreServiceProvider);
  LocalDatabaseService get _localDbService => LocalDatabaseService();

  Future<void> markMedicationTaken(MedicationLogModel log, {String? notes}) async {
    state = const AsyncValue.loading();
    
    try {
      final updatedLog = log.copyWith(
        isTaken: true,
        takenAt: DateTime.now(),
        notes: notes,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _firestoreService.updateMedicationLog(updatedLog);
      
      // Update in local database
      await _localDbService.saveMedicationLog(updatedLog);
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> skipMedication(MedicationLogModel log, {String? reason}) async {
    state = const AsyncValue.loading();
    
    try {
      final updatedLog = log.copyWith(
        isTaken: false,
        notes: reason,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _firestoreService.updateMedicationLog(updatedLog);
      
      // Update in local database
      await _localDbService.saveMedicationLog(updatedLog);
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> snoozeMedication(MedicationLogModel log, int minutes) async {
    state = const AsyncValue.loading();
    
    try {
      final snoozeTime = log.takenAt.add(Duration(minutes: minutes));
      final updatedLog = log.copyWith(
        takenAt: snoozeTime,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _firestoreService.updateMedicationLog(updatedLog);
      
      // Update in local database
      await _localDbService.saveMedicationLog(updatedLog);
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Dashboard Stats Model
class DashboardStats {
  final int totalToday;
  final int taken;
  final int missed;
  final int overdue;
  final int upcoming;
  final int adherenceRate;

  const DashboardStats({
    required this.totalToday,
    required this.taken,
    required this.missed,
    required this.overdue,
    required this.upcoming,
    required this.adherenceRate,
  });
}

// Date Selection Provider for Calendar
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Medication Logs for Selected Date Provider
final selectedDateLogsProvider = FutureProvider<List<MedicationLog>>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final user = await ref.watch(currentUserProvider.future);
  
  if (user == null) return [];
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
  
  return await firestoreService.getMedicationLogs(
    patientId: user.id,
    startDate: startOfDay,
    endDate: endOfDay,
  );
});
