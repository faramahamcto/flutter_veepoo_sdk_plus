package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IBPDataListener
import com.veepoo.protocol.listener.data.IBPSettingDataListener
import com.veepoo.protocol.model.datas.BpData
import com.veepoo.protocol.model.settings.BpSetting
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for blood pressure detection and monitoring.
 *
 * @constructor Creates a new [BloodPressure] instance with the specified event sink and VPOperateManager.
 * @param bloodPressureEventSink The sink that receives the blood pressure events.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class BloodPressure(
    private val bloodPressureEventSink: EventChannel.EventSink?,
    private val vpManager: VPOperateManager,
) {

    private val sendEvent: SendEvent = SendEvent(bloodPressureEventSink)
    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Starts blood pressure detection.
     */
    fun startDetectBloodPressure() {
        executeBloodPressureOperation {
            vpManager.startDetectBP(writeResponse, bpDataListener)
        }
    }

    /**
     * Stops blood pressure detection.
     */
    fun stopDetectBloodPressure() {
        executeBloodPressureOperation {
            vpManager.stopDetectBP(writeResponse)
        }
    }

    /**
     * Sets blood pressure alarm thresholds.
     *
     * @param systolicHigh High systolic threshold
     * @param systolicLow Low systolic threshold
     * @param diastolicHigh High diastolic threshold
     * @param diastolicLow Low diastolic threshold
     * @param enabled Enable or disable alarm
     */
    fun setBloodPressureAlarm(
        systolicHigh: Int,
        systolicLow: Int,
        diastolicHigh: Int,
        diastolicLow: Int,
        enabled: Boolean
    ) {
        executeBloodPressureOperation {
            val bpSetting = BpSetting(
                systolicHigh,
                systolicLow,
                diastolicHigh,
                diastolicLow,
                enabled
            )
            vpManager.settingBP(writeResponse, bpSettingListener, bpSetting)
        }
    }

    /**
     * Reads current blood pressure alarm settings.
     */
    fun readBloodPressureAlarm() {
        executeBloodPressureOperation {
            vpManager.readBP(writeResponse, bpSettingListener)
        }
    }

    private fun executeBloodPressureOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            throw VPException("Error during blood pressure operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            throw VPException("Error during blood pressure operation: ${e.message}", e.cause)
        }
    }

    private val bpDataListener = IBPDataListener { bpData ->
        val result = mapOf<String, Any?>(
            "systolic" to bpData?.highPressure,
            "diastolic" to bpData?.lowPressure,
            "state" to getBpState(bpData),
            "isMeasuring" to (bpData?.isChecking ?: false),
            "progress" to (bpData?.progress ?: 0),
            "timestamp" to System.currentTimeMillis()
        )
        sendEvent.sendBloodPressureEvent(result)
    }

    private val bpSettingListener = IBPSettingDataListener { bpSetting ->
        VPLogger.d("Blood pressure setting: $bpSetting")
    }

    private fun getBpState(bpData: BpData?): String {
        return when {
            bpData == null -> "unknown"
            bpData.isChecking -> "measuring"
            bpData.highPressure > 0 && bpData.lowPressure > 0 -> "complete"
            else -> "idle"
        }
    }
}
