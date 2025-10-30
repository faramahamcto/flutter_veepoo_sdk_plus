import 'package:equatable/equatable.dart';

/// Blood glucose data model
class BloodGlucose extends Equatable {
  /// Blood glucose value in mg/dL
  final double? glucoseMgdL;

  /// Blood glucose value in mmol/L
  final double? glucoseMmolL;

  /// Measurement state
  final BloodGlucoseState? state;

  /// Is measuring
  final bool? isMeasuring;

  /// Measurement progress (0-100)
  final int? progress;

  /// Calibration mode enabled
  final bool? calibrationMode;

  /// Timestamp of measurement
  final int? timestamp;

  const BloodGlucose({
    this.glucoseMgdL,
    this.glucoseMmolL,
    this.state,
    this.isMeasuring,
    this.progress,
    this.calibrationMode,
    this.timestamp,
  });

  factory BloodGlucose.fromMap(Map<String, dynamic> map) {
    return BloodGlucose(
      glucoseMgdL: (map['glucoseMgdL'] as num?)?.toDouble(),
      glucoseMmolL: (map['glucoseMmolL'] as num?)?.toDouble(),
      state: map['state'] != null
          ? BloodGlucoseState.values.firstWhere(
              (e) => e.name == map['state'],
              orElse: () => BloodGlucoseState.unknown,
            )
          : null,
      isMeasuring: map['isMeasuring'] as bool?,
      progress: map['progress'] as int?,
      calibrationMode: map['calibrationMode'] as bool?,
      timestamp: map['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'glucoseMgdL': glucoseMgdL,
      'glucoseMmolL': glucoseMmolL,
      'state': state?.name,
      'isMeasuring': isMeasuring,
      'progress': progress,
      'calibrationMode': calibrationMode,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [
        glucoseMgdL,
        glucoseMmolL,
        state,
        isMeasuring,
        progress,
        calibrationMode,
        timestamp,
      ];
}

/// Blood glucose measurement state
enum BloodGlucoseState {
  /// Idle state
  idle,

  /// Measuring
  measuring,

  /// Measurement complete
  complete,

  /// Measurement failed
  failed,

  /// Not supported
  notSupported,

  /// Unknown state
  unknown,
}
