package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IBPDetectDataListener
import com.veepoo.protocol.model.datas.BpData
import com.veepoo.protocol.model.enums.EBPDetectModel
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for blood pressure detection.
 *
 * @constructor Creates a new [BloodPressure] instance with VPOperateManager.
 * @param bloodPressureEventSink The sink that receives blood pressure events.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class BloodPressure(
    private val bloodPressureEventSink: EventChannel.EventSink?,
    private val vpManager: VPOperateManager,
) {

    private val sendEvent: SendEvent = SendEvent(bloodPressureEventSink)
    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Starts blood pressure detection.
     * Uses DETECT_MODEL_PRIVATE for standard detection.
     */
    fun startDetectBloodPressure() {
        executeBloodPressureOperation {
            vpManager.startDetectBP(
                writeResponse,
                bpDetectDataListener,
                EBPDetectModel.DETECT_MODEL_PRIVATE
            )
            VPLogger.d("Blood pressure detection started")
        }
    }

    /**
     * Stops blood pressure detection.
     */
    fun stopDetectBloodPressure() {
        executeBloodPressureOperation {
            vpManager.stopDetectBP(writeResponse, EBPDetectModel.DETECT_MODEL_PRIVATE)
            VPLogger.d("Blood pressure detection stopped")
        }
    }

    private fun executeBloodPressureOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            throw VPException("Error during blood pressure operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            throw VPException("Error during blood pressure operation: ${e.message}", e.cause)
        }
    }

    private val bpDetectDataListener = IBPDetectDataListener { bpData ->
        if (bpData != null) {
            // Log raw data for debugging
            VPLogger.d("BP raw data - systolic: ${bpData.highPressure}, diastolic: ${bpData.lowPressure}, progress: ${bpData.progress}, status: ${bpData.status}, hasProgress: ${bpData.isHaveProgress}")

            val statusString = when (bpData.status) {
                com.veepoo.protocol.model.enums.EBPDetectStatus.STATE_BP_BUSY -> "BUSY"
                com.veepoo.protocol.model.enums.EBPDetectStatus.STATE_BP_NORMAL -> "NORMAL"
                null -> "MEASURING"
                else -> bpData.status.name
            }

            val result = mapOf<String, Any?>(
                "systolic" to bpData.highPressure,
                "diastolic" to bpData.lowPressure,
                "progress" to bpData.progress,
                "status" to statusString,
                "isComplete" to (bpData.status == com.veepoo.protocol.model.enums.EBPDetectStatus.STATE_BP_NORMAL && bpData.progress >= 100)
            )
            VPLogger.d("BP data sent to Flutter: $result")
            sendEvent.sendBloodPressureEvent(result)
        } else {
            VPLogger.w("Received null BP data from device")
        }
    }
}
