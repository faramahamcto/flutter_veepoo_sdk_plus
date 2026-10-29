import Flutter
import VeepooBleSDK

/// Manual (live) measurements. Each iOS test is one SDK call with `start: true/false` and a single
/// callback; events are reshaped into the maps the Android utils (HeartRate.kt, Spoh.kt, ...) send.
/// The SDK can't run two operations at once: a test started during a data sync reports "busy".
final class VPDetection {
  private let heartEvents, spohEvents, temperatureEvents, ecgEvents: EventStream
  private let bloodPressureEvents, bloodGlucoseEvents, bloodComponentEvents: EventStream
  private let bodyComponentEvents, miniCheckupEvents: EventStream
  private var ecgSamplesSent = 0

  init(heart: EventStream, spoh: EventStream, temperature: EventStream, ecg: EventStream,
       bloodPressure: EventStream, bloodGlucose: EventStream, bloodComponent: EventStream,
       bodyComponent: EventStream, miniCheckup: EventStream) {
    heartEvents = heart
    spohEvents = spoh
    temperatureEvents = temperature
    ecgEvents = ecg
    bloodPressureEvents = bloodPressure
    bloodGlucoseEvents = bloodGlucose
    bloodComponentEvents = bloodComponent
    bodyComponentEvents = bodyComponent
    miniCheckupEvents = miniCheckup
  }

  /// Runs `action` against the connected device and answers the start/stop call right away,
  /// like Android does; results arrive on the event channel.
  private func withDevice(_ reply: Reply, _ action: (VPPeripheralBaseManage) -> Void) {
    guard VPSdk.connectedAddress != nil else {
      return reply.error("NOT_CONNECTED", "Device is not connected")
    }
    action(VPSdk.manage)
    reply(nil)
  }

  // MARK: Heart rate

  func heart(start: Bool, _ reply: Reply) {
    let events = heartEvents
    withDevice(reply) { manage in
      guard start else { return manage.veepooSDKTestHeartStart(false, testResult: nil) }
      manage.veepooSDKTestHeartStart(true) { state, value in
        // VPTestHeartState (start, testing, not worn, busy, over) → Android EHeartStatus names.
        let names = ["STATE_HEART_DETECT", "STATE_HEART_NORMAL", "STATE_HEART_WEAR_ERROR", "STATE_HEART_BUSY", "STATE_INIT"]
        let raw = state.rawValue
        events.send(["data": Int(value), "state": names.indices.contains(raw) ? names[raw] : "STATE_INIT"])
      }
    }
  }

  /// mode: 0 off, 1 on, 2 read. Android only logs the reply, so does this.
  func heartWarning(high: Int, low: Int, mode: Int, _ reply: Reply) {
    withDevice(reply) { manage in
      let model = VPDeviceHeartAlarmModel(heartMaxValue: UInt(max(high, 0)), heartMinValue: UInt(max(low, 0)), openState: mode == 1)
      manage.veepooSDKSettingDeviceHeartAlarm(with: model, settingMode: UInt(mode), successResult: nil, failureResult: nil)
    }
  }

  // MARK: Blood oxygen

  func spoh(start: Bool, _ reply: Reply) {
    let events = spohEvents
    withDevice(reply) { manage in
      guard start else { return manage.veepooSDKTestOxygenStart(false, testResult: nil) }
      manage.veepooSDKTestOxygenStart(true) { state, value in
        var spoh = "OPEN", device = "DETECT_OXYGEN", checking = false, progress = 0, oxygen = 0
        switch state.rawValue {
        case 0: break // started, no value yet
        case 1: oxygen = Int(value)
        case 2: device = "UNPASS_WEAR"
        case 3: device = "BUSY"
        case 4: device = "FREE"
        case 5: spoh = "NOT_SUPPORT"; device = "FREE"
        case 6: checking = true; progress = Int(value) // calibrating: value is the calibration progress
        case 7: progress = 100
        default: spoh = "UNKONW"; device = "UNKONW" // vendor spelling, matches the Dart enums
        }
        events.send(payload(["spohStatus": spoh, "deviceStatus": device, "value": oxygen,
                                 "checking": checking, "checkingProgress": progress, "rate": nil]))
      }
    }
  }

