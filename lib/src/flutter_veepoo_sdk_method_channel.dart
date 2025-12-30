part of '../flutter_veepoo_sdk.dart';

/// {@template method_channel_flutter_veepoo_sdk}
/// An implementation of [FlutterVeepooSdkPlatform] that uses method channels.
/// {@endtemplate}
class MethodChannelFlutterVeepooSdk extends FlutterVeepooSdkPlatform {
  static const String _channelName = 'site.shasmatic.flutter_veepoo_sdk';

  final MethodChannel methodChannel =
      const MethodChannel('$_channelName/command');
  final EventChannel bluetoothEventChannel =
      const EventChannel('$_channelName/scan_bluetooth_event_channel');
  final EventChannel heartRateEventChannel =
      const EventChannel('$_channelName/detect_heart_event_channel');
  final EventChannel spohEventChannel =
      const EventChannel('$_channelName/detect_spoh_event_channel');
  final EventChannel bloodPressureEventChannel =
      const EventChannel('$_channelName/detect_blood_pressure_event_channel');
  final EventChannel temperatureEventChannel =
      const EventChannel('$_channelName/detect_temperature_event_channel');
  final EventChannel bloodGlucoseEventChannel =
      const EventChannel('$_channelName/detect_blood_glucose_event_channel');
  final EventChannel ecgEventChannel =
      const EventChannel('$_channelName/detect_ecg_event_channel');
  final EventChannel bloodComponentEventChannel =
      const EventChannel('$_channelName/detect_blood_component_event_channel');
  final EventChannel stepDataEventChannel =
      const EventChannel('$_channelName/step_data_event_channel');
  final EventChannel originDataProgressEventChannel =
      const EventChannel('$_channelName/origin_data_progress_event_channel');

  // Cached streams
  Stream<List<BluetoothDevice>>? _bluetoothDevicesStream;
  Stream<HeartRate?>? _heartRateStream;
  Stream<Spoh?>? _spohStream;
  Stream<BloodPressure?>? _bloodPressureStream;
  Stream<Temperature?>? _temperatureStream;
  Stream<BloodGlucose?>? _bloodGlucoseStream;
  Stream<EcgData?>? _ecgDataStream;
  Stream<BloodComponent?>? _bloodComponentStream;
  Stream<StepData?>? _stepDataStream;
  Stream<OriginDataProgress?>? _originDataProgressStream;

