# Flutter Veepoo SDK Plus

A comprehensive Flutter plugin for Veepoo smartwatch SDK that provides extensive health monitoring and device management capabilities.

> **Note**: This plugin currently supports Android only. The Dart/Flutter API is complete, but some Android native implementations are still in development. See [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md) for details.

## Features

### 🔗 Connectivity & Device Management
- ✅ Bluetooth device scanning and filtering
- ✅ Device connection and pairing
- ✅ Device binding with PIN authentication
- ✅ Real-time connection status monitoring
- ✅ Device information retrieval
- ✅ Battery level monitoring

### ❤️ Health Monitoring
- ✅ **Heart Rate**: Real-time monitoring with alarm settings
- ✅ **Blood Oxygen (SpO2)**: Continuous oxygen saturation tracking
- 🔄 **Blood Pressure**: Automatic/manual measurement with alarms
- 🔄 **Body Temperature**: Celsius/Fahrenheit with auto-detection
- 🔄 **Blood Glucose**: Monitoring with calibration support
- 🔄 **ECG**: Electrocardiogram with waveform data and diagnostics

### 🏃 Activity & Sleep Tracking
- 🔄 **Step Counter**: Real-time steps, distance, and calories
- 🔄 **Sleep Analysis**: Deep/light sleep, quality scoring, sleep curve
- 🔄 **Activity Minutes**: Track active time throughout the day

### ⚙️ Device Configuration
- 🔄 **Screen Settings**: Brightness and duration control
- 🔄 **Time Format**: 12/24-hour configuration
- 🔄 **Language**: Multi-language support
- 🔄 **Wrist Raise**: Configurable sensitivity
- 🔄 **Do Not Disturb**: Scheduled quiet hours
- 🔄 **Units**: Metric/Imperial, Celsius/Fahrenheit

### 📊 Data Management
- 🔄 **Historical Data**: Retrieve health data for date ranges
- 🔄 **User Profile**: Height, weight, age, gender, goals
- 🔄 **Data Sync**: Automatic synchronization

**Legend**: ✅ Fully Implemented | 🔄 API Ready (Android Implementation Needed)

## Platform Support

| Feature Category | Android | iOS |
|-----------------|---------|-----|
| Basic Connectivity | ✅ Supported | ❌ Not Supported |
| Heart Rate & SpO2 | ✅ Supported | ❌ Not Supported |
| Blood Pressure | 🔄 API Ready | ❌ Not Supported |
| Temperature | 🔄 API Ready | ❌ Not Supported |
| Blood Glucose | 🔄 API Ready | ❌ Not Supported |
| ECG | 🔄 API Ready | ❌ Not Supported |
| Steps & Sleep | 🔄 API Ready | ❌ Not Supported |
| Device Settings | 🔄 API Ready | ❌ Not Supported |
| Historical Data | 🔄 API Ready | ❌ Not Supported |

## Installation

### 1. Add Dependency

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_veepoo_sdk:
    git:
      url: https://github.com/faramahamcto/flutter_veepoo_sdk_plus.git
      ref: main
```

### 2. Android Permissions

Add required permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Bluetooth Permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"
                     android:usesPermissionFlags="neverForLocation"
                     tools:targetApi="s"/>

    <!-- Location (required for Bluetooth scanning on Android) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

    <!-- Network State -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <!-- Bluetooth LE Feature -->
    <uses-feature
        android:name="android.hardware.bluetooth_le"
        android:required="true"/>
</manifest>
```

### 3. Minimum SDK Version

Set minimum SDK version in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Required for Veepoo SDK
    }
}
```

## Quick Start

### Initialize SDK

```dart
import 'package:flutter_veepoo_sdk/flutter_veepoo_sdk.dart';

final veepooSdk = VeepooSDK.instance;
```

### Request Permissions

```dart
final status = await veepooSdk.requestBluetoothPermissions();
if (status == PermissionStatuses.granted) {
  print('Permissions granted');
} else if (status == PermissionStatuses.permanentlyDenied) {
  // Open app settings
  await veepooSdk.openAppSettings();
}
```

### Scan for Devices

```dart
// Start scanning
await veepooSdk.scanDevices();

// Listen to scan results
veepooSdk.bluetoothDevices.listen((devices) {
  for (var device in devices ?? []) {
    print('Found: ${device.name} (${device.address})');
    print('Signal: ${device.rssi} dBm');
  }
});

// Stop scanning when done
await veepooSdk.stopScanDevices();
```

### Connect to Device

```dart
// Connect
await veepooSdk.connectDevice(deviceAddress);

// Check connection status
bool? isConnected = await veepooSdk.isDeviceConnected();

// Bind device (authenticate with PIN)
final bindStatus = await veepooSdk.bindDevice('0000', true); // PIN, 24h format
if (bindStatus == DeviceBindingStatus.checkAndTimeSuccess) {
  print('Device bound successfully');
}

