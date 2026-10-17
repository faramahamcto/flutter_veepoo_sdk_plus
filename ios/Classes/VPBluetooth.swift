import CoreBluetooth
import Flutter
import VeepooBleSDK

/// Permissions, scanning, connecting, binding and connection-state events
/// (Android: VPBluetoothManager).
final class VPBluetooth {
  private let scanEvents: EventStream
  private let connectionEvents: EventStream

  /// Every watch seen so far, by upper-cased MAC. The iOS SDK connects to a scanned model, not an address.
  private var models: [String: VPPeripheralModel] = [:]
  /// The current scan's results as sent to Dart.
  private var devices: [String: [String: Any]] = [:]
  private var isScanning = false
  private var scanGeneration = 0
  private var pendingConnect: (address: String, reply: Reply)?

  /// Outcome of the password check the SDK runs by itself after each connect (nil = not yet known).
  private var verified: Bool?
  private var verifyWaiters: [(Bool) -> Void] = []
  private var lastAddress: String?

  init(scanEvents: EventStream, connectionEvents: EventStream) {
    self.scanEvents = scanEvents
    self.connectionEvents = connectionEvents
    VPSdk.onConnectState = { [weak self] state in self?.connectionStateChanged(state) }
  }

  // MARK: Permission / adapter state

