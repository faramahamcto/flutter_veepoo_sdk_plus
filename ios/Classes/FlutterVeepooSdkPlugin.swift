import Flutter
import UIKit
import VeepooBleSDK

/// iOS side of the plugin. Mirrors the Android `VPMethodChannelHandler`: same channel names,
/// method names, argument keys and result/event map shapes, so the Dart layer is unchanged.
/// See docs/iOS-Android-API-Mapping.md for how each call maps onto the Veepoo iOS SDK.
public class FlutterVeepooSdkPlugin: NSObject, FlutterPlugin {
  private static let channelName = "site.shasmatic.flutter_veepoo_sdk"

  let scanEvents = EventStream()
  let heartEvents = EventStream()
  let spohEvents = EventStream()
  let temperatureEvents = EventStream()
  let ecgEvents = EventStream()
  let bloodPressureEvents = EventStream()
  let bloodGlucoseEvents = EventStream()
  let bloodComponentEvents = EventStream()
  let stepDataEvents = EventStream()
  let originProgressEvents = EventStream()
  let connectionEvents = EventStream()
  let bodyComponentEvents = EventStream()
  let miniCheckupEvents = EventStream()
  let watchFaceProgressEvents = EventStream()

  private lazy var bluetooth = VPBluetooth(scanEvents: scanEvents, connectionEvents: connectionEvents)
  private lazy var detection = VPDetection(
    heart: heartEvents, spoh: spohEvents, temperature: temperatureEvents, ecg: ecgEvents,
    bloodPressure: bloodPressureEvents, bloodGlucose: bloodGlucoseEvents,
    bloodComponent: bloodComponentEvents, bodyComponent: bodyComponentEvents,
    miniCheckup: miniCheckupEvents)
  private lazy var data = VPDataReader(progressEvents: originProgressEvents)
  private lazy var watchFace = VPWatchFace(progressEvents: watchFaceProgressEvents)

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FlutterVeepooSdkPlugin()
    let messenger = registrar.messenger()
    let channel = FlutterMethodChannel(name: "\(channelName)/command", binaryMessenger: messenger)
    registrar.addMethodCallDelegate(instance, channel: channel)

    let streams: [(String, EventStream)] = [
      ("scan_bluetooth_event_channel", instance.scanEvents),
      ("detect_heart_event_channel", instance.heartEvents),
      ("detect_spoh_event_channel", instance.spohEvents),
      ("detect_temperature_event_channel", instance.temperatureEvents),
      ("detect_ecg_event_channel", instance.ecgEvents),
      ("detect_blood_pressure_event_channel", instance.bloodPressureEvents),
      ("detect_blood_glucose_event_channel", instance.bloodGlucoseEvents),
      ("detect_blood_component_event_channel", instance.bloodComponentEvents),
      ("step_data_event_channel", instance.stepDataEvents),
      ("origin_data_progress_event_channel", instance.originProgressEvents),
      ("connection_status_event_channel", instance.connectionEvents),
      ("detect_body_component_event_channel", instance.bodyComponentEvents),
      ("mini_checkup_event_channel", instance.miniCheckupEvents),
      ("watch_face_progress_event_channel", instance.watchFaceProgressEvents),
    ]
    for (name, stream) in streams {
      FlutterEventChannel(name: "\(channelName)/\(name)", binaryMessenger: messenger).setStreamHandler(stream)
    }
    _ = instance.bluetooth // subscribes to connection-state changes; doesn't touch the SDK yet
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let reply = Reply(result)

