package site.shasmatic.flutter_veepoo_sdk.utils

import com.inuker.bluetooth.library.Code
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IBleWriteResponse
import com.veepoo.protocol.listener.data.IOriginDataListener
import com.veepoo.protocol.listener.data.IOriginData3Listener
import com.veepoo.protocol.model.datas.HRVOriginData
import com.veepoo.protocol.model.datas.OriginData
import com.veepoo.protocol.model.datas.OriginData3
import com.veepoo.protocol.model.datas.OriginHalfHourData
import com.veepoo.protocol.model.datas.Spo2hOriginData
import com.veepoo.protocol.shareprence.VpSpGetUtil
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Utility class for reading origin (5-minute interval) health data from Veepoo devices.
 *
 * This class reads detailed health data including heart rate, blood pressure, steps,
 * calories, and distance for specified days (0=today, 1=yesterday, 2=2 days ago).
 *
 * @param result The method channel result to return data to Flutter.
 * @param vpManager The [VPOperateManager] used to control device operations.
 * @param vpSpGetUtil The [VpSpGetUtil] used to check device capabilities.
 */
class OriginDataReader(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
    private val vpSpGetUtil: VpSpGetUtil,
) {
    private val originDataList = mutableListOf<Map<String, Any?>>()
    private var hasReturnedResult = false
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())
    private var timeoutJob: Job? = null
    private var currentDay: Int = 0
    private var totalDays: Int = 3
    private var currentDayData = mutableListOf<Map<String, Any?>>()
    private val allDaysData = mutableMapOf<Int, MutableList<Map<String, Any?>>>()

    companion object {
        private const val READ_TIMEOUT_MS = 60000L // 60 seconds timeout for reading all days
        private const val RECORDS_PER_DAY = 288 // 24 hours * 12 (5-min intervals)
    }

    /**
     * Reads origin health data for 3 days (today, yesterday, 2 days ago).
     */
    fun readOriginData3Days() {
        try {
            VPLogger.d("Starting to read origin health data for 3 days...")

            hasReturnedResult = false
            originDataList.clear()
            allDaysData.clear()
            currentDay = 0
            totalDays = 3

            // Start timeout timer
            startTimeout()

            // Read data starting from today (day 0)
            readDataForDay(0)

        } catch (e: Exception) {
            VPLogger.e("Error reading origin data: ${e.message}")
            cancelTimeout()
            returnError("ORIGIN_DATA_ERROR", "Error reading origin data: ${e.message}")
        }
    }

    /**
     * Reads origin health data for a specific day.
     * @param day The day to read (0=today, 1=yesterday, 2=2 days ago)
     */
    fun readOriginDataForDay(day: Int) {
        try {
            VPLogger.d("Starting to read origin health data for day $day...")

            hasReturnedResult = false
            originDataList.clear()
            currentDay = day
            totalDays = 1
            currentDayData.clear()

            // Start timeout timer
            startTimeout()

            readDataForDay(day)

        } catch (e: Exception) {
            VPLogger.e("Error reading origin data for day $day: ${e.message}")
            cancelTimeout()
            returnError("ORIGIN_DATA_ERROR", "Error reading origin data: ${e.message}")
        }
    }

    private fun readDataForDay(day: Int) {
        VPLogger.d("Reading origin data for day $day...")
        currentDayData = mutableListOf()
        allDaysData[day] = currentDayData

        val writeResponse = IBleWriteResponse { code ->
            VPLogger.d("Origin data write response for day $day: $code")
            if (code != Code.REQUEST_SUCCESS) {
                VPLogger.e("Origin data request failed with code: $code")
            }
        }

        // Check device protocol version to determine which listener to use
        val protocolVersion = vpSpGetUtil.getOriginProtocolVersion()
        VPLogger.d("Device origin protocol version: $protocolVersion")

        // readOriginDataSingleDay(writeResponse, listener, day, position, watchday)
        // day: 0=today, 1=yesterday, etc.
        // position: starting record position (1-288)
        // watchday: which day on the watch (typically same as day)
        if (protocolVersion == 3 || protocolVersion == 5) {
            vpManager.readOriginDataSingleDay(writeResponse, originData3Listener, day, 1, day)
        } else {
            vpManager.readOriginDataSingleDay(writeResponse, originDataListener, day, 1, day)
        }
    }

    private val originDataListener = object : IOriginDataListener {
        override fun onReadOriginProgress(progress: Float) {
            VPLogger.d("Origin data reading progress: ${progress * 100}%")
        }

        override fun onReadOriginProgressDetail(day: Int, date: String?, allPackage: Int, currentPackage: Int) {
            VPLogger.d("Origin reading detail - day: $day, date: $date, package: $currentPackage/$allPackage")
        }

        override fun onOringinFiveMinuteDataChange(originData: OriginData?) {
            if (originData != null) {
                addOriginData(originData)
            }
        }

        override fun onOringinHalfHourDataChange(originHalfHourData: OriginHalfHourData?) {
            VPLogger.d("Half hour data received for day $currentDay")
        }

        override fun onReadOriginComplete() {
            VPLogger.d("Origin data reading complete for day $currentDay. Records: ${currentDayData.size}")
            onDayComplete()
        }
    }

    private val originData3Listener = object : IOriginData3Listener {
        override fun onReadOriginProgress(progress: Float) {
            VPLogger.d("Origin data reading progress: ${progress * 100}%")
        }

        override fun onReadOriginProgressDetail(day: Int, date: String?, allPackage: Int, currentPackage: Int) {
            VPLogger.d("Origin reading detail - day: $day, date: $date, package: $currentPackage/$allPackage")
        }

        override fun onOriginFiveMinuteListDataChange(originData3List: MutableList<OriginData3>?) {
            if (originData3List != null) {
                for (originData in originData3List) {
                    addOriginData3(originData)
                }
            }
        }

        override fun onOriginHalfHourDataChange(originHalfHourData: OriginHalfHourData?) {
            VPLogger.d("Half hour data received for day $currentDay")
        }

        override fun onOriginHRVOriginListDataChange(hrvList: MutableList<HRVOriginData>?) {
            VPLogger.d("HRV origin data received: ${hrvList?.size} records")
        }

        override fun onOriginSpo2OriginListDataChange(spo2List: MutableList<Spo2hOriginData>?) {
            VPLogger.d("SpO2 origin data received: ${spo2List?.size} records")
        }

        override fun onReadOriginComplete() {
            VPLogger.d("Origin data reading complete for day $currentDay. Records: ${currentDayData.size}")
            onDayComplete()
        }
    }

    private fun addOriginData(originData: OriginData) {
        val timeData = originData.getmTime()
        val timeStr = if (timeData != null) {
            String.format("%02d:%02d", timeData.hour, timeData.minute)
        } else null

        val dataMap = mapOf<String, Any?>(
            "date" to originData.date,
            "time" to timeStr,
            "heartRate" to if (originData.rateValue > 0) originData.rateValue else null,
            "steps" to if (originData.stepValue > 0) originData.stepValue else null,
            "systolic" to if (originData.highValue > 0) originData.highValue else null,
            "diastolic" to if (originData.lowValue > 0) originData.lowValue else null,
            "temperature" to if (originData.temperature > 0) originData.temperature.toDouble() / 10.0 else null,
            "calories" to if (originData.calValue > 0) originData.calValue.toDouble() else null,
            "distance" to if (originData.disValue > 0) originData.disValue.toDouble() else null,
            "sportValue" to if (originData.sportValue > 0) originData.sportValue else null,
            "bloodOxygen" to null
        )

        currentDayData.add(dataMap)
    }

    private fun addOriginData3(originData: OriginData3) {
        val timeData = originData.getmTime()
        val timeStr = if (timeData != null) {
            String.format("%02d:%02d", timeData.hour, timeData.minute)
        } else null

        // Get blood oxygen from oxygens array if available
        val bloodOxygen = originData.oxygens?.firstOrNull { it > 0 }

        val dataMap = mapOf<String, Any?>(
            "date" to originData.date,
            "time" to timeStr,
            "heartRate" to if (originData.rateValue > 0) originData.rateValue else null,
            "steps" to if (originData.stepValue > 0) originData.stepValue else null,
            "systolic" to if (originData.highValue > 0) originData.highValue else null,
            "diastolic" to if (originData.lowValue > 0) originData.lowValue else null,
            "temperature" to if (originData.temperature > 0) originData.temperature.toDouble() / 10.0 else null,
            "calories" to if (originData.calValue > 0) originData.calValue.toDouble() else null,
            "distance" to if (originData.disValue > 0) originData.disValue.toDouble() else null,
            "sportValue" to if (originData.sportValue > 0) originData.sportValue else null,
            "bloodOxygen" to bloodOxygen
        )

        currentDayData.add(dataMap)
    }

    private fun onDayComplete() {
        if (totalDays == 1) {
            // Single day reading complete
            val dailyData = aggregateDailyData(currentDay, currentDayData)
            cancelTimeout()
            returnSuccess(dailyData)
        } else {
            // Multi-day reading
            currentDay++
            if (currentDay < totalDays) {
                // Read next day
                readDataForDay(currentDay)
            } else {
                // All days complete
                val result = mutableListOf<Map<String, Any?>>()
                for (day in 0 until totalDays) {
                    val dayData = allDaysData[day] ?: mutableListOf()
                    val dailyData = aggregateDailyData(day, dayData)
                    result.add(dailyData)
                }
                cancelTimeout()
                returnSuccessList(result)
            }
        }
    }

    private fun aggregateDailyData(day: Int, records: List<Map<String, Any?>>): Map<String, Any?> {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -day)
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val dateStr = dateFormat.format(calendar.time)

        val dayLabel = when (day) {
            0 -> "Today"
            1 -> "Yesterday"
            2 -> "2 Days Ago"
            else -> "$day Days Ago"
        }

        // Calculate aggregates
        val heartRates = records.mapNotNull { it["heartRate"] as? Int }.filter { it > 0 }
        val steps = records.mapNotNull { it["steps"] as? Int }
        val systolics = records.mapNotNull { it["systolic"] as? Int }.filter { it > 0 }
        val diastolics = records.mapNotNull { it["diastolic"] as? Int }.filter { it > 0 }
        val calories = records.mapNotNull { (it["calories"] as? Number)?.toDouble() }
        val distances = records.mapNotNull { (it["distance"] as? Number)?.toDouble() }
        val oxygens = records.mapNotNull { it["bloodOxygen"] as? Int }.filter { it > 0 }

        // Group by hour for hourly data
        val hourlyDataList = mutableListOf<Map<String, Any?>>()
        for (hour in 0..23) {
            val hourLabel = String.format("%02d:00", hour)
            val hourRecords = records.filter { record ->
                val time = record["time"] as? String
                time != null && time.startsWith(String.format("%02d:", hour))
            }

            if (hourRecords.isNotEmpty()) {
                val hourHeartRates = hourRecords.mapNotNull { it["heartRate"] as? Int }.filter { it > 0 }
                val hourSteps = hourRecords.mapNotNull { it["steps"] as? Int }.sum()
                val hourSystolics = hourRecords.mapNotNull { it["systolic"] as? Int }.filter { it > 0 }
                val hourDiastolics = hourRecords.mapNotNull { it["diastolic"] as? Int }.filter { it > 0 }
                val hourCalories = hourRecords.mapNotNull { (it["calories"] as? Number)?.toDouble() }.sum()
                val hourDistances = hourRecords.mapNotNull { (it["distance"] as? Number)?.toDouble() }.sum()
                val hourOxygens = hourRecords.mapNotNull { it["bloodOxygen"] as? Int }.filter { it > 0 }

                val hourlyData = mapOf<String, Any?>(
                    "hour" to hour,
                    "hourLabel" to hourLabel,
                    "steps" to hourSteps,
                    "avgHeartRate" to if (hourHeartRates.isNotEmpty()) hourHeartRates.average().toInt() else null,
                    "maxHeartRate" to hourHeartRates.maxOrNull(),
                    "minHeartRate" to hourHeartRates.minOrNull(),
                    "avgSystolic" to if (hourSystolics.isNotEmpty()) hourSystolics.average().toInt() else null,
                    "avgDiastolic" to if (hourDiastolics.isNotEmpty()) hourDiastolics.average().toInt() else null,
                    "calories" to hourCalories,
                    "distance" to hourDistances,
                    "avgBloodOxygen" to if (hourOxygens.isNotEmpty()) hourOxygens.average().toInt() else null,
                    "records" to hourRecords
                )
                hourlyDataList.add(hourlyData)
            }
        }

        return mapOf<String, Any?>(
            "date" to dateStr,
            "dayLabel" to dayLabel,
            "totalSteps" to steps.sum(),
            "avgHeartRate" to if (heartRates.isNotEmpty()) heartRates.average().toInt() else null,
            "maxHeartRate" to heartRates.maxOrNull(),
            "minHeartRate" to heartRates.minOrNull(),
            "avgSystolic" to if (systolics.isNotEmpty()) systolics.average().toInt() else null,
            "avgDiastolic" to if (diastolics.isNotEmpty()) diastolics.average().toInt() else null,
            "totalCalories" to calories.sum(),
            "totalDistance" to distances.sum(),
            "avgBloodOxygen" to if (oxygens.isNotEmpty()) oxygens.average().toInt() else null,
            "hourlyData" to hourlyDataList
        )
    }

    private fun startTimeout() {
        timeoutJob?.cancel()
        timeoutJob = coroutineScope.launch {
            delay(READ_TIMEOUT_MS)
            VPLogger.w("Origin data read timeout after ${READ_TIMEOUT_MS}ms")
            returnError("ORIGIN_DATA_TIMEOUT", "Origin data read timed out. Device may not have data or is not responding.")
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

    private fun returnSuccessList(data: List<Map<String, Any?>>) {
        cancelTimeout()
        if (!hasReturnedResult) {
            hasReturnedResult = true
            result.success(data)
        }
    }
}
