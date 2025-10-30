import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_veepoo_sdk/flutter_veepoo_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veepoo SDK Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const VeepooSDKDemo(),
    );
  }
}

class VeepooSDKDemo extends StatefulWidget {
  const VeepooSDKDemo({super.key});

  @override
  State<VeepooSDKDemo> createState() => _VeepooSDKDemoState();
}

class _VeepooSDKDemoState extends State<VeepooSDKDemo>
    with SingleTickerProviderStateMixin {
  final _veepooSdk = VeepooSDK.instance;
  final List<BluetoothDevice> _bluetoothDevices = [];
  late TabController _tabController;
  String? _connectedDeviceAddress;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _requestPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==================== Bluetooth & Connection ====================

  Future<void> _requestPermissions() async {
    try {
      final status = await _veepooSdk.requestBluetoothPermissions();
      if (status == PermissionStatuses.permanentlyDenied) {
        await _veepooSdk.openAppSettings();
      }
    } catch (e) {
      _showError('Failed to request permissions: $e');
    }
  }

  Future<void> _scanDevices() async {
    try {
      _bluetoothDevices.clear();
      setState(() {});
      await _veepooSdk.scanDevices();
    } catch (e) {
      _showError('Failed to scan devices: $e');
    }
  }

  Future<void> _connectDevice(String address) async {
    try {
      await _veepooSdk.connectDevice(address);
      _connectedDeviceAddress = address;
      _isConnected = true;
      setState(() {});
      _showSuccess('Connected to device');
    } catch (e) {
      _showError('Failed to connect: $e');
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      await _veepooSdk.disconnectDevice();
      _isConnected = false;
      _connectedDeviceAddress = null;
      setState(() {});
      _showSuccess('Disconnected from device');
    } catch (e) {
      _showError('Failed to disconnect: $e');
    }
  }

  Future<void> _bindDevice() async {
    try {
      final status = await _veepooSdk.bindDevice('0000', true);
      _showSuccess('Bind status: ${status?.name}');
    } catch (e) {
      _showError('Failed to bind device: $e');
    }
  }

  // ==================== Device Info & Battery ====================

  Future<void> _getDeviceInfo() async {
    try {
      final info = await _veepooSdk.getDeviceInfo();
      _showInfo('Device Info', '''
Model: ${info?.modelName ?? 'Unknown'}
Hardware: ${info?.hardwareVersion ?? 'Unknown'}
Software: ${info?.softwareVersion ?? 'Unknown'}
Serial: ${info?.serialNumber ?? 'Unknown'}
MAC: ${info?.macAddress ?? 'Unknown'}
      ''');
    } catch (e) {
      _showError('Failed to get device info: $e');
    }
  }

  Future<void> _readBattery() async {
    try {
      final battery = await _veepooSdk.readBattery();
      _showInfo('Battery', '''
Level: ${battery?.level?.name ?? 'Unknown'}
Percent: ${battery?.percent ?? 0}%
State: ${battery?.state?.name ?? 'Unknown'}
Power Model: ${battery?.powerModel?.name ?? 'Unknown'}
      ''');
    } catch (e) {
      _showError('Failed to read battery: $e');
    }
  }

  // ==================== User Profile & Settings ====================

  Future<void> _setUserProfile() async {
    try {
      final profile = UserProfile(
        heightCm: 175,
        weightKg: 70.0,
        age: 30,
        gender: Gender.male,
        targetSteps: 10000,
        targetSleepMinutes: 480,
      );
      await _veepooSdk.setUserProfile(profile);
      _showSuccess('User profile set successfully');
    } catch (e) {
      _showError('Failed to set user profile: $e');
    }
  }

  Future<void> _setDeviceSettings() async {
    try {
      final settings = DeviceSettings(
        screenBrightness: 3,
        screenDurationSeconds: 10,
        is24HourFormat: true,
        language: DeviceLanguage.english,
        temperatureUnit: TemperatureUnit.celsius,
        distanceUnit: DistanceUnit.metric,
        wristRaiseToWake: true,
        wristRaiseSensitivity: 1,
      );
      await _veepooSdk.setDeviceSettings(settings);
      _showSuccess('Device settings updated');
    } catch (e) {
      _showError('Failed to set device settings: $e');
    }
  }

  // ==================== UI Helper Methods ====================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfo(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veepoo SDK Demo'),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.bluetooth_connected : Icons.bluetooth),
            onPressed: _isConnected ? _disconnectDevice : null,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Connect'),
            Tab(text: 'Heart & SpO2'),
            Tab(text: 'BP & Temp'),
            Tab(text: 'Steps & Sleep'),
            Tab(text: 'ECG & Glucose'),
            Tab(text: 'Settings'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConnectionTab(),
          _buildHeartSpO2Tab(),
          _buildBPTempTab(),
          _buildStepsSleepTab(),
          _buildECGGlucoseTab(),
          _buildSettingsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ==================== Connection Tab ====================

  Widget _buildConnectionTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_connectedDeviceAddress != null)
                Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Connected'),
                    subtitle: Text(_connectedDeviceAddress!),
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _scanDevices,
                    icon: const Icon(Icons.search),
                    label: const Text('Scan Devices'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isConnected ? _disconnectDevice : null,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isConnected ? _bindDevice : null,
                    icon: const Icon(Icons.link),
                    label: const Text('Bind Device'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _getDeviceInfo,
                    icon: const Icon(Icons.info),
                    label: const Text('Device Info'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _readBattery,
                    icon: const Icon(Icons.battery_full),
                    label: const Text('Battery'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Available Devices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<BluetoothDevice>?>(
            stream: _veepooSdk.bluetoothDevices,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                _bluetoothDevices.clear();
                _bluetoothDevices.addAll(snapshot.data!);
              }

              if (_bluetoothDevices.isEmpty) {
                return const Center(
                  child: Text('No devices found. Tap "Scan Devices" to start.'),
                );
              }

              return ListView.builder(
                itemCount: _bluetoothDevices.length,
                itemBuilder: (context, index) {
                  final device = _bluetoothDevices[index];
                  return ListTile(
                    leading: const Icon(Icons.watch),
                    title: Text(device.name ?? 'Unknown Device'),
                    subtitle: Text(device.address ?? 'Unknown Address'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${device.rssi ?? 0} dBm'),
                        Icon(
                          Icons.signal_cellular_alt,
                          size: 16,
                          color: (device.rssi ?? 0) > -70 ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                    onTap: () => _connectDevice(device.address ?? ''),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== Heart Rate & SpO2 Tab ====================

  Widget _buildHeartSpO2Tab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Heart Rate Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Heart Rate',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<HeartRate?>(
                    stream: _veepooSdk.heartRate,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final hr = snapshot.data!;
                        return Column(
                          children: [
                            Text(
                              '${hr.data ?? 0}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text('BPM'),
                            const SizedBox(height: 8),
                            Text('Status: ${hr.state?.name ?? "Unknown"}'),
                          ],
                        );
                      }
                      return const Text('No data');
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.startDetectHeart();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Start'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.stopDetectHeart();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Stop'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.settingHeartRate(120, 60, true);
                            _showSuccess('Heart rate alarm set');
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Set Alarm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // SpO2 Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Blood Oxygen (SpO2)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<Spoh?>(
                    stream: _veepooSdk.spoh,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final spoh = snapshot.data!;
                        return Column(
                          children: [
                            Text(
                              '${spoh.value ?? 0}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text('%'),
                            const SizedBox(height: 8),
                            if (spoh.checking == true)
                              LinearProgressIndicator(
                                value: (spoh.checkingProgress ?? 0) / 100,
                              ),
                            Text('Status: ${spoh.spohStatuses?.name ?? "Unknown"}'),
                          ],
                        );
                      }
                      return const Text('No data');
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.startDetectSpoh();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Start'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.stopDetectSpoh();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Blood Pressure & Temperature Tab ====================

  Widget _buildBPTempTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Blood Pressure Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Blood Pressure',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<BloodPressure?>(
                    stream: _veepooSdk.bloodPressure,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final bp = snapshot.data!;
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${bp.systolic ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(' / '),
                                Text(
                                  '${bp.diastolic ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Text('mmHg'),
                            if (bp.isMeasuring == true)
                              LinearProgressIndicator(
                                value: (bp.progress ?? 0) / 100,
                              ),
                            Text('Status: ${bp.state?.name ?? "Unknown"}'),
                          ],
                        );
                      }
                      return const Text('No data');
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.startDetectBloodPressure();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Start'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.stopDetectBloodPressure();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Stop'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.setBloodPressureAlarm(
                              140,
                              90,
                              90,
                              60,
                              true,
                            );
                            _showSuccess('Blood pressure alarm set');
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Set Alarm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Temperature Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Body Temperature',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<Temperature?>(
                    stream: _veepooSdk.temperature,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final temp = snapshot.data!;
                        return Column(
                          children: [
                            Text(
                              '${temp.temperatureCelsius?.toStringAsFixed(1) ?? 0}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Text('°C'),
                            const SizedBox(height: 8),
                            if (temp.isMeasuring == true)
                              LinearProgressIndicator(
                                value: (temp.progress ?? 0) / 100,
                              ),
                            Text('Status: ${temp.state?.name ?? "Unknown"}'),
                          ],
                        );
                      }
                      return const Text('No data');
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.startDetectTemperature();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Start'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.stopDetectTemperature();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Steps & Sleep Tab ====================

  Widget _buildStepsSleepTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Steps Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Steps',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<StepData?>(
                    stream: _veepooSdk.stepData,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final steps = snapshot.data!;
                        return Column(
                          children: [
                            Text(
                              '${steps.steps ?? 0}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text('steps'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    const Text('Distance'),
                                    Text(
                                      '${(steps.distanceMeters ?? 0) / 1000} km',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Calories'),
                                    Text(
                                      '${steps.calories ?? 0} kcal',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return const Text('No data');
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final data = await _veepooSdk.readStepData();
                        _showInfo('Steps Today', '''
Steps: ${data?.steps ?? 0}
Distance: ${(data?.distanceMeters ?? 0) / 1000} km
Calories: ${data?.calories ?? 0} kcal
Active: ${data?.activeMinutes ?? 0} minutes
                        ''');
                      } catch (e) {
                        _showError('$e');
                      }
                    },
                    child: const Text('Read Steps Data'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Sleep Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Sleep',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final data = await _veepooSdk.readSleepData();
                        if (data != null) {
                          _showInfo('Sleep Data', '''
Total Sleep: ${data.totalSleepMinutes ?? 0} minutes
Deep Sleep: ${data.deepSleepMinutes ?? 0} minutes
Light Sleep: ${data.lightSleepMinutes ?? 0} minutes
Awake: ${data.awakeMinutes ?? 0} minutes
Quality: ${data.sleepQuality ?? 0}%
                          ''');
                        } else {
                          _showError('No sleep data available');
                        }
                      } catch (e) {
                        _showError('$e');
                      }
                    },
                    child: const Text('Read Sleep Data'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ECG & Blood Glucose Tab ====================

  Widget _buildECGGlucoseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ECG Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'ECG (Electrocardiogram)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<EcgData?>(
                    stream: _veepooSdk.ecgData,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final ecg = snapshot.data!;
                        return Column(
                          children: [
                            Text(
                              'HR: ${ecg.heartRate ?? 0}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('BPM'),
                            const SizedBox(height: 8),
                            if (ecg.diagnosticResult != null)
                              Text('Result: ${ecg.diagnosticResult}'),
                            Text('Signal Quality: ${ecg.signalQuality ?? 0}%'),
                            if (ecg.isMeasuring == true)
                              LinearProgressIndicator(
                                value: (ecg.progress ?? 0) / 100,
                              ),
                          ],
                        );
                      }
                      return const Text('No data');
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.startDetectEcg();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Start'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.stopDetectEcg();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Blood Glucose Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Blood Glucose',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<BloodGlucose?>(
                    stream: _veepooSdk.bloodGlucose,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final glucose = snapshot.data!;
                        return Column(
                          children: [
                            Text(
                              '${glucose.glucoseMgdL?.toStringAsFixed(1) ?? 0}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            const Text('mg/dL'),
                            const SizedBox(height: 8),
                            Text('${glucose.glucoseMmolL?.toStringAsFixed(1) ?? 0} mmol/L'),
                            if (glucose.isMeasuring == true)
                              LinearProgressIndicator(
                                value: (glucose.progress ?? 0) / 100,
                              ),
                            Text('Status: ${glucose.state?.name ?? "Unknown"}'),
                          ],
                        );
                      }
                      return const Text('No data');
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.startDetectBloodGlucose();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Start'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.stopDetectBloodGlucose();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Stop'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.setBloodGlucoseCalibration(true);
                            _showSuccess('Calibration mode enabled');
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Calibration'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Settings Tab ====================

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'User Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _setUserProfile,
            child: const Text('Set User Profile (Example)'),
          ),
          const Divider(height: 30),
          const Text(
            'Device Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _setDeviceSettings,
            child: const Text('Apply Device Settings (Example)'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _veepooSdk.setScreenBrightness(3);
                    _showSuccess('Brightness set to 3');
                  } catch (e) {
                    _showError('$e');
                  }
                },
                child: const Text('Set Brightness (3)'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _veepooSdk.setScreenDuration(15);
                    _showSuccess('Screen duration set to 15s');
                  } catch (e) {
                    _showError('$e');
                  }
                },
                child: const Text('Screen Duration (15s)'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _veepooSdk.setTimeFormat(true);
                    _showSuccess('24-hour format enabled');
                  } catch (e) {
                    _showError('$e');
                  }
                },
                child: const Text('24-Hour Format'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _veepooSdk.setLanguage('en');
                    _showSuccess('Language set to English');
                  } catch (e) {
                    _showError('$e');
                  }
                },
                child: const Text('Set Language (EN)'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _veepooSdk.setWristRaiseToWake(true, 1);
                    _showSuccess('Wrist raise enabled');
                  } catch (e) {
                    _showError('$e');
                  }
                },
                child: const Text('Wrist Raise (Medium)'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // DND from 22:00 (1320 minutes) to 07:00 (420 minutes)
                    await _veepooSdk.setDoNotDisturb(true, 1320, 420);
                    _showSuccess('DND mode set (22:00-07:00)');
                  } catch (e) {
                    _showError('$e');
                  }
                },
                child: const Text('Do Not Disturb'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== History Tab ====================

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Historical Data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Read historical data from the last 7 days',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final endDate = DateTime.now();
                final startDate = endDate.subtract(const Duration(days: 7));
                final data =
                    await _veepooSdk.readHeartRateHistory(startDate, endDate);
                _showInfo(
                  'Heart Rate History',
                  'Found ${data.length} records from last 7 days',
                );
              } catch (e) {
                _showError('$e');
              }
            },
            icon: const Icon(Icons.favorite),
            label: const Text('Read Heart Rate History'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final endDate = DateTime.now();
                final startDate = endDate.subtract(const Duration(days: 7));
                final data = await _veepooSdk.readStepHistory(startDate, endDate);
                int totalSteps = 0;
                for (var step in data) {
                  totalSteps += step.steps ?? 0;
                }
                _showInfo(
                  'Step History',
                  'Total steps (7 days): $totalSteps\nRecords: ${data.length}',
                );
              } catch (e) {
                _showError('$e');
              }
            },
            icon: const Icon(Icons.directions_walk),
            label: const Text('Read Step History'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final endDate = DateTime.now();
                final startDate = endDate.subtract(const Duration(days: 7));
                final data = await _veepooSdk.readSleepHistory(startDate, endDate);
                int totalMinutes = 0;
                for (var sleep in data) {
                  totalMinutes += sleep.totalSleepMinutes ?? 0;
                }
                _showInfo(
                  'Sleep History',
                  'Total sleep (7 days): ${totalMinutes ~/ 60}h ${totalMinutes % 60}m\nRecords: ${data.length}',
                );
              } catch (e) {
                _showError('$e');
              }
            },
            icon: const Icon(Icons.bed),
            label: const Text('Read Sleep History'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final endDate = DateTime.now();
                final startDate = endDate.subtract(const Duration(days: 7));
                final data =
                    await _veepooSdk.readBloodPressureHistory(startDate, endDate);
                _showInfo(
                  'Blood Pressure History',
                  'Found ${data.length} records from last 7 days',
                );
              } catch (e) {
                _showError('$e');
              }
            },
            icon: const Icon(Icons.monitor_heart),
            label: const Text('Read Blood Pressure History'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final endDate = DateTime.now();
                final startDate = endDate.subtract(const Duration(days: 7));
                final data =
                    await _veepooSdk.readTemperatureHistory(startDate, endDate);
                _showInfo(
                  'Temperature History',
                  'Found ${data.length} records from last 7 days',
                );
              } catch (e) {
                _showError('$e');
              }
            },
            icon: const Icon(Icons.thermostat),
            label: const Text('Read Temperature History'),
          ),
        ],
      ),
    );
  }
}
