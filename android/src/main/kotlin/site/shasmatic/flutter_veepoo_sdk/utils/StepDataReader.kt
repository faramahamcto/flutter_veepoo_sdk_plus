package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IOriginDataListener
import com.veepoo.protocol.model.datas.OriginData
import com.veepoo.protocol.model.datas.OriginHalfHourData
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
    private var latestStepData: Map<String, Any?>? = null

    /**
     * Reads current step data from the device using readOriginData API.
     * Reads origin data for the last 7 days and returns the most recent.
     */
    fun readStepData() {
        try {
            // Read origin data for last 7 days
            vpManager.readOriginData(writeResponse, originDataListener, 7)
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
            // For now, just read the most recent data
            // TODO: Could use readOriginDataSingleDay with proper date conversion
            vpManager.readOriginData(writeResponse, originDataListener, 7)
        } catch (e: InvocationTargetException) {
            result.error("STEP_DATA_ERROR", "Error reading step data for date: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("STEP_DATA_ERROR", "Error reading step data for date: ${e.message}", null)
        }
    }

    private val originDataListener = object : IOriginDataListener {
        override fun onOringinFiveMinuteDataChange(originData: OriginData?) {
            if (originData != null) {
                // Update the latest step data
                latestStepData = mapOf<String, Any?>(
                    "steps" to originData.stepValue,
                    "distanceMeters" to originData.disValue,
                    "calories" to originData.calValue,
                    "activeMinutes" to null, // Not directly available
                    "heartRate" to originData.rateValue,
                    "timestamp" to System.currentTimeMillis(),
                    "date" to originData.date
                )
                VPLogger.d("Step data received: steps=${originData.stepValue}, distance=${originData.disValue}, calories=${originData.calValue}")
            }
        }

        override fun onOringinHalfHourDataChange(originData: OriginHalfHourData?) {
            // Not used for step data (we use five-minute data instead)
        }

        override fun onReadOriginProgressDetail(day: Int, date: String?, allPackage: Int, currentPackage: Int) {
            VPLogger.d("Reading origin data progress for $date: $currentPackage/$allPackage (day $day)")
        }

        override fun onReadOriginProgress(progress: Float) {
            VPLogger.d("Reading origin data progress: $progress%")
        }

        override fun onReadOriginComplete() {
            VPLogger.d("Origin data read complete")
            // Return the most recent step data when reading is complete
            if (latestStepData != null) {
                result.success(latestStepData)
            } else {
                result.success(null)
            }
        }
    }
}
