package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IDeviceInfoListener
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for reading device information.
 *
 * @constructor Creates a new [DeviceInfoReader] instance with VPOperateManager.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class DeviceInfoReader(
    private val vpManager: VPOperateManager,
) {

    private val writeResponse: VPWriteResponse = VPWriteResponse()
    private var deviceInfoData: Map<String, Any?>? = null

    /**
     * Gets device information.
     *
     * @return Map containing device information
     */
    fun getDeviceInfo(): Map<String, Any?>? {
        executeInfoOperation {
            vpManager.readDeviceInfo(writeResponse, deviceInfoListener)
        }

        // Wait for data
        Thread.sleep(1000)

        return deviceInfoData
    }

    private fun executeInfoOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            throw VPException("Error reading device info: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            throw VPException("Error reading device info: ${e.message}", e.cause)
        }
    }

    private val deviceInfoListener = IDeviceInfoListener { deviceInfo ->
        if (deviceInfo != null) {
            deviceInfoData = mapOf(
                "modelName" to deviceInfo.deviceName,
                "hardwareVersion" to deviceInfo.hardwareVersion,
                "softwareVersion" to deviceInfo.softwareVersion,
                "serialNumber" to deviceInfo.deviceNumber,
                "macAddress" to deviceInfo.deviceAddress,
                "manufacturer" to "Veepoo",
                "batteryLevel" to deviceInfo.batteryLevel,
                "isCharging" to deviceInfo.isCharging,
                "screenWidth" to deviceInfo.screenWidth,
                "screenHeight" to deviceInfo.screenHeight,
                "supportedFeatures" to deviceInfo.supportFunctions
            )
            VPLogger.d("Device info received: $deviceInfo")
        }
    }
}
