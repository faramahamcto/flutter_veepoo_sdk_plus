package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IECGDetectListener
import com.veepoo.protocol.model.datas.EcgDetectInfo
import com.veepoo.protocol.model.datas.EcgDetectResult
import com.veepoo.protocol.model.datas.EcgDetectState
import com.veepoo.protocol.model.datas.EcgDiagnosis
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

    private var currentState: String = "idle"
    private var currentWaveform: List<Int> = emptyList()
    private var currentResult: String? = null
    private var samplingFrequency: Int = 0
    private var drawFrequency: Int = 0

    private val ecgDataListener = object : IECGDetectListener {
        override fun onEcgDetectInfoChange(ecgInfo: EcgDetectInfo?) {
            // Store frequency information
            samplingFrequency = ecgInfo?.frequency ?: 0
            drawFrequency = ecgInfo?.drawFrequency ?: 0
            sendEcgUpdate()
        }

        override fun onEcgDetectStateChange(state: EcgDetectState?) {
            // Update state based on progress
            currentState = when {
                state == null -> "idle"
                state.progress < 100 -> "measuring"
                state.progress >= 100 -> "complete"
                else -> "unknown"
            }
            sendEcgUpdate()
        }

        override fun onEcgDetectResultChange(result: EcgDetectResult?) {
            // Store final result - result object contains many fields
            currentResult = if (result?.isSuccess == true) "success" else "failed"
            sendEcgUpdate()
        }

        override fun onEcgDetectDiagnosisChange(diagnosis: EcgDiagnosis?) {
            // Store diagnosis - EcgDiagnosis contains diagnostic information
            currentResult = diagnosis?.toString() ?: "No diagnosis"
            sendEcgUpdate()
        }

        override fun onEcgADCChange(wave1: IntArray?, wave2: IntArray?) {
            // Update waveform data (filter out Int.MAX_VALUE which indicates invalid data)
            // Use wave1 as primary waveform data
            currentWaveform = wave1?.filter { it != Int.MAX_VALUE }?.toList() ?: emptyList()
            sendEcgUpdate()
        }
    }

    private fun sendEcgUpdate() {
        val ecgResult = mapOf<String, Any?>(
            "waveformData" to currentWaveform,
            "state" to currentState,
            "isMeasuring" to (currentState == "measuring"),
            "diagnosticResult" to currentResult,
            "samplingFrequency" to samplingFrequency,
            "drawFrequency" to drawFrequency,
            "signalQuality" to if (currentWaveform.isNotEmpty()) 100 else 0,
            "timestamp" to System.currentTimeMillis()
        )
        sendEvent.sendEcgEvent(ecgResult)
    }
}
