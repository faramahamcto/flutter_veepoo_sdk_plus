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

    private val originDataListener = object : IOriginDataListener {
        override fun onOrinReadOriginProgress(day: Int) {
            // Progress callback - indicates data is being read
            VPLogger.d("Reading sleep data progress: day $day")
        }

        override fun onOrinReadOriginComplete() {
            VPLogger.d("Origin data read complete")
        }

        override fun onOriginFiveMinuteDataChange(originData: com.veepoo.protocol.model.datas.OriginData?) {
            if (originData == null) {
                result.success(null)
                return
            }

            // Extract sleep data from origin data
            val sleepData = originData.originSleepData
            if (sleepData != null) {
                val data = mapOf<String, Any?>(
                    "totalSleepMinutes" to (sleepData.allSleepTime ?: 0),
                    "deepSleepMinutes" to (sleepData.deepSleepTime ?: 0),
                    "lightSleepMinutes" to (sleepData.lowSleepTime ?: 0),
                    "awakeMinutes" to (sleepData.soberTime ?: 0),
                    "sleepQuality" to (sleepData.sleepQulity ?: 0),
                    "sleepStartTime" to (sleepData.originSleepStartData ?: ""),
                    "sleepEndTime" to (sleepData.originSleepEndData ?: ""),
                    "sleepCurve" to sleepData.sleepLine
                )
                VPLogger.d("Sleep data received: $sleepData")
                result.success(data)
            } else {
                result.success(null)
            }
        }

        override fun onOriginHalfHourDataChange(originData: com.veepoo.protocol.model.datas.OriginHalfHourData?) {
            // Not used for sleep data
        }
    }

    private val originProgressListener = object : com.veepoo.protocol.listener.data.IOriginProgressListener {
        override fun onOrinReadOriginProgress(day: Int) {
            VPLogger.d("Reading sleep data progress: day $day")
        }

        override fun onOrinReadOriginComplete() {
            VPLogger.d("Origin data read complete")
        }
    }
}