  // MARK: Temperature

  func temperature(start: Bool, _ reply: Reply) {
    let events = temperatureEvents
    withDevice(reply) { manage in
      guard start else { return manage.veepooSDK_temperatureTestStart(false, result: nil) }
      manage.veepooSDK_temperatureTestStart(true) { state, enable, progress, temp, original in
        // VPTemperatureTestState: 0 unsupported, 1 open, 2 closed, 9 not worn. `enable == false` = busy.
        // Temperatures are reported ×10 °C.
        let name: String
        switch state.rawValue {
        case 0: name = "notSupported"
        case 2: name = "idle"
        case 9: name = "failed"
        default: name = !enable ? "failed" : (progress >= 100 ? "complete" : "measuring")
        }
        let celsius = temp > 0 ? Double(temp) / 10 : nil
        events.send(payload([
          "temperatureCelsius": celsius,
          "temperatureFahrenheit": celsius.map { $0 * 9 / 5 + 32 },
          "wristTemperatureCelsius": original > 0 ? Double(original) / 10 : nil,
          "state": name,
          "isMeasuring": name == "measuring",
          "progress": progress,
          "timestamp": nowMillis,
        ]))
      }
    }
  }

  // MARK: Blood pressure

  func bloodPressure(start: Bool, _ reply: Reply) {
    let events = bloodPressureEvents
    // testMode 1 = private mode, matching Android's EBPDetectModel.DETECT_MODEL_PRIVATE.
    withDevice(reply) { manage in
      guard start else { return manage.veepooSDKTestBloodStart(false, testMode: 1, testResult: nil) }
      manage.veepooSDKTestBloodStart(true, testMode: 1) { state, progress, high, low in
        // VPTestBloodState: 0 testing, 1 busy, 2 failed, 3 stopped, 4 complete, 5 unsupported.
        let names = ["measuring", "failed", "failed", "idle", "complete", "notSupported"]
        let raw = state.rawValue
        let name = names.indices.contains(raw) ? names[raw] : "unknown"
        events.send([
          "systolic": Int(high),
          "diastolic": Int(low),
          "progress": Int(progress),
          "state": name,
          "isMeasuring": name == "measuring",
          "timestamp": nowMillis,
        ])
      }
    }
  }

  // MARK: Blood glucose

  func bloodGlucose(start: Bool, _ reply: Reply) {
    let events = bloodGlucoseEvents
    // isPersonalModel = private mode, matching Android's EBloodGlucoseDetectModel.DETECT_MODEL_PRIVATE.
    withDevice(reply) { manage in
      guard start else { return manage.veepooSDKTestBloodGlucoseStart(false, isPersonalModel: true, testResult: nil) }
      manage.veepooSDKTestBloodGlucoseStart(true, isPersonalModel: true) { state, progress, value, level in
        // VPDeviceBloodGlucoseTestState: 0 unsupported, 1 measuring, 2 closed, 3 low power, 4 busy, 5 not worn.
        switch state.rawValue {
        case 1:
          let mmol = Double(value) / 100 // reported ×100 mmol/L
          let risk = ["NONE", "LOW", "MIDDLE", "HIGH"]
          events.send([
            "progress": Int(progress),
            "glucoseMmolL": mmol,
            "glucoseMgdL": mmol * 18.0182,
            "state": progress >= 100 ? "complete" : "measuring",
            "isMeasuring": progress < 100,
            "timestamp": nowMillis,
            "riskLevel": risk.indices.contains(Int(level)) ? risk[Int(level)] : "UNKNOWN",
          ])
        case 2:
          events.send(["state": "idle", "isMeasuring": false, "stopped": true, "timestamp": nowMillis])
        default:
          events.send([
            "error": true,
            "errorCode": Int(state.rawValue),
            "state": state.rawValue == 0 ? "notSupported" : "failed",
            "isMeasuring": false,
            "timestamp": nowMillis,
          ])
        }
      }
    }
  }

