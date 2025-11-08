package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.ISleepDataListener
import com.veepoo.protocol.model.datas.SleepData
import io.flutter.plugin.common.MethodChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
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
     * Reads sleep data from the device.
     */
    fun readSleepData() {
        try {
            vpManager.readSleepData(writeResponse, object : ISleepDataListener {
                override fun onSleepDataChange(sleepData: SleepData?) {
                    if (sleepData != null) {
                        val data = mapOf<String, Any?>(
                            "totalSleepMinutes" to sleepData.totalSleepTime,
                            "deepSleepMinutes" to sleepData.deepSleepTime,
                            "lightSleepMinutes" to sleepData.lightSleepTime,
                            "awakeMinutes" to sleepData.awakeTime,
                            "sleepQuality" to sleepData.sleepQuality,
                            "sleepStartTime" to sleepData.sleepStartTime,
                            "sleepEndTime" to sleepData.sleepEndTime,
                            "sleepCurve" to sleepData.sleepCurve
                        )
                        VPLogger.d("Sleep data received: $sleepData")
                        result.success(data)
                    } else {
                        result.success(null)
                    }
                }
            })
        } catch (e: InvocationTargetException) {
            result.error("SLEEP_DATA_ERROR", "Error reading sleep data: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("SLEEP_DATA_ERROR", "Error reading sleep data: ${e.message}", null)
        }
    }
}
