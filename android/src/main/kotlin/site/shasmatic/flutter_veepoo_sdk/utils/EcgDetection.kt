package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IECGDetectListener
import com.veepoo.protocol.model.datas.EcgDetectInfo
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for ECG detection via an [EventChannel.EventSink].
 *
 * @constructor Creates a new [EcgDetection] instance with the specified event sink and [VPOperateManager].
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
     * Starts the ECG detection process.
     *
     * @param needWaveform Whether to include waveform data in the results.
     */
    fun startDetectECG(needWaveform: Boolean = true) {
        executeECGOperation {
            vpManager.startDetectECG(writeResponse, needWaveform, ecgDataListener)
        }
    }

    /**
     * Stops the ECG detection process.
     */
    fun stopDetectECG() {
        executeECGOperation {
            vpManager.stopDetectECG(writeResponse, false, ecgDataListener)
        }
    }

    private fun executeECGOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            throw VPException("Error during ECG operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            throw VPException("Error during ECG operation: ${e.message}", e.cause)
        }
    }

    private val ecgDataListener = object : IECGDetectListener {
        override fun onEcgDetectInfoChange(ecgInfo: EcgDetectInfo?) {
            val waveList = ecgInfo?.waveData?.toList() ?: emptyList()
            val ecgResult = mapOf<String, Any?>(
                "waveformData" to waveList,
                "heartRate" to ecgInfo?.value,
                "state" to mapECGState(ecgInfo?.ecgDetectState),
                "isMeasuring" to (ecgInfo?.ecgDetectState == 1),
                "progress" to ecgInfo?.ecgProgress,
                "diagnosticResult" to ecgInfo?.ecgDetectResult,
                "signalQuality" to if (waveList.isNotEmpty()) 100 else 0,
                "timestamp" to System.currentTimeMillis()
            )
            sendEvent.sendEcgEvent(ecgResult)
        }
    }

    private fun mapECGState(state: Int?): String {
        return when (state) {
            0 -> "idle"
            1 -> "measuring"
            2 -> "complete"
            3 -> "failed"
            4 -> "poorSignal"
            else -> "unknown"
        }
    }
}
