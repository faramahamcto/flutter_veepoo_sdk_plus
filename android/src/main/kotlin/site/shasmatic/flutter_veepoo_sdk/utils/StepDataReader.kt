package site.shasmatic.flutter_veepoo_sdk.utils

import android.os.Handler
import android.os.Looper
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IOriginDataListener
import com.veepoo.protocol.model.datas.OriginData
import com.veepoo.protocol.model.datas.OriginHalfHourData
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
            VPLogger.e("Origin data read timeout after 30 seconds")
            hasReturnedResult = true
            if (latestStepData != null) {
                VPLogger.d("Returning partial step data after timeout: $latestStepData")
                result.success(latestStepData)
            } else {
                result.error("TIMEOUT", "No step data received within 30 seconds. Device may not have stored origin data.", null)
            }
        }
    }

    /**
     * Reads current step data from the device using readOriginData API.
     * Reads origin data for the last 7 days and returns the most recent.
     */
    fun readStepData() {
        try {
            VPLogger.d("Starting to read step/origin data for last 1 day...")
            VPLogger.d("Device connected: ${vpManager.currentConnectGatt != null}")
            VPLogger.d("Device address: ${vpManager.currentConnectGatt?.device?.address}")

            // Start timeout timer (30 seconds)
            handler.postDelayed(timeoutRunnable, 30000)
            VPLogger.d("Timeout timer started (30 seconds)")

            // Read origin data for last 1 day
            vpManager.readOriginData(writeResponse, originDataListener, 1)
            VPLogger.d("readOriginData() call completed without exception")
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
     * Note: Currently returns the latest available step data as SDK may not support date-specific queries.
     *
     * @param timestamp Date in milliseconds
     */
    fun readStepDataForDate(timestamp: Long) {
        try {
            VPLogger.d("Starting to read step/origin data for specific date (timestamp: $timestamp)...")
            // For now, just read the most recent data (1 day)
            // TODO: Could use readOriginDataSingleDay with proper date conversion
            vpManager.readOriginData(writeResponse, originDataListener, 1)
        } catch (e: InvocationTargetException) {
            result.error("STEP_DATA_ERROR", "Error reading step data for date: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("STEP_DATA_ERROR", "Error reading step data for date: ${e.message}", null)
        }
    }

    private val originDataListener = object : IOriginDataListener {
        override fun onOringinFiveMinuteDataChange(originData: OriginData?) {
            VPLogger.d("onOringinFiveMinuteDataChange called with originData=$originData")
            if (originData != null) {
                // Update the latest step data
                latestStepData = mapOf<String, Any?>(
                    "steps" to originData.stepValue,
                    "distanceMeters" to originData.disValue,
                    "calories" to originData.calValue,
                    "activeMinutes" to null, // Not directly available
                    "heartRate" to originData.rateValue,
                    "timestamp" to System.currentTimeMillis(),
                    "date" to originData.date
                )
                VPLogger.d("Step data received: steps=${originData.stepValue}, distance=${originData.disValue}, calories=${originData.calValue}, date=${originData.date}")
            } else {
                VPLogger.d("onOringinFiveMinuteDataChange: originData is null")
            }
        }

        override fun onOringinHalfHourDataChange(originData: OriginHalfHourData?) {
            VPLogger.d("onOringinHalfHourDataChange called (not used for step data)")
        }

        override fun onReadOriginProgressDetail(day: Int, date: String?, allPackage: Int, currentPackage: Int) {
            VPLogger.d("Reading origin data progress for day $day ($date): package $currentPackage/$allPackage")
        }

        override fun onReadOriginProgress(progress: Float) {
            VPLogger.d("Reading origin data progress: $progress%")
        }

        override fun onReadOriginComplete() {
            VPLogger.d("Origin data read complete")
            // Cancel timeout
            handler.removeCallbacks(timeoutRunnable)
            VPLogger.d("Timeout timer cancelled")

            // Return result only once when reading is complete
            if (!hasReturnedResult) {
                hasReturnedResult = true
                if (latestStepData != null) {
                    VPLogger.d("Returning step data: $latestStepData")
                    result.success(latestStepData)
                } else {
                    VPLogger.d("No step data found in origin data")
                    result.success(null)
                }
            }
        }
    }
}
