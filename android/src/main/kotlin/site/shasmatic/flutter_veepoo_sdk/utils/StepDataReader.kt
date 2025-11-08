package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IOriginDataListener
import com.veepoo.protocol.listener.data.IOriginProgressListener
import io.flutter.plugin.common.MethodChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for reading step and activity data from the device.
 *
 * @constructor Creates a new [StepDataReader] instance with VPOperateManager.
 * @param result The method channel result to send data back to Flutter.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class StepDataReader(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
) {

    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Reads current step data from the device using readOriginData API.
     */
    fun readStepData() {
        try {
            vpManager.readOriginData(writeResponse, originDataListener, originProgressListener)
        } catch (e: InvocationTargetException) {
            result.error("STEP_DATA_ERROR", "Error reading step data: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("STEP_DATA_ERROR", "Error reading step data: ${e.message}", null)
        }
    }

    /**
     * Reads step data for a specific date.
     * Note: Currently returns the latest available step data as SDK may not support date-specific queries.
     *
     * @param timestamp Date in milliseconds
     */
    fun readStepDataForDate(timestamp: Long) {
        try {
            vpManager.readOriginData(writeResponse, originDataListener, originProgressListener)
        } catch (e: InvocationTargetException) {
            result.error("STEP_DATA_ERROR", "Error reading step data for date: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("STEP_DATA_ERROR", "Error reading step data for date: ${e.message}", null)
        }
    }

    private val originDataListener = IOriginDataListener { originData ->
        if (originData == null) {
            result.success(null)
            return@IOriginDataListener
        }

        // Extract step data from the most recent origin data point
        val allData = originData.originData
        val latestData = allData?.lastOrNull()

        if (latestData != null) {
            val data = mapOf<String, Any?>(
                "steps" to latestData.step,
                "distanceMeters" to (latestData.dis?.toDouble() ?: 0.0),
                "calories" to (latestData.calorie?.toDouble() ?: 0.0),
                "activeMinutes" to null, // Not available in OriginData
                "timestamp" to System.currentTimeMillis()
            )
            VPLogger.d("Step data received: $latestData")
            result.success(data)
        } else {
            result.success(null)
        }
    }

    private val originProgressListener = IOriginProgressListener { day ->
        // Progress callback - indicates data is being read
        VPLogger.d("Reading step data progress: day $day")
    }
}
