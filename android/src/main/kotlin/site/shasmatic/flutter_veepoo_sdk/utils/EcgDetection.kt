package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IECGDataListener
import com.veepoo.protocol.model.datas.EcgData
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for ECG detection and monitoring.
 *
 * @constructor Creates a new [EcgDetection] instance with the specified event sink and VPOperateManager.
 * @param ecgEventSink The sink that receives the ECG events.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class EcgDetection(
    private val ecgEventSink: EventChannel.EventSink?,
    private val vpManager: VPOperateManager,
) {

    private val sendEvent: SendEvent = SendEvent(ecgEventSink)
    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Starts ECG detection.
     */
    fun startDetectEcg() {
        executeEcgOperation {
            vpManager.startDetectECG(writeResponse, ecgDataListener)
        }
    }

    /**
     * Stops ECG detection.
     */
    fun stopDetectEcg() {
        executeEcgOperation {
            vpManager.stopDetectECG(writeResponse)
        }
    }

    private fun executeEcgOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            throw VPException("Error during ECG operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            throw VPException("Error during ECG operation: ${e.message}", e.cause)
        }
    }

    private val ecgDataListener = IECGDataListener { ecgData ->
        val result = mapOf<String, Any?>(
            "waveformData" to ecgData?.waveData,
            "heartRate" to ecgData?.heartRate,
            "state" to getEcgState(ecgData),
            "isMeasuring" to (ecgData?.isChecking ?: false),
            "progress" to (ecgData?.progress ?: 0),
            "diagnosticResult" to ecgData?.diagnosticResult,
            "signalQuality" to ecgData?.signalQuality,
            "timestamp" to System.currentTimeMillis()
        )
        sendEvent.sendEcgEvent(result)
    }

    private fun getEcgState(ecgData: EcgData?): String {
        return when {
            ecgData == null -> "unknown"
            ecgData.isChecking -> "measuring"
            ecgData.signalQuality != null && ecgData.signalQuality!! < 50 -> "poorSignal"
            ecgData.heartRate > 0 -> "complete"
            else -> "idle"
        }
    }
}
