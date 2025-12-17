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
import site.shasmatic.flutter_veepoo_sdk.utils.Battery
import site.shasmatic.flutter_veepoo_sdk.utils.BloodComponentDetection
import site.shasmatic.flutter_veepoo_sdk.utils.BloodGlucose
import site.shasmatic.flutter_veepoo_sdk.utils.BloodPressure
import site.shasmatic.flutter_veepoo_sdk.utils.DeviceStorage
import site.shasmatic.flutter_veepoo_sdk.utils.EcgDetection
import site.shasmatic.flutter_veepoo_sdk.utils.HeartRate
import site.shasmatic.flutter_veepoo_sdk.utils.HRVDataReader
import site.shasmatic.flutter_veepoo_sdk.utils.SleepDataReader
import site.shasmatic.flutter_veepoo_sdk.utils.Spoh
import site.shasmatic.flutter_veepoo_sdk.utils.StepDataReader
import site.shasmatic.flutter_veepoo_sdk.utils.Temperature
import site.shasmatic.flutter_veepoo_sdk.utils.VPBluetoothManager

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
    private var detectTemperatureEventSink: EventChannel.EventSink? = null
    private var detectEcgEventSink: EventChannel.EventSink? = null
    private var detectBloodPressureEventSink: EventChannel.EventSink? = null
    private var detectBloodGlucoseEventSink: EventChannel.EventSink? = null
    private var detectBloodComponentEventSink: EventChannel.EventSink? = null
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
            "isDeviceBinded" -> handleIsDeviceBinded()
            "startDetectHeart" -> handleStartDetectHeart()
            "stopDetectHeart" -> handleStopDetectHeart()
            "settingHeartWarning" -> handleSettingHeartWarning(high, low, open)
            "readHeartWarning" -> handleReadHeartWarning()
            "startDetectSpoh" -> handleStartDetectSpoh()
            "stopDetectSpoh" -> handleStopDetectSpoh()
            "readBattery" -> handleReadBattery()
            "getDeviceInfo" -> handleGetDeviceInfo()
            "startDetectTemperature" -> handleStartDetectTemperature()
            "stopDetectTemperature" -> handleStopDetectTemperature()
            "startDetectECG" -> handleStartDetectECG(call.argument<Boolean>("needWaveform") ?: true)
            "stopDetectECG" -> handleStopDetectECG()
            "startDetectEcg" -> handleStartDetectECG(call.argument<Boolean>("needWaveform") ?: true)
            "stopDetectEcg" -> handleStopDetectECG()
            "startDetectBloodPressure" -> handleStartDetectBloodPressure()
            "stopDetectBloodPressure" -> handleStopDetectBloodPressure()
            "startDetectBloodGlucose" -> handleStartDetectBloodGlucose()
            "stopDetectBloodGlucose" -> handleStopDetectBloodGlucose()
            "startDetectBloodComponent" -> handleStartDetectBloodComponent(call.argument<Boolean>("needCalibration") ?: false)
            "stopDetectBloodComponent" -> handleStopDetectBloodComponent()
            "readSleepData" -> handleReadSleepData()
            "readStepData" -> handleReadStepData()
            "readStepDataForDate" -> handleReadStepDataForDate(call.argument<Long>("timestamp"))
            "readHRVData" -> handleReadHRVData(call.argument<Int>("days") ?: 7)
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

    private fun handleIsDeviceBinded() {
        getBluetoothManager(result).isDeviceBinded()
    }

    private fun handleStartDetectHeart() {
        try {
            getHeartRateManager().startDetectHeart()
            result.success(null)
        } catch (e: Exception) {
            result.error("START_HEART_ERROR", "Failed to start heart detection: ${e.message}", null)
        }
    }

    private fun handleStopDetectHeart() {
        try {
            getHeartRateManager().stopDetectHeart()
            result.success(null)
        } catch (e: Exception) {
            result.error("STOP_HEART_ERROR", "Failed to stop heart detection: ${e.message}", null)
        }
    }

    private fun handleSettingHeartWarning(high: Int?, low: Int?, open: Boolean?) {
        if (high != null && low != null && open != null) {
            try {
                getHeartRateManager().settingHeartWarning(high, low, open)
                result.success(null)
            } catch (e: Exception) {
                result.error("HEART_WARNING_ERROR", "Failed to set heart warning: ${e.message}", null)
            }
        } else {
            result.error("INVALID_ARGUMENT", "High, low, and open values are required", null)
        }
    }

    private fun handleReadHeartWarning() {
        try {
            getHeartRateManager().readHeartWarning()
            result.success(null)
        } catch (e: Exception) {
            result.error("READ_HEART_WARNING_ERROR", "Failed to read heart warning: ${e.message}", null)
        }
    }

    private fun handleStartDetectSpoh() {
        try {
            getSPOHManager().startDetectSpoh()
            result.success(null)
        } catch (e: Exception) {
            result.error("START_SPOH_ERROR", "Failed to start SpO2 detection: ${e.message}", null)
        }
    }

    private fun handleStopDetectSpoh() {
        try {
            getSPOHManager().stopDetectSpoh()
            result.success(null)
        } catch (e: Exception) {
            result.error("STOP_SPOH_ERROR", "Failed to stop SpO2 detection: ${e.message}", null)
        }
    }

    private fun handleReadBattery() {
        getBatteryManager(result).readBattery()
    }

    private fun handleGetDeviceInfo() {
        try {
            // Get basic device information from connected GATT
            val address = vpManager.currentConnectGatt?.device?.address
            val name = vpManager.currentConnectGatt?.device?.name

            val deviceInfo = mapOf<String, Any?>(
                "modelName" to (name ?: "Unknown"),
                "hardwareVersion" to "Unknown",
                "softwareVersion" to "Unknown",
                "macAddress" to (address ?: "Unknown"),
                "manufacturer" to "Veepoo"
            )
            result.success(deviceInfo)
        } catch (e: Exception) {
            result.error("DEVICE_INFO_ERROR", "Failed to get device info: ${e.message}", null)
        }
    }

    private fun handleStartDetectTemperature() {
        try {
            getTemperatureManager().startDetectTemperature()
            result.success(null)
        } catch (e: Exception) {
            result.error("START_TEMPERATURE_ERROR", "Failed to start temperature detection: ${e.message}", null)
        }
    }

    private fun handleStopDetectTemperature() {
        try {
            getTemperatureManager().stopDetectTemperature()
            result.success(null)
        } catch (e: Exception) {
            result.error("STOP_TEMPERATURE_ERROR", "Failed to stop temperature detection: ${e.message}", null)
        }
    }

    private fun handleStartDetectECG(needWaveform: Boolean) {
        try {
            getEcgManager().startDetectECG(needWaveform)
            result.success(null)
        } catch (e: Exception) {
            result.error("START_ECG_ERROR", "Failed to start ECG detection: ${e.message}", null)
        }
    }

    private fun handleStopDetectECG() {
        try {
            getEcgManager().stopDetectECG()
            result.success(null)
        } catch (e: Exception) {
            result.error("STOP_ECG_ERROR", "Failed to stop ECG detection: ${e.message}", null)
        }
    }

    private fun handleStartDetectBloodPressure() {
        try {
            getBloodPressureManager().startDetectBloodPressure()
            result.success(null)
        } catch (e: Exception) {
            result.error("START_BP_ERROR", "Failed to start blood pressure detection: ${e.message}", null)
        }
    }

    private fun handleStopDetectBloodPressure() {
        try {
            getBloodPressureManager().stopDetectBloodPressure()
            result.success(null)
        } catch (e: Exception) {
            result.error("STOP_BP_ERROR", "Failed to stop blood pressure detection: ${e.message}", null)
        }
    }

    private fun handleStartDetectBloodGlucose() {
        try {
            getBloodGlucoseManager().startDetectBloodGlucose()
            result.success(null)
        } catch (e: Exception) {
            result.error("START_GLUCOSE_ERROR", "Failed to start blood glucose detection: ${e.message}", null)
        }
    }

    private fun handleStopDetectBloodGlucose() {
        try {
            getBloodGlucoseManager().stopDetectBloodGlucose()
            result.success(null)
        } catch (e: Exception) {
            result.error("STOP_GLUCOSE_ERROR", "Failed to stop blood glucose detection: ${e.message}", null)
        }
    }

    private fun handleReadSleepData() {
        getSleepDataReader().readSleepData()
    }

    private fun handleReadStepData() {
        getStepDataReader().readStepData()
    }

    private fun handleReadStepDataForDate(timestamp: Long?) {
        if (timestamp != null) {
            getStepDataReader().readStepDataForDate(timestamp)
        } else {
            result.error("INVALID_ARGUMENT", "Timestamp is required", null)
        }
    }

    private fun handleStartDetectBloodComponent(needCalibration: Boolean) {
        try {
            getBloodComponentManager().startDetectBloodComponent(needCalibration)
            result.success(null)
        } catch (e: Exception) {
            result.error("START_BLOOD_COMPONENT_ERROR", "Failed to start blood component detection: ${e.message}", null)
        }
    }

    private fun handleStopDetectBloodComponent() {
        try {
            getBloodComponentManager().stopDetectBloodComponent()
            result.success(null)
        } catch (e: Exception) {
            result.error("STOP_BLOOD_COMPONENT_ERROR", "Failed to stop blood component detection: ${e.message}", null)
        }
    }

    private fun handleReadHRVData(days: Int) {
        try {
            getHRVDataReader().readHRVData(days)
        } catch (e: Exception) {
            result.error("READ_HRV_ERROR", "Failed to read HRV data: ${e.message}", null)
        }
    }

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

    fun setDetectTemperatureEventSink(eventSink: EventChannel.EventSink?) {
        this.detectTemperatureEventSink = eventSink
    }

    fun setDetectEcgEventSink(eventSink: EventChannel.EventSink?) {
        this.detectEcgEventSink = eventSink
    }

    fun setDetectBloodPressureEventSink(eventSink: EventChannel.EventSink?) {
        this.detectBloodPressureEventSink = eventSink
    }

    fun setDetectBloodGlucoseEventSink(eventSink: EventChannel.EventSink?) {
        this.detectBloodGlucoseEventSink = eventSink
    }

    fun setDetectBloodComponentEventSink(eventSink: EventChannel.EventSink?) {
        this.detectBloodComponentEventSink = eventSink
    }

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

    private fun getTemperatureManager(): Temperature {
        return Temperature(detectTemperatureEventSink, vpManager)
    }

    private fun getEcgManager(): EcgDetection {
        return EcgDetection(detectEcgEventSink, vpManager)
    }

    private fun getBloodPressureManager(): BloodPressure {
        return BloodPressure(detectBloodPressureEventSink, vpManager)
    }

    private fun getBloodGlucoseManager(): BloodGlucose {
        return BloodGlucose(detectBloodGlucoseEventSink, vpManager)
    }

    private fun getSleepDataReader(): SleepDataReader {
        return SleepDataReader(result, vpManager)
    }

    private fun getStepDataReader(): StepDataReader {
        return StepDataReader(result, vpManager)
    }

    private fun getBloodComponentManager(): BloodComponentDetection {
        return BloodComponentDetection(detectBloodComponentEventSink, vpManager)
    }

    private fun getHRVDataReader(): HRVDataReader {
        return HRVDataReader(result, vpManager)
    }
}