// Disconnect
await veepooSdk.disconnectDevice();
```

## Usage Examples

### Heart Rate Monitoring

```dart
// Start heart rate detection
await veepooSdk.startDetectHeart();

// Listen to real-time heart rate
veepooSdk.heartRate.listen((heartRate) {
  print('Heart Rate: ${heartRate?.data} BPM');
  print('Status: ${heartRate?.state?.name}');
});

// Set heart rate alarm (high: 120, low: 60)
await veepooSdk.settingHeartRate(120, 60, true);

// Stop detection
await veepooSdk.stopDetectHeart();
```

### Blood Oxygen (SpO2)

```dart
// Start SpO2 detection
await veepooSdk.startDetectSpoh();

// Monitor SpO2 levels
veepooSdk.spoh.listen((spoh) {
  print('SpO2: ${spoh?.value}%');
  print('Checking: ${spoh?.checking}');
  print('Progress: ${spoh?.checkingProgress}%');
});

// Stop detection
await veepooSdk.stopDetectSpoh();
```

### Blood Pressure Monitoring

```dart
// Start blood pressure measurement
await veepooSdk.startDetectBloodPressure();

// Monitor real-time results
veepooSdk.bloodPressure.listen((bp) {
  print('BP: ${bp?.systolic}/${bp?.diastolic} mmHg');
  print('Progress: ${bp?.progress}%');
});

// Set blood pressure alarm
await veepooSdk.setBloodPressureAlarm(
  140, // Systolic high
  90,  // Systolic low
  90,  // Diastolic high
  60,  // Diastolic low
  true // Enable alarm
);

// Stop measurement
await veepooSdk.stopDetectBloodPressure();
```

### Temperature Monitoring

```dart
// Start temperature measurement
await veepooSdk.startDetectTemperature();

// Monitor temperature
veepooSdk.temperature.listen((temp) {
  print('Temperature: ${temp?.temperatureCelsius}°C');
  print('Temperature: ${temp?.temperatureFahrenheit}°F');
});

// Read temperature history (last 7 days)
final endDate = DateTime.now();
final startDate = endDate.subtract(Duration(days: 7));
final history = await veepooSdk.readTemperatureHistory(startDate, endDate);
```

### Step Counting & Activity

```dart
// Monitor real-time steps
veepooSdk.stepData.listen((steps) {
  print('Steps: ${steps?.steps}');
  print('Distance: ${steps?.distanceMeters} meters');
  print('Calories: ${steps?.calories} kcal');
  print('Active Minutes: ${steps?.activeMinutes}');
});

// Read step data for today
final stepData = await veepooSdk.readStepData();

// Read step history
final stepHistory = await veepooSdk.readStepHistory(startDate, endDate);
```

### Sleep Analysis

```dart
// Read last night's sleep
final sleepData = await veepooSdk.readSleepData();
print('Total Sleep: ${sleepData?.totalSleepMinutes} minutes');
print('Deep Sleep: ${sleepData?.deepSleepMinutes} minutes');
print('Light Sleep: ${sleepData?.lightSleepMinutes} minutes');
print('Awake: ${sleepData?.awakeMinutes} minutes');
print('Sleep Quality: ${sleepData?.sleepQuality}%');

// Read sleep history
final sleepHistory = await veepooSdk.readSleepHistory(startDate, endDate);
```

### ECG Measurement

```dart
// Start ECG measurement
await veepooSdk.startDetectEcg();

// Monitor ECG data
veepooSdk.ecgData.listen((ecg) {
  print('Heart Rate: ${ecg?.heartRate} BPM');
  print('Signal Quality: ${ecg?.signalQuality}%');
  print('Diagnostic Result: ${ecg?.diagnosticResult}');
  print('Waveform Data Points: ${ecg?.waveformData?.length}');
});

// Stop ECG
await veepooSdk.stopDetectEcg();
```

### Blood Glucose

```dart
// Enable calibration mode
await veepooSdk.setBloodGlucoseCalibration(true);

// Start measurement
await veepooSdk.startDetectBloodGlucose();

// Monitor glucose levels
veepooSdk.bloodGlucose.listen((glucose) {
  print('Glucose: ${glucose?.glucoseMgdL} mg/dL');
  print('Glucose: ${glucose?.glucoseMmolL} mmol/L');
});

// Stop measurement
await veepooSdk.stopDetectBloodGlucose();
```

### Device Configuration

```dart
// Set user profile
final profile = UserProfile(
  heightCm: 175,
  weightKg: 70.0,
  age: 30,
  gender: Gender.male,
  targetSteps: 10000,
  targetSleepMinutes: 480,
);
await veepooSdk.setUserProfile(profile);

