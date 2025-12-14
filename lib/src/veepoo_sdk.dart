part of '../flutter_veepoo_sdk.dart';

/// A general class for Flutter Veepoo SDK.
///
/// Don't use this class directly, use [VeepooSDK.instance] instead.
class VeepooSDK {
  VeepooSDK._();

  /// The instance of [VeepooSDK].
  static final VeepooSDK instance = VeepooSDK._();

  final FlutterVeepooSdkPlatform _platform = FlutterVeepooSdkPlatform.instance;

  /// Requests the necessary permissions to use Bluetooth.
  Future<PermissionStatuses?> requestBluetoothPermissions() {
    try {
      return _platform.requestBluetoothPermissions();
    } on VeepooException {
      rethrow;
    }
  }

  /// Open app settings.
  Future<void> openAppSettings() {
    try {
      return _platform.openAppSettings();
    } on VeepooException {
      rethrow;
    }
  }

  /// Check if Bluetooth is enabled.
  Future<bool?> isBluetoothEnabled() {
    try {
      return _platform.isBluetoothEnabled();
    } on VeepooException {
      rethrow;
    }
  }

  /// Open Bluetooth.
  Future<void> openBluetooth() {
    try {
      return _platform.openBluetooth();
    } on VeepooException {
      rethrow;
    }
  }

  /// Close Bluetooth.
  Future<void> closeBluetooth() {
    try {
      return _platform.closeBluetooth();
    } on VeepooException {
      rethrow;
    }
  }

  /// Scans Bluetooth devices.
  Future<void> scanDevices() {
    try {
      return _platform.scanDevices();
    } on VeepooException {
      rethrow;
    }
  }

  /// Stop scan Bluetooth devices.
  Future<void> stopScanDevices() {
    try {
      return _platform.stopScanDevices();
    } on VeepooException {
      rethrow;
    }
  }

  /// Connects to a Bluetooth device, or you can simply use [connectAndBindDevice] to connect and bind device.
  Future<void> connectDevice(String address) {
    try {
      return _platform.connectDevice(address);
    } on VeepooException {
      rethrow;
    }
  }

  /// Disconnects from a Bluetooth device.
  Future<void> disconnectDevice() {
    try {
      return _platform.disconnectDevice();
    } on VeepooException {
      rethrow;
    }
  }

  /// Bind device with password and is24H. This function can be used after successfully connecting to the device.
  /// This function will return a [DeviceBindingStatus] to indicate the status of the device binding.
  Future<DeviceBindingStatus?> bindDevice(String password, bool is24H) {
    try {
      return _platform.bindDevice(password, is24H);
    } on VeepooException {
      rethrow;
    }
  }

  /// Get connected device address.
  Future<String?> getAddress() {
    try {
      return _platform.getAddress();
    } on VeepooException {
      rethrow;
    }
  }

  /// Get current status.
  Future<int?> getCurrentStatus() {
    try {
      return _platform.getCurrentStatus();
    } on VeepooException {
      rethrow;
    }
  }

  /// Check if the device is connected.
  Future<bool?> isDeviceConnected() {
    try {
      return _platform.isDeviceConnected();
    } on VeepooException {
      rethrow;
    }
  }

  /// Check if a device has been bound (paired) before.
  /// Returns true if credentials have been saved during the binding process.
  Future<bool?> isDeviceBinded() {
    try {
      return _platform.isDeviceBinded();
    } on VeepooException {
      rethrow;
    }
  }

  /// Start detect heart rate.
  /// This function is used to start detecting heart rate. The device will return the heart rate data to the app.
  ///
  /// Please use [bindDevice] before calling this function or you can use [startDetectHeartAfterBinding] to bind and start detect heart rate.
  Future<void> startDetectHeart() {
    try {
      return _platform.startDetectHeart();
    } on VeepooException {
      rethrow;
    }
  }

  /// Start detect heart rate after binding.
  Future<void> startDetectHeartAfterBinding(String password, bool is24H) {
    try {
      return _platform.startDetectHeartAfterBinding(password, is24H);
    } on VeepooException {
      rethrow;
    }
  }

  /// Stop detect heart rate.
  Future<void> stopDetectHeart() {
    try {
      return _platform.stopDetectHeart();
    } on VeepooException {
      rethrow;
    }
  }

