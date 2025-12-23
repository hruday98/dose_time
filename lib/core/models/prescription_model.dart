import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../constants/app_constants.dart';

part 'prescription_model.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class PrescriptionModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String patientId;
  
  @HiveField(2)
  final String? doctorId;
  
  @HiveField(3)
  final String medicationName;
  
  @HiveField(4)
  final String dosage;
  
  @HiveField(5)
  final MedicationType type;
  
  @HiveField(6)
  final DosageFrequency frequency;
  
  @HiveField(7)
  final List<String> reminderTimes; // Format: "HH:mm"
  
  @HiveField(8)
  final DateTime startDate;
  
  @HiveField(9)
  final DateTime? endDate;
  
  @HiveField(10)
  final String? instructions;
  
  @HiveField(11)
  final String? notes;
  
  @HiveField(12)
  final bool isActive;
  
  @HiveField(13)
  final DateTime createdAt;
  
  @HiveField(14)
  final DateTime updatedAt;
  
  @HiveField(15)
  final String? prescriptionImageUrl;
  
  @HiveField(16)
  final Map<String, dynamic>? metadata;

  const PrescriptionModel({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.medicationName,
    required this.dosage,
    required this.type,
    required this.frequency,
    required this.reminderTimes,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.prescriptionImageUrl,
    this.metadata,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) => _$PrescriptionModelFromJson(json);
  Map<String, dynamic> toJson() => _$PrescriptionModelToJson(this);

  PrescriptionModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? medicationName,
    String? dosage,
    MedicationType? type,
    DosageFrequency? frequency,
    List<String>? reminderTimes,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? prescriptionImageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      prescriptionImageUrl: prescriptionImageUrl ?? this.prescriptionImageUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(startDate) && 
           (endDate == null || now.isBefore(endDate!));
  }
}

@HiveType(typeId: 2)
@JsonSerializable()
class MedicationLog {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String prescriptionId;
  
  @HiveField(2)
  final String patientId;
  
  @HiveField(3)
  final DateTime scheduledTime;
  
  @HiveField(4)
  final DateTime? takenTime;
  
  @HiveField(5)
  final MedicationStatus status;
  
  @HiveField(6)
  final String? notes;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final DateTime updatedAt;

  const MedicationLog({
    required this.id,
    required this.prescriptionId,
    required this.patientId,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) => _$MedicationLogFromJson(json);
  Map<String, dynamic> toJson() => _$MedicationLogToJson(this);

  MedicationLog copyWith({
    String? id,
    String? prescriptionId,
    String? patientId,
    DateTime? scheduledTime,
    DateTime? takenTime,
    MedicationStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      patientId: patientId ?? this.patientId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOverdue {
    return status == MedicationStatus.upcoming && 
           scheduledTime.isBefore(DateTime.now());
  }

  bool get isTaken => status == MedicationStatus.taken;
  bool get isMissed => status == MedicationStatus.missed;
  bool get isSkipped => status == MedicationStatus.skipped;
}

@HiveType(typeId: 3)
enum MedicationStatus {
  @HiveField(0)
  upcoming,
  
  @HiveField(1)
  taken,
  
  @HiveField(2)
  missed,
  
  @HiveField(3)
  skipped,
  
  @HiveField(4)
  overdue;

  String get displayName {
    switch (this) {
      case MedicationStatus.upcoming:
        return 'Upcoming';
      case MedicationStatus.taken:
        return 'Taken';
      case MedicationStatus.missed:
        return 'Missed';
      case MedicationStatus.skipped:
        return 'Skipped';
      case MedicationStatus.overdue:
        return 'Overdue';
    }
  }
}

@HiveType(typeId: 5)

