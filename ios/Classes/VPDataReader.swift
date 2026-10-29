import Flutter
import VeepooBleSDK

/// Stored-data reads, device settings and info (Android: OriginDataReader, SleepDataReader,
/// StepDataReader, HRVDataReader, BodyComponentReader, AutoMeasure, Battery, setUserProfile).
///
/// Android asks the watch for one day at a time. The iOS SDK instead copies everything the watch
/// stores into its own database (`veepooSdkStartReadDeviceAllData`), which is then queried by
/// date + MAC through VPDataBaseOperation.
final class VPDataReader {
  private let progressEvents: EventStream
  private var lastSync: Date?
  private var syncWaiters: [(Bool) -> Void] = []
  private var syncGeneration = 0

  init(progressEvents: EventStream) {
    self.progressEvents = progressEvents
  }

  private static let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian) // the phone may use the Persian calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  private func dateString(daysAgo: Int) -> String {
    let date = Calendar(identifier: .gregorian).date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    return Self.dayFormatter.string(from: date)
  }

  private func connectedMac(_ reply: Reply) -> String? {
    guard let mac = VPSdk.connectedAddress else {
      reply.error("NOT_CONNECTED", "Device is not connected")
      return nil
    }
    return mac
  }

  private var model: VPPeripheralModel? { VPSdk.ble.peripheralModel }

  // MARK: Sync

  /// Copies the watch's stored data into the SDK database. Calls made during a sync share it, and a
  /// sync finished under a minute ago is reused (the app calls readOriginDataForDay once per day).
  private func sync(_ done: @escaping (Bool) -> Void) {
    if let last = lastSync, Date().timeIntervalSince(last) < 60 { return done(true) }
    syncWaiters.append(done)
    guard syncWaiters.count == 1 else { return }

    syncGeneration += 1
    let generation = syncGeneration
    DispatchQueue.main.asyncAfter(deadline: .now() + 120) { [weak self] in
      guard let self = self, self.syncGeneration == generation else { return }
      self.finishSync(false)
    }
    VPSdk.manage.veepooSdkStartReadDeviceAllData { [weak self] state, totalDay, currentDay, dayProgress in
      onMain {
        guard let self = self, self.syncGeneration == generation else { return }
        // VPReadDeviceBaseDataState: 0 start, 1 reading, 2 complete, 3 unavailable.
        switch state.rawValue {
        case 1:
          let total = max(Int(totalDay), 1)
          let day = min(Int(currentDay), total)
          let progress = min((Double(day) + Double(dayProgress) / 100) / Double(total), 1)
          self.progressEvents.send(["progress": progress, "day": day, "dayLabel": dayLabel(day), "totalDays": total])
        case 2, 3:
          // 3: nothing new to read; the database still holds what earlier syncs stored.
          self.finishSync(true)
        default: break
        }
      }
    }
  }

  private func finishSync(_ ok: Bool) {
    syncGeneration += 1
    if ok { lastSync = Date() }
    let waiters = syncWaiters
    syncWaiters.removeAll()
    waiters.forEach { $0(ok) }
  }

  // MARK: Origin (5-minute) data

  func readOrigin(days: [Int], single: Bool, _ reply: Reply) {
    guard let mac = connectedMac(reply) else { return }
    sync { ok in
      guard ok else { return reply.error("ORIGIN_DATA_TIMEOUT", "Origin data read timed out.") }
      let result = days.map { VPOriginData.daily(day: $0, date: self.dateString(daysAgo: $0), mac: mac) }
      if single { reply(result.first) } else { reply(result) }
    }
  }

  // MARK: Sleep

  /// Returns the most recent night, like Android's `sleepDataList.last()`. Multiple sleep periods
  /// of that day are combined into one record.
  func readSleep(_ reply: Reply) {
    guard let mac = connectedMac(reply) else { return }
    sync { ok in
      guard ok else { return reply.error("SLEEP_DATA_ERROR", "Error reading sleep data: sync timed out") }
      // Sleep is filed under the day it ended, so last night is "today"; fall back to yesterday.
      for day in 0...1 {
        if let sleep = self.sleep(date: self.dateString(daysAgo: day), mac: mac) { return reply(sleep) }
      }
      reply(nil)
    }
  }

  private struct SleepPeriod {
    var start: Date?, end: Date?
    var total = 0, deep = 0, light = 0, wakes = 0, quality = 0
    var curve: [Int] = []
  }

  private func sleep(date: String, mac: String) -> [String: Any]? {
    var periods: [SleepPeriod] = []
    let accurate = VPDataBaseOperation.veepooSDKGetAccurateSleepData(withDate: date, andTableID: mac) ?? []
    if !accurate.isEmpty {
      for m in accurate {
        periods.append(SleepPeriod(start: Self.parseTime(m.sleepTime), end: Self.parseTime(m.wakeTime),
                                   total: int(m.sleepDuration) ?? 0, deep: int(m.deepDuration) ?? 0,
                                   light: int(m.lightDuration) ?? 0, wakes: int(m.getUpTimes) ?? 0,
                                   quality: int(m.sleepQuality) ?? 0, curve: Self.digits(m.sleepLine)))
      }
    } else {
      for case let d as [String: Any] in VPDataBaseOperation.veepooSDKGetSleepData(withDate: date, andTableID: mac) ?? [] {
        // DEEP_HOUR / LIGHT_HOUR are fractional hours; SLE_LINE has one digit per 5 minutes
        // (0 light, 1 deep, 2 awake).
        let deep = Int(((num(d["DEEP_HOUR"]) ?? 0) * 60).rounded())
        let light = Int(((num(d["LIGHT_HOUR"]) ?? 0) * 60).rounded())
        let total = (int(d["SLE_HOUR"]) ?? 0) * 60 + (int(d["SLE_MINUTE"]) ?? 0)
        periods.append(SleepPeriod(start: Self.parseTime(d["SLEEP_TIME"]), end: Self.parseTime(d["WAKE_TIME"]),
                                   total: total > 0 ? total : deep + light, deep: deep, light: light,
                                   wakes: int(d["WakeUpTime"]) ?? 0, quality: int(d["SLEEP_LEVEL"]) ?? 0,
                                   curve: Self.digits(d["SLE_LINE"])))
      }
    }
    guard !periods.isEmpty else { return nil }

    let millis: (Date) -> Int = { Int($0.timeIntervalSince1970 * 1000) }
    return payload([
      "totalSleepMinutes": periods.reduce(0) { $0 + $1.total },
      "deepSleepMinutes": periods.reduce(0) { $0 + $1.deep },
      "lightSleepMinutes": periods.reduce(0) { $0 + $1.light },
      "awakeMinutes": 0, // not provided by the SDK, same as Android
      "wakeCount": periods.reduce(0) { $0 + $1.wakes },
      "sleepQuality": periods.map(\.quality).max(),
      "sleepStartTime": periods.compactMap(\.start).min().map(millis),
      "sleepEndTime": periods.compactMap(\.end).max().map(millis),
      "sleepCurve": periods.flatMap(\.curve),
      "date": date,
    ])
  }

  private static func parseTime(_ raw: Any?) -> Date? {
    guard let text = raw as? String else { return nil }
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    for format in ["yyyy/MM/dd HH:mm", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm"] {
      formatter.dateFormat = format
      if let date = formatter.date(from: text) { return date }
    }
    return nil
  }

  private static func digits(_ raw: Any?) -> [Int] {
    guard let raw = raw else { return [] }
    return "\(raw)".compactMap { $0.wholeNumberValue }
  }

  // MARK: Steps

  func readSteps(date: Date, _ reply: Reply) {
    guard let mac = connectedMac(reply) else { return }
    reply.timeout(after: 10, code: "TIMEOUT",
                  "No step data received within 10 seconds. Please ensure device is connected and has step data.")
    let stature = model?.deviceStature ?? 0
    VPDataBaseOperation.veepooSDKGetStepData(withDate: Self.dayFormatter.string(from: date), andTableID: mac,
                                             changeUserStature: stature > 0 ? stature : 170) { stepDict in
      guard let d = stepDict as? [String: Any] else { return reply(nil) }
      reply(payload([
        "steps": int(d["Step"]) ?? 0,
        // Kilometres, like the Android value under this key (the app shows it as km).
        "distanceMeters": num(d["Dis"]) ?? 0,
        "calories": num(d["Cal"]) ?? 0,
        "activeMinutes": nil,
        "timestamp": nowMillis,
      ]))
    }
  }

  // MARK: HRV

  func readHRV(days: Int, startDay: Int, _ reply: Reply) {
    guard let mac = connectedMac(reply) else { return }
    let hrvType = model?.hrvType ?? 0
    guard hrvType != 0 else {
      return reply.error("HRV_NOT_SUPPORTED", "This device does not support HRV data reading")
    }
    sync { ok in
      guard ok else { return reply.error("HRV_TIMEOUT", "HRV data read timed out.") }
      var list: [[String: Any]] = []
      for day in startDay..<(startDay + max(days, 1)) {
        let date = self.dateString(daysAgo: day)
        for case let d as [String: Any] in VPDataBaseOperation.veepooSDKGetDeviceHrvData(withDate: date, andTableID: mac) ?? [] {
          guard let value = positiveInt(d["hrvValue"]) else { continue }
          list.append(payload([
            "date": date,
            "hrvValue": value,
            "heartRate": nil,
            "rrValues": intList(d["hearts"])?.map { $0 * 10 }, // stored as RR interval / 10
            "hrvType": hrvType,
            "timestamp": (d["time"] as? String).map { "\(date) \($0)" },
          ]))
        }
      }
      reply(["hrvDataList": list, "dayHrvScore": 0, "totalRecords": list.count])
    }
  }

  // MARK: Stored body composition

  /// iOS has no record ids: results measured on the watch are synced into the database by date.
  /// "Ids" are 1-based positions in the last 7 days' results, oldest first.
  private func storedBodyComponents(mac: String) -> [[String: Any]] {
    (0..<7).reversed().flatMap { day in
      (VPDataBaseOperation.veepooSDKGetDeviceOffStoreBodyComposition(withDate: dateString(daysAgo: day), andTableID: mac) ?? [])
        .map { payload(bodyComponentMap($0)) }
    }
  }

  func readBodyComponentIds(_ reply: Reply) {
    guard let mac = connectedMac(reply) else { return }
    sync { ok in
      guard ok else { return reply.error("BODY_COMPONENT_TIMEOUT", "Body composition read timed out.") }
      let count = self.storedBodyComponents(mac: mac).count
      reply(count == 0 ? [] : Array(1...count))
    }
  }

  func readBodyComponents(ids: [Int]?, _ reply: Reply) {
    guard let mac = connectedMac(reply) else { return }
    sync { ok in
      guard ok else { return reply.error("BODY_COMPONENT_TIMEOUT", "Body composition read timed out.") }
      let all = self.storedBodyComponents(mac: mac)
      guard let ids = ids, !ids.isEmpty else { return reply(all) }
      reply(ids.compactMap { all.indices.contains($0 - 1) ? all[$0 - 1] : nil })
    }
  }

  // MARK: Automatic measurement

  private var supportsAutoMonit: Bool { (model?.autoMonitSwitchType ?? 0) != 0 }

  private static func autoMap(_ m: VPAutoMonitTestModel, success: Bool? = nil) -> [String: Any] {
    payload([
      "type": Int(m.type.rawValue),
      "isSwitchOpen": m.on,
      "stepUnit": Int(m.minStepValue),
      "isSlotModify": m.supportRangeTime,
      "isIntervalModify": m.minStepValue > 0,
      "supportStartMinute": Int(m.startHourRef) * 60 + Int(m.startMinuteRef),
      "supportEndMinute": Int(m.endHourRef) * 60 + Int(m.endMinuteRef),
      "measureInterval": Int(m.timeInterval),
      "currentStartMinute": Int(m.startHour) * 60 + Int(m.startMinute),
      "currentEndMinute": Int(m.endHour) * 60 + Int(m.endMinute),
      "success": success,
    ])
  }

  private func readAutoMonit(_ reply: Reply, _ done: @escaping ([VPAutoMonitTestModel]) -> Void) {
    guard connectedMac(reply) != nil else { return }
    guard supportsAutoMonit else {
      return reply.error("AUTO_MEASURE_NOT_SUPPORTED", "This device does not support automatic measurement")
    }
    reply.timeout(after: 20, code: "AUTO_MEASURE_READ_FAILED", "Failed to read automatic measurement settings")
    VPSdk.manage.veepooSDKReadAutoMonitSwitchInfo { models in
      onMain { done(models ?? []) }
    }
  }

  func readAutoMeasureSettings(_ reply: Reply) {
    readAutoMonit(reply) { models in reply(models.map { Self.autoMap($0) }) }
  }

  func setAutoMeasureSetting(type: Int, enabled: Bool, interval: Int?, startMinute: Int?, endMinute: Int?, _ reply: Reply) {
    readAutoMonit(reply) { models in
      guard let item = models.first(where: { Int($0.type.rawValue) == type }) else {
        return reply.error("AUTO_MEASURE_UNSUPPORTED_TYPE", "Device does not support automatic measurement type \(type)")
      }
      item.on = enabled
      if let interval = interval { item.timeInterval = UInt16(clamping: interval) }
      if let start = startMinute { item.startHour = UInt8(clamping: start / 60); item.startMinute = UInt8(clamping: start % 60) }
      if let end = endMinute { item.endHour = UInt8(clamping: end / 60); item.endMinute = UInt8(clamping: end % 60) }
      VPSdk.manage.veepooSDKSetAutoMonitSwitch(with: item) { success, _ in
        success ? reply(Self.autoMap(item))
                : reply.error("AUTO_MEASURE_SET_FAILED", "Failed to set automatic measurement type \(type)")
      }
    }
  }

  func enableAllAutoMeasurements(_ reply: Reply) {
    guard connectedMac(reply) != nil else { return }
    supportsAutoMonit ? enableAllAutoMonit(reply) : enableAllLegacy(reply)
  }

  /// Devices with per-type interval settings: switch on every type that is off, one at a time.
  private func enableAllAutoMonit(_ reply: Reply) {
    readAutoMonit(reply) { models in
      var outcome: [[String: Any]] = []
      func next(_ index: Int) {
        guard index < models.count else { return reply(outcome) }
        let item = models[index]
        if item.on {
          outcome.append(Self.autoMap(item))
          return next(index + 1)
        }
        item.on = true
        VPSdk.manage.veepooSDKSetAutoMonitSwitch(with: item) { success, _ in
          onMain {
            if !success { item.on = false }
            outcome.append(Self.autoMap(item, success: success))
            next(index + 1)
          }
        }
      }
      next(0)
    }
  }

  /// Older devices: one on/off switch per function (Android: enableAllLegacy via CustomSetting).
  private func enableAllLegacy(_ reply: Reply) {
    // AutoMeasureType value → VPSettingBaseFunctionSwitchType raw value.
    let switches: [(type: Int, setting: Int)] = [
      (0, 5),    // heart rate      → VPSettingAutomaticHRTest
      (1, 6),    // blood pressure  → VPSettingAutomaticBPTest
      (2, 27),   // blood glucose   → VPSettingAutomaticBloodGlucoseTest
      (3, 29),   // stress          → VPSettingStress
      (4, 1000), // blood oxygen    → VPSettingAutomaticOxygenTest (night)
      (5, 24),   // temperature     → VPSettingAutomaticTemperatureTest
      (7, 13),   // HRV             → VPSettingAutomaticHRVTest
      (8, 31),   // blood component → VPSettingAutomaticBloodCompTest
      (9, 17),   // PPG             → VPSettingAutomaticPPGTest
    ]
    reply.timeout(after: 60, code: "AUTO_MEASURE_ERROR", "Automatic measurement setup timed out")
    var outcome: [[String: Any]] = []
    func next(_ index: Int) {
      guard index < switches.count else { return reply(outcome) }
      let (type, setting) = switches[index]
      var finished = false
      let finish: (Bool?) -> Void = { open in
        onMain {
          guard !finished else { return }
          finished = true
          // nil: the device has no such function (or never answered); leave it out like Android does.
          if let open = open { outcome.append(["type": type, "isSwitchOpen": open, "success": open]) }
          next(index + 1)
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 5) { finish(nil) }
      // Settings must go one at a time: the SDK does not support concurrent commands.
      VPSdk.manage.veepooSDKSettingBaseFunctionType(VPSettingBaseFunctionSwitchType(rawValue: setting)!,
                                                    settingState: VPSettingFunctionState(rawValue: 1)!) { state in
        // VPSettingFunctionCompleteState: 0 no such function, 1 open, 2 closed, 3 failed.
        finish(state.rawValue == 0 ? nil : state.rawValue == 1)
      }
    }
    next(0)
  }

  // MARK: Battery / profile / info

  func readBattery(_ reply: Reply) {
    guard connectedMac(reply) != nil else { return }
    reply.timeout(after: 10, code: "BATTERY_TIMEOUT", "Failed to read battery level")
    VPSdk.manage.veepooSDKReadDeviceBatteryAndChargeInfo { isPercent, chargeState, isLow, battery in
      let value = Int(battery)
      // Non-percentage devices report 0-4 bars.
      let percent = isPercent ? value : value * 25
      reply([
        "level": isPercent ? min(max((value + 24) / 25, 1), 4) : max(value, 1), // BatteryLevels 1-4
        "percent": percent,
        "powerModel": Int(chargeState.rawValue), // 0 normal, 1 charging, 2 low voltage, 3 full = PowerStatuses
        "state": 0,
        "bat": value,
        "isLow": isLow,
        "isPercent": isPercent,
      ])
    }
  }

  func setUserProfile(_ args: [String: Any], _ reply: Reply) {
    guard connectedMac(reply) != nil else { return }
    let info = VPSyncPersonalInfo()
    info.status = Int32(int(args["heightCm"]) ?? 170) // the SDK calls the height "status"
    info.weight = Int32(num(args["weightKg"]) ?? 70)
    info.age = Int32(int(args["age"]) ?? 30)
    info.sex = (args["gender"] as? String)?.lowercased() == "female" ? 0 : 1
    info.targetStep = Int32(int(args["targetSteps"]) ?? 10000)
    info.targetSleepDuration = Int32(int(args["targetSleepMinutes"]) ?? 480)
    reply.timeout(after: 10, code: "SET_PROFILE_FAILED", "Failed to set user profile")
    VPSdk.manage.veepooSDKSynchronousPersonalInformation(info) { result in
      result == 1 ? reply(nil) : reply.error("SET_PROFILE_FAILED", "Failed to set user profile")
    }
  }

  func deviceInfo(_ reply: Reply) {
    let device = VPSdk.connectedAddress == nil ? nil : model
    reply([
      "modelName": device?.deviceName ?? "Unknown",
      "hardwareVersion": "Unknown",
      "softwareVersion": device?.deviceVersion ?? "Unknown",
      "macAddress": device?.deviceAddress ?? "Unknown",
      "manufacturer": "Veepoo",
    ])
  }
}
