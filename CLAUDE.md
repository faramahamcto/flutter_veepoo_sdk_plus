# CLAUDE.md

Flutter plugin wrapping the Veepoo smartwatch BLE SDKs (Android: tested; iOS: implemented to mirror Android, not yet verified on a watch). Package name `flutter_veepoo_sdk`; Kotlin package `site.shasmatic.flutter_veepoo_sdk`.

## Vendor reference (read this before touching native code)

`docs/VeepooSDK-Android-API-Document.md` — local copy (~550 KB) of the vendor's API wiki, downloaded 2026-10-07 from
<https://github.com/HBandSDK/Android_Ble_SDK/wiki/VeepooSDK-Android-API-Document> (raw: `raw.githubusercontent.com/wiki/HBandSDK/Android_Ble_SDK/VeepooSDK-Android-API-Document.md`). Changelog at the top is at v1.2.4. Grep it by feature heading (`## Read daily data function`, `## Scan Device`, …) rather than reading it whole. The Kotlin layer is a thin bridge over this API; behavior questions are answered here first, then by the decompiled jars in `android/libs/`.

iOS vendor reference: `docs/VeepooSDK-iOS-API-Document.md` (v1.3.0, from `HBandSDK/iOS_Ble_SDK` → `iOS_sdk_source/doc/VeepooSDK iOS Api_en.md`; the GitHub wiki stopped updating 2026-06-22). The real API is the headers in `ios/Frameworks/VeepooBleSDK.framework/Headers/`. `docs/iOS-Android-API-Mapping.md` maps every channel method to both SDKs.

## Layout

- `lib/src/veepoo_sdk.dart` — public API (`VeepooSDK.instance`). Delegates to the platform interface.
- `lib/src/flutter_veepoo_sdk_platform_interface.dart` / `flutter_veepoo_sdk_method_channel.dart` — abstract contract / MethodChannel + EventChannel implementation.
- `lib/src/models/`, `enums/`, `exceptions/` — Dart data types (`models.dart` is the barrel). Errors surface as `VeepooException`.
- `android/src/main/kotlin/.../VPMethodChannelHandler.kt` — all MethodChannel handlers (`when (call.method)`).
- `.../FlutterVeepooSdkPlugin.kt` — registers channels; streams use EventChannels named `site.shasmatic.flutter_veepoo_sdk/<name>_event_channel`.
- `.../utils/*.kt` — one class per feature (HeartRate, Spoh, BloodPressure, SleepDataReader, OriginDataReader, MiniCheckup, …). `SendEvent.kt` pushes to event sinks. Follow `HeartRate.kt`/`Spoh.kt` when adding a feature.
- `android/libs/*.jar` + `android/src/main/jniLibs/` — vendor binaries (vpprotocol, vpbluetooth, JieLi OTA). Don't edit; `libnative-lib.so` is needed for ECG/HRV (see `android/NATIVE_LIBRARIES.md`).
- `ios/Classes/` — iOS bridge, same channel/method names and map shapes as Android: `FlutterVeepooSdkPlugin.swift` (dispatch + helpers), `VPBluetooth.swift`, `VPDetection.swift` (live tests), `VPDataReader.swift` (sync + stored data, settings), `VPOriginData.swift` (DailyHealthData merge/aggregation).
- `ios/Frameworks/*.framework` — vendor binaries (VeepooBleSDK 2.2.XX.15 + the frameworks the vendor demo links). Don't edit.
- `example/` — demo app, 7 tabs; use it to verify changes on a real watch (BLE can't be emulated).

Adding a feature = 4 touch points kept in sync: platform interface → method channel → `VeepooSDK` → Kotlin handler (+ EventChannel in plugin class if it streams) → model in `lib/src/models/` and export in `models.dart`.

## Docs in root — and which to trust

- `README.md` — user-facing usage, install steps (manifest `tools:replace="android:label"` is required), `OriginHealthData` field reliability table.
- `IMPLEMENTATION_NOTES.md` — **stale**: says most native handlers are unimplemented, but the code and git history show BP, temp, sleep, steps, body/blood component, HRV, mini-checkup, origin data etc. exist. Check the Kotlin handler before believing "API ready only".
- `CHANGELOG.md` — only up to 0.0.6; not maintained for recent work.

## Known gotchas

iOS:
- No compiler on the Windows dev box — Swift is written against the headers + vendor demo; verify on a Mac (Xcode 26.2+, real iPhone; vendor binaries are arm64 device-only).
- Header has no nullability annotations: every SDK value is an implicitly unwrapped optional. Compare SDK enums by `rawValue` (Swift case names like `.BleConnecting` are inconsistent).
- Stored data uses SDK persistence: `veepooSdkStartReadDeviceAllData` syncs into the SDK database, then `VPDataBaseOperation` queries by `yyyy-MM-dd` (Gregorian, POSIX locale — phones may default to the Persian calendar) + MAC. A sync < 60 s old is reused.
- The SDK can't run two commands at once; a test during a sync reports busy.
- Mini Checkup maps to the iOS "Health Glance" test.

Android:

- Vendor `isCurrentDeviceConnected()` / `isDeviceConnected(String)` always return false; connection state is derived from the connected MAC instead.
- HRV `heartRate` is a `String` on the native side (past crash).
- mcumgr deps are pinned (`no.nordicsemi.android:mcumgr-ble/core` 2.7.4) to avoid a compileSdk 37 requirement; missing `mcumgr-ble` caused `NoClassDefFoundError` on connect.
- Raw origin data arrays use `255` as "no reading". Several fields are undocumented by the vendor — don't guess their meaning (see README table).
- minSdk 21; Android 12+ needs `BLUETOOTH_SCAN/CONNECT`, older needs location.

## Commands

- `flutter pub get`, `flutter analyze`, `flutter test` (root)
- `cd example && flutter run` (needs a physical Android device + watch)
- Android unit test stub: `android/src/test/.../FlutterVeepooSdkPluginTest.kt`

## Working notes

- Working tree already has uncommitted changes in `example/android/*`, `example/pubspec.lock`, `lib/src/models.dart`; don't revert them.
- Commits end with the `Co-Authored-By` line configured for this session.