  func requestPermissions(_ reply: Reply) {
    guard #available(iOS 13.1, *) else {
      _ = VPSdk.ble
      return reply("GRANTED")
    }
    if CBManager.authorization == .notDetermined {
      _ = VPSdk.ble // creating the SDK's CBCentralManager shows the system prompt
    }
    waitForAuthorization(reply, attempts: 120)
  }

  @available(iOS 13.1, *)
  private func waitForAuthorization(_ reply: Reply, attempts: Int) {
    switch CBManager.authorization {
    case .allowedAlways: reply("GRANTED")
    case .denied: reply("PERMANENTLY_DENIED") // iOS never prompts twice; only Settings can change it
    case .restricted: reply("RESTRICTED")
    case .notDetermined:
      guard attempts > 0 else { return reply("DENIED") }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.waitForAuthorization(reply, attempts: attempts - 1)
      }
    @unknown default: reply("UNKNOWN")
    }
  }

  func isBluetoothEnabled(_ reply: Reply) {
    poweredOn { reply($0) }
  }

  /// CBCentralManager reports `.unknown` for a moment after it is created, so wait briefly for a real state.
  private func poweredOn(attempts: Int = 15, _ done: @escaping (Bool) -> Void) {
    let state = VPSdk.ble.centralManager?.state ?? .unknown
    if (state == .unknown || state == .resetting) && attempts > 0 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.poweredOn(attempts: attempts - 1, done) }
    } else {
      done(state == .poweredOn)
    }
  }

  private func whenPoweredOn(_ reply: Reply, _ action: @escaping () -> Void) {
    poweredOn { on in
      on ? action() : reply.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled")
    }
  }

  // MARK: Scan

  func scan(_ reply: Reply) {
    whenPoweredOn(reply) {
      self.startScan()
      reply(nil)
    }
  }

  func stopScan(_ reply: Reply) {
    if isScanning { finishScan() }
    reply(nil)
  }

  private func startScan() {
    scanGeneration += 1
    let generation = scanGeneration
    devices.removeAll()
    isScanning = true
    VPSdk.ble.veepooSDKStartScanDeviceAndReceiveScanningDevice { [weak self] model in
      guard let self = self, let model = model else { return }
      onMain { self.found(model) }
    }
    // Android stops scanning after SCAN_TIMEOUT_MS (60 s) too.
    DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
      guard let self = self, self.isScanning, self.scanGeneration == generation else { return }
      self.finishScan()
    }
  }

  private func finishScan() {
    VPSdk.ble.veepooSDKStopScanDevice()
    isScanning = false
    scanEvents.send(Array(devices.values))
    devices.removeAll()
  }

  private func found(_ model: VPPeripheralModel) {
    guard let address = model.deviceAddress, !address.isEmpty else { return }
    let key = address.uppercased()
    models[key] = model

    if let pending = pendingConnect, pending.address == key {
      pendingConnect = nil
      if !pending.reply.isDone { connect(model, pending.reply) }
      return
    }

    // Same de-duplication as Android: resend only for new devices or an RSSI change of more than 10.
    let rssi = model.rssi?.intValue ?? 0
    if let known = devices[key], abs((known["rssi"] as? Int ?? 0) - rssi) <= 10 { return }
    devices[key] = ["name": model.deviceName ?? "", "address": address, "rssi": rssi]
    scanEvents.send(Array(devices.values))
  }

  // MARK: Connect / bind

  func connect(address: String, _ reply: Reply) {
    whenPoweredOn(reply) {
      reply.timeout(after: 30, code: "OPERATION_TIMEOUT", "Operation timed out after 30000ms")
      let key = address.uppercased()
      if let model = self.models[key] {
        self.connect(model, reply)
      } else {
        // Not seen in this app session yet (e.g. reconnecting to the saved watch on launch): scan for it.
        self.pendingConnect = (key, reply)
        if !self.isScanning { self.startScan() }
      }
    }
  }

  private func connect(_ model: VPPeripheralModel, _ reply: Reply) {
    if isScanning { finishScan() }
    verified = nil
    VPSdk.ble.veepooSDKConnectDevice(model) { [weak self] state in
      // DeviceConnectState: 0 BLE off, 1 connecting, 2 connected, 3 failed, 4/5 password ok/failed,
      // 6 timeout, 7 not confirmed on the watch.
      switch state.rawValue {
      case 2: reply("Connected to device")
      case 4: onMain { self?.setVerified(true) }
      case 5: onMain { self?.setVerified(false) }
      case 0: reply.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled")
      case 3, 6, 7: reply.error("CONNECT_FAILED", "Failed to connect to device (state \(state.rawValue))")
      default: break
      }
    }
  }

  func bind(password: String, is24H: Bool, _ reply: Reply) {
    guard VPSdk.connectedAddress != nil else {
      return reply.error("NOT_CONNECTED", "Device is not connected")
    }
    VPSdk.ble.is24HourFormat = is24H
    reply.timeout(after: 15, code: "BIND_TIMEOUT", "Connection confirmation timed out")

    let finish: (String) -> Void = { status in
      if status == "CHECK_AND_TIME_SUCCESS" { VPDeviceStorage.save(password: password, is24H: is24H) }
      reply(status)
    }
    // The SDK sends the default password (and syncs the phone time) by itself right after connecting,
    // so reuse that outcome and only send the password ourselves when it failed (custom password).
    awaitAutoVerify { ok in
      if ok { return finish("CHECK_AND_TIME_SUCCESS") }
      VPSdk.ble.veepooSDKSynchronousPassword(with: .VerifyPasswordType, password: password) { result in
        finish(Self.bindStatus(result.rawValue))
      }
    }
  }

  /// PasswordSynchronTpye → the Android EPwdStatus names DeviceBindingStatus parses.
  private static func bindStatus(_ raw: Int) -> String {
    let names = ["CHECK_FAIL", "CHECK_SUCCESS", "SETTING_FAIL", "SETTING_SUCCESS",
                 "READ_FAIL", "READ_SUCCESS", "CHECK_AND_TIME_SUCCESS"]
    return names.indices.contains(raw) ? names[raw] : "UNKNOW"
  }

  private func awaitAutoVerify(_ done: @escaping (Bool) -> Void) {
    if let verified = verified { return done(verified) }
    verifyWaiters.append(done)
    DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in self?.flushVerifyWaiters(false) }
  }

  private func setVerified(_ ok: Bool) {
    verified = ok
    flushVerifyWaiters(ok)
  }

  private func flushVerifyWaiters(_ ok: Bool) {
    let waiters = verifyWaiters
    verifyWaiters.removeAll()
    waiters.forEach { $0(ok) }
  }

  func disconnect(_ reply: Reply) {
    VPSdk.ble.veepooSDKDisconnectDevice() // also stops the SDK's automatic reconnect
    verified = nil
    reply(nil)
  }

  func isDeviceConnected(address: String?, _ reply: Reply) {
    let current = VPSdk.connectedAddress
    if let address = address {
      reply(current?.caseInsensitiveCompare(address) == .orderedSame)
    } else {
      reply(current != nil)
    }
  }

  // MARK: Connection events

  /// VPDeviceConnectState: 0 disconnected, 1 connecting, 2 connected, 3/4 password ok/failed, ...
  private func connectionStateChanged(_ state: Int) {
    onMain {
      switch state {
      case 0:
        self.verified = nil
        self.flushVerifyWaiters(false)
        self.emit("disconnected")
      case 2:
        self.lastAddress = VPSdk.ble.peripheralModel?.deviceAddress
        self.emit("connected")
      case 3: self.setVerified(true)
      case 4: self.setVerified(false)
      default: break
      }
    }
  }

  private func emit(_ state: String) {
    connectionEvents.send(payload(["state": state, "address": lastAddress, "timestamp": nowMillis]))
  }
}
