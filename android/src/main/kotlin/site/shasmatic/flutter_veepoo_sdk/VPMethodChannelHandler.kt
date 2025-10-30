package site.shasmatic.flutter_veepoo_sdk

import android.app.Activity
import android.os.Build
import androidx.annotation.RequiresApi
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.shareprence.VpSpGetUtil
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import site.shasmatic.flutter_veepoo_sdk.utils.*

/**
 * Handles method calls from Flutter to perform various operations related to Bluetooth management,
 * heart rate detection, and blood oxygen (SpO2) detection.
 *
 * @constructor Initializes the [VPMethodChannelHandler] with the given [VPOperateManager], [VpSpGetUtil], and [DeviceStorage].
 * @param vpManager An instance of [VPOperateManager] used to control operations on the wearable device.
 * @param vpSpGetUtil An instance of [VpSpGetUtil] used to access shared preferences for device settings.
 * @param deviceStorage An instance of [DeviceStorage] used for local storage interactions.
 */
class VPMethodChannelHandler(
    private val vpManager: VPOperateManager,
    private val vpSpGetUtil: VpSpGetUtil,
    private val deviceStorage: DeviceStorage,
): MethodChannel.MethodCallHandler, PluginRegistry.RequestPermissionsResultListener {

    private var activity: Activity? = null
    private var scanBluetoothEventSink: EventChannel.EventSink? = null
    private var detectHeartEventSink: EventChannel.EventSink? = null
    private var detectSpohEventSink: EventChannel.EventSink? = null
    private var detectBloodPressureEventSink: EventChannel.EventSink? = null
    private var detectTemperatureEventSink: EventChannel.EventSink? = null
    private var detectBloodGlucoseEventSink: EventChannel.EventSink? = null
    private var detectEcgEventSink: EventChannel.EventSink? = null
    private var stepDataEventSink: EventChannel.EventSink? = null
    private lateinit var result: MethodChannel.Result

    @RequiresApi(Build.VERSION_CODES.S)
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val address = call.argument<String>("address")
        val password = call.argument<String>("password")
        val is24H = call.argument<Boolean>("is24H")
        val high = call.argument<Int>("high")
        val low = call.argument<Int>("low")
        val open = call.argument<Boolean>("open")
        this.result = result

        when(call.method) {
            "requestBluetoothPermissions" -> handleRequestBluetoothPermissions()
            "openAppSettings" -> handleOpenAppSettings()
            "isBluetoothEnabled" -> handleIsBluetoothEnabled()
            "openBluetooth" -> handleOpenBluetooth()
            "closeBluetooth" -> handleCloseBluetooth()
            "scanDevices" -> handleScanDevices()
            "stopScanDevices" -> handleStopScanDevices()
            "connectDevice" -> handleConnectDevice(address)
            "bindDevice" -> handleBindDevice(password, is24H)
            "disconnectDevice" -> handleDisconnectDevice()
            "getAddress" -> handleGetAddress()
            "getCurrentStatus" -> handleGetCurrentStatus()
            "isDeviceConnected" -> handleIsDeviceConnected()
            "startDetectHeart" -> handleStartDetectHeart()
            "stopDetectHeart" -> handleStopDetectHeart()
            "settingHeartWarning" -> handleSettingHeartWarning(high, low, open)
            "readHeartWarning" -> handleReadHeartWarning()
            "startDetectSpoh" -> handleStartDetectSpoh()
            "stopDetectSpoh" -> handleStopDetectSpoh()
            "readBattery" -> handleReadBattery()
            // Blood Pressure
            "startDetectBloodPressure" -> handleStartDetectBloodPressure()
            "stopDetectBloodPressure" -> handleStopDetectBloodPressure()
            "setBloodPressureAlarm" -> handleSetBloodPressureAlarm(call)
            "readBloodPressure" -> handleReadBloodPressure()
            // Temperature
            "startDetectTemperature" -> handleStartDetectTemperature()
            "stopDetectTemperature" -> handleStopDetectTemperature()
            "readTemperature" -> handleReadTemperature()
            "readTemperatureHistory" -> handleReadTemperatureHistory(call)
            // Blood Glucose
            "startDetectBloodGlucose" -> handleStartDetectBloodGlucose()
            "stopDetectBloodGlucose" -> handleStopDetectBloodGlucose()
            "setBloodGlucoseCalibration" -> handleSetBloodGlucoseCalibration(call)
            "readBloodGlucose" -> handleReadBloodGlucose()
            // ECG
            "startDetectEcg" -> handleStartDetectEcg()
            "stopDetectEcg" -> handleStopDetectEcg()
            "readEcgData" -> handleReadEcgData()
            // Sleep & Steps
            "readSleepData" -> handleReadSleepData()
            "readSleepHistory" -> handleReadSleepHistory(call)
            "readStepData" -> handleReadStepData()
            "readStepDataForDate" -> handleReadStepDataForDate(call)
            "readStepHistory" -> handleReadStepHistory(call)
            // Device Info & Settings
            "getDeviceInfo" -> handleGetDeviceInfo()
            "setUserProfile" -> handleSetUserProfile(call)
            "getUserProfile" -> handleGetUserProfile()
            "setDeviceSettings" -> handleSetDeviceSettings(call)
            "getDeviceSettings" -> handleGetDeviceSettings()
            "setScreenBrightness" -> handleSetScreenBrightness(call)
            "setScreenDuration" -> handleSetScreenDuration(call)
            "setTimeFormat" -> handleSetTimeFormat(call)
            "setLanguage" -> handleSetLanguage(call)
            "setWristRaiseToWake" -> handleSetWristRaiseToWake(call)
            "setDoNotDisturb" -> handleSetDoNotDisturb(call)
            // Historical Data
            "readHeartRateHistory" -> handleReadHeartRateHistory(call)
            "readBloodPressureHistory" -> handleReadBloodPressureHistory(call)
            else -> result.notImplemented()
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String?>, grantResults: IntArray): Boolean {
        getBluetoothManager(result).onRequestPermissionsResult(requestCode, grantResults)
        return true
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun handleRequestBluetoothPermissions() {
        getBluetoothManager(result).requestBluetoothPermissions()
    }

    private fun handleOpenAppSettings() {
        getBluetoothManager(result).openAppSettings()
    }

    private fun handleIsBluetoothEnabled() {
        getBluetoothManager(result).isBluetoothEnabled()
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun handleOpenBluetooth() {
        getBluetoothManager(result).openBluetooth()
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun handleCloseBluetooth() {
        getBluetoothManager(result).closeBluetooth()
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun handleScanDevices() {
        getBluetoothManager(result).scanDevices()
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun handleStopScanDevices() {
        getBluetoothManager(result).stopScanDevices()
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun handleConnectDevice(address: String?) {
        if (address != null) {
            getBluetoothManager(result).connectDevice(address)
        } else {
            result.error("INVALID_ARGUMENT", "MAC address is required", null)
        }
    }

    private fun handleBindDevice(password: String?, is24H: Boolean?) {
        if (password != null && is24H != null) {
            getBluetoothManager(result).bindDevice(password, is24H)
        } else {
            result.error("INVALID_ARGUMENT", "Password and 24-hour mode are required", null)
        }
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun handleDisconnectDevice() {
        getBluetoothManager(result).disconnectDevice()
    }

    private fun handleGetAddress() {
        getBluetoothManager(result).getAddress()
    }

    private fun handleGetCurrentStatus() {
        getBluetoothManager(result).getCurrentStatus()
    }

    private fun handleIsDeviceConnected() {
        getBluetoothManager(result).isDeviceConnected()
    }

    private fun handleStartDetectHeart() {
        getHeartRateManager().startDetectHeart()
    }

    private fun handleStopDetectHeart() {
        getHeartRateManager().stopDetectHeart()
    }

    private fun handleSettingHeartWarning(high: Int?, low: Int?, open: Boolean?) {
        if (high != null && low != null && open != null) {
            getHeartRateManager().settingHeartWarning(high, low, open)
        } else {
            result.error("INVALID_ARGUMENT", "High, low, and open values are required", null)
        }
    }

    private fun handleReadHeartWarning() {
        getHeartRateManager().readHeartWarning()
    }

    private fun handleStartDetectSpoh() {
        getSPOHManager().startDetectSpoh()
    }

    private fun handleStopDetectSpoh() {
        getSPOHManager().stopDetectSpoh()
    }

    private fun handleReadBattery() {
        getBatteryManager(result).readBattery()
    }

    // ==================== Blood Pressure Handlers ====================

    private fun handleStartDetectBloodPressure() {
        getBloodPressureManager().startDetectBloodPressure()
        result.success(null)
    }

    private fun handleStopDetectBloodPressure() {
        getBloodPressureManager().stopDetectBloodPressure()
        result.success(null)
    }

    private fun handleSetBloodPressureAlarm(call: MethodCall) {
        val systolicHigh = call.argument<Int>("systolicHigh") ?: 0
        val systolicLow = call.argument<Int>("systolicLow") ?: 0
        val diastolicHigh = call.argument<Int>("diastolicHigh") ?: 0
        val diastolicLow = call.argument<Int>("diastolicLow") ?: 0
        val enabled = call.argument<Boolean>("enabled") ?: false
        getBloodPressureManager().setBloodPressureAlarm(systolicHigh, systolicLow, diastolicHigh, diastolicLow, enabled)
        result.success(null)
    }

    private fun handleReadBloodPressure() {
        result.notImplemented()
    }

    // ==================== Temperature Handlers ====================

    private fun handleStartDetectTemperature() {
        getTemperatureManager().startDetectTemperature()
        result.success(null)
    }

    private fun handleStopDetectTemperature() {
        getTemperatureManager().stopDetectTemperature()
        result.success(null)
    }

    private fun handleReadTemperature() {
        result.notImplemented()
    }

    private fun handleReadTemperatureHistory(call: MethodCall) {
        result.notImplemented()
    }

    // ==================== Blood Glucose Handlers ====================

    private fun handleStartDetectBloodGlucose() {
        getBloodGlucoseManager().startDetectBloodGlucose()
        result.success(null)
    }

    private fun handleStopDetectBloodGlucose() {
        getBloodGlucoseManager().stopDetectBloodGlucose()
        result.success(null)
    }

    private fun handleSetBloodGlucoseCalibration(call: MethodCall) {
        val enabled = call.argument<Boolean>("enabled") ?: false
        getBloodGlucoseManager().setBloodGlucoseCalibration(enabled)
        result.success(null)
    }

    private fun handleReadBloodGlucose() {
        result.notImplemented()
    }

    // ==================== ECG Handlers ====================

    private fun handleStartDetectEcg() {
        getEcgManager().startDetectEcg()
        result.success(null)
    }

    private fun handleStopDetectEcg() {
        getEcgManager().stopDetectEcg()
        result.success(null)
    }

    private fun handleReadEcgData() {
        result.notImplemented()
    }

    // ==================== Sleep Data Handlers ====================

    private fun handleReadSleepData() {
        val sleepData = getSleepDataReader().readSleepData()
        result.success(sleepData)
    }

    private fun handleReadSleepHistory(call: MethodCall) {
        val startTimestamp = call.argument<Long>("startTimestamp") ?: 0L
        val endTimestamp = call.argument<Long>("endTimestamp") ?: 0L
        val history = getSleepDataReader().readSleepHistory(startTimestamp, endTimestamp)
        result.success(history)
    }

    // ==================== Step Data Handlers ====================

    private fun handleReadStepData() {
        val stepData = getStepDataReader().readStepData()
        result.success(stepData)
    }

    private fun handleReadStepDataForDate(call: MethodCall) {
        val timestamp = call.argument<Long>("timestamp") ?: 0L
        val stepData = getStepDataReader().readStepDataForDate(timestamp)
        result.success(stepData)
    }

    private fun handleReadStepHistory(call: MethodCall) {
        val startTimestamp = call.argument<Long>("startTimestamp") ?: 0L
        val endTimestamp = call.argument<Long>("endTimestamp") ?: 0L
        val history = getStepDataReader().readStepHistory(startTimestamp, endTimestamp)
        result.success(history)
    }

    // ==================== Device Info & Settings Handlers ====================

    private fun handleGetDeviceInfo() {
        val deviceInfo = getDeviceInfoReader().getDeviceInfo()
        result.success(deviceInfo)
    }

    private fun handleSetUserProfile(call: MethodCall) {
        val profileMap = call.arguments as? Map<String, Any?> ?: emptyMap()
        getUserProfileManager().setUserProfile(profileMap)
        result.success(null)
    }

    private fun handleGetUserProfile() {
        val profile = getUserProfileManager().getUserProfile()
        result.success(profile)
    }

    private fun handleSetDeviceSettings(call: MethodCall) {
        val settingsMap = call.arguments as? Map<String, Any?> ?: emptyMap()
        getDeviceConfiguration().setDeviceSettings(settingsMap)
        result.success(null)
    }

    private fun handleGetDeviceSettings() {
        val settings = getDeviceConfiguration().getDeviceSettings()
        result.success(settings)
    }

    private fun handleSetScreenBrightness(call: MethodCall) {
        val brightness = call.argument<Int>("brightness") ?: 3
        getDeviceConfiguration().setScreenBrightness(brightness)
        result.success(null)
    }

    private fun handleSetScreenDuration(call: MethodCall) {
        val seconds = call.argument<Int>("seconds") ?: 10
        getDeviceConfiguration().setScreenDuration(seconds)
        result.success(null)
    }

    private fun handleSetTimeFormat(call: MethodCall) {
        val is24Hour = call.argument<Boolean>("is24Hour") ?: true
        getDeviceConfiguration().setTimeFormat(is24Hour)
        result.success(null)
    }

    private fun handleSetLanguage(call: MethodCall) {
        val languageCode = call.argument<String>("languageCode") ?: "en"
        getDeviceConfiguration().setLanguage(languageCode)
        result.success(null)
    }

    private fun handleSetWristRaiseToWake(call: MethodCall) {
        val enabled = call.argument<Boolean>("enabled") ?: false
        val sensitivity = call.argument<Int>("sensitivity") ?: 1
        getDeviceConfiguration().setWristRaiseToWake(enabled, sensitivity)
        result.success(null)
    }

    private fun handleSetDoNotDisturb(call: MethodCall) {
        val enabled = call.argument<Boolean>("enabled") ?: false
        val startMinutes = call.argument<Int>("startMinutes") ?: 0
        val endMinutes = call.argument<Int>("endMinutes") ?: 0
        getDeviceConfiguration().setDoNotDisturb(enabled, startMinutes, endMinutes)
        result.success(null)
    }

    // ==================== Historical Data Handlers ====================

    private fun handleReadHeartRateHistory(call: MethodCall) {
        result.notImplemented()
    }

    private fun handleReadBloodPressureHistory(call: MethodCall) {
        result.notImplemented()
    }

    // ==================== Setters ====================

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    fun setScanBluetoothEventSink(eventSink: EventChannel.EventSink?) {
        this.scanBluetoothEventSink = eventSink
    }

    fun setDetectHeartEventSink(eventSink: EventChannel.EventSink?) {
        this.detectHeartEventSink = eventSink
    }

    fun setDetectSpohEventSink(eventSink: EventChannel.EventSink?) {
        this.detectSpohEventSink = eventSink
    }

    fun setDetectBloodPressureEventSink(eventSink: EventChannel.EventSink?) {
        this.detectBloodPressureEventSink = eventSink
    }

    fun setDetectTemperatureEventSink(eventSink: EventChannel.EventSink?) {
        this.detectTemperatureEventSink = eventSink
    }

    fun setDetectBloodGlucoseEventSink(eventSink: EventChannel.EventSink?) {
        this.detectBloodGlucoseEventSink = eventSink
    }

    fun setDetectEcgEventSink(eventSink: EventChannel.EventSink?) {
        this.detectEcgEventSink = eventSink
    }

    fun setStepDataEventSink(eventSink: EventChannel.EventSink?) {
        this.stepDataEventSink = eventSink
    }

    // ==================== Manager Getters ====================

    private fun getBluetoothManager(result: MethodChannel.Result): VPBluetoothManager {
        return VPBluetoothManager(deviceStorage, result, activity!!, scanBluetoothEventSink, vpManager)
    }

    private fun getHeartRateManager(): HeartRate {
        return HeartRate(detectHeartEventSink, vpManager)
    }

    private fun getSPOHManager(): Spoh {
        return Spoh(detectSpohEventSink, vpSpGetUtil, vpManager)
    }

    private fun getBatteryManager(result: MethodChannel.Result): Battery {
        return Battery(result, vpManager)
    }

    private fun getBloodPressureManager(): BloodPressure {
        return BloodPressure(detectBloodPressureEventSink, vpManager)
    }

    private fun getTemperatureManager(): Temperature {
        return Temperature(detectTemperatureEventSink, vpManager)
    }

    private fun getBloodGlucoseManager(): BloodGlucose {
        return BloodGlucose(detectBloodGlucoseEventSink, vpManager)
    }

    private fun getEcgManager(): EcgDetection {
        return EcgDetection(detectEcgEventSink, vpManager)
    }

    private fun getSleepDataReader(): SleepDataReader {
        return SleepDataReader(vpManager)
    }

    private fun getStepDataReader(): StepDataReader {
        return StepDataReader(stepDataEventSink, vpManager)
    }

    private fun getDeviceConfiguration(): DeviceConfiguration {
        return DeviceConfiguration(vpManager)
    }

    private fun getUserProfileManager(): UserProfileManager {
        return UserProfileManager(vpManager)
    }

    private fun getDeviceInfoReader(): DeviceInfoReader {
        return DeviceInfoReader(vpManager)
    }
}