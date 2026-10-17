# iOS ↔ Android API Mapping

How each method-channel call of this plugin maps to the native Veepoo SDKs.
Implemented in `ios/Classes/` (not yet verified on a real watch).

- Android doc: [VeepooSDK-Android-API-Document.md](VeepooSDK-Android-API-Document.md)
- iOS doc: [VeepooSDK-iOS-API-Document.md](VeepooSDK-iOS-API-Document.md) — v1.3.0, copied from
  `HBandSDK/iOS_Ble_SDK` → `iOS_sdk_source/doc/VeepooSDK iOS Api_en.md` (the GitHub wiki is no longer updated since 2026-06-22).
- iOS framework + demo: `HBandSDK/iOS_Ble_SDK` → `iOS_sdk_source/Framework`, `iOS_sdk_source/Demo`.

## Key model differences

| Topic | Android | iOS |
|---|---|---|
| Entry point | `VPOperateManager.getInstance()` | `VPBleCentralManage.sharedBleManager()` (connection) + `.peripheralManage` (device ops) + `VPDataBaseOperation` (stored data) |
| Password / bind | Separate `confirmDevicePwd` after connect | Part of `veepooSDKConnectDevice` — state `BleVerifyPasswordSuccess` (4) / `Failure` (5). `bindDevice` should resolve on that state |
| Daily / history data | Pull per day: `readOriginDataSingleDay`, `readSleepData`, … return data in callbacks | **Two steps**: `veepooSdkStartReadDeviceAllData` syncs everything into the SDK's SQLite DB (with progress), then query by date + MAC via `VPDataBaseOperation` (`yyyy-MM-dd`, `tableID = peripheralModel.deviceAddress`). Requires `peripheralManage = VPPeripheralManage.shareVPPeripheralManager()` (SDK persistence) |
| Day selector | Day offset (0 = today) | Date string `yyyy-MM-dd` (offset version exists only in self-persistence mode) |
| Feature support check | `VpSpGetUtil…isSupportX()` | `peripheralModel` properties (`deviceFuctionData[...]`, `bodyCompositionType`, `bloodAnalysisType`, `autoMonitSwitchType`, …) |
| Concurrency | Command queue | **No concurrent ops** — don't start a measurement while daily data is syncing (device reports *busy*) |
| Permissions | Runtime BT scan/connect + location | Only `NSBluetoothAlwaysUsageDescription`; no location needed for BLE. `requestBluetoothPermissions` / `openBluetooth` / `openAppSettings` become iOS-native (CoreBluetooth state + `UIApplication.openSettingsURLString`) |
| Device address | Real MAC | `peripheralModel.deviceAddress` (SDK reads it from advertising data — use it, not the CoreBluetooth UUID, so the server sees the same ID as Android) |
| Reconnect | Plugin-managed | SDK auto-reconnects unless `veepooSDKDisconnectDevice` was called; background needs `bluetooth-central` mode |

## Method-by-method

