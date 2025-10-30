import 'package:equatable/equatable.dart';

/// Device settings model
class DeviceSettings extends Equatable {
  /// Screen brightness level (0-5)
  final int? screenBrightness;

  /// Screen duration in seconds
  final int? screenDurationSeconds;

  /// 24-hour time format enabled
  final bool? is24HourFormat;

  /// Device language
  final DeviceLanguage? language;

  /// Temperature unit
  final TemperatureUnit? temperatureUnit;

  /// Distance unit
  final DistanceUnit? distanceUnit;

  /// Wrist raise to wake enabled
  final bool? wristRaiseToWake;

  /// Wrist raise sensitivity (0-2: low, medium, high)
  final int? wristRaiseSensitivity;

  /// Do not disturb mode enabled
  final bool? doNotDisturb;

  /// Do not disturb start time (minutes from midnight)
  final int? doNotDisturbStart;

  /// Do not disturb end time (minutes from midnight)
  final int? doNotDisturbEnd;

  const DeviceSettings({
    this.screenBrightness,
    this.screenDurationSeconds,
    this.is24HourFormat,
    this.language,
    this.temperatureUnit,
    this.distanceUnit,
    this.wristRaiseToWake,
    this.wristRaiseSensitivity,
    this.doNotDisturb,
    this.doNotDisturbStart,
    this.doNotDisturbEnd,
  });

  factory DeviceSettings.fromMap(Map<String, dynamic> map) {
    return DeviceSettings(
      screenBrightness: map['screenBrightness'] as int?,
      screenDurationSeconds: map['screenDurationSeconds'] as int?,
      is24HourFormat: map['is24HourFormat'] as bool?,
      language: map['language'] != null
          ? DeviceLanguage.values.firstWhere(
              (e) => e.name == map['language'],
              orElse: () => DeviceLanguage.english,
            )
          : null,
      temperatureUnit: map['temperatureUnit'] != null
          ? TemperatureUnit.values.firstWhere(
              (e) => e.name == map['temperatureUnit'],
              orElse: () => TemperatureUnit.celsius,
            )
          : null,
      distanceUnit: map['distanceUnit'] != null
          ? DistanceUnit.values.firstWhere(
              (e) => e.name == map['distanceUnit'],
              orElse: () => DistanceUnit.metric,
            )
          : null,
      wristRaiseToWake: map['wristRaiseToWake'] as bool?,
      wristRaiseSensitivity: map['wristRaiseSensitivity'] as int?,
      doNotDisturb: map['doNotDisturb'] as bool?,
      doNotDisturbStart: map['doNotDisturbStart'] as int?,
      doNotDisturbEnd: map['doNotDisturbEnd'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'screenBrightness': screenBrightness,
      'screenDurationSeconds': screenDurationSeconds,
      'is24HourFormat': is24HourFormat,
      'language': language?.name,
      'temperatureUnit': temperatureUnit?.name,
      'distanceUnit': distanceUnit?.name,
      'wristRaiseToWake': wristRaiseToWake,
      'wristRaiseSensitivity': wristRaiseSensitivity,
      'doNotDisturb': doNotDisturb,
      'doNotDisturbStart': doNotDisturbStart,
      'doNotDisturbEnd': doNotDisturbEnd,
    };
  }

  @override
  List<Object?> get props => [
        screenBrightness,
        screenDurationSeconds,
        is24HourFormat,
        language,
        temperatureUnit,
        distanceUnit,
        wristRaiseToWake,
        wristRaiseSensitivity,
        doNotDisturb,
        doNotDisturbStart,
        doNotDisturbEnd,
      ];
}

/// Device language enum
enum DeviceLanguage {
  english,
  chinese,
  japanese,
  korean,
  german,
  french,
  spanish,
  italian,
  portuguese,
  russian,
}

/// Temperature unit enum
enum TemperatureUnit {
  celsius,
  fahrenheit,
}

/// Distance unit enum
enum DistanceUnit {
  metric,
  imperial,
}
