package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IBloodComponentDetectListener
import com.veepoo.protocol.model.datas.BloodComponent
import com.veepoo.protocol.model.enums.EBloodComponentDetectState
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for blood component detection.
 *
 * Blood components include:
 * - Uric Acid (μmol/L)
 * - Total Cholesterol (mmol/L)
 * - Triglyceride (mmol/L)
 * - High-Density Lipoprotein (mmol/L)
 * - Low-Density Lipoprotein (mmol/L)
 *
 * @constructor Creates a new [BloodComponentDetection] instance with VPOperateManager.
 * @param bloodComponentEventSink The sink that receives blood component events.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class BloodComponentDetection(
    private val bloodComponentEventSink: EventChannel.EventSink?,
    private val vpManager: VPOperateManager,
) {

    private val sendEvent: SendEvent = SendEvent(bloodComponentEventSink)
    private val writeResponse: VPWriteResponse = VPWriteResponse()
    private var isDetecting = false

    /**
     * Starts blood component detection.
     * @param needCalibration Whether calibration is needed for the measurement.
     */
    fun startDetectBloodComponent(needCalibration: Boolean = false) {
        if (isDetecting) {
            VPLogger.w("Blood component detection already in progress, stopping first...")
            stopDetectBloodComponent()
            Thread.sleep(300)
        }

        executeBloodComponentOperation {
            isDetecting = true
            VPLogger.d("Starting blood component detection with calibration=$needCalibration")
            vpManager.startDetectBloodComponent(writeResponse, needCalibration, bloodComponentDetectListener)
        }
    }

    /**
     * Stops blood component detection.
     */
    fun stopDetectBloodComponent() {
        if (!isDetecting) {
            VPLogger.w("Blood component detection not running, nothing to stop")
            return
        }

        executeBloodComponentOperation {
            VPLogger.d("Stopping blood component detection")
            vpManager.stopDetectBloodComponent(writeResponse)
            isDetecting = false
            // Send stopped event
            sendStoppedEvent()
        }
    }

    private fun executeBloodComponentOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            isDetecting = false
            throw VPException("Error during blood component operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            isDetecting = false
            VPLogger.e("Error during blood component operation: ${e.message}")
            throw VPException("Error during blood component operation: ${e.message}", e.cause)
        }
    }

    private val bloodComponentDetectListener = object : IBloodComponentDetectListener {
        override fun onDetecting(progress: Int, bloodComponent: BloodComponent) {
            VPLogger.d("Blood component detecting - progress: $progress")

            val result = mapOf<String, Any?>(
                "progress" to progress,
                "state" to "measuring",
                "isMeasuring" to true,
                "uricAcid" to bloodComponent.getUricAcid(),
                "totalCholesterol" to bloodComponent.getTCHO(),
                "triglyceride" to bloodComponent.getTAG(),
                "hdl" to bloodComponent.getHDL(),
                "ldl" to bloodComponent.getLDL(),
                "timestamp" to System.currentTimeMillis()
            )
            sendEvent.sendBloodComponentEvent(result)
        }

        override fun onDetectComplete(bloodComponent: BloodComponent) {
            VPLogger.d("Blood component detection complete: $bloodComponent")
            isDetecting = false

            val result = mapOf<String, Any?>(
                "progress" to 100,
                "state" to "complete",
                "isMeasuring" to false,
                "uricAcid" to bloodComponent.getUricAcid(),
                "totalCholesterol" to bloodComponent.getTCHO(),
                "triglyceride" to bloodComponent.getTAG(),
                "hdl" to bloodComponent.getHDL(),
                "ldl" to bloodComponent.getLDL(),
                "timestamp" to System.currentTimeMillis()
            )
            sendEvent.sendBloodComponentEvent(result)
        }

        override fun onDetectFailed(errorState: EBloodComponentDetectState) {
            VPLogger.e("Blood component detection failed: $errorState")
            isDetecting = false

            val stateString = when (errorState) {
                EBloodComponentDetectState.ENABLE -> "idle"
                EBloodComponentDetectState.DETECTING -> "measuring"
                EBloodComponentDetectState.LOW_POWER -> "failed"
                EBloodComponentDetectState.BUSY -> "failed"
                EBloodComponentDetectState.WEAR_ERROR -> "failed"
                EBloodComponentDetectState.UNKNOWN -> "unknown"
                else -> errorState.name.lowercase()
            }

            val result = mapOf<String, Any?>(
                "error" to true,
                "state" to stateString,
                "errorMessage" to errorState.name,
                "isMeasuring" to false,
                "timestamp" to System.currentTimeMillis()
            )
            sendEvent.sendBloodComponentEvent(result)
        }

        override fun onDetectStop() {
            VPLogger.d("Blood component detection stopped")
            isDetecting = false
            sendStoppedEvent()
        }
    }

    private fun sendStoppedEvent() {
        val result = mapOf<String, Any?>(
            "state" to "idle",
            "isMeasuring" to false,
            "stopped" to true,
            "timestamp" to System.currentTimeMillis()
        )
        sendEvent.sendBloodComponentEvent(result)
    }
}
