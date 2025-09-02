import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../constants/app_constants.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class UserModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String email;
  
  @HiveField(2)
  final String displayName;
  
  @HiveField(3)
  final UserRole role;
  
  @HiveField(4)
  final String? phoneNumber;
  
  @HiveField(5)
  final String? profileImageUrl;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  final DateTime updatedAt;
  
  @HiveField(8)
  final Map<String, dynamic>? preferences;
  
  @HiveField(9)
  final List<String>? patientIds; // For doctors and caretakers
  
  @HiveField(10)
  final List<String>? doctorIds; // For patients
  
  @HiveField(11)
  final List<String>? caretakerIds; // For patients

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
    this.patientIds,
    this.doctorIds,
    this.caretakerIds,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    List<String>? patientIds,
    List<String>? doctorIds,
    List<String>? caretakerIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      patientIds: patientIds ?? this.patientIds,
      doctorIds: doctorIds ?? this.doctorIds,
      caretakerIds: caretakerIds ?? this.caretakerIds,
    );
  }

  bool get isPatient => role == UserRole.patient;
  bool get isDoctor => role == UserRole.doctor;
  bool get isCaretaker => role == UserRole.caretaker;
  
  String get roleString => role.name;
}
