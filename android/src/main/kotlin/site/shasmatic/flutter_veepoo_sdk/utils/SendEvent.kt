package site.shasmatic.flutter_veepoo_sdk.utils

import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import site.shasmatic.flutter_veepoo_sdk.VPLogger

/**
 * Utility class for sending various types of events, such as Bluetooth, heart rate, heart warning,
 * and SpO2 events, via an [EventChannel.EventSink].
 *
 * @constructor Initializes the [SendEvent] with the given [EventChannel.EventSink].
 * @param eventSink The sink that receives the events.
 */
class SendEvent(private val eventSink: EventChannel.EventSink?) {

    /**
     * Sends a Bluetooth event with the given scan result data.
     *
     * This method is responsible for sending Bluetooth scan result events
     * to the [EventChannel.EventSink]. The event data is provided as a
     * map containing key-value pairs representing the scan result.
     *
     * @param scanResult A map containing the Bluetooth scan result data.
     */
    fun sendBluetoothEvent(scanResult: List<Map<String, Any?>>) {
        sendEvent(scanResult)
    }

    /**
     * Sends a heart rate event with the given heart rate data.
     *
     * This method is responsible for sending heart rate events to the
     * [EventChannel.EventSink]. The event data is provided as a map
     * containing key-value pairs representing the heart rate data.
     *
     * @param heartRateData A map containing the heart rate data.
     */
    fun sendHeartRateEvent(heartRateData: Map<String, Any?>) {
        sendEvent(heartRateData)
    }

    /**
     * Sends a SpO2 event with the given SpO2 data.
     *
     * This method is responsible for sending SpO2 events to the
     * [EventChannel.EventSink]. The event data is provided as a map
     * containing key-value pairs representing the SpO2 data.
     *
     * @param spO2Data A map containing the SpO2 data.
     */
    fun sendSpO2Event(spO2Data: Map<String, Any?>) {
        sendEvent(spO2Data)
    }

    /**
     * Sends a temperature event with the given temperature data.
     *
     * @param temperatureData A map containing the temperature data.
     */
    fun sendTemperatureEvent(temperatureData: Map<String, Any?>) {
        sendEvent(temperatureData)
    }

    /**
     * Sends an ECG event with the given ECG data.
     *
     * @param ecgData A map containing the ECG data.
     */
    fun sendEcgEvent(ecgData: Map<String, Any?>) {
        sendEvent(ecgData)
    }

    /**
     * Sends a blood pressure event with the given BP data.
     *
     * @param bloodPressureData A map containing the blood pressure data.
     */
    fun sendBloodPressureEvent(bloodPressureData: Map<String, Any?>) {
        sendEvent(bloodPressureData)
    }

    /**
     * Sends a blood glucose event with the given BG data.
     *
     * @param bloodGlucoseData A map containing the blood glucose data.
     */
    fun sendBloodGlucoseEvent(bloodGlucoseData: Map<String, Any?>) {
        sendEvent(bloodGlucoseData)
    }

    private fun sendEvent(eventData: Any) {
        if (eventSink == null) {
            VPLogger.w("Event sink is null, cannot send event: $eventData")
            return
        }
        CoroutineScope(Dispatchers.Main).launch {
            try {
                eventSink.success(eventData)
                VPLogger.i("Event sent successfully: ${if (eventData is List<*>) "List with ${eventData.size} items" else eventData.javaClass.simpleName}")
            } catch (e: Exception) {
                VPLogger.e("Failed to send event: ${e.message}")
            }
        }
    }
}