    switch call.method {
    // Bluetooth / connection
    case "requestBluetoothPermissions": bluetooth.requestPermissions(reply)
    case "openAppSettings", "openBluetooth": openSettings(reply) // iOS apps can't switch Bluetooth on
    case "closeBluetooth": reply(nil)
    case "isBluetoothEnabled": bluetooth.isBluetoothEnabled(reply)
    case "scanDevices": bluetooth.scan(reply)
    case "stopScanDevices": bluetooth.stopScan(reply)
    case "connectDevice":
      guard let address = args["address"] as? String else {
        return reply.error("INVALID_ARGUMENT", "MAC address is required")
      }
      bluetooth.connect(address: address, reply)
    case "bindDevice":
      guard let password = args["password"] as? String, let is24H = args["is24H"] as? Bool else {
        return reply.error("INVALID_ARGUMENT", "Password and 24-hour mode are required")
      }
      bluetooth.bind(password: password, is24H: is24H, reply)
    case "disconnectDevice": bluetooth.disconnect(reply)
    case "getAddress", "getCurrentDeviceAddress": reply(VPSdk.connectedAddress)
    case "getCurrentStatus": reply(VPSdk.connectedAddress == nil ? 0 : 2) // DeviceConnectionState.fromCode
    case "isDeviceConnected": bluetooth.isDeviceConnected(address: args["address"] as? String, reply)
    case "isDeviceBinded": reply(VPDeviceStorage.password != nil)

    // Live measurements
    case "startDetectHeart": detection.heart(start: true, reply)
    case "stopDetectHeart": detection.heart(start: false, reply)
    case "settingHeartWarning":
      guard let high = args["high"] as? Int, let low = args["low"] as? Int, let open = args["open"] as? Bool else {
        return reply.error("INVALID_ARGUMENT", "High, low, and open values are required")
      }
      detection.heartWarning(high: high, low: low, mode: open ? 1 : 0, reply)
    case "readHeartWarning": detection.heartWarning(high: 0, low: 0, mode: 2, reply)
    case "startDetectSpoh": detection.spoh(start: true, reply)
    case "stopDetectSpoh": detection.spoh(start: false, reply)
    case "startDetectTemperature": detection.temperature(start: true, reply)
    case "stopDetectTemperature": detection.temperature(start: false, reply)
    case "startDetectEcg", "startDetectECG": detection.ecg(start: true, reply)
    case "stopDetectEcg", "stopDetectECG": detection.ecg(start: false, reply)
    case "startDetectBloodPressure": detection.bloodPressure(start: true, reply)
    case "stopDetectBloodPressure": detection.bloodPressure(start: false, reply)
    case "startDetectBloodGlucose": detection.bloodGlucose(start: true, reply)
    case "stopDetectBloodGlucose": detection.bloodGlucose(start: false, reply)
    case "startDetectBloodComponent":
      detection.bloodComponent(start: true, personal: args["needCalibration"] as? Bool ?? false, reply)
    case "stopDetectBloodComponent": detection.bloodComponent(start: false, personal: false, reply)
    case "startDetectBodyComponent": detection.bodyComponent(start: true, reply)
    case "stopDetectBodyComponent": detection.bodyComponent(start: false, reply)
    case "startMiniCheckup": detection.miniCheckup(start: true, reply)
    case "stopMiniCheckup": detection.miniCheckup(start: false, reply)

    // Device data
    case "readBattery": data.readBattery(reply)
    case "getDeviceInfo": data.deviceInfo(reply)
    case "setUserProfile": data.setUserProfile(args, reply)
    case "readSleepData": data.readSleep(reply)
    case "readStepData": data.readSteps(date: Date(), reply)
    case "readStepDataForDate":
      guard let ts = args["timestamp"] as? Int else { return reply.error("INVALID_ARGUMENT", "Timestamp is required") }
      data.readSteps(date: Date(timeIntervalSince1970: Double(ts) / 1000), reply)
    case "readHRVData": data.readHRV(days: args["days"] as? Int ?? 7, startDay: args["startDay"] as? Int ?? 0, reply)
    case "readBodyComponentId": data.readBodyComponentIds(reply)
    case "readBodyComponentData": data.readBodyComponents(ids: args["ids"] as? [Int], reply)
    case "readOriginData3Days": data.readOrigin(days: [0, 1, 2], single: false, reply)
    case "readOriginDataForDay": data.readOrigin(days: [args["day"] as? Int ?? 0], single: true, reply)
    case "readAutoMeasureSettings": data.readAutoMeasureSettings(reply)
    case "enableAllAutoMeasurements": data.enableAllAutoMeasurements(reply)
    case "setAutoMeasureSetting":
      guard let type = args["type"] as? Int, let enabled = args["enabled"] as? Bool else {
        return reply.error("INVALID_ARGUMENT", "type and enabled are required")
      }
      data.setAutoMeasureSetting(type: type, enabled: enabled, interval: args["measureInterval"] as? Int,
                                 startMinute: args["startMinute"] as? Int, endMinute: args["endMinute"] as? Int, reply)

    // Photo watch face
    case "readCustomWatchFace": watchFace.read(reply)
    case "setCustomWatchFace": watchFace.set(args, reply)
    case "readMarketWatchFaces": watchFace.readMarket(reply)
    case "installMarketWatchFace": watchFace.installMarket(args["fileUrl"] as? String, reply)
    default: reply(FlutterMethodNotImplemented)
    }
  }

  private func openSettings(_ reply: Reply) {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
    reply(nil)
  }
}