  // MARK: ECG

  func ecg(start: Bool, _ reply: Reply) {
    withDevice(reply) { manage in
      guard start else {
        manage.veepooSDKTestECGStart(false, testResult: nil)
        ecgEvents.send(ecgEvent(state: "idle", progress: 0, heartRate: 0, waveform: [], result: nil))
        return
      }
      ecgSamplesSent = 0
      manage.veepooSDKTestECGStart(true) { [weak self] state, progress, model in
        guard let self = self else { return }
        // VPTestECGState: 0 start, 1 testing, 2 lead off, 3 busy, 4 stopped, 5 failed, 6 complete, 7 unsupported.
        let names = ["measuring", "measuring", "poorSignal", "failed", "idle", "failed", "complete", "notSupported"]
        let raw = state.rawValue
        let name = names.indices.contains(raw) ? names[raw] : "unknown"

        // The model accumulates the whole recording; send only samples not sent yet, like Android's
        // per-packet onEcgADCChange.
        let signals = intList(model?.originalSignals) ?? []
        if signals.count < self.ecgSamplesSent { self.ecgSamplesSent = 0 }
        let waveform = Array(signals.dropFirst(self.ecgSamplesSent))
        self.ecgSamplesSent = signals.count

        let heartRate = int(model?.aveHeart) ?? (intList(model?.hearts)?.last ?? 0)
        let result: String? = raw == 6 ? "success" : (raw == 5 ? "failed" : nil)
        self.ecgEvents.send(self.ecgEvent(state: name, progress: Int(progress), heartRate: heartRate, waveform: waveform, result: result))
      }
    }
  }

  private func ecgEvent(state: String, progress: Int, heartRate: Int, waveform: [Int], result: String?) -> [String: Any] {
    payload([
      "waveformData": waveform,
      "heartRate": heartRate,
      "state": state,
      "isMeasuring": state == "measuring",
      "progress": progress,
      "diagnosticResult": result,
      "signalQuality": waveform.isEmpty ? 0 : 100,
      "timestamp": nowMillis,
    ])
  }

  // MARK: Blood component (blood analysis)

  func bloodComponent(start: Bool, personal: Bool, _ reply: Reply) {
    let events = bloodComponentEvents
    withDevice(reply) { manage in
      guard start else {
        manage.veepooSDKTestBloodAnalysisStart(false, isPersonalModel: personal, progress: nil, testResult: nil)
        return
      }
      manage.veepooSDKTestBloodAnalysisStart(true, isPersonalModel: personal, progress: { progress in
        events.send([
          "progress": Int((progress?.fractionCompleted ?? 0) * 100),
          "state": "measuring",
          "isMeasuring": true,
          "timestamp": nowMillis,
        ])
      }, testResult: { state, model in
        // VPDeviceBloodAnalysisState: 0 unsupported, 1 busy, 2 stopped, 3 low power, 4 failed, 5 not worn, 6 complete.
        switch state.rawValue {
        case 6:
          events.send(payload([
            "progress": 100,
            "state": "complete",
            "isMeasuring": false,
            "uricAcid": model?.uricAcidValue,
            "totalCholesterol": model?.totalCholesterolValue,
            "triglyceride": model?.triglycerideValue,
            "hdl": model?.highDensityLipoproteinValue,
            "ldl": model?.lowDensityLipoproteinValue,
            "timestamp": nowMillis,
          ]))
        case 2:
          events.send(["state": "idle", "isMeasuring": false, "stopped": true, "timestamp": nowMillis])
        default:
          let errors = ["NO_FUNCTION", "BUSY", "OVER", "LOW_POWER", "FAILURE", "WEAR_ERROR"]
          events.send([
            "error": true,
            "state": state.rawValue == 0 ? "notSupported" : "failed",
            "errorMessage": errors.indices.contains(Int(state.rawValue)) ? errors[Int(state.rawValue)] : "UNKNOWN",
            "isMeasuring": false,
            "timestamp": nowMillis,
          ])
        }
      })
    }
  }