  /// Requests Bluetooth permissions.
  ///
  /// Returns a [PermissionStatuses] if the request is successful, otherwise null.
  /// Throws a [PermissionException] if the request fails.
  @override
  Future<PermissionStatuses?> requestBluetoothPermissions() async {
    try {
      final String? status = await methodChannel
          .invokeMethod<String>('requestBluetoothPermissions');
      return status != null ? PermissionStatuses.fromString(status) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to request permission: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Open app settings.
  @override
  Future<void> openAppSettings() async {
    try {
      await methodChannel.invokeMethod<void>('openAppSettings');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to open app settings: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Checks if Bluetooth is enabled.
  @override
  Future<bool?> isBluetoothEnabled() async {
    final bool? isEnabled =
        await methodChannel.invokeMethod<bool>('isBluetoothEnabled');
    return isEnabled;
  }

  /// Opens Bluetooth.
  @override
  Future<void> openBluetooth() async {
    try {
      await methodChannel.invokeMethod<void>('openBluetooth');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to open Bluetooth: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Closes Bluetooth.
  @override
  Future<void> closeBluetooth() async {
    try {
      await methodChannel.invokeMethod<void>('closeBluetooth');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to close Bluetooth: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Starts scanning for Bluetooth devices.
  @override
  Future<void> scanDevices() async {
    try {
      await methodChannel.invokeMethod<void>('scanDevices');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to scan devices: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Stops scanning for Bluetooth devices.
  @override
  Future<void> stopScanDevices() async {
    try {
      await methodChannel.invokeMethod<void>('stopScanDevices');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to stop scan devices: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Connects to a Bluetooth device with the given [address].
  ///
  /// Throws a [DeviceConnectionException] if the connection fails.
  @override
  Future<void> connectDevice(String address) async {
    try {
      await methodChannel.invokeMethod<void>(
        'connectDevice',
        {'address': address},
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to connect address $address: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Disconnects from the currently connected Bluetooth device.
  ///
  /// Throws a [DeviceConnectionException] if the disconnection fails or if no device is connected.
  @override
  Future<void> disconnectDevice() async {
    try {
      if (await isDeviceConnected() == true) {
        await methodChannel.invokeMethod<void>('disconnectDevice');
      } else {
        throw const VeepooException(message: 'Device is not connected');
      }
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to disconnect from device: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Gets the address of the currently connected Bluetooth device.
  ///
  /// Returns the address as a [String].
  /// Throws a [DeviceConnectionException] if the request fails.
  @override
  Future<String?> getAddress() async {
    try {
      return await methodChannel.invokeMethod<String>('getAddress');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to get address: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Gets the current status of the Bluetooth device.
  ///
  /// Returns the status as an [int].
  /// Throws a [DeviceConnectionException] if the request fails.
  @override
  Future<int?> getCurrentStatus() async {
    try {
      return await methodChannel.invokeMethod<int>('getCurrentStatus');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to get current status: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Checks if a Bluetooth device is currently connected.
  ///
  /// Returns [true] if a device is connected, otherwise [false].
  /// Throws a [DeviceConnectionException] if the request fails.
  @override
  Future<bool?> isDeviceConnected() async {
    try {
      return await methodChannel.invokeMethod<bool>('isDeviceConnected');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to check device connection: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Checks if a device has been bound (paired) before.
  /// Returns [true] if credentials have been saved during binding, otherwise [false].
  /// Throws a [VeepooException] if the request fails.
  @override
  Future<bool?> isDeviceBinded() async {
    try {
      return await methodChannel.invokeMethod<bool>('isDeviceBinded');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to check device binding: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Binds a Bluetooth device with the given [password] and [is24H] flag.
  ///
  /// Returns a [DeviceBindingStatus] if the binding is successful, otherwise null.
  /// Throws a [DeviceConnectionException] if the binding fails or if no device is connected.
  @override
  Future<DeviceBindingStatus?> bindDevice(String password, bool is24H) async {
    try {
      final String? result = await methodChannel.invokeMethod<String>(
        'bindDevice',
        {'password': password, 'is24H': is24H},
      );

      return result != null ? DeviceBindingStatus.fromString(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to bind device: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Starts heart rate detection.
  /// You can alternatively use [startDetectHeartAfterBinding] to bind and start detection.
  ///
  /// Throws a [HeartDetectionException] if the detection fails or if no device is connected.
  @override
  Future<void> startDetectHeart() async {
    try {
      if (await isDeviceConnected() == true) {
        await methodChannel.invokeMethod<void>('startDetectHeart');
      } else {
        throw const VeepooException(message: 'Device is not connected');
      }
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to start detect heart: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Binds a device and starts heart rate detection with the given [password] and [is24H] flag.
  ///
  /// Throws a [HeartDetectionException] if the binding or detection fails.
  @override
  Future<void> startDetectHeartAfterBinding(String password, bool is24H) async {
    try {
      final DeviceBindingStatus? status = await bindDevice(password, is24H);
      if (status == DeviceBindingStatus.checkAndTimeSuccess) {
        await startDetectHeart();
      }
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to start detect heart: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Stops heart rate detection.
  ///
  /// Throws a [HeartDetectionException] if the detection fails or if no device is connected.
  @override
  Future<void> stopDetectHeart() async {
    try {
      if (await isDeviceConnected() == true) {
        await methodChannel.invokeMethod<void>('stopDetectHeart');
      } else {
        throw const VeepooException(message: 'Device is not connected');
      }
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to stop detect heart: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Setting heart rate warning.
  @override
  Future<void> settingHeartWarning(int high, int low, bool open) async {
    await methodChannel.invokeMethod<void>(
      'settingHeartWarning',
      {'high': high, 'low': low, 'open': open},
    );
  }

  /// Read heart rate warning.
  @override
  Future<void> readHeartWarning() async {
    await methodChannel.invokeMethod<void>('readHeartWarning');
  }

  /// Start detect blood oxygen.
  /// You can alternatively use [startDetectSpohAfterBinding] to bind and start detection.
  ///
  /// Throws a [SpohDetectionException] if the detection fails.
  @override
  Future<void> startDetectSpoh() async {
    try {
      await methodChannel.invokeMethod<void>('startDetectSpoh');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to start detect blood oxygen: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Start detect blood oxygen after binding
  @override
  Future<void> startDetectSpohAfterBinding(String password, bool is24H) async {
    try {
      final DeviceBindingStatus? status = await bindDevice(password, is24H);
      if (status == DeviceBindingStatus.checkAndTimeSuccess) {
        await startDetectSpoh();
      }
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to start detect blood oxygen: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Stop detect blood oxygen
  @override
  Future<void> stopDetectSpoh() async {
    try {
      if (await isDeviceConnected() == true) {
        await methodChannel.invokeMethod<void>('stopDetectSpoh');
      } else {
        throw const VeepooException(message: 'Device is not connected');
      }
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to stop detect blood oxygen: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Read battery level.
  @override
  Future<Battery?> readBattery() async {
    try {
      if (await isDeviceConnected() == true) {
        final result =
            await methodChannel.invokeMapMethod<String, dynamic>('readBattery');
        return result != null ? Battery.fromJson(result) : null;
      } else {
        // throw DeviceConnectionException('Device is not connected');
        throw const VeepooException(message: 'Device is not connected');
      }
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read battery: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  /// Stream of Bluetooth scan results.
  ///
  /// Returns a [Stream] of [List] of [BluetoothDevice] objects.
  @override
  Stream<List<BluetoothDevice>> get bluetoothDevices {
    _bluetoothDevicesStream ??= bluetoothEventChannel.receiveBroadcastStream().map<List<BluetoothDevice>>((event) {
      if (event == null) return <BluetoothDevice>[];

      if (event is List) {
        return event.map<BluetoothDevice>((item) {
          if (item is Map<Object?, Object?>) {
            final convertedMap = Map<String, dynamic>.from(
              item.map((key, value) => MapEntry(key.toString(), value)),
            );
            return BluetoothDevice.fromJson(convertedMap);
          }
          throw VeepooException(
            message: 'Unexpected event type: ${item.runtimeType}',
          );
        }).toList();
      }

      throw VeepooException(
        message: 'Unexpected event type: ${event.runtimeType}',
      );
    }).asBroadcastStream();

    return _bluetoothDevicesStream!;
  }

  /// Stream of heart rate detection results.
  ///
  /// Returns a [Stream] of [HeartRate] objects.
  @override
  Stream<HeartRate?> get heartRate {
    _heartRateStream ??= heartRateEventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map) {
        final result =
            event.map((key, value) => MapEntry(key.toString(), value));

        return HeartRate.fromJson(result);
      } else {
        throw VeepooException(
          message: 'Unexpected event type: ${event.runtimeType}',
        );
      }
    }).asBroadcastStream();

    return _heartRateStream!;
  }

  /// Stream of blood oxygen results.
  ///
  /// Returns a [Stream] of [Spoh] objects.
  @override
  Stream<Spoh?> get spoh {
    _spohStream ??= spohEventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map<Object?, Object?>) {
        final result =
            event.map((key, value) => MapEntry(key.toString(), value));

        return Spoh.fromJson(result);
      } else {
        throw VeepooException(
          message: 'Unexpected event type: ${event.runtimeType}',
        );
      }
    }).asBroadcastStream();

    return _spohStream!;
  }

  // ==================== Sleep Data ====================

  @override
  Future<SleepData?> readSleepData() async {
    try {
      final result =
          await methodChannel.invokeMapMethod<String, dynamic>('readSleepData');
      return result != null ? SleepData.fromMap(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read sleep data: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== Step Data ====================

  @override
  Future<StepData?> readStepData() async {
    try {
      final result =
          await methodChannel.invokeMapMethod<String, dynamic>('readStepData');
      return result != null ? StepData.fromMap(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read step data: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<StepData?> readStepDataForDate(DateTime date) async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'readStepDataForDate',
        {'timestamp': date.millisecondsSinceEpoch},
      );
      return result != null ? StepData.fromMap(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read step data for date: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== Blood Pressure ====================

  @override
  Future<void> startDetectBloodPressure() async {
    try {
      await methodChannel.invokeMethod<void>('startDetectBloodPressure');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to start blood pressure detection: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> stopDetectBloodPressure() async {
    try {
      await methodChannel.invokeMethod<void>('stopDetectBloodPressure');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to stop blood pressure detection: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setBloodPressureAlarm(
    int systolicHigh,
    int systolicLow,
    int diastolicHigh,
    int diastolicLow,
    bool enabled,
  ) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setBloodPressureAlarm',
        {
          'systolicHigh': systolicHigh,
          'systolicLow': systolicLow,
          'diastolicHigh': diastolicHigh,
          'diastolicLow': diastolicLow,
          'enabled': enabled,
        },
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to set blood pressure alarm: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<BloodPressure?> readBloodPressure() async {
    try {
      final result = await methodChannel
          .invokeMapMethod<String, dynamic>('readBloodPressure');
      return result != null ? BloodPressure.fromMap(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read blood pressure: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== Temperature ====================

  @override
  Future<void> startDetectTemperature() async {
    try {
      await methodChannel.invokeMethod<void>('startDetectTemperature');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to start temperature detection: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> stopDetectTemperature() async {
    try {
      await methodChannel.invokeMethod<void>('stopDetectTemperature');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to stop temperature detection: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<Temperature?> readTemperature() async {
    try {
      final result = await methodChannel
          .invokeMapMethod<String, dynamic>('readTemperature');
      return result != null ? Temperature.fromMap(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read temperature: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Temperature>> readTemperatureHistory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await methodChannel.invokeListMethod<Map>(
        'readTemperatureHistory',
        {
          'startTimestamp': startDate.millisecondsSinceEpoch,
          'endTimestamp': endDate.millisecondsSinceEpoch,
        },
      );
      return result
              ?.map((item) => Temperature.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [];
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read temperature history: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== Blood Glucose ====================

  @override
  Future<void> startDetectBloodGlucose() async {
    try {
      await methodChannel.invokeMethod<void>('startDetectBloodGlucose');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to start blood glucose detection: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> stopDetectBloodGlucose() async {
    try {
      await methodChannel.invokeMethod<void>('stopDetectBloodGlucose');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to stop blood glucose detection: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setBloodGlucoseCalibration(bool enabled) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setBloodGlucoseCalibration',
        {'enabled': enabled},
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to set blood glucose calibration: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<BloodGlucose?> readBloodGlucose() async {
    try {
      final result = await methodChannel
          .invokeMapMethod<String, dynamic>('readBloodGlucose');
      return result != null ? BloodGlucose.fromMap(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read blood glucose: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== ECG ====================

  @override
  Future<void> startDetectEcg() async {
    try {
      await methodChannel.invokeMethod<void>('startDetectEcg');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to start ECG detection: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> stopDetectEcg() async {
    try {
      await methodChannel.invokeMethod<void>('stopDetectEcg');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to stop ECG detection: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<EcgData?> readEcgData() async {
    try {
      final result =
          await methodChannel.invokeMapMethod<String, dynamic>('readEcgData');
      return result != null ? EcgData.fromMap(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read ECG data: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== Blood Component ====================

  @override
  Future<void> startDetectBloodComponent({bool needCalibration = false}) async {
    try {
      await methodChannel.invokeMethod<void>(
        'startDetectBloodComponent',
        {'needCalibration': needCalibration},
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to start blood component detection: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> stopDetectBloodComponent() async {
    try {
      await methodChannel.invokeMethod<void>('stopDetectBloodComponent');
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to stop blood component detection: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== HRV ====================

  @override
  Future<List<HRVData>> readHRVData({int days = 7}) async {
    try {
      final result = await methodChannel.invokeMethod<List<dynamic>>(
        'readHRVData',
        {'days': days},
      );
      if (result == null) return [];
      return result
          .map((e) => HRVData.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read HRV data: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== Device Info ====================

  @override
  Future<DeviceInfo?> getDeviceInfo() async {
    try {
      final result =
          await methodChannel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      return result != null ? DeviceInfo.fromMap(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to get device info: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== User Profile ====================

  @override
  Future<void> setUserProfile(UserProfile profile) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setUserProfile',
        profile.toMap(),
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to set user profile: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      final result = await methodChannel
          .invokeMapMethod<String, dynamic>('getUserProfile');
      return result != null ? UserProfile.fromMap(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to get user profile: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== Device Settings ====================

  @override
  Future<void> setDeviceSettings(DeviceSettings settings) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setDeviceSettings',
        settings.toMap(),
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to set device settings: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<DeviceSettings?> getDeviceSettings() async {
    try {
      final result = await methodChannel
          .invokeMapMethod<String, dynamic>('getDeviceSettings');
      return result != null ? DeviceSettings.fromMap(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to get device settings: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setScreenBrightness(int brightness) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setScreenBrightness',
        {'brightness': brightness},
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to set screen brightness: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setScreenDuration(int seconds) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setScreenDuration',
        {'seconds': seconds},
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to set screen duration: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setTimeFormat(bool is24Hour) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setTimeFormat',
        {'is24Hour': is24Hour},
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to set time format: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setLanguage',
        {'languageCode': languageCode},
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to set language: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setWristRaiseToWake(bool enabled, int sensitivity) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setWristRaiseToWake',
        {'enabled': enabled, 'sensitivity': sensitivity},
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to set wrist raise to wake: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<void> setDoNotDisturb(
    bool enabled,
    int startMinutes,
    int endMinutes,
  ) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setDoNotDisturb',
        {
          'enabled': enabled,
          'startMinutes': startMinutes,
          'endMinutes': endMinutes,
        },
      );
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to set do not disturb: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== Origin Health Data ====================

  @override
  Future<List<DailyHealthData>> readOriginData3Days() async {
    try {
      final result = await methodChannel.invokeListMethod<Map>(
        'readOriginData3Days',
      );
      if (result == null) return [];
      return result
          .map((item) => DailyHealthData.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read origin data for 3 days: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<DailyHealthData?> readOriginDataForDay(int day) async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'readOriginDataForDay',
        {'day': day},
      );
      return result != null ? DailyHealthData.fromMap(result) : null;
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read origin data for day $day: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== Historical Data ====================

  @override
  Future<List<HeartRate>> readHeartRateHistory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await methodChannel.invokeListMethod<Map>(
        'readHeartRateHistory',
        {
          'startTimestamp': startDate.millisecondsSinceEpoch,
          'endTimestamp': endDate.millisecondsSinceEpoch,
        },
      );
      return result
              ?.map((item) => HeartRate.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [];
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read heart rate history: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<List<SleepData>> readSleepHistory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await methodChannel.invokeListMethod<Map>(
        'readSleepHistory',
        {
          'startTimestamp': startDate.millisecondsSinceEpoch,
          'endTimestamp': endDate.millisecondsSinceEpoch,
        },
      );
      return result
              ?.map((item) => SleepData.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [];
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read sleep history: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<List<StepData>> readStepHistory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await methodChannel.invokeListMethod<Map>(
        'readStepHistory',
        {
          'startTimestamp': startDate.millisecondsSinceEpoch,
          'endTimestamp': endDate.millisecondsSinceEpoch,
        },
      );
      return result
              ?.map((item) => StepData.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [];
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read step history: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  @override
  Future<List<BloodPressure>> readBloodPressureHistory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await methodChannel.invokeListMethod<Map>(
        'readBloodPressureHistory',
        {
          'startTimestamp': startDate.millisecondsSinceEpoch,
          'endTimestamp': endDate.millisecondsSinceEpoch,
        },
      );
      return result
              ?.map((item) =>
                  BloodPressure.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [];
    } on PlatformException catch (error, stackTrace) {
      throw VeepooException(
        message: 'Failed to read blood pressure history: ${error.message}',
        details: error.details,
        stacktrace: stackTrace,
      );
    }
  }

  // ==================== Streams ====================

  @override
  Stream<BloodPressure?> get bloodPressure {
    _bloodPressureStream ??= bloodPressureEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
      if (event is Map<Object?, Object?>) {
        final result =
            event.map((key, value) => MapEntry(key.toString(), value));
        return BloodPressure.fromMap(result);
      } else {
        throw VeepooException(
          message: 'Unexpected event type: ${event.runtimeType}',
        );
      }
    }).asBroadcastStream();

    return _bloodPressureStream!;
  }

  @override
  Stream<Temperature?> get temperature {
    _temperatureStream ??= temperatureEventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map<Object?, Object?>) {
        final result =
            event.map((key, value) => MapEntry(key.toString(), value));
        return Temperature.fromMap(result);
      } else {
        throw VeepooException(
          message: 'Unexpected event type: ${event.runtimeType}',
        );
      }
    }).asBroadcastStream();

    return _temperatureStream!;
  }

  @override
  Stream<BloodGlucose?> get bloodGlucose {
    _bloodGlucoseStream ??= bloodGlucoseEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
      if (event is Map<Object?, Object?>) {
        final result =
            event.map((key, value) => MapEntry(key.toString(), value));
        return BloodGlucose.fromMap(result);
      } else {
        throw VeepooException(
          message: 'Unexpected event type: ${event.runtimeType}',
        );
      }
    }).asBroadcastStream();

    return _bloodGlucoseStream!;
  }

  @override
  Stream<EcgData?> get ecgData {
    _ecgDataStream ??= ecgEventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map<Object?, Object?>) {
        final result =
            event.map((key, value) => MapEntry(key.toString(), value));
        return EcgData.fromMap(result);
      } else {
        throw VeepooException(
          message: 'Unexpected event type: ${event.runtimeType}',
        );
      }
    }).asBroadcastStream();

    return _ecgDataStream!;
  }

  @override
  Stream<BloodComponent?> get bloodComponent {
    _bloodComponentStream ??= bloodComponentEventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map<Object?, Object?>) {
        final result =
            event.map((key, value) => MapEntry(key.toString(), value));
        return BloodComponent.fromMap(result);
      } else {
        throw VeepooException(
          message: 'Unexpected event type: ${event.runtimeType}',
        );
      }
    }).asBroadcastStream();

    return _bloodComponentStream!;
  }

  @override
  Stream<StepData?> get stepData {
    _stepDataStream ??= stepDataEventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map<Object?, Object?>) {
        final result =
            event.map((key, value) => MapEntry(key.toString(), value));
        return StepData.fromMap(result);
      } else {
        throw VeepooException(
          message: 'Unexpected event type: ${event.runtimeType}',
        );
      }
    }).asBroadcastStream();

    return _stepDataStream!;
  }

  @override
  Stream<OriginDataProgress?> get originDataProgress {
    _originDataProgressStream ??= originDataProgressEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
      if (event is Map<Object?, Object?>) {
        final result =
            event.map((key, value) => MapEntry(key.toString(), value));
        return OriginDataProgress.fromMap(result);
      } else {
        throw VeepooException(
          message: 'Unexpected event type: ${event.runtimeType}',
        );
      }
    }).asBroadcastStream();

    return _originDataProgressStream!;
  }
}