// Configure device settings
final settings = DeviceSettings(
  screenBrightness: 3,              // 0-5
  screenDurationSeconds: 10,
  is24HourFormat: true,
  language: DeviceLanguage.english,
  temperatureUnit: TemperatureUnit.celsius,
  distanceUnit: DistanceUnit.metric,
  wristRaiseToWake: true,
  wristRaiseSensitivity: 1,         // 0=low, 1=medium, 2=high
);
await veepooSdk.setDeviceSettings(settings);

// Individual settings
await veepooSdk.setScreenBrightness(3);
await veepooSdk.setTimeFormat(true); // 24-hour
await veepooSdk.setLanguage('en');

// Do Not Disturb (22:00 to 07:00)
await veepooSdk.setDoNotDisturb(true, 1320, 420); // minutes from midnight
```

### Device Information & Battery

```dart
// Get device info
final info = await veepooSdk.getDeviceInfo();
print('Model: ${info?.modelName}');
print('Hardware: ${info?.hardwareVersion}');
print('Software: ${info?.softwareVersion}');
print('Serial: ${info?.serialNumber}');

// Read battery level
final battery = await veepooSdk.readBattery();
print('Battery: ${battery?.percent}%');
print('State: ${battery?.state?.name}');
print('Charging: ${battery?.state == BatteryStates.charging}');
```

### Historical Data

```dart
final endDate = DateTime.now();
final startDate = endDate.subtract(Duration(days: 7));

// Heart rate history
final hrHistory = await veepooSdk.readHeartRateHistory(startDate, endDate);

// Step history
final stepHistory = await veepooSdk.readStepHistory(startDate, endDate);

// Sleep history
final sleepHistory = await veepooSdk.readSleepHistory(startDate, endDate);

// Blood pressure history
final bpHistory = await veepooSdk.readBloodPressureHistory(startDate, endDate);

// Temperature history
final tempHistory = await veepooSdk.readTemperatureHistory(startDate, endDate);
```

## Data Models

The SDK provides comprehensive data models for all health metrics:

- **BluetoothDevice**: Device information during scanning
- **HeartRate**: Real-time heart rate data and status
- **Spoh**: Blood oxygen (SpO2) measurements
- **BloodPressure**: Systolic/diastolic pressure readings
- **Temperature**: Body and wrist temperature
- **BloodGlucose**: Glucose levels in mg/dL and mmol/L
- **EcgData**: ECG waveform and diagnostic results
- **StepData**: Steps, distance, calories, activity
- **SleepData**: Sleep duration, quality, and stages
- **Battery**: Battery level and charging status
- **DeviceInfo**: Device model, version, serial number
- **UserProfile**: User health information
- **DeviceSettings**: All configurable device settings

See the [example app](example/lib/main.dart) for complete usage demonstrations.

## Example Application

The package includes a comprehensive example application with 7 tabs demonstrating all features:

1. **Connection**: Device scanning, pairing, and management
2. **Heart & SpO2**: Real-time heart rate and oxygen monitoring
3. **BP & Temp**: Blood pressure and temperature tracking
4. **Steps & Sleep**: Activity and sleep analysis
5. **ECG & Glucose**: Advanced health monitoring
6. **Settings**: User profile and device configuration
7. **History**: Historical data retrieval and visualization

Run the example:
```bash
cd example
flutter run
```

## Error Handling

All methods throw `VeepooException` on errors:

```dart
try {
  await veepooSdk.connectDevice(address);
} on VeepooException catch (e) {
  print('Error: ${e.message}');
  print('Details: ${e.details}');
}
```

## Implementation Status

### ✅ Complete Features (Working Now)
- Bluetooth scanning and connection
- Device binding and authentication
- Heart rate monitoring
- Blood oxygen (SpO2) monitoring
- Battery level reading
- Connection status tracking

### 🔄 API Ready (Android Native Implementation Needed)
- Blood pressure monitoring
- Temperature tracking
- Blood glucose monitoring
- ECG measurements
- Step counting
- Sleep analysis
- Device settings configuration
- Historical data retrieval

See [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md) for detailed implementation guide.

## Requirements

- Flutter SDK: >=3.0.0
- Dart SDK: >=3.0.0
- Android: minSdkVersion 21 (Android 5.0+)
- iOS: Not supported yet

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [Veepoo SDK Documentation](https://github.com/HBandSDK/Android_Ble_SDK/wiki/VeepooSDK-Android-API-Document)
- [Example App](example/)
- [Implementation Notes](IMPLEMENTATION_NOTES.md)
- [Issue Tracker](https://github.com/faramahamcto/flutter_veepoo_sdk_plus/issues)

## Support

If you encounter any issues or have questions:
1. Check the [example app](example/) for usage patterns
2. Review [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md) for technical details
3. Open an issue on GitHub with detailed information

## Acknowledgments

Based on the Veepoo Android SDK by HBandSDK. Flutter implementation by the Flutter Veepoo SDK Plus team.
