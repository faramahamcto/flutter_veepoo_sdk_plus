package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.ITemptureDetectDataListener
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for temperature detection via an [EventChannel.EventSink].
 *
 * @constructor Creates a new [Temperature] instance with the specified event sink and [VPOperateManager].
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
     * Starts the temperature detection process.
     */
    fun startDetectTemperature() {
        executeTemperatureOperation {
            vpManager.startDetectTempture(writeResponse, temperatureDataListener)
        }
    }

    /**
     * Stops the temperature detection process.
     */
    fun stopDetectTemperature() {
        executeTemperatureOperation {
            vpManager.stopDetectTempture(writeResponse)
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

    private val temperatureDataListener = ITemptureDetectDataListener { data ->
        // Convert Celsius to Fahrenheit: F = C * 9/5 + 32
        val fahrenheit = data?.tempture?.let { it * 9.0 / 5.0 + 32.0 }

        val temperatureResult = mapOf<String, Any?>(
            "temperatureCelsius" to data?.tempture,
            "temperatureFahrenheit" to fahrenheit,
            "wristTemperatureCelsius" to data?.wristTempture,
            "state" to if (data?.isDetecting == true) "measuring" else "complete",
            "isMeasuring" to data?.isDetecting,
            "progress" to data?.progress,
            "timestamp" to System.currentTimeMillis()
        )
        sendEvent.sendTemperatureEvent(temperatureResult)
    }
}
