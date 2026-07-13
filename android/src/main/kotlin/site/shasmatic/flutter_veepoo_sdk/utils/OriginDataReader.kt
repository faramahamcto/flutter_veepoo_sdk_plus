package site.shasmatic.flutter_veepoo_sdk.utils

import android.os.Handler
import android.os.Looper
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
import io.flutter.plugin.common.EventChannel
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
 */
class OriginDataReader(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
    private val vpSpGetUtil: VpSpGetUtil,
    private val progressEventSink: EventChannel.EventSink?,
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var hasReturnedResult = false
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())
    private var timeoutJob: Job? = null
    private var currentDay: Int = 0
    private var totalDays: Int = 3
    private var currentDayData = mutableListOf<Map<String, Any?>>()
    private val allDaysData = mutableMapOf<Int, MutableList<Map<String, Any?>>>()
    private val hrvDataMap = mutableMapOf<String, Int>() // Maps "HH:mm" to HRV value

    companion object {
        private const val READ_TIMEOUT_MS = 90000L // 90 seconds timeout
    }

    fun readOriginData3Days() {
        try {
            VPLogger.d("Starting to read origin health data for 3 days...")
            hasReturnedResult = false
            allDaysData.clear()
            currentDay = 0
            totalDays = 3
            startTimeout()
            readDataForDay(0)
        } catch (e: Exception) {
            VPLogger.e("Error reading origin data: ${e.message}")
            cancelTimeout()
            returnError("ORIGIN_DATA_ERROR", "Error reading origin data: ${e.message}")
        }
    }

    fun readOriginDataForDay(day: Int) {
        try {
            VPLogger.d("Starting to read origin health data for day $day...")
            hasReturnedResult = false
            currentDay = day
            totalDays = 1
            currentDayData.clear()
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
        hrvDataMap.clear() // Clear HRV data for new day

        val writeResponse = IBleWriteResponse { code ->
            VPLogger.d("Origin data write response for day $day: $code")
            if (code != Code.REQUEST_SUCCESS) {
                VPLogger.e("Origin data request failed with code: $code")
            }
        }

        val protocolVersion = vpSpGetUtil.getOriginProtocolVersion()
        VPLogger.d("Device origin protocol version: $protocolVersion")

        if (protocolVersion == 3 || protocolVersion == 5) {
            vpManager.readOriginDataSingleDay(writeResponse, originData3Listener, day, 1, day)
        } else {
            vpManager.readOriginDataSingleDay(writeResponse, originDataListener, day, 1, day)
        }
    }

    private fun sendProgress(progress: Float, day: Int, dayLabel: String) {
        mainHandler.post {
            progressEventSink?.success(mapOf(
                "progress" to progress,
                "day" to day,
                "dayLabel" to dayLabel,
                "totalDays" to totalDays
            ))
        }
    }

    private fun getDayLabel(day: Int): String {
        return when (day) {
            0 -> "Today"
            1 -> "Yesterday"
            2 -> "2 Days Ago"
            else -> "$day Days Ago"
        }
    }

    private val originDataListener = object : IOriginDataListener {
        override fun onReadOriginProgress(progress: Float) {
            VPLogger.d("Origin data reading progress: ${progress * 100}%")
            val overallProgress = if (totalDays > 1) {
                (currentDay.toFloat() + progress) / totalDays.toFloat()
            } else {
                progress
            }
            sendProgress(overallProgress, currentDay, getDayLabel(currentDay))
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
            val overallProgress = if (totalDays > 1) {
                (currentDay.toFloat() + progress) / totalDays.toFloat()
            } else {
                progress
            }
            sendProgress(overallProgress, currentDay, getDayLabel(currentDay))
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
            hrvList?.forEach { hrvData ->
                val timeData = hrvData.getmTime()
                if (timeData != null && hrvData.hrvValue > 0) {
                    val timeKey = String.format("%02d:%02d", timeData.hour, timeData.minute)
                    hrvDataMap[timeKey] = hrvData.hrvValue
                    VPLogger.d("HRV data stored: $timeKey -> ${hrvData.hrvValue}")
                }
            }
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

        // Look up HRV value for this time
        val hrvValue = timeStr?.let { hrvDataMap[it] }

        val dataMap = mapOf<String, Any?>(
            "date" to originData.date,
            "time" to timeStr,
            // Heart Rate
            "heartRate" to if (originData.rateValue > 0) originData.rateValue else null,
            // Blood Pressure
            "systolic" to if (originData.highValue > 0) originData.highValue else null,
            "diastolic" to if (originData.lowValue > 0) originData.lowValue else null,
            // Temperature
            "temperature" to if (originData.temperature > 0) originData.temperature.toDouble() else null,
            // Steps & Activity
            "steps" to if (originData.stepValue > 0) originData.stepValue else null,
            "calories" to if (originData.calValue > 0) originData.calValue.toDouble() else null,
            "distance" to if (originData.disValue > 0) originData.disValue.toDouble() else null,
            "sportValue" to if (originData.sportValue > 0) originData.sportValue else null,
            // Blood Oxygen (not available in OriginData)
            "bloodOxygen" to null,
            // Blood Glucose (not available in OriginData)
            "bloodGlucose" to null,
            // Respiration Rate (not available in OriginData)
            "respirationRate" to null,
            // ECG heart rate (not available in OriginData)
            "ecgHeartRate" to null,
            // Blood Components (not available in OriginData)
            "uricAcid" to null,
            "totalCholesterol" to null,
            "triglyceride" to null,
            "hdl" to null,
            "ldl" to null,
            // HRV
            "hrvValue" to hrvValue
        )

        currentDayData.add(dataMap)
    }

    private fun addOriginData3(originData: OriginData3) {
        val timeData = originData.getmTime()
        val timeStr = if (timeData != null) {
            String.format("%02d:%02d", timeData.hour, timeData.minute)
        } else null

        // Extract values from arrays
        val bloodOxygen = originData.oxygens?.firstOrNull { it > 0 }
        val respirationRate = originData.resRates?.firstOrNull { it > 0 }
        val ecgHeartRate = originData.ecgs?.firstOrNull { it > 0 }
        val ppgHeartRate = originData.ppgs?.firstOrNull { it > 0 }

        // Extract blood component data
        val bloodComponent = originData.bloodComponent
        val uricAcid = bloodComponent?.uricAcid?.takeIf { it > 0 }
        val totalCholesterol = bloodComponent?.tCHO?.takeIf { it > 0 }
        val triglyceride = bloodComponent?.tAG?.takeIf { it > 0 }
        val hdl = bloodComponent?.hDL?.takeIf { it > 0 }
        val ldl = bloodComponent?.lDL?.takeIf { it > 0 }

        // Look up HRV value for this time
        val hrvValue = timeStr?.let { hrvDataMap[it] }

        val dataMap = mapOf<String, Any?>(
            "date" to originData.date,
            "time" to timeStr,
            // Heart Rate (use ppg or rate value)
            "heartRate" to (ppgHeartRate ?: if (originData.rateValue > 0) originData.rateValue else null),
            // Blood Pressure
            "systolic" to if (originData.highValue > 0) originData.highValue else null,
            "diastolic" to if (originData.lowValue > 0) originData.lowValue else null,
            // Temperature
            "temperature" to if (originData.temperature > 0) originData.temperature.toDouble() else null,
            // Blood Oxygen
            "bloodOxygen" to bloodOxygen,
            // Steps & Activity
            "steps" to if (originData.stepValue > 0) originData.stepValue else null,
            "calories" to if (originData.calValue > 0) originData.calValue.toDouble() else null,
            "distance" to if (originData.disValue > 0) originData.disValue.toDouble() else null,
            "sportValue" to if (originData.sportValue > 0) originData.sportValue else null,
            // Blood Glucose
            "bloodGlucose" to if (originData.bloodGlucose > 0) originData.bloodGlucose else null,
            // Respiration Rate
            "respirationRate" to respirationRate,
            // ECG Heart Rate
            "ecgHeartRate" to ecgHeartRate,
            // Blood Components
            "uricAcid" to uricAcid,
            "totalCholesterol" to totalCholesterol,
            "triglyceride" to triglyceride,
            "hdl" to hdl,
            "ldl" to ldl,
            // HRV
            "hrvValue" to hrvValue
        )

        currentDayData.add(dataMap)
    }

    private fun onDayComplete() {
        if (totalDays == 1) {
            val dailyData = aggregateDailyData(currentDay, currentDayData)
            cancelTimeout()
            returnSuccess(dailyData)
        } else {
            currentDay++
            if (currentDay < totalDays) {
                readDataForDay(currentDay)
            } else {
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

        // Calculate aggregates for each category
        val heartRates = records.mapNotNull { it["heartRate"] as? Int }.filter { it > 0 }
        val systolics = records.mapNotNull { it["systolic"] as? Int }.filter { it > 0 }
        val diastolics = records.mapNotNull { it["diastolic"] as? Int }.filter { it > 0 }
        val temperatures = records.mapNotNull { (it["temperature"] as? Number)?.toDouble() }.filter { it > 0 }
        val oxygens = records.mapNotNull { it["bloodOxygen"] as? Int }.filter { it > 0 }
        val steps = records.mapNotNull { it["steps"] as? Int }
        val calories = records.mapNotNull { (it["calories"] as? Number)?.toDouble() }
        val distances = records.mapNotNull { (it["distance"] as? Number)?.toDouble() }
        val sports = records.mapNotNull { it["sportValue"] as? Int }.filter { it > 0 }
        val glucoses = records.mapNotNull { it["bloodGlucose"] as? Int }.filter { it > 0 }
        val respRates = records.mapNotNull { it["respirationRate"] as? Int }.filter { it > 0 }
        val ecgRates = records.mapNotNull { it["ecgHeartRate"] as? Int }.filter { it > 0 }
        // Blood Components
        val uricAcids = records.mapNotNull { (it["uricAcid"] as? Number)?.toDouble() }.filter { it > 0 }
        val cholesterols = records.mapNotNull { (it["totalCholesterol"] as? Number)?.toDouble() }.filter { it > 0 }
        val triglycerides = records.mapNotNull { (it["triglyceride"] as? Number)?.toDouble() }.filter { it > 0 }
        val hdls = records.mapNotNull { (it["hdl"] as? Number)?.toDouble() }.filter { it > 0 }
        val ldls = records.mapNotNull { (it["ldl"] as? Number)?.toDouble() }.filter { it > 0 }
        // HRV
        val hrvValues = records.mapNotNull { it["hrvValue"] as? Int }.filter { it > 0 }

        // Group by hour for hourly data
        val hourlyDataList = mutableListOf<Map<String, Any?>>()
        for (hour in 0..23) {
            val hourLabel = String.format("%02d:00", hour)
            val hourRecords = records.filter { record ->
                val time = record["time"] as? String
                time != null && time.startsWith(String.format("%02d:", hour))
            }

            if (hourRecords.isNotEmpty()) {
                val hourData = aggregateHourlyData(hour, hourLabel, hourRecords)
                hourlyDataList.add(hourData)
            }
        }

        return mapOf<String, Any?>(
            "date" to dateStr,
            "dayLabel" to dayLabel,
            // Heart Rate
            "avgHeartRate" to if (heartRates.isNotEmpty()) heartRates.average().toInt() else null,
            "maxHeartRate" to heartRates.maxOrNull(),
            "minHeartRate" to heartRates.minOrNull(),
            // Blood Pressure
            "avgSystolic" to if (systolics.isNotEmpty()) systolics.average().toInt() else null,
            "avgDiastolic" to if (diastolics.isNotEmpty()) diastolics.average().toInt() else null,
            "maxSystolic" to systolics.maxOrNull(),
            "minSystolic" to systolics.minOrNull(),
            // Temperature
            "avgTemperature" to if (temperatures.isNotEmpty()) temperatures.average() else null,
            "maxTemperature" to temperatures.maxOrNull(),
            "minTemperature" to temperatures.minOrNull(),
            // Blood Oxygen
            "avgBloodOxygen" to if (oxygens.isNotEmpty()) oxygens.average().toInt() else null,
            "minBloodOxygen" to oxygens.minOrNull(),
            // Steps & Activity
            "totalSteps" to steps.sum(),
            "totalCalories" to calories.sum(),
            "totalDistance" to distances.sum(),
            "avgSportValue" to if (sports.isNotEmpty()) sports.average().toInt() else null,
            // Blood Glucose
            "avgBloodGlucose" to if (glucoses.isNotEmpty()) glucoses.average().toInt() else null,
            // Respiration Rate
            "avgRespirationRate" to if (respRates.isNotEmpty()) respRates.average().toInt() else null,
            // ECG Heart Rate
            "avgEcgHeartRate" to if (ecgRates.isNotEmpty()) ecgRates.average().toInt() else null,
            // Blood Components
            "avgUricAcid" to if (uricAcids.isNotEmpty()) uricAcids.average() else null,
            "avgTotalCholesterol" to if (cholesterols.isNotEmpty()) cholesterols.average() else null,
            "avgTriglyceride" to if (triglycerides.isNotEmpty()) triglycerides.average() else null,
            "avgHdl" to if (hdls.isNotEmpty()) hdls.average() else null,
            "avgLdl" to if (ldls.isNotEmpty()) ldls.average() else null,
            // HRV
            "avgHrvValue" to if (hrvValues.isNotEmpty()) hrvValues.average().toInt() else null,
            "maxHrvValue" to hrvValues.maxOrNull(),
            "minHrvValue" to hrvValues.minOrNull(),
            // Hourly data
            "hourlyData" to hourlyDataList
        )
    }

    private fun aggregateHourlyData(hour: Int, hourLabel: String, records: List<Map<String, Any?>>): Map<String, Any?> {
        val heartRates = records.mapNotNull { it["heartRate"] as? Int }.filter { it > 0 }
        val systolics = records.mapNotNull { it["systolic"] as? Int }.filter { it > 0 }
        val diastolics = records.mapNotNull { it["diastolic"] as? Int }.filter { it > 0 }
        val temperatures = records.mapNotNull { (it["temperature"] as? Number)?.toDouble() }.filter { it > 0 }
        val oxygens = records.mapNotNull { it["bloodOxygen"] as? Int }.filter { it > 0 }
        val steps = records.mapNotNull { it["steps"] as? Int }
        val calories = records.mapNotNull { (it["calories"] as? Number)?.toDouble() }
        val distances = records.mapNotNull { (it["distance"] as? Number)?.toDouble() }
        val sports = records.mapNotNull { it["sportValue"] as? Int }.filter { it > 0 }
        val glucoses = records.mapNotNull { it["bloodGlucose"] as? Int }.filter { it > 0 }
        val respRates = records.mapNotNull { it["respirationRate"] as? Int }.filter { it > 0 }
        // Blood Components
        val uricAcids = records.mapNotNull { (it["uricAcid"] as? Number)?.toDouble() }.filter { it > 0 }
        val cholesterols = records.mapNotNull { (it["totalCholesterol"] as? Number)?.toDouble() }.filter { it > 0 }
        val triglycerides = records.mapNotNull { (it["triglyceride"] as? Number)?.toDouble() }.filter { it > 0 }
        val hdls = records.mapNotNull { (it["hdl"] as? Number)?.toDouble() }.filter { it > 0 }
        val ldls = records.mapNotNull { (it["ldl"] as? Number)?.toDouble() }.filter { it > 0 }
        // HRV
        val hrvValues = records.mapNotNull { it["hrvValue"] as? Int }.filter { it > 0 }

        return mapOf<String, Any?>(
            "hour" to hour,
            "hourLabel" to hourLabel,
            // Heart Rate
            "avgHeartRate" to if (heartRates.isNotEmpty()) heartRates.average().toInt() else null,
            "maxHeartRate" to heartRates.maxOrNull(),
            "minHeartRate" to heartRates.minOrNull(),
            // Blood Pressure
            "avgSystolic" to if (systolics.isNotEmpty()) systolics.average().toInt() else null,
            "avgDiastolic" to if (diastolics.isNotEmpty()) diastolics.average().toInt() else null,
            // Temperature
            "avgTemperature" to if (temperatures.isNotEmpty()) temperatures.average() else null,
            // Blood Oxygen
            "avgBloodOxygen" to if (oxygens.isNotEmpty()) oxygens.average().toInt() else null,
            // Steps & Activity
            "steps" to steps.sum(),
            "calories" to calories.sum(),
            "distance" to distances.sum(),
            "avgSportValue" to if (sports.isNotEmpty()) sports.average().toInt() else null,
            // Blood Glucose
            "avgBloodGlucose" to if (glucoses.isNotEmpty()) glucoses.average().toInt() else null,
            // Respiration Rate
            "avgRespirationRate" to if (respRates.isNotEmpty()) respRates.average().toInt() else null,
            // Blood Components
            "avgUricAcid" to if (uricAcids.isNotEmpty()) uricAcids.average() else null,
            "avgTotalCholesterol" to if (cholesterols.isNotEmpty()) cholesterols.average() else null,
            "avgTriglyceride" to if (triglycerides.isNotEmpty()) triglycerides.average() else null,
            "avgHdl" to if (hdls.isNotEmpty()) hdls.average() else null,
            "avgLdl" to if (ldls.isNotEmpty()) ldls.average() else null,
            // HRV
            "avgHrvValue" to if (hrvValues.isNotEmpty()) hrvValues.average().toInt() else null,
            "maxHrvValue" to hrvValues.maxOrNull(),
            "minHrvValue" to hrvValues.minOrNull(),
            // Raw records
            "records" to records
        )
    }

    private fun startTimeout() {
        timeoutJob?.cancel()
        timeoutJob = coroutineScope.launch {
            delay(READ_TIMEOUT_MS)
            VPLogger.w("Origin data read timeout after ${READ_TIMEOUT_MS}ms")
            returnError("ORIGIN_DATA_TIMEOUT", "Origin data read timed out.")
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
