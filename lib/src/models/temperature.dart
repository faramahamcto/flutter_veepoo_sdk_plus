part of '../../flutter_veepoo_sdk.dart';

/// Temperature data model
class Temperature extends Equatable {
  /// Body temperature in Celsius
  final double? temperatureCelsius;

  /// Body temperature in Fahrenheit
  final double? temperatureFahrenheit;

  /// Wrist temperature in Celsius
  final double? wristTemperatureCelsius;

  /// Measurement state
  final TemperatureState? state;

  /// Is measuring
  final bool? isMeasuring;

  /// Measurement progress (0-100)
  final int? progress;

  /// Timestamp of measurement
  final int? timestamp;

  const Temperature({
    this.temperatureCelsius,
    this.temperatureFahrenheit,
    this.wristTemperatureCelsius,
    this.state,
    this.isMeasuring,
    this.progress,
    this.timestamp,
  });

  factory Temperature.fromMap(Map<String, dynamic> map) {
    return Temperature(
      temperatureCelsius: (map['temperatureCelsius'] as num?)?.toDouble(),
      temperatureFahrenheit: (map['temperatureFahrenheit'] as num?)?.toDouble(),
      wristTemperatureCelsius:
          (map['wristTemperatureCelsius'] as num?)?.toDouble(),
      state: map['state'] != null
          ? TemperatureState.values.firstWhere(
              (e) => e.name == map['state'],
              orElse: () => TemperatureState.unknown,
            )
          : null,
      isMeasuring: map['isMeasuring'] as bool?,
      progress: map['progress'] as int?,
      timestamp: map['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperatureCelsius': temperatureCelsius,
      'temperatureFahrenheit': temperatureFahrenheit,
      'wristTemperatureCelsius': wristTemperatureCelsius,
      'state': state?.name,
      'isMeasuring': isMeasuring,
      'progress': progress,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [
        temperatureCelsius,
        temperatureFahrenheit,
        wristTemperatureCelsius,
        state,
        isMeasuring,
        progress,
        timestamp,
      ];
}

/// Temperature measurement state
enum TemperatureState {
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
