package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IBloodGlucoseDataListener
import com.veepoo.protocol.model.datas.BloodGlucoseData
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for blood glucose detection and monitoring.
 *
 * @constructor Creates a new [BloodGlucose] instance with the specified event sink and VPOperateManager.
 * @param bloodGlucoseEventSink The sink that receives the blood glucose events.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class BloodGlucose(
    private val bloodGlucoseEventSink: EventChannel.EventSink?,
    private val vpManager: VPOperateManager,
) {

    private val sendEvent: SendEvent = SendEvent(bloodGlucoseEventSink)
    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Starts blood glucose detection.
     */
    fun startDetectBloodGlucose() {
        executeBloodGlucoseOperation {
            vpManager.startDetectBloodGlucose(writeResponse, bloodGlucoseDataListener)
        }
    }

    /**
     * Stops blood glucose detection.
     */
    fun stopDetectBloodGlucose() {
        executeBloodGlucoseOperation {
            vpManager.stopDetectBloodGlucose(writeResponse)
        }
    }

    /**
     * Sets blood glucose calibration mode.
     *
     * @param enabled Enable or disable calibration mode
     */
    fun setBloodGlucoseCalibration(enabled: Boolean) {
        executeBloodGlucoseOperation {
            // Implementation depends on SDK API for calibration
            // This is a placeholder - adjust based on actual SDK method
            vpManager.setBloodGlucoseCalibration(writeResponse, enabled)
        }
    }

    private fun executeBloodGlucoseOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            throw VPException("Error during blood glucose operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            throw VPException("Error during blood glucose operation: ${e.message}", e.cause)
        }
    }

    private val bloodGlucoseDataListener = IBloodGlucoseDataListener { glucoseData ->
        val result = mapOf<String, Any?>(
            "glucoseMgdL" to glucoseData?.glucoseValue,
            "glucoseMmolL" to mgdlToMmol(glucoseData?.glucoseValue),
            "state" to getGlucoseState(glucoseData),
            "isMeasuring" to (glucoseData?.isChecking ?: false),
            "progress" to (glucoseData?.progress ?: 0),
            "calibrationMode" to (glucoseData?.isCalibrationMode ?: false),
            "timestamp" to System.currentTimeMillis()
        )
        sendEvent.sendBloodGlucoseEvent(result)
    }

    private fun getGlucoseState(glucoseData: BloodGlucoseData?): String {
        return when {
            glucoseData == null -> "unknown"
            glucoseData.isChecking -> "measuring"
            glucoseData.glucoseValue > 0 -> "complete"
            else -> "idle"
        }
    }

    private fun mgdlToMmol(mgdl: Float?): Float? {
        return mgdl?.let { it / 18.0f }
    }
}
