package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IBloodGlucoseChangeListener
import com.veepoo.protocol.model.datas.MealInfo
import com.veepoo.protocol.model.enums.EBloodGlucoseDetectModel
import com.veepoo.protocol.model.enums.EBloodGlucoseRiskLevel
import com.veepoo.protocol.model.enums.EBloodGlucoseStatus
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for blood glucose detection.
 *
 * @constructor Creates a new [BloodGlucose] instance with VPOperateManager.
 * @param bloodGlucoseEventSink The sink that receives blood glucose events.
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
     * Uses DETECT_MODEL_PRIVATE for standard detection.
     */
    fun startDetectBloodGlucose() {
        executeBloodGlucoseOperation {
            vpManager.startBloodGlucoseDetect(
                writeResponse,
                bloodGlucoseChangeListener,
                EBloodGlucoseDetectModel.DETECT_MODEL_PRIVATE
            )
            VPLogger.d("Blood glucose detection started")
        }
    }

    /**
     * Stops blood glucose detection.
     */
    fun stopDetectBloodGlucose() {
        executeBloodGlucoseOperation {
            vpManager.stopBloodGlucoseDetect(
                writeResponse,
                bloodGlucoseChangeListener,
                EBloodGlucoseDetectModel.DETECT_MODEL_PRIVATE
            )
            VPLogger.d("Blood glucose detection stopped")
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

    private val bloodGlucoseChangeListener = object : IBloodGlucoseChangeListener {
        override fun onBloodGlucoseDetect(
            progress: Int,
            value: Float,
            riskLevel: EBloodGlucoseRiskLevel?
        ) {
            VPLogger.d("BG raw data - progress: $progress, value: $value, riskLevel: $riskLevel")

            // Determine state based on progress
            val state = when {
                progress >= 100 -> "complete"
                progress > 0 -> "measuring"
                else -> "idle"
            }

            // The value from the device is typically in mmol/L
            // Convert mmol/L to mg/dL (multiply by 18.0182)
            val glucoseMmolL = value.toDouble()
            val glucoseMgdL = value * 18.0182

            val result = mapOf<String, Any?>(
                "progress" to progress,
                "glucoseMmolL" to glucoseMmolL,
                "glucoseMgdL" to glucoseMgdL,
                "state" to state,
                "isMeasuring" to (progress < 100),
                "timestamp" to System.currentTimeMillis(),
                "riskLevel" to when (riskLevel) {
                    EBloodGlucoseRiskLevel.NONE -> "NONE"
                    EBloodGlucoseRiskLevel.LOW -> "LOW"
                    EBloodGlucoseRiskLevel.MIDDLE -> "MIDDLE"
                    EBloodGlucoseRiskLevel.HIGH -> "HIGH"
                    null -> "UNKNOWN"
                    else -> riskLevel.name
                }
            )
            VPLogger.d("BG data sent to Flutter: $result")
            sendEvent.sendBloodGlucoseEvent(result)
        }

        override fun onDetectError(errorCode: Int, status: EBloodGlucoseStatus?) {
            VPLogger.e("BG detect error - code: $errorCode, status: $status")

            val statusString = when (status) {
                EBloodGlucoseStatus.NONSUPPORT -> "notSupported"
                EBloodGlucoseStatus.ENABLE -> "idle"
                EBloodGlucoseStatus.DETECTING -> "measuring"
                EBloodGlucoseStatus.LOW_POWER -> "failed"
                EBloodGlucoseStatus.BUSY -> "failed"
                EBloodGlucoseStatus.WEARING_ERROR -> "failed"
                null -> "unknown"
                else -> status.name.lowercase()
            }

            val errorResult = mapOf<String, Any?>(
                "error" to true,
                "errorCode" to errorCode,
                "state" to statusString,
                "isMeasuring" to false,
                "timestamp" to System.currentTimeMillis()
            )
            VPLogger.d("BG error sent to Flutter: $errorResult")
            sendEvent.sendBloodGlucoseEvent(errorResult)
        }

        override fun onBloodGlucoseStopDetect() {
            VPLogger.d("BG detection stopped")
            val result = mapOf<String, Any?>(
                "state" to "idle",
                "isMeasuring" to false,
                "stopped" to true,
                "timestamp" to System.currentTimeMillis()
            )
            sendEvent.sendBloodGlucoseEvent(result)
        }

        override fun onBloodGlucoseAdjustingSettingSuccess(p0: Boolean, p1: Float) {
            VPLogger.d("BG adjusting setting success: $p0, $p1")
        }

        override fun onBloodGlucoseAdjustingSettingFailed() {
            VPLogger.d("BG adjusting setting failed")
        }

        override fun onBloodGlucoseAdjustingReadSuccess(p0: Boolean, p1: Float) {
            VPLogger.d("BG adjusting read success: $p0, $p1")
        }

        override fun onBloodGlucoseAdjustingReadFailed() {
            VPLogger.d("BG adjusting read failed")
        }

        override fun onBGMultipleAdjustingReadSuccess(
            p0: Boolean,
            p1: MealInfo?,
            p2: MealInfo?,
            p3: MealInfo?
        ) {
            VPLogger.d("BG multiple adjusting read success")
        }

        override fun onBGMultipleAdjustingReadFailed() {
            VPLogger.d("BG multiple adjusting read failed")
        }

        override fun onBGMultipleAdjustingSettingSuccess() {
            VPLogger.d("BG multiple adjusting setting success")
        }

        override fun onBGMultipleAdjustingSettingFailed() {
            VPLogger.d("BG multiple adjusting setting failed")
        }
    }
}
