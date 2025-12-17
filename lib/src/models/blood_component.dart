part of '../../flutter_veepoo_sdk.dart';

/// Blood component analysis data model
class BloodComponent extends Equatable {
  /// Uric acid level
  final double? uricAcid;

  /// Total cholesterol level
  final double? totalCholesterol;

  /// Triglyceride level
  final double? triglyceride;

  /// HDL (high-density lipoprotein) cholesterol level
  final double? hdl;

  /// LDL (low-density lipoprotein) cholesterol level
  final double? ldl;

  /// Measurement state
  final BloodComponentState? state;

  /// Is measuring
  final bool? isMeasuring;

  /// Measurement progress (0-100)
  final int? progress;

  /// Timestamp of measurement
  final int? timestamp;

  const BloodComponent({
    this.uricAcid,
    this.totalCholesterol,
    this.triglyceride,
    this.hdl,
    this.ldl,
    this.state,
    this.isMeasuring,
    this.progress,
    this.timestamp,
  });

  factory BloodComponent.fromMap(Map<String, dynamic> map) {
    return BloodComponent(
      uricAcid: (map['uricAcid'] as num?)?.toDouble(),
      totalCholesterol: (map['totalCholesterol'] as num?)?.toDouble(),
      triglyceride: (map['triglyceride'] as num?)?.toDouble(),
      hdl: (map['hdl'] as num?)?.toDouble(),
      ldl: (map['ldl'] as num?)?.toDouble(),
      state: map['state'] != null
          ? BloodComponentState.values.firstWhere(
              (e) => e.name == map['state'],
              orElse: () => BloodComponentState.unknown,
            )
          : null,
      isMeasuring: map['isMeasuring'] as bool?,
      progress: map['progress'] as int?,
      timestamp: map['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uricAcid': uricAcid,
      'totalCholesterol': totalCholesterol,
      'triglyceride': triglyceride,
      'hdl': hdl,
      'ldl': ldl,
      'state': state?.name,
      'isMeasuring': isMeasuring,
      'progress': progress,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [
        uricAcid,
        totalCholesterol,
        triglyceride,
        hdl,
        ldl,
        state,
        isMeasuring,
        progress,
        timestamp,
      ];
}

/// Blood component measurement state
enum BloodComponentState {
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
