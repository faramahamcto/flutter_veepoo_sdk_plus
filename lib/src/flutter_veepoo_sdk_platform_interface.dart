part of '../flutter_veepoo_sdk.dart';

/// The interface that implementations of flutter_veepoo_sdk must implement.
abstract class FlutterVeepooSdkPlatform extends PlatformInterface {
  /// Constructs a FlutterVeepooSdkPlatform.
  FlutterVeepooSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterVeepooSdkPlatform _instance = MethodChannelFlutterVeepooSdk();

  /// The default instance of [FlutterVeepooSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterVeepooSdk].
  static FlutterVeepooSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterVeepooSdkPlatform] when
  /// they register themselves.
  static set instance(FlutterVeepooSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Requests the necessary permissions to use Bluetooth.
  Future<PermissionStatuses?> requestBluetoothPermissions() {
    throw UnimplementedError(
      'requestBluetoothPermissions() has not been implemented.',
    );
  }

  /// Open app settings.
  Future<void> openAppSettings() {
    throw UnimplementedError(
      'openAppSettings() has not been implemented.',
    );
  }

  /// Check if Bluetooth is enabled.
  Future<bool?> isBluetoothEnabled() {
    throw UnimplementedError(
      'isBluetoothEnabled() has not been implemented.',
    );
  }

  /// Open Bluetooth.
  Future<void> openBluetooth() {
    throw UnimplementedError('openBluetooth() has not been implemented.');
  }

  /// Close Bluetooth.
  Future<void> closeBluetooth() {
    throw UnimplementedError('closeBluetooth() has not been implemented.');
  }

  /// Scans Bluetooth devices.
  Future<void> scanDevices() {
    throw UnimplementedError('scanDevices() has not been implemented.');
  }

  /// Stop scan Bluetooth devices.
  Future<void> stopScanDevices() {
    throw UnimplementedError('stopScanDevices() has not been implemented.');
  }

  /// Connects to a Bluetooth device.
  Future<void> connectDevice(String address) {
    throw UnimplementedError('connectDevice() has not been implemented.');
  }

  /// Bind device with password and is24H.
  /// This function will return a [DeviceBindingStatus] to indicate the status of the device binding.
  Future<DeviceBindingStatus?> bindDevice(String password, bool is24H) {
    throw UnimplementedError('bindDevice() has not been implemented.');
  }

  /// Disconnects from a Bluetooth device.
  Future<void> disconnectDevice() {
    throw UnimplementedError('disconnectDevice() has not been implemented.');
  }

  /// Get the address of the connected device.
  Future<String?> getAddress() {
    throw UnimplementedError('getAddress() has not been implemented.');
  }

  /// Get the current status of the device.
  Future<int?> getCurrentStatus() {
    throw UnimplementedError('getCurrentStatus() has not been implemented.');
  }

  /// Check if the device is connected.
  Future<bool?> isDeviceConnected() {
    throw UnimplementedError('isDeviceConnected() has not been implemented.');
  }

  /// Check if a device has been bound (paired) before.
  /// A device is considered bound if credentials have been saved during the binding process.
  Future<bool?> isDeviceBinded() {
    throw UnimplementedError('isDeviceBinded() has not been implemented.');
  }

  /// Start detect heart rate.
  /// This function is used to start detecting heart rate. The device will return the heart rate data to the app.
  ///
  /// Please use [bindDevice] before calling this function or you can use [startDetectHeartAfterBinding] to bind and start detect heart rate.
  Future<void> startDetectHeart() {
    throw UnimplementedError('startDetectHeart() has not been implemented.');
  }

  /// Start detect heart rate after binding.
  Future<void> startDetectHeartAfterBinding(String password, bool is24H) {
    throw UnimplementedError(
      'startDetectHeartAfterBinding() has not been implemented.',
    );
  }

  /// Stop detect heart rate.
  Future<void> stopDetectHeart() {
    throw UnimplementedError('stopDetectHeart() has not been implemented.');
  }

  /// Setting heart rate warning.
  Future<void> settingHeartWarning(int high, int low, bool open) {
    throw UnimplementedError('settingHeartWarning() has not been implemented.');
  }

  /// Read heart rate warning.
  Future<void> readHeartWarning() {
    throw UnimplementedError('readHeartWarning() has not been implemented.');
  }

  /// Start detect blood oxygen.
  Future<void> startDetectSpoh() {
    throw UnimplementedError('startDetectSpoh() has not been implemented.');
  }

  /// Start detect blood oxygen after binding.
  Future<void> startDetectSpohAfterBinding(String password, bool is24H) {
    throw UnimplementedError(
      'startDetectSpohAfterBinding() has not been implemented.',
    );
  }

  /// Stop detect blood oxygen.
  Future<void> stopDetectSpoh() {
    throw UnimplementedError('stopDetectSpoh() has not been implemented.');
  }

  /// Read battery level.
  Future<Battery?> readBattery() {
    throw UnimplementedError('readBattery() has not been implemented.');
  }

  // ==================== Sleep Data ====================

  /// Read sleep data.
  Future<SleepData?> readSleepData() {
    throw UnimplementedError('readSleepData() has not been implemented.');
  }

  // ==================== Step Data ====================

  /// Read step data.
  Future<StepData?> readStepData() {
    throw UnimplementedError('readStepData() has not been implemented.');
  }

  /// Read step data for a specific date.
  Future<StepData?> readStepDataForDate(DateTime date) {
    throw UnimplementedError('readStepDataForDate() has not been implemented.');
  }

  // ==================== Blood Pressure ====================

  /// Start blood pressure detection.
  Future<void> startDetectBloodPressure() {
    throw UnimplementedError(
      'startDetectBloodPressure() has not been implemented.',
    );
  }

  /// Stop blood pressure detection.
  Future<void> stopDetectBloodPressure() {
    throw UnimplementedError(
      'stopDetectBloodPressure() has not been implemented.',
    );
  }

  /// Set blood pressure alarm thresholds.
  Future<void> setBloodPressureAlarm(
    int systolicHigh,
    int systolicLow,
    int diastolicHigh,
    int diastolicLow,
    bool enabled,
  ) {
    throw UnimplementedError(
      'setBloodPressureAlarm() has not been implemented.',
    );
  }

  /// Read blood pressure data.
  Future<BloodPressure?> readBloodPressure() {
    throw UnimplementedError('readBloodPressure() has not been implemented.');
  }

  // ==================== Temperature ====================

  /// Start temperature detection.
  Future<void> startDetectTemperature() {
    throw UnimplementedError(
      'startDetectTemperature() has not been implemented.',
    );
  }

  /// Stop temperature detection.
  Future<void> stopDetectTemperature() {
    throw UnimplementedError(
      'stopDetectTemperature() has not been implemented.',
    );
  }

  /// Read temperature data.
  Future<Temperature?> readTemperature() {
    throw UnimplementedError('readTemperature() has not been implemented.');
  }

  /// Read temperature data for a specific date range.
  Future<List<Temperature>> readTemperatureHistory(
    DateTime startDate,
    DateTime endDate,
  ) {
    throw UnimplementedError(
      'readTemperatureHistory() has not been implemented.',
    );
  }

  // ==================== Blood Glucose ====================

  /// Start blood glucose detection.
  Future<void> startDetectBloodGlucose() {
    throw UnimplementedError(
      'startDetectBloodGlucose() has not been implemented.',
    );
  }

  /// Stop blood glucose detection.
  Future<void> stopDetectBloodGlucose() {
    throw UnimplementedError(
      'stopDetectBloodGlucose() has not been implemented.',
    );
  }

  /// Set blood glucose calibration mode.
  Future<void> setBloodGlucoseCalibration(bool enabled) {
    throw UnimplementedError(
      'setBloodGlucoseCalibration() has not been implemented.',
    );
  }

  /// Read blood glucose data.
  Future<BloodGlucose?> readBloodGlucose() {
    throw UnimplementedError('readBloodGlucose() has not been implemented.');
  }

  // ==================== ECG ====================

  /// Start ECG detection.
  Future<void> startDetectEcg() {
    throw UnimplementedError('startDetectEcg() has not been implemented.');
  }

  /// Stop ECG detection.
  Future<void> stopDetectEcg() {
    throw UnimplementedError('stopDetectEcg() has not been implemented.');
  }

  /// Read ECG data.
  Future<EcgData?> readEcgData() {
    throw UnimplementedError('readEcgData() has not been implemented.');
  }

  // ==================== Blood Component ====================

  /// Start blood component detection.
  Future<void> startDetectBloodComponent({bool needCalibration = false}) {
    throw UnimplementedError(
      'startDetectBloodComponent() has not been implemented.',
    );
  }

  /// Stop blood component detection.
  Future<void> stopDetectBloodComponent() {
    throw UnimplementedError(
      'stopDetectBloodComponent() has not been implemented.',
    );
  }

  // ==================== HRV ====================

  /// Read HRV data.
  Future<List<HRVData>> readHRVData({int days = 7}) {
    throw UnimplementedError('readHRVData() has not been implemented.');
  }

  // ==================== Device Info ====================

  /// Get device information.
  Future<DeviceInfo?> getDeviceInfo() {
    throw UnimplementedError('getDeviceInfo() has not been implemented.');
  }

  // ==================== User Profile ====================

  /// Set user profile information.
  Future<void> setUserProfile(UserProfile profile) {
    throw UnimplementedError('setUserProfile() has not been implemented.');
  }

  /// Get user profile information.
  Future<UserProfile?> getUserProfile() {
    throw UnimplementedError('getUserProfile() has not been implemented.');
  }

  // ==================== Device Settings ====================

  /// Set device settings.
  Future<void> setDeviceSettings(DeviceSettings settings) {
    throw UnimplementedError('setDeviceSettings() has not been implemented.');
  }

  /// Get device settings.
  Future<DeviceSettings?> getDeviceSettings() {
    throw UnimplementedError('getDeviceSettings() has not been implemented.');
  }

  /// Set screen brightness (0-5).
  Future<void> setScreenBrightness(int brightness) {
    throw UnimplementedError('setScreenBrightness() has not been implemented.');
  }

  /// Set screen duration in seconds.
  Future<void> setScreenDuration(int seconds) {
    throw UnimplementedError('setScreenDuration() has not been implemented.');
  }

  /// Set time format (12h/24h).
  Future<void> setTimeFormat(bool is24Hour) {
    throw UnimplementedError('setTimeFormat() has not been implemented.');
  }

  /// Set device language.
  Future<void> setLanguage(String languageCode) {
    throw UnimplementedError('setLanguage() has not been implemented.');
  }

  /// Set wrist raise to wake feature.
  Future<void> setWristRaiseToWake(bool enabled, int sensitivity) {
    throw UnimplementedError('setWristRaiseToWake() has not been implemented.');
  }

  /// Set do not disturb mode.
  Future<void> setDoNotDisturb(bool enabled, int startMinutes, int endMinutes) {
    throw UnimplementedError('setDoNotDisturb() has not been implemented.');
  }

  // ==================== Origin Health Data ====================

  /// Read origin health data for 3 days (today, yesterday, 2 days ago).
  /// Returns a list of [DailyHealthData] objects with aggregated data.
  Future<List<DailyHealthData>> readOriginData3Days() {
    throw UnimplementedError('readOriginData3Days() has not been implemented.');
  }

  /// Read origin health data for a specific day.
  /// [day] - 0 for today, 1 for yesterday, 2 for 2 days ago
  /// Returns a [DailyHealthData] object with aggregated data.
  Future<DailyHealthData?> readOriginDataForDay(int day) {
    throw UnimplementedError('readOriginDataForDay() has not been implemented.');
  }

  // ==================== Historical Data ====================

  /// Read historical heart rate data for a date range.
  Future<List<HeartRate>> readHeartRateHistory(
    DateTime startDate,
    DateTime endDate,
  ) {
    throw UnimplementedError(
      'readHeartRateHistory() has not been implemented.',
    );
  }

  /// Read historical sleep data for a date range.
  Future<List<SleepData>> readSleepHistory(
    DateTime startDate,
    DateTime endDate,
  ) {
    throw UnimplementedError('readSleepHistory() has not been implemented.');
  }

  /// Read historical step data for a date range.
  Future<List<StepData>> readStepHistory(
    DateTime startDate,
    DateTime endDate,
  ) {
    throw UnimplementedError('readStepHistory() has not been implemented.');
  }

  /// Read historical blood pressure data for a date range.
  Future<List<BloodPressure>> readBloodPressureHistory(
    DateTime startDate,
    DateTime endDate,
  ) {
    throw UnimplementedError(
      'readBloodPressureHistory() has not been implemented.',
    );
  }

  // ==================== Streams ====================

  /// Stream of Bluetooth scan results.
  Stream<List<BluetoothDevice>?> get bluetoothDevices {
    throw UnimplementedError(
      'bluetoothEventChannel has not been implemented.',
    );
  }

  /// Stream of heart rate results.
  Stream<HeartRate?> get heartRate {
    throw UnimplementedError('heartRateEventChannel has not been implemented.');
  }

  /// Stream of blood oxygen results.
  Stream<Spoh?> get spoh {
    throw UnimplementedError('spohEventChannel has not been implemented.');
  }

  /// Stream of blood pressure results.
  Stream<BloodPressure?> get bloodPressure {
    throw UnimplementedError(
      'bloodPressureEventChannel has not been implemented.',
    );
  }

  /// Stream of temperature results.
  Stream<Temperature?> get temperature {
    throw UnimplementedError(
      'temperatureEventChannel has not been implemented.',
    );
  }

  /// Stream of blood glucose results.
  Stream<BloodGlucose?> get bloodGlucose {
    throw UnimplementedError(
      'bloodGlucoseEventChannel has not been implemented.',
    );
  }

  /// Stream of ECG results.
  Stream<EcgData?> get ecgData {
    throw UnimplementedError('ecgDataEventChannel has not been implemented.');
  }

  /// Stream of blood component results.
  Stream<BloodComponent?> get bloodComponent {
    throw UnimplementedError(
      'bloodComponentEventChannel has not been implemented.',
    );
  }

  /// Stream of step data updates.
  Stream<StepData?> get stepData {
    throw UnimplementedError('stepDataEventChannel has not been implemented.');
  }

  /// Stream of origin data reading progress updates.
  Stream<OriginDataProgress?> get originDataProgress {
    throw UnimplementedError('originDataProgressEventChannel has not been implemented.');
  }
}