  /// Setting heart rate warning.
  Future<void> settingHeartRate(int high, int low, bool open) {
    return _platform.settingHeartWarning(high, low, open);
  }

  /// Read heart rate warning.
  Future<void> readHeartRate() {
    return _platform.readHeartWarning();
  }

  /// Start detect SPOH (blood oxygen).
  /// This function is used to start detecting SPOH (blood oxygen). The device will return the SPOH data to the app.
  /// Please use [bindDevice] before calling this function or you can use [startDetectSpohAfterBinding] to bind and start detect SPOH.
  Future<void> startDetectSpoh() {
    try {
      return _platform.startDetectSpoh();
    } on VeepooException {
      rethrow;
    }
  }

  /// Start detect SPOH (blood oxygen) after binding.
  Future<void> startDetectSpohAfterBinding(String password, bool is24H) {
    try {
      return _platform.startDetectSpohAfterBinding(password, is24H);
    } on VeepooException {
      rethrow;
    }
  }

  /// Stop detect SPOH (blood oxygen).
  Future<void> stopDetectSpoh() {
    try {
      return _platform.stopDetectSpoh();
    } on VeepooException {
      rethrow;
    }
  }

  /// Read battery level.
  Future<Battery?> readBattery() {
    try {
      return _platform.readBattery();
    } on VeepooException {
      rethrow;
    }
  }

  /// Stream of Bluetooth scan results.
  Stream<List<BluetoothDevice>?> get bluetoothDevices {
    try {
      return _platform.bluetoothDevices;
    } on VeepooException {
      rethrow;
    }
  }

  /// Stream of heart rate results.
  Stream<HeartRate?> get heartRate {
    try {
      return _platform.heartRate;
    } on VeepooException {
      rethrow;
    }
  }

  /// Stream of SPOH (blood oxygen) results.
  Stream<Spoh?> get spoh {
    try {
      return _platform.spoh;
    } on VeepooException {
      rethrow;
    }
  }

  // ==================== Sleep Data ====================

  /// Read sleep data from the device.
  Future<SleepData?> readSleepData() => _platform.readSleepData();

  /// Stream of sleep data updates.
  Future<List<SleepData>> readSleepHistory(DateTime startDate, DateTime endDate) =>
      _platform.readSleepHistory(startDate, endDate);

  // ==================== Step Data ====================

  /// Read current step data from the device.
  Future<StepData?> readStepData() => _platform.readStepData();

  /// Read step data for a specific date.
  Future<StepData?> readStepDataForDate(DateTime date) =>
      _platform.readStepDataForDate(date);

  /// Stream of real-time step data updates.
  Stream<StepData?> get stepData => _platform.stepData;

  /// Read step history for a date range.
  Future<List<StepData>> readStepHistory(DateTime startDate, DateTime endDate) =>
      _platform.readStepHistory(startDate, endDate);

  // ==================== Blood Pressure ====================

  /// Start blood pressure detection.
  Future<void> startDetectBloodPressure() =>
      _platform.startDetectBloodPressure();

  /// Stop blood pressure detection.
  Future<void> stopDetectBloodPressure() => _platform.stopDetectBloodPressure();

  /// Set blood pressure alarm thresholds.
  /// [systolicHigh] - High systolic threshold (mmHg)
  /// [systolicLow] - Low systolic threshold (mmHg)
  /// [diastolicHigh] - High diastolic threshold (mmHg)
  /// [diastolicLow] - Low diastolic threshold (mmHg)
  /// [enabled] - Enable or disable alarm
  Future<void> setBloodPressureAlarm(
    int systolicHigh,
    int systolicLow,
    int diastolicHigh,
    int diastolicLow,
    bool enabled,
  ) =>
      _platform.setBloodPressureAlarm(
        systolicHigh,
        systolicLow,
        diastolicHigh,
        diastolicLow,
        enabled,
      );

  /// Read blood pressure data.
  Future<BloodPressure?> readBloodPressure() => _platform.readBloodPressure();

  /// Stream of real-time blood pressure updates.
  Stream<BloodPressure?> get bloodPressure => _platform.bloodPressure;

  /// Read blood pressure history for a date range.
  Future<List<BloodPressure>> readBloodPressureHistory(
    DateTime startDate,
    DateTime endDate,
  ) =>
      _platform.readBloodPressureHistory(startDate, endDate);

