package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IOriginDataListener
import com.veepoo.protocol.listener.data.IOriginProgressListener
import io.flutter.plugin.common.MethodChannel
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for reading origin health data (sleep, steps, etc.).
 *
 * @constructor Creates a new [OriginDataReader] instance with [VPOperateManager] and result channel.
 * @param result The result channel to return data to Flutter.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class OriginDataReader(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
) {

    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Reads the latest sleep data.
     */
    fun readSleepData() {
        executeDataOperation {
            vpManager.readOriginData(writeResponse, originDataListener, originProgressListener)
        }
    }

    /**
     * Reads the latest step data.
     */
    fun readStepData() {
        executeDataOperation {
            vpManager.readOriginData(writeResponse, originDataListener, originProgressListener)
        }
    }

    private fun executeDataOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            result.error("OPERATION_ERROR", "Error during data read: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("OPERATION_ERROR", "Error during data read: ${e.message}", null)
        }
    }

    private val originDataListener = IOriginDataListener { originData ->
        if (originData == null) {
            result.error("NO_DATA", "No origin data available", null)
            return@IOriginDataListener
        }

        // Extract sleep data
        val sleepData = originData.sleepData
        val sleepResult = if (sleepData != null) {
            mapOf<String, Any?>(
                "totalSleepMinutes" to sleepData.allSleepTime,
                "deepSleepMinutes" to sleepData.deepSleepTime,
                "lightSleepMinutes" to sleepData.lowSleepTime,
                "awakeMinutes" to sleepData.soberTime,
                "sleepQuality" to sleepData.sleepQulity,
                "sleepStartTime" to sleepData.sleepStartTime,
                "sleepEndTime" to sleepData.sleepEndTime,
                "sleepCurve" to sleepData.sleepLine?.toList()
            )
        } else null

        // Extract step data from the most recent data point
        val allData = originData.originData
        val latestData = allData?.lastOrNull()
        val stepResult = if (latestData != null) {
            mapOf<String, Any?>(
                "steps" to latestData.step,
                "distanceMeters" to (latestData.dis?.toDouble() ?: 0.0),
                "calories" to (latestData.calorie?.toDouble() ?: 0.0),
                "activeMinutes" to null, // Not available in OriginData
                "timestamp" to System.currentTimeMillis()
            )
        } else null

        // Return both sleep and step data
        val resultData = mapOf<String, Any?>(
            "sleepData" to sleepResult,
            "stepData" to stepResult,
            "hasData" to true
        )

        result.success(resultData)
    }

    private val originProgressListener = IOriginProgressListener { day ->
        // Progress callback - could be used to show progress to user
        // For now, we'll just log it
    }
}
