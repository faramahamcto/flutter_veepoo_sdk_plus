part of '../../flutter_veepoo_sdk.dart';

/// Step data model containing activity tracking information
class StepData extends Equatable {
  /// Total number of steps
  final int? steps;

  /// Distance traveled in meters
  final double? distanceMeters;

  /// Calories burned in kcal
  final double? calories;

  /// Active duration in minutes
  final int? activeMinutes;

  /// Timestamp of the data
  final int? timestamp;

  const StepData({
    this.steps,
    this.distanceMeters,
    this.calories,
    this.activeMinutes,
    this.timestamp,
  });

  factory StepData.fromMap(Map<String, dynamic> map) {
    return StepData(
      steps: map['steps'] as int?,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toDouble(),
      activeMinutes: map['activeMinutes'] as int?,
      timestamp: map['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'steps': steps,
      'distanceMeters': distanceMeters,
      'calories': calories,
      'activeMinutes': activeMinutes,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [
        steps,
        distanceMeters,
        calories,
        activeMinutes,
        timestamp,
      ];
}