  // MARK: Body composition

  func bodyComponent(start: Bool, _ reply: Reply) {
    let events = bodyComponentEvents
    withDevice(reply) { manage in
      guard start else {
        manage.veepooSDKTestBodyCompositionStart(false, progress: nil, testResult: nil)
        return
      }
      manage.veepooSDKTestBodyCompositionStart(true, progress: { lead, progress in
        events.send([
          "state": "measuring",
          "isMeasuring": true,
          "progress": Int((progress?.fractionCompleted ?? 0) * 100),
          "detectStep": lead, // 0 = hand on the electrode, 1 = not
          "timestamp": nowMillis,
        ])
      }, testResult: { state, model in
        // VPDeviceBodyCompositionState: 0 unsupported, 1 busy, 2 stopped, 3 low power, 4 failed, 5 complete.
        switch state.rawValue {
        case 5:
          var event = model.map(bodyComponentMap) ?? [:]
          event["state"] = "complete"
          event["isMeasuring"] = false
          event["progress"] = 100
          event["timestamp"] = nowMillis
          events.send(payload(event))
        case 2:
          events.send(["state": "idle", "isMeasuring": false, "stopped": true, "timestamp": nowMillis])
        default:
          let states = ["failed", "busy", "idle", "lowPower", "failed"]
          let errors = ["NO_FUNCTION", "BUSY", "OVER", "LOW_POWER", "FAILED"]
          let raw = Int(state.rawValue)
          events.send([
            "error": true,
            "state": states.indices.contains(raw) ? states[raw] : "failed",
            "errorMessage": errors.indices.contains(raw) ? errors[raw] : "UNKNOWN",
            "isMeasuring": false,
            "timestamp": nowMillis,
          ])
        }
      })
    }
  }

  // MARK: Mini checkup (iOS "Health Glance")

  /// The iOS Health Glance test measures the same set as Android's Mini-Checkup
  /// (heart, SpO2, PPG + cuff BP, glucose, temperature, stress, emotion, fatigue, HRV, GSR,
  /// blood and body composition), so it is exposed through the same event shapes.
  func miniCheckup(start: Bool, _ reply: Reply) {
    let events = miniCheckupEvents
    withDevice(reply) { manage in
      guard start else {
        manage.veepooSDK_healthGlanceTestStart(false, andProgress: nil, andResult: nil)
        return
      }
      manage.veepooSDK_healthGlanceTestStart(true, andProgress: { progress in
        events.send(["type": "progress", "progress": progress, "timestamp": nowMillis])
      }, andResult: { state, model in
        // VPDeviceHealthGlanceState: 0 unsupported, 1 busy, 2 stopped, 3 low power, 4 failed,
        // 5 not worn, 6 complete, 7 ECG lead off.
        switch state.rawValue {
        case 6 where model != nil:
          let m = model!
          events.send(["type": "detail", "detail": healthGlanceDetail(m), "timestamp": nowMillis])
          events.send(["type": "result", "result": healthGlanceResult(m), "timestamp": nowMillis])
        case 2:
          events.send(["type": "stopped", "timestamp": nowMillis])
        default:
          let codes = [0: "FUNCTION_NOT_SUPPORT", 1: "DEVICE_BUSY", 3: "LOW_POWER", 4: "TEST_COMPLETE_NO_RESULT",
                       5: "WEARING_ABNORMALITY", 6: "TEST_COMPLETE_NO_RESULT", 7: "ECG_LEAD_DETACHMENT"]
          let code = codes[Int(state.rawValue)] ?? "UNKNOWN"
          events.send(["type": "error", "errorCode": code, "errorMessage": code, "timestamp": nowMillis])
        }
      })
    }
  }
}

