package site.shasmatic.flutter_veepoo_sdk.utils

import com.inuker.bluetooth.library.Code
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IBleWriteResponse
import com.veepoo.protocol.listener.data.ISleepDataListener
import com.veepoo.protocol.model.datas.SleepData
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for reading sleep data from the device.
 *
 * @constructor Creates a new [SleepDataReader] instance with VPOperateManager.
 * @param result The method channel result to send data back to Flutter.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class SleepDataReader(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
) {

    private val sleepDataList = mutableListOf<Map<String, Any?>>()
    private var hasReturnedResult = false
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())
    private var timeoutJob: Job? = null
    private var lastProgressTime: Long = 0
    private var inactivityCheckJob: Job? = null

    companion object {
        private const val READ_TIMEOUT_MS = 60000L // 60 seconds total timeout
        private const val INACTIVITY_TIMEOUT_MS = 10000L // 10 seconds of no progress = done
    }

    /**
     * Reads sleep data from the device using readSleepData API.
     * Reads sleep data for the last 7 days.
     */
    fun readSleepData() {
        try {
            VPLogger.d("Starting to read sleep data for 7 days...")
            sleepDataList.clear()
            hasReturnedResult = false
            lastProgressTime = System.currentTimeMillis()

            // Start total timeout
            startTotalTimeout()
            // Start inactivity check
            startInactivityCheck()

            // Create write response with error handling
            val writeResponse = IBleWriteResponse { code ->
                VPLogger.d("Sleep read write response: $code (SUCCESS=${Code.REQUEST_SUCCESS})")
                when (code) {
                    Code.REQUEST_SUCCESS -> {
                        VPLogger.d("Sleep read request sent successfully, waiting for data...")
                    }
                    else -> {
                        VPLogger.e("Sleep read request failed with code: $code")
                        cancelTimeouts()
                        returnError("SLEEP_REQUEST_FAILED", "Failed to request sleep data (code: $code)")
                    }
                }
            }

            VPLogger.d("Calling vpManager.readSleepData with days=7")
            vpManager.readSleepData(writeResponse, sleepDataListener, 7)
            VPLogger.d("vpManager.readSleepData called, waiting for response...")
        } catch (e: InvocationTargetException) {
            VPLogger.e("InvocationTargetException reading sleep data: ${e.targetException?.message}")
            cancelTimeouts()
            returnError("SLEEP_DATA_ERROR", "Error reading sleep data: ${e.targetException?.message}")
        } catch (e: Exception) {
            VPLogger.e("Exception reading sleep data: ${e.message}")
            cancelTimeouts()
            returnError("SLEEP_DATA_ERROR", "Error reading sleep data: ${e.message}")
        }
    }

    private fun startTotalTimeout() {
        timeoutJob?.cancel()
        timeoutJob = coroutineScope.launch {
            delay(READ_TIMEOUT_MS)
            VPLogger.w("Sleep data read total timeout after ${READ_TIMEOUT_MS}ms")
            returnDataOrTimeout()
        }
    }

    private fun startInactivityCheck() {
        inactivityCheckJob?.cancel()
        inactivityCheckJob = coroutineScope.launch {
            while (true) {
                delay(1000) // Check every second
                val timeSinceLastProgress = System.currentTimeMillis() - lastProgressTime
                if (timeSinceLastProgress > INACTIVITY_TIMEOUT_MS) {
                    VPLogger.d("No progress for ${INACTIVITY_TIMEOUT_MS}ms, assuming read is complete")
                    returnDataOrTimeout()
                    break
                }
            }
        }
    }

    private fun cancelTimeouts() {
        timeoutJob?.cancel()
        timeoutJob = null
        inactivityCheckJob?.cancel()
        inactivityCheckJob = null
    }

    private fun returnError(code: String, message: String) {
        if (!hasReturnedResult) {
            hasReturnedResult = true
            result.error(code, message, null)
        }
    }

    private fun returnDataOrTimeout() {
        cancelTimeouts()
        if (!hasReturnedResult) {
            hasReturnedResult = true
            if (sleepDataList.isNotEmpty()) {
                VPLogger.d("Returning ${sleepDataList.size} sleep data records")
                // Return the most recent sleep data (last item)
                result.success(sleepDataList.last())
            } else {
                VPLogger.d("No sleep data found")
                result.success(null)
            }
        }
    }

    private val sleepDataListener = object : ISleepDataListener {
        override fun onSleepDataChange(date: String?, sleepData: SleepData?) {
            lastProgressTime = System.currentTimeMillis() // Update activity timestamp

            if (sleepData != null) {
                val sleepDataMap = mapOf<String, Any?>(
                    "totalSleepMinutes" to sleepData.allSleepTime,
                    "deepSleepMinutes" to sleepData.deepSleepTime,
                    "lightSleepMinutes" to sleepData.lowSleepTime,
                    "awakeMinutes" to 0, // SDK doesn't provide awake time, only wake count
                    "wakeCount" to sleepData.wakeCount,
                    "sleepQuality" to sleepData.sleepQulity,
                    "sleepStartTime" to sleepData.sleepDown?.toString(),
                    "sleepEndTime" to sleepData.sleepUp?.toString(),
                    "sleepCurve" to sleepData.sleepLine,
                    "date" to date
                )
                sleepDataList.add(sleepDataMap)
                VPLogger.d("Sleep data received for $date: allSleep=${sleepData.allSleepTime}, deep=${sleepData.deepSleepTime}, light=${sleepData.lowSleepTime}")
            } else {
                VPLogger.d("No sleep data available for $date")
            }
        }

        override fun onSleepProgress(progress: Float) {
            lastProgressTime = System.currentTimeMillis() // Update activity timestamp
            VPLogger.d("Sleep data read progress: $progress%")
        }

        override fun onSleepProgressDetail(date: String?, progress: Int) {
            lastProgressTime = System.currentTimeMillis() // Update activity timestamp
            VPLogger.d("Sleep data read progress for $date: $progress%")
        }

        override fun onReadSleepComplete() {
            VPLogger.d("Sleep data read complete callback received")
            returnDataOrTimeout()
        }
    }
}
