import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../core/models/user_model.dart';
import '../core/models/prescription_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // User Management
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .set(user.toJson());
      _logger.i('User created in Firestore: ${user.id}');
    } catch (e) {
      _logger.e('Error creating user in Firestore: $e');
      throw 'Failed to create user profile.';
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting user from Firestore: $e');
      throw 'Failed to get user profile.';
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(user.copyWith(updatedAt: DateTime.now()).toJson());
      _logger.i('User updated in Firestore: ${user.id}');
    } catch (e) {
      _logger.e('Error updating user in Firestore: $e');
      throw 'Failed to update user profile.';
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Delete user's prescriptions
      final prescriptionsQuery = await _firestore
          .collection(AppConstants.prescriptionsCollection)
          .where('patientId', isEqualTo: userId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in prescriptionsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's medication logs
      final logsQuery = await _firestore
          .collection(AppConstants.medicationLogsCollection)
          .where('patientId', isEqualTo: userId)
          .get();
      
      for (final doc in logsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete user document
      batch.delete(_firestore.collection(AppConstants.usersCollection).doc(userId));
      
      await batch.commit();
      _logger.i('User and related data deleted from Firestore: $userId');
    } catch (e) {
      _logger.e('Error deleting user from Firestore: $e');
      throw 'Failed to delete user data.';
    }
  }

  // Prescription Management
  Future<void> createPrescription(PrescriptionModel prescription) async {
    try {
      await _firestore
          .collection(AppConstants.prescriptionsCollection)
          .doc(prescription.id)
          .set(prescription.toJson());
      _logger.i('Prescription created in Firestore: ${prescription.id}');
    } catch (e) {
      _logger.e('Error creating prescription in Firestore: $e');
      throw 'Failed to create prescription.';
    }
  }

  Future<List<PrescriptionModel>> getUserPrescriptions(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.prescriptionsCollection)
          .where('patientId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      return query.docs
          .map((doc) => PrescriptionModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error getting user prescriptions: $e');
      throw 'Failed to get prescriptions.';
    }
  }

  Future<void> updatePrescription(PrescriptionModel prescription) async {
    try {
      await _firestore
          .collection(AppConstants.prescriptionsCollection)
          .doc(prescription.id)
          .update(prescription.copyWith(updatedAt: DateTime.now()).toJson());
      _logger.i('Prescription updated in Firestore: ${prescription.id}');
    } catch (e) {
      _logger.e('Error updating prescription in Firestore: $e');
      throw 'Failed to update prescription.';
    }
  }

  Future<void> deletePrescription(String prescriptionId) async {
    try {
      await _firestore
          .collection(AppConstants.prescriptionsCollection)
          .doc(prescriptionId)
          .delete();
      _logger.i('Prescription deleted from Firestore: $prescriptionId');
    } catch (e) {
      _logger.e('Error deleting prescription from Firestore: $e');
      throw 'Failed to delete prescription.';
    }
  }

  // Medication Log Management
  Future<void> createMedicationLog(MedicationLog log) async {
    try {
      await _firestore
          .collection(AppConstants.medicationLogsCollection)
          .doc(log.id)
          .set(log.toJson());
      _logger.i('Medication log created in Firestore: ${log.id}');
    } catch (e) {
      _logger.e('Error creating medication log in Firestore: $e');
      throw 'Failed to create medication log.';
    }
  }

  Future<List<MedicationLog>> getMedicationLogs({
    required String patientId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.medicationLogsCollection)
          .where('patientId', isEqualTo: patientId);

      if (startDate != null) {
        query = query.where('scheduledTime', isGreaterThanOrEqualTo: startDate);
      }
      
      if (endDate != null) {
        query = query.where('scheduledTime', isLessThanOrEqualTo: endDate);
      }

      final result = await query
          .orderBy('scheduledTime', descending: true)
          .get();
      
      return result.docs
          .map((doc) => MedicationLog.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting medication logs: $e');
      throw 'Failed to get medication logs.';
    }
  }

  Future<void> updateMedicationLog(MedicationLog log) async {
    try {
      await _firestore
          .collection(AppConstants.medicationLogsCollection)
          .doc(log.id)
          .update(log.copyWith(updatedAt: DateTime.now()).toJson());
      _logger.i('Medication log updated in Firestore: ${log.id}');
    } catch (e) {
      _logger.e('Error updating medication log in Firestore: $e');
      throw 'Failed to update medication log.';
    }
  }

  // Doctor-Patient Relationships
  Future<List<UserModel>> getDoctorPatients(String doctorId) async {
    try {
      final doctor = await getUser(doctorId);
      if (doctor?.patientIds == null || doctor!.patientIds!.isEmpty) {
        return [];
      }

      final patients = <UserModel>[];
      for (final patientId in doctor.patientIds!) {
        final patient = await getUser(patientId);
        if (patient != null) {
          patients.add(patient);
        }
      }
      
      return patients;
    } catch (e) {
      _logger.e('Error getting doctor patients: $e');
      throw 'Failed to get patients.';
    }
  }

  Future<List<UserModel>> getPatientDoctors(String patientId) async {
    try {
      final patient = await getUser(patientId);
      if (patient?.doctorIds == null || patient!.doctorIds!.isEmpty) {
        return [];
      }

      final doctors = <UserModel>[];
      for (final doctorId in patient.doctorIds!) {
        final doctor = await getUser(doctorId);
        if (doctor != null) {
          doctors.add(doctor);
        }
      }
      
      return doctors;
    } catch (e) {
      _logger.e('Error getting patient doctors: $e');
      throw 'Failed to get doctors.';
    }
  }

  // Real-time streams
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return UserModel.fromJson(doc.data()!);
          }
          return null;
        });
  }

  Stream<List<PrescriptionModel>> getUserPrescriptionsStream(String userId) {
    return _firestore
        .collection(AppConstants.prescriptionsCollection)
        .where('patientId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => PrescriptionModel.fromJson(doc.data()))
            .toList());
  }

  Stream<List<MedicationLog>> getTodaysMedicationLogsStream(String patientId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection(AppConstants.medicationLogsCollection)
        .where('patientId', isEqualTo: patientId)
        .where('scheduledTime', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledTime', isLessThanOrEqualTo: endOfDay)
        .orderBy('scheduledTime')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => MedicationLog.fromJson(doc.data()))
            .toList());
  }
}