  // ==================== Temperature ====================

  /// Start temperature detection.
  Future<void> startDetectTemperature() => _platform.startDetectTemperature();

  /// Stop temperature detection.
  Future<void> stopDetectTemperature() => _platform.stopDetectTemperature();

  /// Read current temperature data.
  Future<Temperature?> readTemperature() => _platform.readTemperature();

  /// Stream of real-time temperature updates.
  Stream<Temperature?> get temperature => _platform.temperature;

  /// Read temperature history for a date range.
  Future<List<Temperature>> readTemperatureHistory(
    DateTime startDate,
    DateTime endDate,
  ) =>
      _platform.readTemperatureHistory(startDate, endDate);

  // ==================== Blood Glucose ====================

  /// Start blood glucose detection.
  Future<void> startDetectBloodGlucose() => _platform.startDetectBloodGlucose();

  /// Stop blood glucose detection.
  Future<void> stopDetectBloodGlucose() => _platform.stopDetectBloodGlucose();

  /// Set blood glucose calibration mode.
  Future<void> setBloodGlucoseCalibration(bool enabled) =>
      _platform.setBloodGlucoseCalibration(enabled);

  /// Read blood glucose data.
  Future<BloodGlucose?> readBloodGlucose() => _platform.readBloodGlucose();

  /// Stream of real-time blood glucose updates.
  Stream<BloodGlucose?> get bloodGlucose => _platform.bloodGlucose;

  // ==================== ECG ====================

  /// Start ECG detection.
  Future<void> startDetectEcg() => _platform.startDetectEcg();

  /// Stop ECG detection.
  Future<void> stopDetectEcg() => _platform.stopDetectEcg();

  /// Read ECG data.
  Future<EcgData?> readEcgData() => _platform.readEcgData();

  /// Stream of real-time ECG data updates.
  Stream<EcgData?> get ecgData => _platform.ecgData;

  // ==================== Device Info ====================

  /// Get device information including model, version, battery, etc.
  Future<DeviceInfo?> getDeviceInfo() => _platform.getDeviceInfo();

  // ==================== User Profile ====================

  /// Set user profile information (height, weight, age, gender, etc.).
  /// This information is used for accurate health calculations.
  Future<void> setUserProfile(UserProfile profile) =>
      _platform.setUserProfile(profile);

  /// Get stored user profile information.
  Future<UserProfile?> getUserProfile() => _platform.getUserProfile();

  // ==================== Device Settings ====================

  /// Set device settings (screen brightness, time format, language, etc.).
  Future<void> setDeviceSettings(DeviceSettings settings) =>
      _platform.setDeviceSettings(settings);

  /// Get current device settings.
  Future<DeviceSettings?> getDeviceSettings() => _platform.getDeviceSettings();

  /// Set screen brightness (0-5).
  Future<void> setScreenBrightness(int brightness) =>
      _platform.setScreenBrightness(brightness);

  /// Set screen duration in seconds.
  Future<void> setScreenDuration(int seconds) =>
      _platform.setScreenDuration(seconds);

  /// Set time format (12-hour or 24-hour).
  Future<void> setTimeFormat(bool is24Hour) =>
      _platform.setTimeFormat(is24Hour);

  /// Set device language.
  Future<void> setLanguage(String languageCode) =>
      _platform.setLanguage(languageCode);

  /// Set wrist raise to wake feature.
  /// [enabled] - Enable or disable wrist raise to wake
  /// [sensitivity] - Sensitivity level (0-2: low, medium, high)
  Future<void> setWristRaiseToWake(bool enabled, int sensitivity) =>
      _platform.setWristRaiseToWake(enabled, sensitivity);

  /// Set do not disturb mode.
  /// [enabled] - Enable or disable do not disturb
  /// [startMinutes] - Start time in minutes from midnight (0-1439)
  /// [endMinutes] - End time in minutes from midnight (0-1439)
  Future<void> setDoNotDisturb(bool enabled, int startMinutes, int endMinutes) =>
      _platform.setDoNotDisturb(enabled, startMinutes, endMinutes);

  // ==================== Historical Data ====================

  /// Read heart rate history for a date range.
  Future<List<HeartRate>> readHeartRateHistory(
    DateTime startDate,
    DateTime endDate,
  ) =>
      _platform.readHeartRateHistory(startDate, endDate);
}
