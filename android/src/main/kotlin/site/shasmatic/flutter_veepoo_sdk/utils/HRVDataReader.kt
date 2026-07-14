package site.shasmatic.flutter_veepoo_sdk.utils

import com.inuker.bluetooth.library.Code
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IBleWriteResponse
import com.veepoo.protocol.listener.data.IHRVOriginDataListener
import com.veepoo.protocol.model.datas.HRVOriginData
import com.veepoo.protocol.model.settings.ReadOriginSetting
import com.veepoo.protocol.shareprence.VpSpGetUtil
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException

/**
 * Utility class for reading HRV (Heart Rate Variability) data.
 *
 * HRV data provides insights into stress, recovery, and autonomic nervous system balance.
 *
 * @constructor Creates a new [HRVDataReader] instance.
 * @param result The method channel result to return data to Flutter.
 * @param vpManager The [VPOperateManager] used to control device operations.
 * @param vpSpGetUtil The [VpSpGetUtil] used to check device capabilities.
 */
class HRVDataReader(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
    private val vpSpGetUtil: VpSpGetUtil,
) {

    private val hrvDataList = mutableListOf<Map<String, Any?>>()
    private var hasReturnedResult = false
    private var dayHrvScore: Int = 0
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())
    private var timeoutJob: Job? = null

    companion object {
        private const val READ_TIMEOUT_MS = 30000L // 30 seconds timeout
    }

    /**
     * Reads HRV data for the specified number of days.
     *
     * @param days Number of days to read (default: 7)
     * @param startDay Day offset to start from: 0 = today, 1 = yesterday, etc (default: 0).
     * HRV is generated as an end-of-day statistic, so day 0 (today, still accumulating) may
     * have nothing to return yet — some devices will then never send a response at all,
     * which surfaces here as a timeout rather than an empty result. If today's HRV keeps
     * timing out, try startDay = 1 to read yesterday's (complete) data instead.
     */
    fun readHRVData(days: Int = 7, startDay: Int = 0) {
        try {
            VPLogger.d("Starting to read HRV data for $days days starting from day $startDay...")

            // Check if device supports HRV
            val supportsHRV = vpSpGetUtil.isSupportHRV()
            val supportsAllDayHRV = vpSpGetUtil.isSupportAllDayHRV()
            val hrvType = vpSpGetUtil.getHrvType()

            VPLogger.d("Device HRV support - isSupportHRV: $supportsHRV, isSupportAllDayHRV: $supportsAllDayHRV, hrvType: $hrvType")

            if (!supportsHRV) {
                returnError("HRV_NOT_SUPPORTED", "This device does not support HRV data reading")
                return
            }

            hrvDataList.clear()
            hasReturnedResult = false

            // Start timeout timer
            startTimeout()

            // Create write response with error handling
            val writeResponse = IBleWriteResponse { code ->
                VPLogger.d("HRV write response received with code: $code (SUCCESS=${Code.REQUEST_SUCCESS})")
                when (code) {
                    Code.REQUEST_SUCCESS -> {
                        VPLogger.d("HRV read request sent successfully, waiting for data...")
                    }
                    else -> {
                        VPLogger.e("HRV read request failed with code: $code")
                        cancelTimeout()
                        returnError("HRV_REQUEST_FAILED", "Failed to request HRV data (code: $code)")
                    }
                }
            }

            // Call readHRVOriginBySetting directly rather than the readHRVOrigin(days)
            // convenience wrapper, since that wrapper always hardcodes day=0 (today) and
            // gives no way to start from an earlier, complete day.
            val setting = ReadOriginSetting(startDay, 1, days == 1, days)
            VPLogger.d("Calling vpManager.readHRVOriginBySetting with $setting")
            vpManager.readHRVOriginBySetting(writeResponse, hrvOriginDataListener, setting)
            VPLogger.d("vpManager.readHRVOriginBySetting called, waiting for response...")
        } catch (e: Exception) {
            VPLogger.e("Error reading HRV data: ${e.message}")
            cancelTimeout()
            returnError("HRV_DATA_ERROR", "Error reading HRV data: ${e.message}")
        }
    }

    private fun startTimeout() {
        timeoutJob?.cancel()
        timeoutJob = coroutineScope.launch {
            delay(READ_TIMEOUT_MS)
            VPLogger.w("HRV data read timeout after ${READ_TIMEOUT_MS}ms")
            returnError(
                "HRV_TIMEOUT",
                "HRV data read timed out with zero response from the device (not even a " +
                "write acknowledgment) — this looks like an internal SDK compatibility gate " +
                "for this specific watch/firmware rather than a timing issue, since it " +
                "doesn't depend on which day was requested. Consider using the origin/5-min " +
                "data flow (readOriginData3Days/readOriginDataForDay) instead, which reaches " +
                "this device successfully."
            )
        }
    }

    private fun cancelTimeout() {
        timeoutJob?.cancel()
        timeoutJob = null
    }

    private fun returnError(code: String, message: String) {
        if (!hasReturnedResult) {
            hasReturnedResult = true
            result.error(code, message, null)
        }
    }

    private fun returnSuccess(data: Map<String, Any?>) {
        cancelTimeout()
        if (!hasReturnedResult) {
            hasReturnedResult = true
            result.success(data)
        }
    }

    private val hrvOriginDataListener = object : IHRVOriginDataListener {
        override fun onReadOriginProgress(progress: Float) {
            // Logged unconditionally, including 0%, so a total absence of this line in logcat
            // means the device never acknowledged the read at all (as opposed to acknowledging
            // and then reporting no progress).
            VPLogger.d("RAW onReadOriginProgress: ${progress * 100}%")
        }

        override fun onReadOriginProgressDetail(
            currentPackNumber: Int,
            date: String?,
            allPackNumber: Int,
            currentAllPackNumber: Int
        ) {
            VPLogger.d(
                "RAW onReadOriginProgressDetail - pack: $currentPackNumber/$allPackNumber, " +
                "date: $date, currentAllPackNumber: $currentAllPackNumber"
            )
        }

        override fun onHRVOriginListener(hrvData: HRVOriginData?) {
            VPLogger.d("RAW onHRVOriginListener: $hrvData")
            if (hrvData != null) {
                VPLogger.d("HRV data received - date: ${hrvData.date}, value: ${hrvData.hrvValue}, rate: ${hrvData.rate}")

                val hrvMap = mapOf<String, Any?>(
                    "date" to hrvData.date,
                    "hrvValue" to hrvData.hrvValue,
                    "heartRate" to hrvData.rate,
                    "rrValues" to hrvData.rrValue?.toList(),
                    "hrvType" to hrvData.hrvType,
                    "timestamp" to hrvData.getmTime()?.let { timeData ->
                        // Convert TimeData to timestamp if needed
                        "${hrvData.date} ${timeData.hour}:${timeData.minute}:${timeData.second}"
                    }
                )

                hrvDataList.add(hrvMap)
            }
        }

        override fun onDayHrvScore(score: Int, date: String?, type: Int) {
            VPLogger.d("Day HRV score: $score, date: $date, type: $type")
            dayHrvScore = score
        }

        override fun onReadOriginComplete() {
            VPLogger.d("HRV data reading complete. Total records: ${hrvDataList.size}")

            val resultData = mapOf<String, Any?>(
                "hrvDataList" to hrvDataList,
                "dayHrvScore" to dayHrvScore,
                "totalRecords" to hrvDataList.size
            )

            returnSuccess(resultData)
        }
    }
}
