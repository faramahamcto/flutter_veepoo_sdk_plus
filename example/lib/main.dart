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
    _tabController = TabController(length: 9, vsync: this);
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
            Tab(text: 'Blood Analysis'),
            Tab(text: 'Health Data'),
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
          _buildBloodAnalysisTab(),
          _buildHealthDataTab(),
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

  // ==================== Blood Analysis Tab ====================

  Widget _buildBloodAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Blood Components Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Blood Component Analysis',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<BloodComponent?>(
                    stream: _veepooSdk.bloodComponent,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final bc = snapshot.data!;
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('Uric Acid', style: TextStyle(fontSize: 12)),
                                    Text(
                                      '${bc.uricAcid?.toStringAsFixed(1) ?? 0}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Cholesterol', style: TextStyle(fontSize: 12)),
                                    Text(
                                      '${bc.totalCholesterol?.toStringAsFixed(1) ?? 0}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('HDL', style: TextStyle(fontSize: 12)),
                                    Text(
                                      '${bc.hdl?.toStringAsFixed(1) ?? 0}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('LDL', style: TextStyle(fontSize: 12)),
                                    Text(
                                      '${bc.ldl?.toStringAsFixed(1) ?? 0}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('Triglyceride', style: TextStyle(fontSize: 12)),
                                    Text(
                                      '${bc.triglyceride?.toStringAsFixed(1) ?? 0}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (bc.isMeasuring == true)
                              LinearProgressIndicator(
                                value: (bc.progress ?? 0) / 100,
                              ),
                            Text('Status: ${bc.state?.name ?? "Unknown"}'),
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
                            await _veepooSdk.startDetectBloodComponent();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Start'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.stopDetectBloodComponent();
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Stop'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _veepooSdk.startDetectBloodComponent(needCalibration: true);
                            _showInfo('Calibration', 'Blood component calibration started');
                          } catch (e) {
                            _showError('$e');
                          }
                        },
                        child: const Text('Calibrate'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // HRV Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Heart Rate Variability (HRV)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'HRV measures the variation in time between heartbeats and is an indicator of autonomic nervous system health.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final data = await _veepooSdk.readHRVData(days: 7);
                        if (data.isEmpty) {
                          _showError('No HRV data available');
                          return;
                        }

                        // Calculate average HRV
                        double totalHrv = 0;
                        int count = 0;
                        for (var hrv in data) {
                          if (hrv.hrvValue != null) {
                            totalHrv += hrv.hrvValue!;
                            count++;
                          }
                        }

                        final avgHrv = count > 0 ? totalHrv / count : 0;

                        _showInfo('HRV Data (Last 7 Days)', '''
Records: ${data.length}
Average HRV: ${avgHrv.toStringAsFixed(1)}
Latest HRV: ${data.last.hrvValue ?? 'N/A'}
Latest HR: ${data.last.heartRate ?? 'N/A'} BPM
Date: ${data.last.date ?? 'Unknown'}
                        ''');
                      } catch (e) {
                        _showError('$e');
                      }
                    },
                    child: const Text('Read HRV History (7 Days)'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final data = await _veepooSdk.readHRVData(days: 1);
                        if (data.isEmpty) {
                          _showError('No HRV data available for today');
                          return;
                        }

                        _showInfo('Today\'s HRV', '''
Records: ${data.length}
HRV Value: ${data.last.hrvValue ?? 'N/A'}
Heart Rate: ${data.last.heartRate ?? 'N/A'} BPM
Type: ${data.last.hrvType ?? 'N/A'}
                        ''');
                      } catch (e) {
                        _showError('$e');
                      }
                    },
                    child: const Text('Read Today\'s HRV'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Health Data Tab ====================

  Widget _buildHealthDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Health Data (3 Days)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Read detailed health data including heart rate, blood pressure, temperature, blood oxygen, steps, and more.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select a day:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDayButton('Today', 0)),
              const SizedBox(width: 8),
              Expanded(child: _buildDayButton('Yesterday', 1)),
              const SizedBox(width: 8),
              Expanded(child: _buildDayButton('2 Days Ago', 2)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _loadHealthData3Days(),
            icon: const Icon(Icons.calendar_view_day),
            label: const Text('View All 3 Days Summary'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Available Health Metrics:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _buildHealthMetricInfo('Heart Rate', 'Average, max, min BPM'),
          _buildHealthMetricInfo('Blood Pressure', 'Systolic/Diastolic mmHg'),
          _buildHealthMetricInfo('Blood Oxygen', 'SpO2 percentage'),
          _buildHealthMetricInfo('Body Temperature', 'Celsius degrees'),
          _buildHealthMetricInfo('Steps & Activity', 'Steps, calories, distance'),
          _buildHealthMetricInfo('Blood Glucose', 'Glucose levels'),
          _buildHealthMetricInfo('Respiration Rate', 'Breaths per minute'),
        ],
      ),
    );
  }

  Widget _buildHealthMetricInfo(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        leading: Icon(_getMetricIcon(title), color: _getMetricColor(title)),
      ),
    );
  }

  IconData _getMetricIcon(String metric) {
    switch (metric) {
      case 'Heart Rate': return Icons.favorite;
      case 'Blood Pressure': return Icons.monitor_heart;
      case 'Blood Oxygen': return Icons.water_drop;
      case 'Body Temperature': return Icons.thermostat;
      case 'Steps & Activity': return Icons.directions_walk;
      case 'Blood Glucose': return Icons.bloodtype;
      case 'Respiration Rate': return Icons.air;
      default: return Icons.health_and_safety;
    }
  }

  Color _getMetricColor(String metric) {
    switch (metric) {
      case 'Heart Rate': return Colors.red;
      case 'Blood Pressure': return Colors.purple;
      case 'Blood Oxygen': return Colors.blue;
      case 'Body Temperature': return Colors.orange;
      case 'Steps & Activity': return Colors.green;
      case 'Blood Glucose': return Colors.pink;
      case 'Respiration Rate': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Widget _buildDayButton(String label, int day) {
    return ElevatedButton(
      onPressed: () => _loadHealthDataForDay(day, label),
      child: Text(label, textAlign: TextAlign.center),
    );
  }

  Future<void> _loadHealthDataForDay(int day, String label) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Reading health data for $label...'),
            const SizedBox(height: 8),
            const Text('This may take up to 60 seconds', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      final data = await _veepooSdk.readOriginDataForDay(day);
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      if (data == null) {
        _showError('No health data available for $label');
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DailyHealthDataPage(data: data),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showError('$e');
    }
  }

  Future<void> _loadHealthData3Days() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Reading health data for 3 days...'),
            SizedBox(height: 8),
            Text('This may take up to 90 seconds', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      final data = await _veepooSdk.readOriginData3Days();
      if (!mounted) return;
      Navigator.of(context).pop();
      if (data.isEmpty) {
        _showError('No health data available for the last 3 days');
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HealthDataSummaryPage(data: data),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showError('$e');
    }
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

// ==================== Health Data Summary Page ====================

class HealthDataSummaryPage extends StatelessWidget {
  final List<DailyHealthData> data;

  const HealthDataSummaryPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Data Summary')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final day = data[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DailyHealthDataPage(data: day)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(day.dayLabel ?? 'Unknown',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(day.date ?? '', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Divider(),
                    _buildCategoryRow('Heart Rate', '${day.avgHeartRate ?? '-'} BPM avg', Colors.red, Icons.favorite),
                    _buildCategoryRow('Blood Pressure', '${day.avgSystolic ?? '-'}/${day.avgDiastolic ?? '-'} mmHg', Colors.purple, Icons.monitor_heart),
                    _buildCategoryRow('Blood Oxygen', '${day.avgBloodOxygen ?? '-'}%', Colors.blue, Icons.water_drop),
                    _buildCategoryRow('Temperature', '${day.avgTemperature?.toStringAsFixed(1) ?? '-'}°C', Colors.orange, Icons.thermostat),
                    _buildCategoryRow('Steps', '${day.totalSteps ?? 0}', Colors.green, Icons.directions_walk),
                    _buildCategoryRow('Calories', '${day.totalCalories?.toStringAsFixed(0) ?? 0} kcal', Colors.deepOrange, Icons.local_fire_department),
                    if (day.avgBloodGlucose != null)
                      _buildCategoryRow('Blood Glucose', '${day.avgBloodGlucose} mg/dL', Colors.pink, Icons.bloodtype),
                    if (day.avgRespirationRate != null)
                      _buildCategoryRow('Respiration', '${day.avgRespirationRate} /min', Colors.teal, Icons.air),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Tap to view hourly details',
                            style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
                        Icon(Icons.chevron_right, color: Theme.of(context).primaryColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryRow(String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

// ==================== Daily Health Data Page ====================

class DailyHealthDataPage extends StatelessWidget {
  final DailyHealthData data;

  const DailyHealthDataPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(data.dayLabel ?? 'Health Data'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(data.date ?? '', style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Health Categories
          _buildCategoryCard('Heart Rate', Icons.favorite, Colors.red, [
            _DataItem('Average', '${data.avgHeartRate ?? '-'} BPM'),
            _DataItem('Maximum', '${data.maxHeartRate ?? '-'} BPM'),
            _DataItem('Minimum', '${data.minHeartRate ?? '-'} BPM'),
          ]),
          _buildCategoryCard('Blood Pressure', Icons.monitor_heart, Colors.purple, [
            _DataItem('Average Systolic', '${data.avgSystolic ?? '-'} mmHg'),
            _DataItem('Average Diastolic', '${data.avgDiastolic ?? '-'} mmHg'),
          ]),
          _buildCategoryCard('Blood Oxygen', Icons.water_drop, Colors.blue, [
            _DataItem('Average SpO2', '${data.avgBloodOxygen ?? '-'}%'),
            _DataItem('Minimum SpO2', '${data.minBloodOxygen ?? '-'}%'),
          ]),
          _buildCategoryCard('Body Temperature', Icons.thermostat, Colors.orange, [
            _DataItem('Average', '${data.avgTemperature?.toStringAsFixed(1) ?? '-'}°C'),
            _DataItem('Maximum', '${data.maxTemperature?.toStringAsFixed(1) ?? '-'}°C'),
            _DataItem('Minimum', '${data.minTemperature?.toStringAsFixed(1) ?? '-'}°C'),
          ]),
          _buildCategoryCard('Activity', Icons.directions_walk, Colors.green, [
            _DataItem('Total Steps', '${data.totalSteps ?? 0}'),
            _DataItem('Calories Burned', '${data.totalCalories?.toStringAsFixed(0) ?? 0} kcal'),
            _DataItem('Distance', '${data.totalDistance?.toStringAsFixed(2) ?? 0} km'),
          ]),
          if (data.avgBloodGlucose != null)
            _buildCategoryCard('Blood Glucose', Icons.bloodtype, Colors.pink, [
              _DataItem('Average', '${data.avgBloodGlucose} mg/dL'),
            ]),
          if (data.avgRespirationRate != null)
            _buildCategoryCard('Respiration Rate', Icons.air, Colors.teal, [
              _DataItem('Average', '${data.avgRespirationRate} breaths/min'),
            ]),
          const SizedBox(height: 16),
          const Text('Hourly Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (data.hourlyData == null || data.hourlyData!.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No hourly data available')))
          else
            ...data.hourlyData!.map((hour) => _buildHourlyCard(context, hour)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, List<_DataItem> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.label, style: const TextStyle(color: Colors.grey)),
                  Text(item.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyCard(BuildContext context, HourlyHealthData hour) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(hour.hourLabel?.substring(0, 2) ?? '')),
        title: Text(hour.hourLabel ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Wrap(
          spacing: 12,
          children: [
            if (hour.avgHeartRate != null) Text('HR: ${hour.avgHeartRate}', style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
            if (hour.avgSystolic != null) Text('BP: ${hour.avgSystolic}/${hour.avgDiastolic}', style: TextStyle(color: Colors.purple.shade400, fontSize: 12)),
            if (hour.avgBloodOxygen != null) Text('O2: ${hour.avgBloodOxygen}%', style: TextStyle(color: Colors.blue.shade400, fontSize: 12)),
            if (hour.steps != null && hour.steps! > 0) Text('Steps: ${hour.steps}', style: TextStyle(color: Colors.green.shade400, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HourlyHealthDataPage(data: hour, date: data.date ?? '')),
        ),
      ),
    );
  }
}

class _DataItem {
  final String label;
  final String value;
  _DataItem(this.label, this.value);
}

// ==================== Hourly Health Data Page ====================

class HourlyHealthDataPage extends StatelessWidget {
  final HourlyHealthData data;
  final String date;

  const HourlyHealthDataPage({super.key, required this.data, required this.date});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${data.hourLabel ?? 'Unknown'} - $date'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hour Header
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 32, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.hourLabel ?? 'Unknown Hour',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(date, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Hourly Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Category Cards for Hourly Data
          _buildCategoryCard('Heart Rate', Icons.favorite, Colors.red, [
            _HourlyDataItem('Average', '${data.avgHeartRate ?? '-'} BPM'),
            _HourlyDataItem('Maximum', '${data.maxHeartRate ?? '-'} BPM'),
            _HourlyDataItem('Minimum', '${data.minHeartRate ?? '-'} BPM'),
          ]),
          _buildCategoryCard('Blood Pressure', Icons.monitor_heart, Colors.purple, [
            _HourlyDataItem('Systolic', '${data.avgSystolic ?? '-'} mmHg'),
            _HourlyDataItem('Diastolic', '${data.avgDiastolic ?? '-'} mmHg'),
          ]),
          _buildCategoryCard('Blood Oxygen', Icons.water_drop, Colors.blue, [
            _HourlyDataItem('Average SpO2', '${data.avgBloodOxygen ?? '-'}%'),
          ]),
          _buildCategoryCard('Body Temperature', Icons.thermostat, Colors.orange, [
            _HourlyDataItem('Average', '${data.avgTemperature?.toStringAsFixed(1) ?? '-'}°C'),
          ]),
          _buildCategoryCard('Activity', Icons.directions_walk, Colors.green, [
            _HourlyDataItem('Steps', '${data.steps ?? 0}'),
            _HourlyDataItem('Calories', '${data.calories?.toStringAsFixed(1) ?? 0} kcal'),
            _HourlyDataItem('Distance', '${data.distance?.toStringAsFixed(2) ?? 0} km'),
            _HourlyDataItem('Sport Value', '${data.avgSportValue ?? '-'}'),
          ]),
          if (data.avgBloodGlucose != null)
            _buildCategoryCard('Blood Glucose', Icons.bloodtype, Colors.pink, [
              _HourlyDataItem('Average', '${data.avgBloodGlucose} mg/dL'),
            ]),
          if (data.avgRespirationRate != null)
            _buildCategoryCard('Respiration Rate', Icons.air, Colors.teal, [
              _HourlyDataItem('Average', '${data.avgRespirationRate} breaths/min'),
            ]),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('5-Minute Interval Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (data.records != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${data.records!.length} records', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 5-Minute Interval Data List
          if (data.records == null || data.records!.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No detailed records available')))
          else
            ...data.records!.map((record) => _buildRecordCard(record)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, List<_HourlyDataItem> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.label, style: const TextStyle(color: Colors.grey)),
                  Text(item.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(OriginHealthData record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  record.time ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Health data with text labels in grid format
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                if (record.heartRate != null)
                  _buildRecordItem('Heart Rate', '${record.heartRate} BPM', Icons.favorite, Colors.red),
                if (record.systolic != null && record.diastolic != null)
                  _buildRecordItem('Blood Pressure', '${record.systolic}/${record.diastolic} mmHg', Icons.monitor_heart, Colors.purple),
                if (record.bloodOxygen != null)
                  _buildRecordItem('Blood Oxygen', '${record.bloodOxygen}%', Icons.water_drop, Colors.blue),
                if (record.temperature != null)
                  _buildRecordItem('Temperature', '${record.temperature?.toStringAsFixed(1)}°C', Icons.thermostat, Colors.orange),
                if (record.steps != null && record.steps! > 0)
                  _buildRecordItem('Steps', '${record.steps}', Icons.directions_walk, Colors.green),
                if (record.calories != null && record.calories! > 0)
                  _buildRecordItem('Calories', '${record.calories?.toStringAsFixed(1)} kcal', Icons.local_fire_department, Colors.deepOrange),
                if (record.distance != null && record.distance! > 0)
                  _buildRecordItem('Distance', '${record.distance?.toStringAsFixed(2)} km', Icons.straighten, Colors.teal),
                if (record.sportValue != null && record.sportValue! > 0)
                  _buildRecordItem('Sport Value', '${record.sportValue}', Icons.fitness_center, Colors.indigo),
                if (record.bloodGlucose != null)
                  _buildRecordItem('Blood Glucose', '${record.bloodGlucose} mg/dL', Icons.bloodtype, Colors.pink),
                if (record.respirationRate != null)
                  _buildRecordItem('Respiration', '${record.respirationRate} /min', Icons.air, Colors.cyan),
                if (record.ecgHeartRate != null)
                  _buildRecordItem('ECG Heart Rate', '${record.ecgHeartRate} BPM', Icons.monitor_heart_outlined, Colors.red.shade300),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}

class _HourlyDataItem {
  final String label;
  final String value;
  _HourlyDataItem(this.label, this.value);
}
