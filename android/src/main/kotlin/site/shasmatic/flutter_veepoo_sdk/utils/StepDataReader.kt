package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IStepDataListener
import com.veepoo.protocol.model.datas.StepData
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
     * Reads current step data from the device.
     */
    fun readStepData() {
        try {
            vpManager.readStepData(writeResponse, object : IStepDataListener {
                override fun onStepDataChange(stepData: StepData?) {
                    if (stepData != null) {
                        val data = mapStepDataToMap(stepData)
                        VPLogger.d("Step data received: $stepData")
                        result.success(data)
                    } else {
                        result.success(null)
                    }
                }
            })
        } catch (e: InvocationTargetException) {
            result.error("STEP_DATA_ERROR", "Error reading step data: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("STEP_DATA_ERROR", "Error reading step data: ${e.message}", null)
        }
    }

    /**
     * Reads step data for a specific date.
     *
     * @param timestamp Date in milliseconds
     */
    fun readStepDataForDate(timestamp: Long) {
        try {
            vpManager.readStepDataByDate(writeResponse, timestamp, object : IStepDataListener {
                override fun onStepDataChange(stepData: StepData?) {
                    if (stepData != null) {
                        val data = mapStepDataToMap(stepData)
                        VPLogger.d("Step data for date received: $stepData")
                        result.success(data)
                    } else {
                        result.success(null)
                    }
                }
            })
        } catch (e: InvocationTargetException) {
            result.error("STEP_DATA_ERROR", "Error reading step data for date: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("STEP_DATA_ERROR", "Error reading step data for date: ${e.message}", null)
        }
    }

    private fun mapStepDataToMap(stepData: StepData): Map<String, Any?> {
        return mapOf(
            "steps" to stepData.step,
            "distanceMeters" to stepData.distance,
            "calories" to stepData.calories,
            "activeMinutes" to stepData.activeTime,
            "timestamp" to System.currentTimeMillis()
        )
    }
}