| Channel method / stream | Android (`VPOperateManager`) | iOS |
|---|---|---|
| `scanDevices` / `stopScanDevices` / `scan_bluetooth_event_channel` | `startScanDevice` / `stopScanDevice` | `veepooSDKStartScanDeviceAndReceiveScanningDevice:` / `veepooSDKStopScanDevice` (dedupe by `deviceAddress`) |
| `connectDevice` + `connection_status_event_channel` | `connectDevice`, `registerConnectStatusListener` | `veepooSDKConnectDevice:deviceConnectBlock:` (`DeviceConnectState`) |
| `bindDevice` / `isDeviceBinded` | `confirmDevicePwd` | Implicit in connect (`BleVerifyPasswordSuccess`) |
| `disconnectDevice` | `disconnectWatch` | `veepooSDKDisconnectDevice` |
| `getCurrentStatus` / `isDeviceConnected` / `getAddress` | `getConnectStatus`, `currentConnectGatt` | `sharedBleManager().isConnected`, `peripheralModel.deviceAddress` |
| `isBluetoothEnabled` / `openBluetooth` / `closeBluetooth` | `isBluetoothOpened` / `openBluetooth` / `closeBluetooth` | CoreBluetooth state; iOS can't toggle BT — open Settings instead, `closeBluetooth` = no-op |
| `readBattery` | `readBattery` | `veepooSDKReadDeviceBatteryAndChargeInfo:` |
| `getDeviceInfo` | `currentConnectGatt` / version callbacks | `peripheralModel` (model, `deviceVersion`, …) |
| `setUserProfile` | `syncPersonInfo` | `veepooSDKSynchronousPersonalInformation:result:` (`VPSyncPersonalInfo`; note field `status` = height) |
| `settingHeartRate` / `readHeartWarning` | `settingHeartWarning` / `readHeartWarning` | `veepooSDKSettingDeviceHeartAlarmWithHeartAlarmModel:settingMode:…` |
| `enableAllAutoMeasurements` | `readAutoMeasureSettingData` / `setAutoMeasureSettingData`, `changeCustomSetting`, `settingSpo` | `veepooSDKReadAutoMonitSwitchInfo:` / `veepooSDKSetAutoMonitSwitchWithModel:` if `autoMonitSwitchType != 0`, else `veepooSDKSettingBaseFunctionType:settingState:completeBlock:` (don't mix both) |
| `readOriginData` / `readOriginDataForDay` / `origin_data_progress_event_channel` | `readOriginDataSingleDay` | `veepooSdkStartReadDeviceAllData` (progress) → `VPDataBaseOperation.veepooSDKGetOriginalDataWithDate:andTableID:` (5-min records, keys `"HH:mm"`) + `…HalfHourData…` |
| `readSleepData` | `readSleepData` | `veepooSDKGetSleepDataWithDate:` or `veepooSDKGetAccurateSleepDataWithDate:` (check sleep type on device) |
| `readStepData` / `step_data_event_channel` | `readSportStep` | `veepooSDKGetStepDataWithDate:andTableID:changeUserStature:` (no push stream — poll, the demo uses a 5 s timer) |
| HRV | `readHRVOriginBySetting` | `VPDataBaseOperation.veepooSDKGetDeviceHrvData…` |
| `startDetectHeart` / `stopDetectHeart` | `startDetectHeart` / `stopDetectHeart` | `veepooSDKTestHeartStart:testResult:` (`start: true/false`) |
| `startDetectSpoh` / `stop…` | `startDetectSPO` / `stopDetectSPO` | `veepooSDKTestOxygenStart:…` |
| `startDetectBloodPressure` / `stop…` | `startDetectBP` / `stopDetectBP` | `veepooSDKTestBloodStart:…` |
| `startDetectTemperature` / `stop…` | `startDetectTempture` / `stopDetectTempture` | `veepooSDK_temperatureTestStart:result:` |
| `startDetectEcg` / `stop…` | `startDetectECG` / `stopDetectECG` | `veepooSDKTestECGStart:testResult:` |
| `startDetectBloodGlucose` / `stop…` | `startBloodGlucoseDetect` / `stopBloodGlucoseDetect` | `veepooSDKTestBloodGlucoseStart:…` |
| `startDetectBodyComponent` / `stop…` (+ stored reads) | `startDetectBodyComponent`, `readBodyComponentId`, `readBodyComponentData` | `veepooSDKTestBodyCompositionStart:…`; stored results via daily-data sync |
| `startDetectBloodComponent` / `stop…` | `startDetectBloodComponent` / `stopDetectBloodComponent` | `veepooSDKTestBloodAnalysisStart:…` |
| `startMiniCheckup` / `stopMiniCheckup` | `startMiniCheckup` / `stopMiniCheckup` | `veepooSDK_healthGlanceTestStart:andProgress:andResult:` — "Health Glance" measures the same set (heart, SpO2, PPG + cuff BP, glucose, temperature, stress, emotion, fatigue, HRV, GSR, blood + body composition); sent as `detail` + `result` events |

On iOS every `start…` call takes a single `start: Bool` + one result block (the same call stops the test with `false`), so each Android start/stop pair maps to one iOS method.

## iOS implementation decisions

Where the iOS SDK can't reproduce Android exactly, the bridge does this:

| Topic | iOS behaviour |
|---|---|
| `connectDevice(address)` | Uses the model from the last scan; if the watch wasn't scanned this session (auto-reconnect on launch) it scans until that MAC appears. 30 s timeout. Resolves on "connected", like Android. |
| `bindDevice` | Reuses the SDK's automatic default-password check (it also syncs the phone time) → `CHECK_AND_TIME_SUCCESS`; only sends the given password explicitly if that check failed. |
| `connection_status` events | `state` sent as the strings `connected` / `disconnected` (the Dart model accepts both forms). |
| `getCurrentStatus` | `2` connected / `0` disconnected (`DeviceConnectionState.fromCode`). |
| Stored-data reads | One `veepooSdkStartReadDeviceAllData` sync (progress → `origin_data_progress`), then database queries. A sync under 60 s old is reused, so per-day calls don't re-sync. |
| `readOriginDataForDay` / `3Days` | Merges the base 5-min table with the SpO2, HRV (per-minute, averaged into 5-min slots), temperature, glucose, blood-analysis and BP tables by `HH:mm`; daily/hourly aggregation is the Android code ported. Fields with no iOS source (`wear`, `tempOne/Two`, `drinkPart*`, `sleepStates`, ...) are absent. |
| `readSleepData` | Today's sleep record (falls back to yesterday), periods of that day combined. `sleepStartTime`/`sleepEndTime` are epoch ms and `sleepCurve` an int list, as the Dart model expects. |
| `readStepData` | `distanceMeters` carries **km**, same as Android (the app displays it as km). |
| `readBodyComponentId/Data` | iOS has no record ids: returns the last 7 days of watch-stored results; ids are 1-based positions (oldest first). |
| Blood pressure / glucose tests | Private mode, matching Android's `DETECT_MODEL_PRIVATE`. |
| `enableAllAutoMeasurements` | `autoMonitSwitchType != 0` → per-type auto-monitor settings; otherwise the per-function switches (HR, BP, glucose, stress, night SpO2, temperature, HRV, blood component, PPG), one at a time. |
| `openBluetooth` / `closeBluetooth` | iOS apps can't toggle Bluetooth: opens the app's Settings page / no-op. |
| Not implemented (on either platform) | `setDeviceSettings` & friends, `read*History`, `readBloodPressure`/`readTemperature`/`readBloodGlucose`/`readEcgData`, `setBloodPressureAlarm`, `setBloodGlucoseCalibration` → `notImplemented`. |
