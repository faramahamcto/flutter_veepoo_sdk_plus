package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.ISleepDataListener
import com.veepoo.protocol.model.datas.SleepData
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
    private var latestSleepData: Map<String, Any?>? = null
    private var hasReturnedResult = false

    /**
     * Reads sleep data from the device using readSleepData API.
     * Reads sleep data for the last 7 days.
     */
    fun readSleepData() {
        try {
            // Read sleep data for last 7 days
            vpManager.readSleepData(writeResponse, sleepDataListener, 7)
        } catch (e: InvocationTargetException) {
            result.error("SLEEP_DATA_ERROR", "Error reading sleep data: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("SLEEP_DATA_ERROR", "Error reading sleep data: ${e.message}", null)
        }
    }

    private val sleepDataListener = object : ISleepDataListener {
        override fun onSleepDataChange(date: String?, sleepData: SleepData?) {
            if (sleepData != null) {
                // Store the most recent sleep data (will be overwritten if newer data comes)
                latestSleepData = mapOf<String, Any?>(
                    "totalSleepMinutes" to sleepData.allSleepTime,
                    "deepSleepMinutes" to sleepData.deepSleepTime,
                    "lightSleepMinutes" to sleepData.lowSleepTime,
                    "awakeMinutes" to 0, // SDK doesn't provide awake time, only wake count
                    "wakeCount" to sleepData.wakeCount,
                    "sleepQuality" to sleepData.sleepQulity,
                    "sleepStartTime" to sleepData.sleepDown?.toString(),
                    "sleepEndTime" to sleepData.sleepUp?.toString(),
                    "sleepCurve" to sleepData.sleepLine,
                    "date" to date
                )
                VPLogger.d("Sleep data received for $date: allSleep=${sleepData.allSleepTime}, deep=${sleepData.deepSleepTime}, light=${sleepData.lowSleepTime}")
            } else {
                VPLogger.d("No sleep data available for $date")
            }
        }

        override fun onSleepProgress(progress: Float) {
            VPLogger.d("Sleep data read progress: $progress%")
        }

        override fun onSleepProgressDetail(date: String?, progress: Int) {
            VPLogger.d("Sleep data read progress for $date: $progress%")
        }

        override fun onReadSleepComplete() {
            VPLogger.d("Sleep data read complete")
            // Return result only once when reading is complete
            if (!hasReturnedResult) {
                hasReturnedResult = true
                if (latestSleepData != null) {
                    VPLogger.d("Returning sleep data: $latestSleepData")
                    result.success(latestSleepData)
                } else {
                    VPLogger.d("No sleep data found in any of the days")
                    result.success(null)
                }
            }
        }
    }
}
