import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'medication_log_model.g.dart';

@HiveType(typeId: 3)
@JsonSerializable()
class MedicationLogModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String prescriptionId;

  @HiveField(2)
  final String patientId;

  @HiveField(3)
  final String medicationName;

  @HiveField(4)
  final DateTime takenAt;

  @HiveField(5)
  final bool isTaken;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  MedicationLogModel({
    required this.id,
    required this.prescriptionId,
    required this.patientId,
    required this.medicationName,
    required this.takenAt,
    required this.isTaken,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory MedicationLogModel.fromJson(Map<String, dynamic> json) =>
      _$MedicationLogModelFromJson(json);

  Map<String, dynamic> toJson() => _$MedicationLogModelToJson(this);

  MedicationLogModel copyWith({
    String? id,
    String? prescriptionId,
    String? patientId,
    String? medicationName,
    DateTime? takenAt,
    bool? isTaken,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationLogModel(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      patientId: patientId ?? this.patientId,
      medicationName: medicationName ?? this.medicationName,
      takenAt: takenAt ?? this.takenAt,
      isTaken: isTaken ?? this.isTaken,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
