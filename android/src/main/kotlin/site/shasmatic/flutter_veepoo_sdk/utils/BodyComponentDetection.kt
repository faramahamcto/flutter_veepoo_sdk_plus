package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IBodyComponentDetectListener
import com.veepoo.protocol.model.datas.BodyComponent
import com.veepoo.protocol.model.enums.DetectState
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for live body composition detection (weight scale style measurement taken on
 * the watch, e.g. via ECG-style hand contact).
 *
 * Body composition includes:
 * - BMI
 * - Body fat rate / fat rate
 * - Fat-free mass (FFM)
 * - Muscle rate / muscle mass
 * - Subcutaneous fat
 * - Body water / water content
 * - Skeletal muscle rate
 * - Bone mass
 * - Protein proportion / protein mass
 * - Basal metabolic rate
 *
 * For reading previously stored measurements from the device, see [BodyComponentReader].
 *
 * @constructor Creates a new [BodyComponentDetection] instance.
 * @param bodyComponentEventSink The sink that receives body composition detection events.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class BodyComponentDetection(
    private val bodyComponentEventSink: EventChannel.EventSink?,
    private val vpManager: VPOperateManager,
) {

    private val sendEvent: SendEvent = SendEvent(bodyComponentEventSink)
    private val writeResponse: VPWriteResponse = VPWriteResponse()
    private var isDetecting = false

    /**
     * Starts body composition detection.
     */
    fun startDetectBodyComponent() {
        if (isDetecting) {
            VPLogger.w("Body composition detection already in progress, stopping first...")
            stopDetectBodyComponent()
            Thread.sleep(300)
        }

        executeBodyComponentOperation {
            isDetecting = true
            VPLogger.d("Starting body composition detection")
            vpManager.startDetectBodyComponent(writeResponse, bodyComponentDetectListener)
        }
    }

    /**
     * Stops body composition detection.
     */
    fun stopDetectBodyComponent() {
        if (!isDetecting) {
            VPLogger.w("Body composition detection not running, nothing to stop")
            return
        }

        executeBodyComponentOperation {
            VPLogger.d("Stopping body composition detection")
            vpManager.stopDetectBodyComponent(writeResponse)
            isDetecting = false
            sendStoppedEvent()
        }
    }

    private fun executeBodyComponentOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            isDetecting = false
            throw VPException("Error during body composition operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            isDetecting = false
            VPLogger.e("Error during body composition operation: ${e.message}")
            throw VPException("Error during body composition operation: ${e.message}", e.cause)
        }
    }

    private val bodyComponentDetectListener = object : IBodyComponentDetectListener {
        override fun onDetecting(progress: Int, step: Int) {
            VPLogger.d("Body composition detecting - progress: $progress, step: $step")

            val result = mapOf<String, Any?>(
                "state" to "measuring",
                "isMeasuring" to true,
                "progress" to progress,
                // Raw step code reported by the SDK during measurement; the vendor does not
                // document its meaning beyond "detection is in progress".
                "detectStep" to step,
                "timestamp" to System.currentTimeMillis()
            )
            sendEvent.sendBodyComponentEvent(result)
        }

        override fun onDetectSuccess(bodyComponent: BodyComponent) {
            VPLogger.d("Body composition detection complete: $bodyComponent")
            isDetecting = false

            val result = bodyComponentToMap(bodyComponent) + mapOf<String, Any?>(
                "state" to "complete",
                "isMeasuring" to false,
                "progress" to 100,
                "timestamp" to System.currentTimeMillis()
            )
            sendEvent.sendBodyComponentEvent(result)
        }

        override fun onDetectFailed(errorState: DetectState) {
            VPLogger.e("Body composition detection failed: ${errorState.name}")
            isDetecting = false

            val stateString = when (errorState) {
                DetectState.BUSY -> "busy"
                DetectState.LOW_POWER -> "lowPower"
                DetectState.FAILED -> "failed"
                else -> "failed"
            }

            val result = mapOf<String, Any?>(
                "error" to true,
                "state" to stateString,
                "errorMessage" to errorState.name,
                "isMeasuring" to false,
                "timestamp" to System.currentTimeMillis()
            )
            sendEvent.sendBodyComponentEvent(result)
        }

        override fun onDetectStop() {
            VPLogger.d("Body composition detection stopped")
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
        sendEvent.sendBodyComponentEvent(result)
    }
}

/**
 * Converts a native [BodyComponent] into a serializable map. Shared with [BodyComponentReader]
 * since both live detection results and historical records use the same data shape.
 */
internal fun bodyComponentToMap(bodyComponent: BodyComponent): Map<String, Any?> {
    val timeBean = bodyComponent.timeBean
    val date = timeBean?.let {
        String.format(
            "%04d-%02d-%02d %02d:%02d:%02d",
            it.year, it.month, it.day, it.hour, it.minute, it.second
        )
    }

    return mapOf(
        "date" to date,
        "id" to bodyComponent.id,
        "idType" to bodyComponent.idType,
        "duration" to bodyComponent.duration,
        // Kotlin keeps BMI/FFM uppercase when synthesizing properties from getBMI()/getFFM()
        // (both leading letters are capitalized, so Introspector-style decapitalization no-ops).
        "bmi" to bodyComponent.BMI.toDouble(),
        "bodyFatRate" to bodyComponent.bodyFatRate.toDouble(),
        "fatRate" to bodyComponent.fatRate.toDouble(),
        "ffm" to bodyComponent.FFM.toDouble(),
        "muscleRate" to bodyComponent.muscleRate.toDouble(),
        "muscleMass" to bodyComponent.muscleMass.toDouble(),
        "subcutaneousFat" to bodyComponent.subcutaneousFat.toDouble(),
        "bodyWater" to bodyComponent.bodyWater.toDouble(),
        "waterContent" to bodyComponent.waterContent.toDouble(),
        "skeletalMuscleRate" to bodyComponent.skeletalMuscleRate.toDouble(),
        "boneMass" to bodyComponent.boneMass.toDouble(),
        "proteinProportion" to bodyComponent.proteinProportion.toDouble(),
        "proteinMass" to bodyComponent.proteinMass.toDouble(),
        "basalMetabolicRate" to bodyComponent.basalMetabolicRate.toDouble()
    )
}
