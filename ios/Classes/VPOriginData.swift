import Foundation
import VeepooBleSDK

/// Builds the `DailyHealthData` map (Android: OriginDataReader) from the SDK database after a sync.
///
/// Android gets one stream of 5-minute records per day. The iOS SDK stores the same data in separate
/// tables (5-minute base data, blood oxygen, HRV, temperature, glucose, blood analysis, blood pressure),
/// so they are merged per "HH:mm" slot here; a slot keeps the first value found for each field.
enum VPOriginData {
  static func daily(day: Int, date: String, mac: String) -> [String: Any] {
    let records = self.records(date: date, mac: mac)
    var hourly: [[String: Any]] = []
    for hour in 0..<24 {
      let prefix = String(format: "%02d:", hour)
      let hourRecords = records.filter { ($0["time"] as? String)?.hasPrefix(prefix) == true }
      if !hourRecords.isEmpty { hourly.append(hourlyData(hour: hour, records: hourRecords)) }
    }

    let heart = ints(records, "heartRate"), systolic = ints(records, "systolic"), diastolic = ints(records, "diastolic")
    let temperature = doubles(records, "temperature"), oxygen = ints(records, "bloodOxygen")
    let hrv = ints(records, "hrvValue")
    return payload([
      "date": date,
      "dayLabel": dayLabel(day), // TEMP
      "avgHeartRate": average(heart),
      "maxHeartRate": heart.max(),
      "minHeartRate": heart.min(),
      "avgSystolic": average(systolic),
      "avgDiastolic": average(diastolic),
      "maxSystolic": systolic.max(),
      "minSystolic": systolic.min(),
      "avgTemperature": average(temperature),
      "maxTemperature": temperature.max(),
      "minTemperature": temperature.min(),
      "avgBloodOxygen": average(oxygen),
      "minBloodOxygen": oxygen.min(),
      "totalSteps": ints(records, "steps").reduce(0, +),
      "totalCalories": doubles(records, "calories").reduce(0, +),
      "totalDistance": doubles(records, "distance").reduce(0, +),
      "avgSportValue": average(ints(records, "sportValue")),
      "avgBloodGlucose": average(ints(records, "bloodGlucose")),
      "avgRespirationRate": average(ints(records, "respirationRate")),
      "avgEcgHeartRate": average(ints(records, "ecgHeartRate")),
      "avgUricAcid": average(doubles(records, "uricAcid")),
      "avgTotalCholesterol": average(doubles(records, "totalCholesterol")),
      "avgTriglyceride": average(doubles(records, "triglyceride")),
      "avgHdl": average(doubles(records, "hdl")),
      "avgLdl": average(doubles(records, "ldl")),
      "avgHrvValue": average(hrv),
      "maxHrvValue": hrv.max(),
      "minHrvValue": hrv.min(),
      "hourlyData": hourly,
    ])
  }

  private static func hourlyData(hour: Int, records: [[String: Any]]) -> [String: Any] {
    let heart = ints(records, "heartRate"), hrv = ints(records, "hrvValue")
    return payload([
      "hour": hour,
      "hourLabel": String(format: "%02d:00", hour),
      "avgHeartRate": average(heart),
      "maxHeartRate": heart.max(),
      "minHeartRate": heart.min(),
      "avgSystolic": average(ints(records, "systolic")),
      "avgDiastolic": average(ints(records, "diastolic")),
      "avgTemperature": average(doubles(records, "temperature")),
      "avgBloodOxygen": average(ints(records, "bloodOxygen")),
      "steps": ints(records, "steps").reduce(0, +),
      "calories": doubles(records, "calories").reduce(0, +),
      "distance": doubles(records, "distance").reduce(0, +),
      "avgSportValue": average(ints(records, "sportValue")),
      "avgBloodGlucose": average(ints(records, "bloodGlucose")),
      "avgRespirationRate": average(ints(records, "respirationRate")),
      "avgUricAcid": average(doubles(records, "uricAcid")),
      "avgTotalCholesterol": average(doubles(records, "totalCholesterol")),
      "avgTriglyceride": average(doubles(records, "triglyceride")),
      "avgHdl": average(doubles(records, "hdl")),
      "avgLdl": average(doubles(records, "ldl")),
      "avgHrvValue": average(hrv),
      "maxHrvValue": hrv.max(),
      "minHrvValue": hrv.min(),
      "records": records,
    ])
  }