/// VPBodyCompositionValueModel (string fields) → Android bodyComponentToMap keys.
func bodyComponentMap(_ m: VPBodyCompositionValueModel) -> [String: Any?] {
  let date = [m.date, m.testTime].compactMap { $0 }.joined(separator: " ")
  return [
    "date": date.isEmpty ? nil : date,
    "id": nil,
    "idType": nil,
    "duration": nil,
    "bmi": num(m.bmi),
    "bodyFatRate": num(m.bodyFatPercentage),
    "fatRate": num(m.fatMass),
    "ffm": num(m.leanBodyMass),
    "muscleRate": num(m.muscleRate),
    "muscleMass": num(m.muscleMass),
    "subcutaneousFat": num(m.subcutaneousFat),
    "bodyWater": num(m.bodyMoisture),
    "waterContent": num(m.waterContent),
    "skeletalMuscleRate": num(m.skeletalMuscleRate),
    "boneMass": num(m.boneMass),
    "proteinProportion": num(m.proportionOfProtein),
    "proteinMass": num(m.proteinAmount),
    "basalMetabolicRate": num(m.basalMetabolicRate),
  ]
}

private func healthGlanceResult(_ m: VPHealthGlanceTestModel) -> [String: Any] {
  [
    "heartRate": Int(m.heartRate),
    "bloodOxygen": Int(m.bloodOxygen),
    "stress": Int(m.stress),
    "emotion": m.emotionLevel,
    "fatigue": Int(m.fatigueLevel),
    "bloodGlucose": m.bloodSugar,
    "bodyTemperature": m.bodyTemperature,
    "systolicBloodPressure": Int(m.systolicBloodPressure),
    "diastolicBloodPressure": Int(m.diastolicBloodPressure),
    "hrv": Int(m.hrv),
  ]
}

private func healthGlanceDetail(_ m: VPHealthGlanceTestModel) -> [String: Any] {
  [
    "basePersonalInfo": ["gender": Int(m.gender), "age": Int(m.age), "height": Int(m.height), "weight": Int(m.weight)],
    "heartRate": Int(m.heartRate),
    "bloodOxygen": Int(m.bloodOxygen),
    "stress": Int(m.stress),
    "emotion": m.emotionLevel,
    "fatigue": Int(m.fatigueLevel),
    "bloodGlucoseType": Int(m.bloodSugarType),
    "bloodGlucose": m.bloodSugar,
    "bodyTemperature": m.bodyTemperature,
    "originalTemperature": m.orgTemperature,
    "bpAirPump": ["systolicBloodPressure": Int(m.cuffBloodPressureHigh), "diastolicBloodPressure": Int(m.cuffBloodPressureLow)],
    "bpPhotoelectric": ["systolicBloodPressure": Int(m.ppgBloodPressureHigh), "diastolicBloodPressure": Int(m.ppgBloodPressureLow)],
    "hrv": Int(m.hrv),
    "bloodComponent": [
      "uricAcid": m.uricAcid,
      "totalCholesterol": m.totalCholesterol,
      "triglyceride": m.triglyceride,
      "hdl": m.highDensityLipoprotein,
      "ldl": m.lowDensityLipoprotein,
    ],
    "bodyComponent": [
      "gender": Int(m.gender),
      "age": Int(m.age),
      "height": Int(m.height),
      "weight": Int(m.weight),
      "bmi": m.bmi,
      "bodyFatRate": m.bodyFatPercentage,
      "fatRate": m.fatMass,
      "ffm": m.leanBodyMass,
      "muscleRate": m.muscleRate,
      "muscleMass": m.muscleMass,
      "subcutaneousFat": m.subcutaneousFat,
      "bodyWater": m.bodyMoisture,
      "waterContent": m.waterContent,
      "skeletalMuscleRate": m.skeletalMuscleRate,
      "boneMass": m.boneMass,
      "proteinProportion": m.proportionOfProtein,
      "proteinMass": m.proteinAmount,
      "basalMetabolicRate": m.basalMetabolicRate,
    ],
    "skinElectricity": [
      "emotion": m.emotionLevel,
      "skinMoistureContent": Int(m.skinMoisture),
      "depressionRisk": Int(m.depressionRisk),
      "sympatheticActivity": Int(m.snsActivation),
      "cortisolConcentration": Int(m.cortisolValue),
    ],
  ]
}
