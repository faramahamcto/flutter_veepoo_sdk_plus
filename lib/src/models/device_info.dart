import 'package:equatable/equatable.dart';

/// Device information model
class DeviceInfo extends Equatable {
  /// Device model name
  final String? modelName;

  /// Hardware version
  final String? hardwareVersion;

  /// Software/firmware version
  final String? softwareVersion;

  /// Device serial number
  final String? serialNumber;

  /// Device MAC address
  final String? macAddress;

  /// Device manufacturer
  final String? manufacturer;

  /// Battery level percentage
  final int? batteryLevel;

  /// Is device charging
  final bool? isCharging;

  /// Device screen width
  final int? screenWidth;

  /// Device screen height
  final int? screenHeight;

  /// Supported features list
  final List<String>? supportedFeatures;

  const DeviceInfo({
    this.modelName,
    this.hardwareVersion,
    this.softwareVersion,
    this.serialNumber,
    this.macAddress,
    this.manufacturer,
    this.batteryLevel,
    this.isCharging,
    this.screenWidth,
    this.screenHeight,
    this.supportedFeatures,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      modelName: map['modelName'] as String?,
      hardwareVersion: map['hardwareVersion'] as String?,
      softwareVersion: map['softwareVersion'] as String?,
      serialNumber: map['serialNumber'] as String?,
      macAddress: map['macAddress'] as String?,
      manufacturer: map['manufacturer'] as String?,
      batteryLevel: map['batteryLevel'] as int?,
      isCharging: map['isCharging'] as bool?,
      screenWidth: map['screenWidth'] as int?,
      screenHeight: map['screenHeight'] as int?,
      supportedFeatures:
          (map['supportedFeatures'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modelName': modelName,
      'hardwareVersion': hardwareVersion,
      'softwareVersion': softwareVersion,
      'serialNumber': serialNumber,
      'macAddress': macAddress,
      'manufacturer': manufacturer,
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'supportedFeatures': supportedFeatures,
    };
  }

  @override
  List<Object?> get props => [
        modelName,
        hardwareVersion,
        softwareVersion,
        serialNumber,
        macAddress,
        manufacturer,
        batteryLevel,
        isCharging,
        screenWidth,
        screenHeight,
        supportedFeatures,
      ];
}