  // MARK: Records

  /// One map per base-data slot (5 minutes), sorted by time, with the OriginHealthData keys.
  ///
  /// Like Android (one record per OriginData3), only the 5-minute base data creates records. The
  /// other tables, some stored every minute (blood oxygen), are merged into the slot their reading
  /// falls in and averaged; on their own they made a step-less record per minute, which buried the
  /// slots that carry steps / calories / distance / MET.
  static func records(date: String, mac: String) -> [[String: Any]] {
    var slots: [String: [String: Any]] = [:]

    // 5-minute base data, keyed "HH:mm".
    if let base = VPDataBaseOperation.veepooSDKGetOriginalData(withDate: date, andTableID: mac) as? [String: Any] {
      for (rawTime, value) in base {
        guard let d = value as? [String: Any], let time = slotTime(rawTime) else { continue }
        let fields: [String: Any?] = [
          // Vendor rule: use heartValue; without it the per-minute ppgs, then ecgs.
          "heartRate": reading(d["heartValue"]) ?? firstReading(d["ppgs"]) ?? firstReading(d["ecgs"]),
          "systolic": reading(d["systolic"]),
          "diastolic": reading(d["diastolic"]),
          "steps": positiveInt(d["stepValue"]),
          "calories": positive(d["calValue"]),
          "distance": positive(d["disValue"]),
          "sportValue": positiveInt(d["sportValue"]),
          "ecgHeartRate": firstReading(d["ecgs"]),
          "ppgValues": intList(d["ppgs"]),
          "ecgValues": intList(d["ecgs"]),
          "met": positive(d["met"]),
          "pressure": positiveInt(d["stress"]),
        ]
        slots[time] = fields.compactMapValues { $0 }.merging(["date": date, "time": time]) { a, _ in a }
      }
    }
    let slotTimes = slots.keys.sorted()

    // Other tables: collected per base slot, combined below.
    var extra: [String: [String: [Any]]] = [:]
    func add(_ rawTime: Any?, _ fields: [String: Any?]) {
      guard let time = slotTime(rawTime), let slot = baseSlot(containing: time, in: slotTimes) else { return }
      for (key, value) in fields {
        if let value = value { extra[slot, default: [:]][key, default: []].append(value) }
      }
    }

    for d in table(VPDataBaseOperation.veepooSDKGetDeviceHrvData(withDate: date, andTableID: mac)) {
      add(d["time"], ["hrvValue": reading(d["hrvValue"])])
    }

    for d in table(VPDataBaseOperation.veepooSDKGetDeviceOxygenData(withDate: date, andTableID: mac)) {
      add(d["Time"], [
        "bloodOxygen": reading(d["OxygenValue"]),
        "respirationRate": reading(d["RespirationRate"]),
        "heartRate": reading(d["HeartValue"]),
        "hrvValue": reading(d["HRV"]),
        "apneaResults": int(d["ApneaResult"]).map { [$0] },
        "hypoxiaTimes": int(d["HypoxiaTime"]).map { [$0] },
        "cardiacLoads": int(d["CardiacLoad"]).map { [$0] },
        "isHypoxias": int(d["IsHypoxia"]).map { [$0] },
      ])
    }

    for d in table(VPDataBaseOperation.veepooSDKGetDeviceTemperatureData(withDate: date, andTableID: mac)) {
      guard let hour = int(d["hour"]), let minute = int(d["minute"]) else { continue }
      add(String(format: "%02d:%02d", hour, minute), ["temperature": positive(d["value"])])
    }

    for d in table(VPDataBaseOperation.veepooSDKGetDeviceBloodGlucoseData(withDate: date, andTableID: mac)) {
      let level = firstPositive(d["bloodGlucoseLevels"]).map { Int($0) }
      add(d["time"], [
        // mmol/L like the Android value the app converts with ×18; Dart reads it as an int.
        "bloodGlucose": firstPositive(d["bloodGlucoses"]),
        "bloodGlucoseRiskLevel": level.map { ["NONE", "LOW", "MIDDLE", "HIGH"][min($0, 3)] },
      ])
    }

    for m in VPDataBaseOperation.veepooSDKGetDeviceBloodAnalysisData(withDate: date, andTableID: mac) ?? [] {
      add(m.time, [
        "uricAcid": firstPositive(m.uricAcids),
        "totalCholesterol": firstPositive(m.totalCholesterols),
        "triglyceride": firstPositive(m.triglycerides),
        "hdl": firstPositive(m.highDensityLipoproteins),
        "ldl": firstPositive(m.lowDensityLipoproteins),
      ])
    }

    for d in table(VPDataBaseOperation.veepooSDKGetBloodData(withDate: date, andTableID: mac)) {
      add(d["Time"], ["systolic": reading(d["systolic"]), "diastolic": reading(d["diastolic"])])
    }

    for (slot, fields) in extra {
      guard var record = slots[slot] else { continue }
      // The base data's own value wins (e.g. its heart rate over the oxygen table's).
      for (key, values) in fields where record[key] == nil {
        if let value = combine(key, values) { record[key] = value }
      }
      slots[slot] = record
    }
    return slotTimes.compactMap { slots[$0] }
  }

