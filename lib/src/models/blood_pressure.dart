part of '../../flutter_veepoo_sdk.dart';

/// Blood pressure data model
class BloodPressure extends Equatable {
  /// Systolic blood pressure (mmHg)
  final int? systolic;

  /// Diastolic blood pressure (mmHg)
  final int? diastolic;

  /// Measurement state
  final BloodPressureState? state;

  /// Is measuring
  final bool? isMeasuring;

  /// Measurement progress (0-100)
  final int? progress;

  /// Timestamp of measurement
  final int? timestamp;

  const BloodPressure({
    this.systolic,
    this.diastolic,
    this.state,
    this.isMeasuring,
    this.progress,
    this.timestamp,
  });

  factory BloodPressure.fromMap(Map<String, dynamic> map) {
    return BloodPressure(
      systolic: map['systolic'] as int?,
      diastolic: map['diastolic'] as int?,
      state: map['state'] != null
          ? BloodPressureState.values.firstWhere(
              (e) => e.name == map['state'],
              orElse: () => BloodPressureState.unknown,
            )
          : null,
      isMeasuring: map['isMeasuring'] as bool?,
      progress: map['progress'] as int?,
      timestamp: map['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'state': state?.name,
      'isMeasuring': isMeasuring,
      'progress': progress,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [
        systolic,
        diastolic,
        state,
        isMeasuring,
        progress,
        timestamp,
      ];
}

/// Blood pressure measurement state
enum BloodPressureState {
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
