package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IStepDataListener
import com.veepoo.protocol.model.datas.StepData
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for reading step and activity data from the device.
 *
 * @constructor Creates a new [StepDataReader] instance with VPOperateManager.
 * @param stepDataEventSink The sink that receives the step data events for real-time updates.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class StepDataReader(
    private val stepDataEventSink: EventChannel.EventSink?,
    private val vpManager: VPOperateManager,
) {

    private val sendEvent: SendEvent = SendEvent(stepDataEventSink)
    private val writeResponse: VPWriteResponse = VPWriteResponse()
    private var currentStepData: StepData? = null

    /**
     * Reads current step data from the device.
     *
     * @return Map containing step data
     */
    fun readStepData(): Map<String, Any?>? {
        executeStepOperation {
            vpManager.readStepData(writeResponse, stepDataListener)
        }

        // Wait for data
        Thread.sleep(1000)

        return currentStepData?.let { stepData ->
            mapStepDataToMap(stepData)
        }
    }

    /**
     * Reads step data for a specific date.
     *
     * @param timestamp Date in milliseconds
     * @return Map containing step data
     */
    fun readStepDataForDate(timestamp: Long): Map<String, Any?>? {
        executeStepOperation {
            vpManager.readStepDataByDate(writeResponse, timestamp, stepDataListener)
        }

        Thread.sleep(1000)

        return currentStepData?.let { stepData ->
            mapStepDataToMap(stepData)
        }
    }

    /**
     * Reads step history for a date range.
     *
     * @param startTimestamp Start date in milliseconds
     * @param endTimestamp End date in milliseconds
     * @return List of step data maps
     */
    fun readStepHistory(startTimestamp: Long, endTimestamp: Long): List<Map<String, Any?>> {
        val stepHistory = mutableListOf<Map<String, Any?>>()

        executeStepOperation {
            vpManager.readStepHistoryByDateRange(
                writeResponse,
                startTimestamp,
                endTimestamp
            ) { stepDataList ->
                stepDataList?.forEach { stepData ->
                    stepHistory.add(mapStepDataToMap(stepData))
                }
            }
        }

        Thread.sleep(2000)

        return stepHistory
    }

    /**
     * Starts real-time step data monitoring.
     */
    fun startStepMonitoring() {
        executeStepOperation {
            vpManager.startStepMonitoring(writeResponse, realtimeStepDataListener)
        }
    }

    /**
     * Stops real-time step data monitoring.
     */
    fun stopStepMonitoring() {
        executeStepOperation {
            vpManager.stopStepMonitoring(writeResponse)
        }
    }

    private fun executeStepOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            throw VPException("Error during step operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            throw VPException("Error during step operation: ${e.message}", e.cause)
        }
    }

    private val stepDataListener = IStepDataListener { stepData ->
        currentStepData = stepData
        VPLogger.d("Step data received: $stepData")
    }

    private val realtimeStepDataListener = IStepDataListener { stepData ->
        val result = mapStepDataToMap(stepData)
        sendEvent.sendStepDataEvent(result)
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
