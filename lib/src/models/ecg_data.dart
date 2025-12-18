part of '../../flutter_veepoo_sdk.dart';

/// ECG (Electrocardiogram) data model
class EcgData extends Equatable {
  /// ECG waveform data points
  final List<int>? waveformData;

  /// Heart rate from ECG
  final int? heartRate;

  /// Measurement state
  final EcgState? state;

  /// Is measuring
  final bool? isMeasuring;

  /// Measurement progress (0-100)
  final int? progress;

  /// Diagnostic result
  final String? diagnosticResult;

  /// Quality of ECG signal (0-100)
  final int? signalQuality;

  /// Timestamp of measurement
  final int? timestamp;

  const EcgData({
    this.waveformData,
    this.heartRate,
    this.state,
    this.isMeasuring,
    this.progress,
    this.diagnosticResult,
    this.signalQuality,
    this.timestamp,
  });

  factory EcgData.fromMap(Map<String, dynamic> map) {
    return EcgData(
      waveformData: (map['waveformData'] as List<dynamic>?)?.cast<int>(),
      heartRate: map['heartRate'] as int?,
      state: map['state'] != null
          ? EcgState.values.firstWhere(
              (e) => e.name == map['state'],
              orElse: () => EcgState.unknown,
            )
          : null,
      isMeasuring: map['isMeasuring'] as bool?,
      progress: map['progress'] as int?,
      diagnosticResult: map['diagnosticResult'] as String?,
      signalQuality: map['signalQuality'] as int?,
      timestamp: map['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'waveformData': waveformData,
      'heartRate': heartRate,
      'state': state?.name,
      'isMeasuring': isMeasuring,
      'progress': progress,
      'diagnosticResult': diagnosticResult,
      'signalQuality': signalQuality,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [
        waveformData,
        heartRate,
        state,
        isMeasuring,
        progress,
        diagnosticResult,
        signalQuality,
        timestamp,
      ];
}

/// ECG measurement state
enum EcgState {
  /// Idle state
  idle,

  /// Measuring
  measuring,

  /// Measurement complete
  complete,

  /// Measurement failed
  failed,

  /// Poor signal quality
  poorSignal,

  /// Not supported
  notSupported,

  /// Unknown state
  unknown,
}
