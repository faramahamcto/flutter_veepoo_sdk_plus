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
    private var dayCompleteJob: Job? = null

    companion object {
        private const val READ_TIMEOUT_MS = 90000L // 90 seconds timeout

        // Per the vendor docs, HRV is generated as a post-processing step "after reading the
        // original data of the day" — i.e. on its own timer, not pushed alongside the rest of
        // the day's data. Real device logs confirm onOriginFiveMinuteListDataChange/
        // onOriginSpo2OriginListDataChange/onOriginHalfHourDataChange/onReadOriginComplete all
        // fire within ~100ms of each other with zero onOriginHRVOriginListDataChange calls in
        // between. Finalizing the instant onReadOriginComplete fires was very likely cutting
        // off HRV before the device had a chance to send it, so we wait a bit longer first.
        private const val HRV_GRACE_PERIOD_MS = 2500L
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

        // readOriginDataSingleDay(response, listener, day, position, watchday) builds
        // ReadOriginSetting(day, position, onlyReadOneDay=true, watchday) under the hood. The
        // last argument is the day *count* (watchday), not the day offset again — passing `day`
        // there (e.g. watchday=0 for "today") was asking the device for zero/wrong-count days
        // of data, which may be why HRV generation for the day never fires. We always want
        // exactly one day (this is a single-day read), so watchday must be 1.
        VPLogger.d("Requesting origin data: day=$day, position=1, watchday=1 (protocol=$protocolVersion)")

        if (protocolVersion == 3 || protocolVersion == 5) {
            vpManager.readOriginDataSingleDay(writeResponse, originData3Listener, day, 1, 1)
        } else {
            vpManager.readOriginDataSingleDay(writeResponse, originDataListener, day, 1, 1)
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
            scheduleDayComplete()
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
            VPLogger.d(
                "RAW onOriginFiveMinuteListDataChange: ${originData3List?.size} records" +
                (originData3List?.firstOrNull()?.let { " | first=${it}" } ?: "")
            )
            if (originData3List != null) {
                for (originData in originData3List) {
                    addOriginData3(originData)
                }
            }
        }

        override fun onOriginHalfHourDataChange(originHalfHourData: OriginHalfHourData?) {
            VPLogger.d("RAW onOriginHalfHourDataChange for day $currentDay: $originHalfHourData")
        }

        override fun onOriginHRVOriginListDataChange(hrvList: MutableList<HRVOriginData>?) {
            // Logged unconditionally (even null/empty) so a missing "RAW onOriginHRVOrigin..."
            // line in logcat means the SDK never called this back at all, as opposed to
            // calling back with nothing.
            VPLogger.d(
                "RAW onOriginHRVOriginListDataChange: " +
                (if (hrvList == null) "null (callback fired with null list)" else "${hrvList.size} records")
            )
            hrvList?.forEachIndexed { index, hrvData ->
                VPLogger.d("RAW HRVOriginData[$index]: $hrvData")
                val timeData = hrvData.getmTime()
                if (timeData != null && hrvData.hrvValue > 0) {
                    val timeKey = String.format("%02d:%02d", timeData.hour, timeData.minute)
                    hrvDataMap[timeKey] = hrvData.hrvValue
                    VPLogger.d("HRV data stored: $timeKey -> ${hrvData.hrvValue}")
                }
            }
        }

        override fun onOriginSpo2OriginListDataChange(spo2List: MutableList<Spo2hOriginData>?) {
            VPLogger.d("RAW onOriginSpo2OriginListDataChange: ${spo2List?.size} records")
        }

        override fun onReadOriginComplete() {
            VPLogger.d("Origin data reading complete for day $currentDay. Records: ${currentDayData.size}")
            scheduleDayComplete()
        }
    }

    private fun addOriginData(originData: OriginData) {
        val timeData = originData.getmTime()
        val timeStr = if (timeData != null) {
            String.format("%02d:%02d", timeData.hour, timeData.minute)
        } else null

        // HRV is delivered separately (onOriginHRVOriginListDataChange) after the five-minute
        // data for the day, so it can't be resolved yet. It's merged in later via mergeHrvData().
        val hrvValue = null

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
            "hrvValue" to hrvValue,
            // Raw device wear-detection code (vendor doesn't document the exact value
            // mapping, e.g. worn/not-worn/uncertain — exposed as-is for filtering).
            "wear" to originData.wear,
            // Remaining raw OriginData fields, exposed as-is (undocumented by vendor beyond
            // their names). tempOne/tempTwo are the raw dual-sensor temperature readings that
            // "temperature" is calibrated/derived from; drinkPartOne/Two relate to hydration
            // tracking on devices that support it.
            "tempOne" to originData.tempOne.takeIf { it > 0 },
            "tempTwo" to originData.tempTwo.takeIf { it > 0 },
            "calcType" to originData.calcType,
            "baseTemperature" to originData.baseTemperature.takeIf { it > 0 }?.toDouble(),
            "drinkPartOne" to originData.drinkPartOne?.takeIf { it.isNotEmpty() },
            "drinkPartTwo" to originData.drinkPartTwo?.takeIf { it.isNotEmpty() }
        )

        currentDayData.add(dataMap)
    }

    private fun addOriginData3(originData: OriginData3) {
        val timeData = originData.getmTime()
        val timeStr = if (timeData != null) {
            String.format("%02d:%02d", timeData.hour, timeData.minute)
        } else null

        // Extract values from arrays. 255 is the device's "no reading" sentinel for these
        // byte-range channels (confirmed from real device logs: resRates comes back as
        // [255, 255, 255, 255, 255] with no respiration sensor active) — treating it as a
        // valid reading of 255 breaths/min was a real bug, not just a theoretical edge case.
        val bloodOxygen = originData.oxygens?.firstOrNull { it in 1..254 }
        val respirationRate = originData.resRates?.firstOrNull { it in 1..254 }
        val ecgHeartRate = originData.ecgs?.firstOrNull { it in 1..254 }
        val ppgHeartRate = originData.ppgs?.firstOrNull { it in 1..254 }

        // Extract blood component data
        val bloodComponent = originData.bloodComponent
        val uricAcid = bloodComponent?.uricAcid?.takeIf { it > 0 }
        val totalCholesterol = bloodComponent?.tCHO?.takeIf { it > 0 }
        val triglyceride = bloodComponent?.tAG?.takeIf { it > 0 }
        val hdl = bloodComponent?.hDL?.takeIf { it > 0 }
        val ldl = bloodComponent?.lDL?.takeIf { it > 0 }

        // HRV is delivered separately (onOriginHRVOriginListDataChange) after the five-minute
        // data for the day, so it can't be resolved yet. It's merged in later via mergeHrvData().
        val hrvValue = null

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
            "hrvValue" to hrvValue,
            // Raw device wear-detection code (vendor doesn't document the exact value
            // mapping, e.g. worn/not-worn/uncertain — exposed as-is for filtering).
            "wear" to originData.wear,
            // Remaining raw OriginData fields (see addOriginData for details).
            "tempOne" to originData.tempOne.takeIf { it > 0 },
            "tempTwo" to originData.tempTwo.takeIf { it > 0 },
            "calcType" to originData.calcType,
            "baseTemperature" to originData.baseTemperature.takeIf { it > 0 }?.toDouble(),
            "drinkPartOne" to originData.drinkPartOne?.takeIf { it.isNotEmpty() },
            "drinkPartTwo" to originData.drinkPartTwo?.takeIf { it.isNotEmpty() },
            // Remaining raw OriginData3-only fields, exposed as-is (undocumented by vendor
            // beyond their names). These are per-record arrays (one value per minute within the
            // 5-minute window) rather than the single reduced values above (bloodOxygen,
            // respirationRate, ecgHeartRate, heartRate), so apps that need the full detail
            // rather than "first valid reading in this window" can use these instead.
            "gesture" to originData.gesture?.toList(),
            "ppgValues" to originData.ppgs?.toList(),
            "ecgValues" to originData.ecgs?.toList(),
            "respirationRateValues" to originData.resRates?.toList(),
            "oxygenValues" to originData.oxygens?.toList(),
            "sleepStates" to originData.sleepStates?.toList(),
            "sleepStatusQuantity" to originData.sleepStatusQuantity?.toList(),
            "sleepSports" to originData.sleepSports?.toList(),
            "resetTagContent" to originData.resetTagContent?.toList(),
            "apneaResults" to originData.apneaResults?.toList(),
            "hypoxiaTimes" to originData.hypoxiaTimes?.toList(),
            "cardiacLoads" to originData.cardiacLoads?.toList(),
            "isHypoxias" to originData.isHypoxias?.toList(),
            "corrects" to originData.corrects?.toList(),
            "bloodGlucoseRiskLevel" to originData.bloodGlucoseRiskLevel?.name,
            "pressure" to originData.pressure.takeIf { it > 0 },
            "met" to originData.met.takeIf { it > 0 }?.toDouble()
        )

        currentDayData.add(dataMap)
    }

    /**
     * Waits [HRV_GRACE_PERIOD_MS] after onReadOriginComplete before finalizing the day, to give
     * a chance for onOriginHRVOriginListDataChange to arrive — it's generated as a trailing
     * post-processing step, not pushed alongside the rest of the day's data.
     */
    private fun scheduleDayComplete() {
        dayCompleteJob?.cancel()
        dayCompleteJob = coroutineScope.launch {
            delay(HRV_GRACE_PERIOD_MS)
            onDayComplete()
        }
    }

    private fun onDayComplete() {
        // hrvDataMap is fully populated for currentDay at this point (HRV list arrives after the
        // five-minute data, per SDK docs), and is about to be cleared when the next day starts
        // reading, so the merge must happen here rather than after all days have been read.
        val mergedRecords = mergeHrvData(currentDayData)
        currentDayData = mergedRecords
        allDaysData[currentDay] = mergedRecords

        if (totalDays == 1) {
            val dailyData = aggregateDailyData(currentDay, mergedRecords)
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

    /**
     * Fills in `hrvValue` for each record now that HRV data for the day is fully known.
     */
    private fun mergeHrvData(records: MutableList<Map<String, Any?>>): MutableList<Map<String, Any?>> {
        if (hrvDataMap.isEmpty()) return records
        return records.map { record ->
            val time = record["time"] as? String
            val hrv = time?.let { hrvDataMap[it] }
            if (hrv != null) record + ("hrvValue" to hrv) else record
        }.toMutableList()
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
        dayCompleteJob?.cancel()
        dayCompleteJob = null
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