// MARK: - Shared helpers

/// Lazily configures and returns the vendor SDK singleton. Touching it creates a CBCentralManager,
/// which shows the iOS Bluetooth permission prompt, so nothing calls this at plugin registration.
enum VPSdk {
  private static var configured = false
  static var onConnectState: ((Int) -> Void)?

  static var ble: VPBleCentralManage {
    let manager: VPBleCentralManage = VPBleCentralManage.sharedBleManager()
    if !configured {
      configured = true
      // SDK persistence mode: synced data lands in the SDK's database and is queried by date + MAC.
      manager.peripheralManage = VPPeripheralManage.shareVPPeripheralManager()
      manager.vpBleConnectStateChangeBlock = { state in onConnectState?(state.rawValue) }
    }
    return manager
  }

  static var manage: VPPeripheralBaseManage { ble.peripheralManage }

  /// MAC of the connected watch, or nil. Also the `tableID` for every VPDataBaseOperation query.
  static var connectedAddress: String? {
    guard configured, ble.isConnected, let address = ble.peripheralModel?.deviceAddress, !address.isEmpty else {
      return nil
    }
    return address
  }
}

/// Saved binding credentials (Android: DeviceStorage shared preferences).
enum VPDeviceStorage {
  private static let passwordKey = "flutter_veepoo_sdk.password"
  private static let is24HKey = "flutter_veepoo_sdk.is24H"

  static var password: String? { UserDefaults.standard.string(forKey: passwordKey) }

  static func save(password: String, is24H: Bool) {
    UserDefaults.standard.set(password, forKey: passwordKey)
    UserDefaults.standard.set(is24H, forKey: is24HKey)
  }
}

/// Answers a FlutterResult at most once, always on the main thread. SDK callbacks can fire
/// repeatedly and timeouts race with them; later answers are dropped.
final class Reply {
  private var result: FlutterResult?

  init(_ result: @escaping FlutterResult) { self.result = result }

  var isDone: Bool { result == nil }

  func callAsFunction(_ value: Any?) {
    onMain {
      guard let result = self.result else { return }
      self.result = nil
      result(value)
    }
  }

  func error(_ code: String, _ message: String) {
    self(FlutterError(code: code, message: message, details: nil))
  }

  func timeout(after seconds: Double, code: String, _ message: String) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { self.error(code, message) }
  }
}

final class EventStream: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func send(_ event: Any) {
    onMain { self.sink?(event) }
  }
}

func onMain(_ block: @escaping () -> Void) {
  if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
}

var nowMillis: Int { Int(Date().timeIntervalSince1970 * 1000) }

/// Event/result map with nil values sent as Dart null.
func payload(_ map: [String: Any?]) -> [String: Any] { map.mapValues { $0 ?? NSNull() } }

/// The SDK database returns numbers as NSNumber or as strings ("71", "5.60") depending on the table.
func num(_ value: Any?) -> Double? {
  switch value {
  case let n as NSNumber: return n.doubleValue
  case let s as String: return Double(s.trimmingCharacters(in: .whitespaces))
  default: return nil
  }
}

func int(_ value: Any?) -> Int? { num(value).map { Int($0) } }

/// Positive reading or nil. 255 is the vendor's "no reading" sentinel for byte-sized channels.
func reading(_ value: Any?) -> Int? {
  guard let v = int(value), v > 0, v < 255 else { return nil }
  return v
}

func positive(_ value: Any?) -> Double? {
  guard let v = num(value), v > 0 else { return nil }
  return v
}

func intList(_ value: Any?) -> [Int]? {
  guard let array = value as? [Any] else { return nil }
  return array.compactMap { int($0) }
}

/// First valid reading of a per-minute array (ppgs, ecgs, bloodGlucoses, ...).
func firstReading(_ value: Any?) -> Int? {
  (value as? [Any])?.lazy.compactMap { reading($0) }.first
}

func firstPositive(_ value: Any?) -> Double? {
  (value as? [Any])?.lazy.compactMap { positive($0) }.first
}
