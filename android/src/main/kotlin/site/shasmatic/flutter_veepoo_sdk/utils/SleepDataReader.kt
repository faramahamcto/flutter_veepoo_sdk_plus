package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IOriginDataListener
import com.veepoo.protocol.listener.data.IOriginProgressListener
import io.flutter.plugin.common.MethodChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for reading sleep data from the device.
 *
 * @constructor Creates a new [SleepDataReader] instance with VPOperateManager.
 * @param result The method channel result to send data back to Flutter.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class SleepDataReader(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
) {

    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Reads sleep data from the device using readOriginData API.
     */
    fun readSleepData() {
        try {
            vpManager.readOriginData(writeResponse, originDataListener, originProgressListener)
        } catch (e: InvocationTargetException) {
            result.error("SLEEP_DATA_ERROR", "Error reading sleep data: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("SLEEP_DATA_ERROR", "Error reading sleep data: ${e.message}", null)
        }
    }

    private val originDataListener = IOriginDataListener { originData ->
        if (originData == null) {
            result.success(null)
            return@IOriginDataListener
        }

        // Extract sleep data from origin data
        val sleepData = originData.sleepData
        if (sleepData != null) {
            val data = mapOf<String, Any?>(
                "totalSleepMinutes" to sleepData.allSleepTime,
                "deepSleepMinutes" to sleepData.deepSleepTime,
                "lightSleepMinutes" to sleepData.lowSleepTime,
                "awakeMinutes" to sleepData.soberTime,
                "sleepQuality" to sleepData.sleepQulity,
                "sleepStartTime" to sleepData.sleepStartTime,
                "sleepEndTime" to sleepData.sleepEndTime,
                "sleepCurve" to sleepData.sleepLine?.toList()
            )
            VPLogger.d("Sleep data received: $sleepData")
            result.success(data)
        } else {
            result.success(null)
        }
    }

    private val originProgressListener = IOriginProgressListener { day ->
        // Progress callback - indicates data is being read
        VPLogger.d("Reading sleep data progress: day $day")
    }
}
