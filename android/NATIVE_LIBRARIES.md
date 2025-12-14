# Native Library Requirements for Veepoo SDK

## Missing Native Library for ECG Feature

### Issue
The ECG (Electrocardiogram) feature requires a native JNI library called `libnative-lib.so` that is **not included** in the current SDK package.

### Error Message
```
java.lang.UnsatisfiedLinkError: ... couldn't find "libnative-lib.so"
at com.vp.cso.hrvreport.JNIChange.<clinit>
```

### Root Cause
The ECG functionality uses HRV (Heart Rate Variability) processing that requires native C/C++ code compiled as:
- `libnative-lib.so` for ARM64 (`arm64-v8a`)
- `libnative-lib.so` for ARMv7 (`armeabi-v7a`)
- `libnative-lib.so` for x86 (`x86`)
- `libnative-lib.so` for x86_64 (`x86_64`)

### Solution

#### Option 1: Contact SDK Vendor (Recommended)
Contact the Veepoo SDK provider to obtain the complete SDK package including:
- All JAR files (already present)
- **All native libraries** (.so files for ECG/HRV processing)

Request specifically:
- `libnative-lib.so` for all architectures (arm64-v8a, armeabi-v7a, x86, x86_64)

#### Option 2: Place Native Libraries Manually
If you obtain the `libnative-lib.so` files, place them in:

```
android/src/main/jniLibs/
├── arm64-v8a/
│   └── libnative-lib.so
├── armeabi-v7a/
│   └── libnative-lib.so
├── x86/
│   └── libnative-lib.so
└── x86_64/
    └── libnative-lib.so
```

#### Option 3: Disable ECG Feature
If ECG is not needed, you can simply not call the ECG methods:
- `startDetectEcg()`
- `stopDetectEcg()`
- `readEcgData()`

All other features (heart rate, SpO2, blood pressure, blood glucose, temperature, sleep, steps) work fine without this library.

## Current Native Libraries (Working)

The following native libraries are already present and working:

### JL (JieLi) Libraries
- `libjl_auth.so` - Authentication
- `libjl_bmp_convert.so` - Bitmap conversion
- `libjl_crc.so` - CRC checking
- `libjl_fatfs.so` - FAT file system
- `libjl_ota_auth.so` - OTA update authentication
- `libjl_pack_format.so` - Data packing

These are located in:
```
android/src/main/jniLibs/
├── arm64-v8a/
├── armeabi-v7a/
├── x86/
└── x86_64/
```

## Features Status

| Feature | Status | Native Library Required |
|---------|--------|------------------------|
| Heart Rate | ✅ Working | None |
| SpO2 | ✅ Working | None |
| Blood Pressure | ✅ Working | None |
| Blood Glucose | ✅ Working | None |
| Temperature | ✅ Working | None |
| Sleep Data | ✅ Working | None |
| Step Counting | ✅ Working | None |
| **ECG** | ❌ **Missing Library** | **libnative-lib.so** |

## Error Handling

The SDK now includes proper error handling for the missing library. When attempting to use ECG without the library, you'll receive a clear error message:

```dart
VeepooException: ECG feature requires native library 'libnative-lib.so' which is missing.
This library should be provided by the Veepoo SDK vendor.
Please contact the SDK provider to obtain the complete SDK package with native libraries for ECG support.
```

## Next Steps

1. **Contact Veepoo SDK vendor** for the complete SDK package
2. **Request `libnative-lib.so`** for all architectures
3. **Place libraries** in the jniLibs directory as shown above
4. **Rebuild** the Flutter app
5. **Test ECG** functionality

## Support

For SDK-related issues, contact the Veepoo SDK provider directly.
For plugin integration issues, create an issue on the GitHub repository.
