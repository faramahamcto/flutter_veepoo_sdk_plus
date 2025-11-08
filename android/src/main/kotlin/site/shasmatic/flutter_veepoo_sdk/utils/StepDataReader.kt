package site.shasmatic.flutter_veepoo_sdk.utils

import android.os.Handler
import android.os.Looper
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.ISportDataListener
import com.veepoo.protocol.model.datas.SportData
import io.flutter.plugin.common.MethodChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for reading step and activity data from the device.
 *
 * @constructor Creates a new [StepDataReader] instance with VPOperateManager.
 * @param result The method channel result to send data back to Flutter.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class StepDataReader(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
) {

    private val writeResponse: VPWriteResponse = VPWriteResponse()
    private var latestStepData: Map<String, Any?>? = null
    private var hasReturnedResult = false
    private val handler = Handler(Looper.getMainLooper())
    private val timeoutRunnable = Runnable {
        if (!hasReturnedResult) {
            VPLogger.e("Sport data read timeout after 10 seconds")
            hasReturnedResult = true
            result.error("TIMEOUT", "No step data received within 10 seconds. Please ensure device is connected and has step data.", null)
        }
    }

    /**
     * Reads current step data from the device using readSportStep API.
     * This gets the current/today's step count from the device.
     */
    fun readStepData() {
        try {
            VPLogger.d("Starting to read current step/sport data...")
            VPLogger.d("Device connected: ${vpManager.currentConnectGatt != null}")
            VPLogger.d("Device address: ${vpManager.currentConnectGatt?.device?.address}")

            // Start timeout timer (10 seconds - sport data is immediate)
            handler.postDelayed(timeoutRunnable, 10000)
            VPLogger.d("Timeout timer started (10 seconds)")

            // Read current sport/step data
            vpManager.readSportStep(writeResponse, sportDataListener)
            VPLogger.d("readSportStep() call completed without exception")
        } catch (e: InvocationTargetException) {
            handler.removeCallbacks(timeoutRunnable)
            VPLogger.e("InvocationTargetException: ${e.targetException.message}")
            result.error("STEP_DATA_ERROR", "Error reading step data: ${e.targetException.message}", null)
        } catch (e: Exception) {
            handler.removeCallbacks(timeoutRunnable)
            VPLogger.e("Exception: ${e.message}")
            result.error("STEP_DATA_ERROR", "Error reading step data: ${e.message}", null)
        }
    }

    /**
     * Reads step data for a specific date.
     * Note: readSportStep only returns current/today's data, not historical.
     *
     * @param timestamp Date in milliseconds
     */
    fun readStepDataForDate(timestamp: Long) {
        VPLogger.d("readStepDataForDate called - but readSportStep only returns today's data")
        // Just call readStepData since readSportStep doesn't support date queries
        readStepData()
    }

    private val sportDataListener = ISportDataListener { sportData ->
        VPLogger.d("onSportDataChange called with sportData=$sportData")

        // Cancel timeout
        handler.removeCallbacks(timeoutRunnable)
        VPLogger.d("Timeout timer cancelled")

        if (!hasReturnedResult) {
            hasReturnedResult = true

            if (sportData != null) {
                val data = mapOf<String, Any?>(
                    "steps" to sportData.step,
                    "distanceMeters" to sportData.dis,
                    "calories" to sportData.kcal,
                    "activeMinutes" to null, // Not available in SportData
                    "timestamp" to System.currentTimeMillis()
                )
                VPLogger.d("Step data received: steps=${sportData.step}, distance=${sportData.dis}, calories=${sportData.kcal}")
                result.success(data)
            } else {
                VPLogger.d("SportData is null")
                result.success(null)
            }
        }
    }
}
