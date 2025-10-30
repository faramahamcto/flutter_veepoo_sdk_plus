package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.ITemperatureDataListener
import com.veepoo.protocol.model.datas.TemperatureData
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for temperature detection and monitoring.
 *
 * @constructor Creates a new [Temperature] instance with the specified event sink and VPOperateManager.
 * @param temperatureEventSink The sink that receives the temperature events.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class Temperature(
    private val temperatureEventSink: EventChannel.EventSink?,
    private val vpManager: VPOperateManager,
) {

    private val sendEvent: SendEvent = SendEvent(temperatureEventSink)
    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Starts temperature detection.
     */
    fun startDetectTemperature() {
        executeTemperatureOperation {
            vpManager.startDetectTemperature(writeResponse, temperatureDataListener)
        }
    }

    /**
     * Stops temperature detection.
     */
    fun stopDetectTemperature() {
        executeTemperatureOperation {
            vpManager.stopDetectTemperature(writeResponse)
        }
    }

    private fun executeTemperatureOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            throw VPException("Error during temperature operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            throw VPException("Error during temperature operation: ${e.message}", e.cause)
        }
    }

    private val temperatureDataListener = ITemperatureDataListener { tempData ->
        val result = mapOf<String, Any?>(
            "temperatureCelsius" to tempData?.temperature,
            "temperatureFahrenheit" to celsiusToFahrenheit(tempData?.temperature),
            "wristTemperatureCelsius" to tempData?.wristTemperature,
            "state" to getTemperatureState(tempData),
            "isMeasuring" to (tempData?.isChecking ?: false),
            "progress" to (tempData?.progress ?: 0),
            "timestamp" to System.currentTimeMillis()
        )
        sendEvent.sendTemperatureEvent(result)
    }

    private fun getTemperatureState(tempData: TemperatureData?): String {
        return when {
            tempData == null -> "unknown"
            tempData.isChecking -> "measuring"
            tempData.temperature > 0 -> "complete"
            else -> "idle"
        }
    }

    private fun celsiusToFahrenheit(celsius: Float?): Float? {
        return celsius?.let { (it * 9 / 5) + 32 }
    }
}
