part of '../../flutter_veepoo_sdk.dart';

/// User profile model for device synchronization
class UserProfile extends Equatable {
  /// User height in cm
  final int? heightCm;

  /// User weight in kg
  final double? weightKg;

  /// User age in years
  final int? age;

  /// User gender
  final Gender? gender;

  /// Target steps per day
  final int? targetSteps;

  /// Target sleep duration in minutes
  final int? targetSleepMinutes;

  const UserProfile({
    this.heightCm,
    this.weightKg,
    this.age,
    this.gender,
    this.targetSteps,
    this.targetSleepMinutes,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      heightCm: map['heightCm'] as int?,
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      age: map['age'] as int?,
      gender: map['gender'] != null
          ? Gender.values.firstWhere(
              (e) => e.name == map['gender'],
              orElse: () => Gender.other,
            )
          : null,
      targetSteps: map['targetSteps'] as int?,
      targetSleepMinutes: map['targetSleepMinutes'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'heightCm': heightCm,
      'weightKg': weightKg,
      'age': age,
      'gender': gender?.name,
      'targetSteps': targetSteps,
      'targetSleepMinutes': targetSleepMinutes,
    };
  }

  @override
  List<Object?> get props => [
        heightCm,
        weightKg,
        age,
        gender,
        targetSteps,
        targetSleepMinutes,
      ];
}

/// User gender enum
enum Gender {
  /// Male
  male,

  /// Female
  female,

  /// Other
  other,
}
