part of '../../flutter_veepoo_sdk.dart';

/// Sleep data model containing sleep quality and duration information
class SleepData extends Equatable {
  /// Total sleep duration in minutes
  final int? totalSleepMinutes;

  /// Deep sleep duration in minutes
  final int? deepSleepMinutes;

  /// Light sleep duration in minutes
  final int? lightSleepMinutes;

  /// Awake duration in minutes
  final int? awakeMinutes;

  /// Sleep quality score (0-100)
  final int? sleepQuality;

  /// Sleep start time (timestamp in milliseconds)
  final int? sleepStartTime;

  /// Sleep end time (timestamp in milliseconds)
  final int? sleepEndTime;

  /// Sleep curve data points
  final List<int>? sleepCurve;

  const SleepData({
    this.totalSleepMinutes,
    this.deepSleepMinutes,
    this.lightSleepMinutes,
    this.awakeMinutes,
    this.sleepQuality,
    this.sleepStartTime,
    this.sleepEndTime,
    this.sleepCurve,
  });

  factory SleepData.fromMap(Map<String, dynamic> map) {
    return SleepData(
      totalSleepMinutes: map['totalSleepMinutes'] as int?,
      deepSleepMinutes: map['deepSleepMinutes'] as int?,
      lightSleepMinutes: map['lightSleepMinutes'] as int?,
      awakeMinutes: map['awakeMinutes'] as int?,
      sleepQuality: map['sleepQuality'] as int?,
      sleepStartTime: map['sleepStartTime'] as int?,
      sleepEndTime: map['sleepEndTime'] as int?,
      sleepCurve: (map['sleepCurve'] as List<dynamic>?)?.cast<int>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSleepMinutes': totalSleepMinutes,
      'deepSleepMinutes': deepSleepMinutes,
      'lightSleepMinutes': lightSleepMinutes,
      'awakeMinutes': awakeMinutes,
      'sleepQuality': sleepQuality,
      'sleepStartTime': sleepStartTime,
      'sleepEndTime': sleepEndTime,
      'sleepCurve': sleepCurve,
    };
  }

  @override
  List<Object?> get props => [
        totalSleepMinutes,
        deepSleepMinutes,
        lightSleepMinutes,
        awakeMinutes,
        sleepQuality,
        sleepStartTime,
        sleepEndTime,
        sleepCurve,
      ];
}
