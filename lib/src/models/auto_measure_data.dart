part of '../../flutter_veepoo_sdk.dart';

/// Measurement types that support automatic (background) measurement.
/// [value] matches the vendor's `EAutoMeasureType`.
enum AutoMeasureType {
  pulseRate(0),
  bloodPressure(1),
  bloodGlucose(2),
  stress(3),
  bloodOxygen(4),
  bodyTemperature(5),
  lorenz(6),
  hrv(7),
  bloodComposition(8);

  final int value;
  const AutoMeasureType(this.value);

  static AutoMeasureType? fromValue(int? value) {
    for (final t in values) {
      if (t.value == value) return t;
    }
    return null;
  }
}

/// Automatic measurement setting for one [AutoMeasureType].
/// Times are minutes from midnight; intervals are minutes.
class AutoMeasureData extends Equatable {
  final AutoMeasureType? type;
  final bool isEnabled;
  final int stepUnit;
  final bool isSlotModifiable;
  final bool isIntervalModifiable;
  final int supportStartMinute;
  final int supportEndMinute;
  final int measureInterval;
  final int currentStartMinute;
  final int currentEndMinute;

  /// Only set by [VeepooSDK.enableAllAutoMeasurements]: whether enabling this
  /// type succeeded (null when it was already on or not part of that call).
  final bool? success;

  const AutoMeasureData({
    this.type,
    this.isEnabled = false,
    this.stepUnit = 0,
    this.isSlotModifiable = false,
    this.isIntervalModifiable = false,
    this.supportStartMinute = 0,
    this.supportEndMinute = 0,
    this.measureInterval = 0,
    this.currentStartMinute = 0,
    this.currentEndMinute = 0,
    this.success,
  });

  factory AutoMeasureData.fromMap(Map<String, dynamic> map) {
    return AutoMeasureData(
      type: AutoMeasureType.fromValue(map['type'] as int?),
      isEnabled: map['isSwitchOpen'] as bool? ?? false,
      stepUnit: map['stepUnit'] as int? ?? 0,
      isSlotModifiable: map['isSlotModify'] as bool? ?? false,
      isIntervalModifiable: map['isIntervalModify'] as bool? ?? false,
      supportStartMinute: map['supportStartMinute'] as int? ?? 0,
      supportEndMinute: map['supportEndMinute'] as int? ?? 0,
      measureInterval: map['measureInterval'] as int? ?? 0,
      currentStartMinute: map['currentStartMinute'] as int? ?? 0,
      currentEndMinute: map['currentEndMinute'] as int? ?? 0,
      success: map['success'] as bool?,
    );
  }

  @override
  List<Object?> get props => [
        type,
        isEnabled,
        stepUnit,
        isSlotModifiable,
        isIntervalModifiable,
        supportStartMinute,
        supportEndMinute,
        measureInterval,
        currentStartMinute,
        currentEndMinute,
        success,
      ];
}
