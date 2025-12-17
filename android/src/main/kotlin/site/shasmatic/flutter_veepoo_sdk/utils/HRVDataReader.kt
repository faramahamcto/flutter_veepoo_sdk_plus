package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.IHRVOriginDataListener
import com.veepoo.protocol.model.datas.HRVOriginData
import io.flutter.plugin.common.MethodChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException

/**
 * Utility class for reading HRV (Heart Rate Variability) data.
 *
 * HRV data provides insights into stress, recovery, and autonomic nervous system balance.
 *
 * @constructor Creates a new [HRVDataReader] instance.
 * @param result The method channel result to return data to Flutter.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class HRVDataReader(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
) {

    private val writeResponse: VPWriteResponse = VPWriteResponse()
    private val hrvDataList = mutableListOf<Map<String, Any?>>()
    private var hasReturnedResult = false
    private var dayHrvScore: Int = 0

    /**
     * Reads HRV data for the specified number of days.
     * @param days Number of days to read (default: 7)
     */
    fun readHRVData(days: Int = 7) {
        try {
            VPLogger.d("Starting to read HRV data for $days days...")
            hrvDataList.clear()
            hasReturnedResult = false

            vpManager.readHRVOrigin(writeResponse, hrvOriginDataListener, days)
        } catch (e: Exception) {
            VPLogger.e("Error reading HRV data: ${e.message}")
            result.error("HRV_DATA_ERROR", "Error reading HRV data: ${e.message}", null)
        }
    }

    private val hrvOriginDataListener = object : IHRVOriginDataListener {
        override fun onReadOriginProgress(progress: Float) {
            VPLogger.d("HRV data reading progress: ${progress}%")
        }

        override fun onReadOriginProgressDetail(
            currentPackNumber: Int,
            date: String?,
            allPackNumber: Int,
            currentAllPackNumber: Int
        ) {
            VPLogger.d("HRV reading detail - pack: $currentPackNumber/$allPackNumber, date: $date")
        }

        override fun onHRVOriginListener(hrvData: HRVOriginData?) {
            if (hrvData != null) {
                VPLogger.d("HRV data received - date: ${hrvData.date}, value: ${hrvData.hrvValue}, rate: ${hrvData.rate}")

                val hrvMap = mapOf<String, Any?>(
                    "date" to hrvData.date,
                    "hrvValue" to hrvData.hrvValue,
                    "heartRate" to hrvData.rate,
                    "rrValues" to hrvData.rrValue?.toList(),
                    "hrvType" to hrvData.hrvType,
                    "timestamp" to hrvData.mTime?.let { timeData ->
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

            if (!hasReturnedResult) {
                hasReturnedResult = true

                val resultData = mapOf<String, Any?>(
                    "hrvDataList" to hrvDataList,
                    "dayHrvScore" to dayHrvScore,
                    "totalRecords" to hrvDataList.size
                )

                result.success(resultData)
            }
        }
    }
}
