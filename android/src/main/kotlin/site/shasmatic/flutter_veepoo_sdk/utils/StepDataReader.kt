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

    private val originDataListener = object : IOriginDataListener {
        override fun onOrinReadOriginProgress(day: Int) {
            // Progress callback - indicates data is being read
            VPLogger.d("Reading step data progress: day $day")
        }

        override fun onOrinReadOriginComplete() {
            VPLogger.d("Origin data read complete")
        }

        override fun onOriginFiveMinuteDataChange(originData: com.veepoo.protocol.model.datas.OriginData?) {
            if (originData == null) {
                result.success(null)
                return
            }

            // Extract step data from the most recent five-minute data point
            val fiveMinData = originData.originDataList
            val latestData = fiveMinData?.lastOrNull()

            if (latestData != null) {
                val data = mapOf<String, Any?>(
                    "steps" to (latestData.step ?: 0),
                    "distanceMeters" to ((latestData.dis ?: 0) * 10.0), // dis is in 0.01m units
                    "calories" to ((latestData.calorie ?: 0).toDouble()),
                    "activeMinutes" to null, // Not available in OriginData
                    "timestamp" to System.currentTimeMillis()
                )
                VPLogger.d("Step data received: $latestData")
                result.success(data)
            } else {
                result.success(null)
            }
        }

        override fun onOriginHalfHourDataChange(originData: com.veepoo.protocol.model.datas.OriginHalfHourData?) {
            // Not used for step data (we use five-minute data instead)
        }
    }

    private val originProgressListener = object : com.veepoo.protocol.listener.data.IOriginProgressListener {
        override fun onOrinReadOriginProgress(day: Int) {
            VPLogger.d("Reading step data progress: day $day")
        }

        override fun onOrinReadOriginComplete() {
            VPLogger.d("Origin data read complete")
        }
    }
}