  /// Keys whose readings are whole numbers; the rest of the numeric keys are averaged as decimals.
  private static let intKeys: Set<String> = [
    "heartRate", "systolic", "diastolic", "bloodOxygen", "respirationRate", "hrvValue",
  ]

  private static func combine(_ key: String, _ values: [Any]) -> Any? {
    if values.first is [Any] { return values.flatMap { $0 as? [Any] ?? [] } }
    let numbers = values.compactMap { num($0) }
    guard !numbers.isEmpty else { return values.first } // e.g. bloodGlucoseRiskLevel
    let mean = numbers.reduce(0, +) / Double(numbers.count)
    return intKeys.contains(key) ? Int(mean.rounded()) : mean
  }

  /// The base slot a reading at [time] belongs to: the last slot at or before it, if it started
  /// less than 10 minutes earlier (base data is every 5 minutes; a gap means the watch was off).
  private static func baseSlot(containing time: String, in slotTimes: [String]) -> String? {
    let minutes: (String) -> Int = { t in
      let p = t.split(separator: ":").compactMap { Int($0) }
      return p.count == 2 ? p[0] * 60 + p[1] : -1
    }
    let t = minutes(time)
    guard let slot = slotTimes.last(where: { minutes($0) <= t }), t - minutes(slot) < 10 else { return nil }
    return slot
  }

  private static func table(_ rows: [Any]?) -> [[String: Any]] {
    (rows ?? []).compactMap { $0 as? [String: Any] }
  }

  /// "HH:mm" from "HH:mm", "HH:mm:ss" or "yyyy-MM-dd HH:mm".
  private static func slotTime(_ raw: Any?) -> String? {
    guard let text = raw as? String,
          let clock = text.split(separator: " ").last?.split(separator: ":"), clock.count >= 2,
          let hour = Int(clock[0]), let minute = Int(clock[1]) else { return nil }
    return String(format: "%02d:%02d", hour, minute)
  }

  private static func ints(_ records: [[String: Any]], _ key: String) -> [Int] {
    records.compactMap { int($0[key]) }.filter { $0 > 0 }
  }

  private static func doubles(_ records: [[String: Any]], _ key: String) -> [Double] {
    records.compactMap { num($0[key]) }.filter { $0 > 0 }
  }

  private static func average(_ values: [Int]) -> Int? {
    values.isEmpty ? nil : values.reduce(0, +) / values.count
  }

  private static func average(_ values: [Double]) -> Double? {
    values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
  }
}

func positiveInt(_ value: Any?) -> Int? {
  guard let v = int(value), v > 0 else { return nil }
  return v
}

func dayLabel(_ day: Int) -> String {
  switch day {
  case 0: return "Today"
  case 1: return "Yesterday"
  case 2: return "2 Days Ago"
  default: return "\(day) Days Ago"
  }
}
