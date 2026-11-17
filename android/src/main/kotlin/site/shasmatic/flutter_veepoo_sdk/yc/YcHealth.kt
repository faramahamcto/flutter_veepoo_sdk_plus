package site.shasmatic.flutter_veepoo_sdk.yc

import android.os.Handler
import android.os.Looper
import com.yucheng.ycbtsdk.Constants
import com.yucheng.ycbtsdk.YCBTClient
import com.yucheng.ycbtsdk.response.BleDataResponse
import com.yucheng.ycbtsdk.response.BleDeviceToAppDataResponse
import com.yucheng.ycbtsdk.response.BleRealDataResponse
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.utils.aggregateDailyData
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Health features of the YC backend: live measurements, history (steps / sleep / origin data),
 * ECG, auto-measure and profile. Everything is converted to the exact map shapes the Veepoo
 * handler sends, so the Dart models stay untouched.
 */
internal class YcHealth(private val sink: (String) -> EventChannel.EventSink?) {

    private val main = Handler(Looper.getMainLooper())
    private var started = false

    // Latest live readings, used to build the final "complete" event when the watch says it is done.
    private var lastHeart = 0
    private var lastSys = 0
    private var lastDia = 0
    private var lastSpo2 = 0
    private var lastTemp: Double? = null
    private var lastGlucose: Double? = null
    private var activeType: Int? = null
    private var ecgActive = false
    private var ecgHeart = 0
    private val ecgBuffer = ArrayList<Int>()
    private var ecgStartedAt = 0L
    private var lastEcgChunk: List<Int>? = null
    private var liveSteps: Triple<Int, Int, Int>? = null // steps, meters, kcal
    private var profileHeightCm = 0
    private var profileWeightKg = 0
    private var bloodPollGen = 0 // bumping it cancels a running blood-component poll
    // Monitors the watch can switch: type -> (on, interval minutes). In-memory: YC has no read-back call.
    private val auto = linkedMapOf(0 to (false to 10), 5 to (false to 10), 4 to (false to 10))

    private companion object {
        const val T_HEART = 0
        const val T_BP = 1
        const val T_SPO2 = 2
        const val T_TEMP = 4
        const val T_GLUCOSE = 5
        const val HISTORY_TIMEOUT_MS = 6_000L
        const val CACHE_MS = 20_000L
        const val LIVE_TIMEOUT_MS = 40_000L
        const val ECG_NO_SIGNAL_MS = 20_000L
    }

    fun start() {
        if (started) return
        started = true
        YCBTClient.appRegisterRealDataCallBack(realData)
        YCBTClient.deviceToApp(deviceToApp)
    }

    /** Returns false when the method is not a health method (caller answers UNSUPPORTED_BRAND). */
    fun handle(call: MethodCall, rawResult: MethodChannel.Result): Boolean {
        // YC callbacks can fire repeatedly (ECG streams, late timeouts); a second reply crashes the app.
        val result = OnceResult(rawResult)
        try {
            when (call.method) {
                "startDetectHeart" -> startMeasure(T_HEART, result)
                "stopDetectHeart" -> stopMeasure(T_HEART, result)
                "startDetectBloodPressure" -> startMeasure(T_BP, result)
                "stopDetectBloodPressure" -> stopMeasure(T_BP, result)
                "startDetectSpoh" -> startMeasure(T_SPO2, result)
                "stopDetectSpoh" -> stopMeasure(T_SPO2, result)
                "startDetectTemperature" -> startMeasure(T_TEMP, result)
                "stopDetectTemperature" -> stopMeasure(T_TEMP, result)
                "startDetectBloodGlucose" -> startMeasure(T_GLUCOSE, result)
                "stopDetectBloodGlucose" -> stopMeasure(T_GLUCOSE, result)
                "startDetectECG", "startDetectEcg" -> startEcg(result)
                "stopDetectECG", "stopDetectEcg" -> stopEcg(result)
                "settingHeartWarning" -> {
                    val high = call.argument<Int>("high") ?: 150
                    val low = call.argument<Int>("low") ?: 50
                    val open = call.argument<Boolean>("open") ?: true
                    ack(result, "HEART_WARNING_FAILED") {
                        YCBTClient.settingHeartAlarm(if (open) 1 else 0, high, low, it)
                    }
                }
                "setUserProfile" -> setUserProfile(call, result)
                "enableAllAutoMeasurements" -> enableAllAutoMeasurements(result)
                "ycProbe" -> probe(result)
                "readHeartWarning" -> result.success(null) // Veepoo only logs the value
                "startDetectBloodComponent" -> startBloodComponent(result)
                "stopDetectBloodComponent" -> { bloodPollGen++; result.success(null) }
                "startDetectBodyComponent" -> startBodyComponent(result)
                "stopDetectBodyComponent" -> result.success(null)
                "readBodyComponentId" -> result.success(emptyList<Int>()) // YC keeps no body-scan records
                "readBodyComponentData" -> result.success(emptyList<Map<String, Any?>>())
                "startMiniCheckup" -> {
                    emit("miniCheckup", mapOf("type" to "error", "errorCode" to "FUNCTION_NOT_SUPPORT", "timestamp" to now()))
                    result.success(null)
                }
                "stopMiniCheckup" -> {
                    emit("miniCheckup", mapOf("type" to "stopped", "timestamp" to now()))
                    result.success(null)
                }
                "readHRVData" -> readHrv(call.argument<Int>("days") ?: 7, call.argument<Int>("startDay") ?: 0, result)
                "readAutoMeasureSettings" -> result.success(autoList())
                "setAutoMeasureSetting" -> setAutoMeasure(call, result)
                "readStepDataForDate" -> {
                    val ts = call.argument<Number>("timestamp")?.toLong() ?: now()
                    val from = Calendar.getInstance().apply {
                        timeInMillis = ts
                        set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
                    }.timeInMillis
                    readStepData(result, from, from + 24L * 3600 * 1000)
                }
                "readStepData" -> readStepData(result)
                "readSleepData" -> readSleepData(result)
                "readOriginData3Days" -> readOrigin(listOf(0, 1, 2), result, single = false)
                "readOriginDataForDay" -> readOrigin(listOf(call.argument<Int>("day") ?: 0), result, single = true)
                else -> return false
            }
        } catch (e: Exception) {
            result.error("YC_ERROR", "${call.method} failed: ${e.message}", null)
        }
        return true
    }

    // ---------------------------------------------------------------- helpers

    private fun emit(name: String, data: Map<String, Any?>) = main.post { sink(name)?.success(data) }

    /** Runs a YC write command and answers `success(null)` on code 0, otherwise an error. */
    private fun ack(result: MethodChannel.Result, errorCode: String, command: (BleDataResponse) -> Unit) {
        command(BleDataResponse { code, _, _ ->
            main.post {
                if (code == 0) result.success(null) else result.error(errorCode, "YC command failed (code=$code)", null)
            }
        })
    }

    private fun num(map: Map<*, *>?, key: String): Number? = map?.get(key) as? Number

    private fun int(map: Map<*, *>?, key: String): Int = num(map, key)?.toInt() ?: 0

    private fun now() = System.currentTimeMillis()

    // ---------------------------------------------------------------- live measurements

    // Some firmwares (E810) answer the start-measurement command with 0xFC (unsupported). They still
    // stream live values in "real data" mode, so fall back to that and finish after a few valid readings.
    private var realMode: Int? = null
    private var validReadings = 0
    private var liveGen = 0

    private fun realModeFor(type: Int): Int? = when (type) {
        T_HEART -> 0x01
        T_SPO2 -> 0x02
        T_BP -> 0x03
        T_TEMP -> 0x07
        else -> null
    }

    private fun startMeasure(type: Int, result: MethodChannel.Result) {
        if (type != T_GLUCOSE) return doStartMeasure(type, result)
        supports("bloodSugar") { ok ->
            if (ok) doStartMeasure(type, result)
            else {
                emitNotSupported("bloodGlucose")
                result.error("UNSUPPORTED_BRAND", "This watch cannot measure blood glucose", null)
            }
        }
    }

    /** Reads the watch's own capability flags (getMeasurementFunction); unknown or no reply counts as supported. */
    private fun supports(key: String, cb: (Boolean) -> Unit) {
        var done = false
        main.postDelayed({ if (!done) { done = true; cb(true) } }, 3_000)
        YCBTClient.getMeasurementFunction(BleDataResponse { code, _, map ->
            main.post {
                if (!done) {
                    done = true
                    cb(code != 0 || ((map?.get(key) as? Number)?.toInt() ?: 1) != 0)
                }
            }
        })
    }

    private fun emitNotSupported(channel: String) =
        emit(channel, mapOf("state" to "notSupported", "isMeasuring" to false, "progress" to 0, "timestamp" to now()))

    private fun doStartMeasure(type: Int, result: MethodChannel.Result) {
        activeType = type
        realMode = null; validReadings = 0; liveGen++
        lastHeart = 0; lastSys = 0; lastDia = 0; lastSpo2 = 0; lastTemp = null; lastGlucose = null
        emitState(type, measuring = true, complete = false, failed = false)
        YCBTClient.appStartMeasurement(1, type, BleDataResponse { code, _, _ ->
            if (code == 0) { main.post { result.success(null) }; return@BleDataResponse }
            val mode = realModeFor(type)
            VPLogger.d("YC start measurement type=$type code=$code, fallback real-data mode=$mode")
            if (mode == null) {
                main.post {
                    activeType = null
                    emitState(type, measuring = false, complete = false, failed = true)
                    result.error("MEASURE_FAILED", "This watch does not support measurement type $type (code=$code)", null)
                }
                return@BleDataResponse
            }
            // The watch streams values without acknowledging this command, so do not wait for a reply.
            realMode = mode
            YCBTClient.appRealDataFromDevice(1, mode, BleDataResponse { _, _, _ -> })
            if (type == T_TEMP) pollTemp()
            // No valid value in time (not worn, or this watch has no such sensor): report failure, do not hang.
            val gen = ++liveGen
            main.postDelayed({
                if (gen == liveGen && activeType == type && realMode != null) {
                    emitState(type, measuring = false, complete = false, failed = true)
                    realMode?.let { YCBTClient.appRealDataFromDevice(0, it, BleDataResponse { _, _, _ -> }) }
                    realMode = null
                    activeType = null
                }
            }, LIVE_TIMEOUT_MS)
            main.post { result.success(null) }
        })
    }

    private fun stopMeasure(type: Int, result: MethodChannel.Result) {
        if (activeType == type) activeType = null
        liveGen++
        val mode = realMode
        realMode = null
        // Stopping is best-effort: an unsupported command must not surface as an error.
        if (mode != null) YCBTClient.appRealDataFromDevice(0, mode, BleDataResponse { _, _, _ -> })
        YCBTClient.appStartMeasurement(0, type, BleDataResponse { _, _, _ -> main.post { result.success(null) } })
    }

    /** Some watches report body temperature only when asked (getRealTemp) while a measurement is open. */
    private fun pollTemp() {
        main.postDelayed({
            if (activeType != T_TEMP) return@postDelayed
            YCBTClient.getRealTemp(BleDataResponse { code, _, map ->
                VPLogger.d("YC getRealTemp code=$code map=$map")
                val raw = map?.get("tempValue")
                val t = (raw as? Number)?.toDouble() ?: (raw as? String)?.toDoubleOrNull()
                main.post {
                    if (code == 0 && t != null && t > 0 && activeType == T_TEMP) { lastTemp = t; liveTick(T_TEMP) }
                    pollTemp()
                }
            })
        }, 2_000)
    }

    /** One more valid live reading: keep "measuring", or finish after three in real-data mode. */
    private fun liveTick(type: Int) {
        if (realMode != null && ++validReadings >= 3) {
            emitState(type, measuring = false, complete = true, failed = false)
            realMode?.let { YCBTClient.appRealDataFromDevice(0, it, BleDataResponse { _, _, _ -> }) }
            realMode = null
            activeType = null
        } else {
            emitState(type, measuring = true, complete = false, failed = false)
        }
    }

    /** Emits the current state of measurement [type] on its event channel, in the Veepoo shape. */
    private fun emitState(type: Int, measuring: Boolean, complete: Boolean, failed: Boolean) {
        val state = when {
            failed -> "failed"
            complete -> "complete"
            measuring -> "measuring"
            else -> "idle"
        }
        val progress = if (complete) 100 else 0
        when (type) {
            T_HEART -> emit(
                "heart",
                mapOf(
                    "data" to lastHeart,
                    // STATE_HEART_NORMAL is what the Veepoo SDK reports for a valid reading.
                    "state" to if (complete) "STATE_HEART_NORMAL" else if (failed) "STATE_HEART_WEAR_ERROR" else "STATE_HEART_DETECT",
                ),
            )
            T_BP -> emit(
                "bloodPressure",
                mapOf(
                    "systolic" to lastSys, "diastolic" to lastDia, "progress" to progress,
                    "state" to state, "isMeasuring" to measuring, "timestamp" to now(),
                ),
            )
            T_SPO2 -> emit(
                "spoh",
                mapOf(
                    "spohStatus" to "OPEN", "deviceStatus" to if (measuring) "DETECT_OXYGEN" else "FREE",
                    "value" to lastSpo2, "checking" to measuring, "checkingProgress" to progress,
                    "rate" to lastHeart,
                ),
            )
            T_TEMP -> {
                val c = lastTemp
                emit(
                    "temperature",
                    mapOf(
                        "temperatureCelsius" to c, "temperatureFahrenheit" to c?.let { it * 9.0 / 5.0 + 32.0 },
                        "state" to state, "isMeasuring" to measuring, "progress" to progress, "timestamp" to now(),
                    ),
                )
            }
            T_GLUCOSE -> {
                val mmol = lastGlucose
                emit(
                    "bloodGlucose",
                    mapOf(
                        "glucoseMmolL" to mmol, "glucoseMgdL" to mmol?.let { it * 18.0 },
                        "state" to state, "isMeasuring" to measuring, "progress" to progress,
                        "calibrationMode" to false, "timestamp" to now(),
                    ),
                )
            }
        }
    }

    private var probeLog = false

    private val realData = BleRealDataResponse { dataType, raw ->
        if (probeLog) VPLogger.d("YC probe real type=$dataType map=$raw")
        val map = raw as? Map<*, *> ?: return@BleRealDataResponse
        when (dataType) {
            Constants.DATATYPE.Real_UploadHeart -> {
                lastHeart = int(map, "heartValue")
                if (activeType == T_HEART && lastHeart > 0) liveTick(T_HEART)
            }
            Constants.DATATYPE.Real_UploadBlood -> {
                lastSys = int(map, "bloodSBP"); lastDia = int(map, "bloodDBP")
                val hr = int(map, "heartValue")
                if (ecgActive) ecgHeart = hr
                if (hr > 0) lastHeart = hr
                if (activeType == T_BP && lastSys > 0 && lastDia > 0) liveTick(T_BP)
            }
            Constants.DATATYPE.Real_UploadBloodOxygen -> {
                lastSpo2 = int(map, "bloodOxygenValue")
                if (activeType == T_SPO2 && lastSpo2 > 0) liveTick(T_SPO2)
            }
            Constants.DATATYPE.Real_UploadComprehensive -> {
                val i = num(map, "tempInteger"); val f = num(map, "tempFloat")
                if (i != null && f != null) lastTemp = "${i.toInt()}.${f.toInt()}".toDoubleOrNull()
                if (activeType == T_TEMP && lastTemp != null) liveTick(T_TEMP)
                // Glucose has no documented real-time type; keep every unknown key visible for tuning.
                num(map, "bloodSugarValue")?.let {
                    lastGlucose = it.toDouble() / 10.0
                    if (activeType == T_GLUCOSE) emitState(T_GLUCOSE, measuring = true, complete = false, failed = false)
                }
            }
            Constants.DATATYPE.Real_UploadECG -> {
                @Suppress("UNCHECKED_CAST")
                val data = map["data"] as? List<Number>
                if (ecgActive && data != null) onEcgChunk(data.map { it.toInt() })
            }
            Constants.DATATYPE.Real_UploadSport -> {
                liveSteps = Triple(int(map, "sportStep"), int(map, "sportDistance"), int(map, "sportCalorie"))
            }
            else -> VPLogger.d("YC real data type=$dataType keys=${map.keys}")
        }
    }

    /** The watch tells us when a measurement ended (data[0]=type, data[1]=0 cancelled / 1 ok / 2 failed). */
    private val deviceToApp = BleDeviceToAppDataResponse { _, raw ->
        val map = raw as? Map<*, *> ?: return@BleDeviceToAppDataResponse
        if (map["dataType"] != Constants.DATATYPE.DeviceMeasurementResult) return@BleDeviceToAppDataResponse
        val bytes = map["datas"] as? ByteArray ?: return@BleDeviceToAppDataResponse
        if (bytes.size < 2) return@BleDeviceToAppDataResponse
        val ycType = bytes[0].toInt()
        val type = when (ycType) { 0 -> T_HEART; 1 -> T_BP; 2 -> T_SPO2; 4 -> T_TEMP; else -> return@BleDeviceToAppDataResponse }
        when (bytes[1].toInt()) {
            1 -> emitState(type, measuring = false, complete = true, failed = false)
            2 -> emitState(type, measuring = false, complete = false, failed = true)
            else -> emitState(type, measuring = false, complete = false, failed = false)
        }
        if (activeType == type) activeType = null
    }

    // ---------------------------------------------------------------- ECG

    private fun startEcg(result: MethodChannel.Result) {
        ecgBuffer.clear(); ecgHeart = 0; ecgActive = true; ecgStartedAt = now(); lastEcgChunk = null
        emitEcg("measuring", emptyList(), measuring = true, progress = 0)
        YCBTClient.appEcgTestStart(BleDataResponse { code, _, _ ->
            main.post {
                if (code == 0) result.success(null)
                else { ecgActive = false; result.error("ECG_FAILED", "YC ECG start failed (code=$code)", null) }
            }
        }, realData)
        main.postDelayed({
            if (ecgActive && ecgBuffer.isEmpty()) emitEcg("poorSignal", emptyList(), measuring = true, progress = 0)
        }, ECG_NO_SIGNAL_MS)
    }

    private fun onEcgChunk(chunk: List<Int>) {
        // The SDK delivers every chunk twice (global + per-call callback); drop the repeat.
        if (chunk == lastEcgChunk) return
        lastEcgChunk = chunk
        ecgBuffer.addAll(chunk)
        // A reading takes ~30 s; report time-based progress, capped below 100 until stopped.
        val progress = ((now() - ecgStartedAt) / 300).toInt().coerceIn(0, 99)
        emitEcg("measuring", chunk, measuring = true, progress = progress)
    }

    private fun stopEcg(result: MethodChannel.Result) {
        ecgActive = false
        YCBTClient.appEcgTestEnd(BleDataResponse { code, _, _ ->
            // E810 keeps streaming ECG (and refuses other live data) until the waveform upload is switched off too.
            YCBTClient.appControlWave(0, 0x01, BleDataResponse { _, _, _ -> })
            YCBTClient.appControlWave(0, 0x00, BleDataResponse { _, _, _ -> })
            main.post {
                emitEcg(if (ecgBuffer.isEmpty()) "failed" else "complete", emptyList(), measuring = false, progress = 100)
                if (code == 0) result.success(null) else result.error("ECG_FAILED", "YC ECG stop failed (code=$code)", null)
            }
        })
    }

    private fun emitEcg(state: String, waveform: List<Int>, measuring: Boolean, progress: Int) = emit(
        "ecg",
        mapOf(
            "waveformData" to waveform, "heartRate" to ecgHeart, "state" to state,
            "isMeasuring" to measuring, "progress" to progress,
            "diagnosticResult" to null, "signalQuality" to null, "timestamp" to now(),
        ),
    )

    // ---------------------------------------------------------------- profile / auto measure

    private fun setUserProfile(call: MethodCall, result: MethodChannel.Result) {
        val height = call.argument<Int>("heightCm") ?: 170
        val weight = (call.argument<Double>("weightKg") ?: 70.0).toInt()
        val age = call.argument<Int>("age") ?: 30
        profileHeightCm = height; profileWeightKg = weight
        val sex = if (call.argument<String>("gender")?.lowercase() == "female") 1 else 0 // YC: 0 male, 1 female
        ack(result, "SET_PROFILE_FAILED") { YCBTClient.settingUserInfo(height, weight, sex, age, it) }
    }

    /** Turns on the monitors the app relies on; reports one AutoMeasureData-shaped map per monitor. */
    private fun enableAllAutoMeasurements(result: MethodChannel.Result) {
        val interval = 10 // minutes
        val jobs = listOf<Pair<Int, ((BleDataResponse) -> Unit)>>(
            0 to { r: BleDataResponse -> YCBTClient.settingHeartMonitor(0x01, interval, r) },
            5 to { r: BleDataResponse -> YCBTClient.settingTemperatureMonitor(true, interval, r) },
            4 to { r: BleDataResponse -> YCBTClient.settingBloodOxygenModeMonitor(true, interval, r) },
        )
        val out = ArrayList<Map<String, Any?>>()
        fun next(i: Int) {
            if (i >= jobs.size) { main.post { result.success(out) }; return }
            val (type, run) = jobs[i]
            var done = false
            val finish = { ok: Boolean ->
                if (!done) {
                    done = true
                    if (ok) auto[type] = true to interval
                    out.add(
                        mapOf(
                            "type" to type, "isSwitchOpen" to ok, "stepUnit" to 1, "isSlotModify" to false,
                            "isIntervalModify" to true, "supportStartMinute" to 0, "supportEndMinute" to 1439,
                            "measureInterval" to interval, "currentStartMinute" to 0, "currentEndMinute" to 1439,
                            "success" to ok,
                        ),
                    )
                    next(i + 1)
                }
            }
            main.postDelayed({ finish(false) }, 5_000) // a monitor the watch lacks never answers
            try { run(BleDataResponse { code, _, _ -> main.post { finish(code == 0) } }) } catch (_: Exception) { finish(false) }
        }
        next(0)
    }

    // ---------------------------------------------------------------- history

    private data class Rec(
        val ts: Long, // millis
        var heart: Int? = null, var sys: Int? = null, var dia: Int? = null, var spo2: Int? = null,
        var temp: Double? = null, var resp: Int? = null, var hrv: Int? = null, var glucose: Int? = null,
        var steps: Int? = null, var distance: Double? = null, var calories: Double? = null,
    )

    /**
     * History timestamps: the E810 already reports unix milliseconds (13 digits) although the docs say seconds.
     * Accept ms, unix seconds, and the 2000-based epoch some firmwares use.
     */
    private fun toMillis(v: Long): Long = when {
        v >= 100_000_000_000L -> v
        v >= 1_000_000_000L -> v * 1000L
        else -> (v + YCBTClient.SecFrom30Year) * 1000L
    }

    private fun history(type: Int, onRows: (List<Map<*, *>>) -> Unit) {
        var done = false
        val finish = { rows: List<Map<*, *>> -> if (!done) { done = true; onRows(rows) } }
        main.postDelayed({ if (!done) VPLogger.d("YC history type=$type: no callback in ${HISTORY_TIMEOUT_MS}ms"); finish(emptyList()) }, HISTORY_TIMEOUT_MS)
        try {
            YCBTClient.healthHistoryData(type, BleDataResponse { code, _, map ->
                val rows = if (code == 0) (map?.get("data") as? List<*>)?.filterIsInstance<Map<*, *>>() else null
                VPLogger.d("YC history type=$type code=$code rows=${rows?.size} raw=${"$map".take(600)}")
                main.post { finish(rows ?: emptyList()) }
            })
        } catch (e: Exception) {
            VPLogger.e("YC history type=$type failed: ${e.message}")
            finish(emptyList())
        }
    }

    // The app reads day 2, 1, 0 in a row; one device read serves all three, so cache it briefly and
    // let concurrent callers share the in-flight read.
    private var cachedRecs: List<Rec>? = null
    private var cachedAt = 0L
    private var waiting: MutableList<(List<Rec>) -> Unit>? = null

    /** Reads all history types in parallel (the SDK queues them) and merges them per timestamp. */
    private fun readRecords(onDone: (List<Rec>) -> Unit, progress: (Float) -> Unit = {}) {
        cachedRecs?.let { if (now() - cachedAt < CACHE_MS) { onDone(it); return } }
        waiting?.let { it.add(onDone); return }
        waiting = mutableListOf(onDone)

        val recs = LinkedHashMap<Long, Rec>()
        fun rec(sec: Long): Rec { val ms = toMillis(sec); return recs.getOrPut(ms) { Rec(ms) } }
        var pending = 4

        fun oneDone() {
            pending--
            progress(1f - pending / 4f)
            if (pending > 0) return
            val out = recs.values.sortedBy { it.ts }
            cachedRecs = out; cachedAt = now()
            val callbacks = waiting.orEmpty()
            waiting = null
            callbacks.forEach { it(out) }
        }

        history(Constants.DATATYPE.Health_HistoryHeart) { rows ->
            rows.forEach { r -> num(r, "heartStartTime")?.let { rec(it.toLong()).heart = int(r, "heartValue") } }
            oneDone()
        }
        history(Constants.DATATYPE.Health_HistoryBlood) { rows ->
            rows.forEach { r ->
                num(r, "bloodStartTime")?.let { rec(it.toLong()).apply { sys = int(r, "bloodSBP"); dia = int(r, "bloodDBP") } }
            }
            oneDone()
        }
        history(Constants.DATATYPE.Health_HistorySport) { rows ->
            rows.forEach { r ->
                num(r, "sportStartTime")?.let {
                    rec(it.toLong()).apply {
                        steps = int(r, "sportStep"); distance = int(r, "sportDistance").toDouble(); calories = int(r, "sportCalorie").toDouble()
                    }
                }
            }
            oneDone()
        }
        // "Combined" only for what the single types lack: oxygen, respiration, temperature, glucose, HRV.
        history(Constants.DATATYPE.Health_HistoryAll) { rows ->
            rows.forEach { r ->
                num(r, "startTime")?.let {
                    rec(it.toLong()).apply {
                        int(r, "OOValue").takeIf { v -> v > 0 }?.let { v -> spo2 = v }
                        int(r, "respiratoryRateValue").takeIf { v -> v > 0 }?.let { v -> resp = v }
                        int(r, "hrvValue").takeIf { v -> v > 0 }?.let { v -> hrv = v }
                        val ti = int(r, "tempIntValue")
                        if (ti > 0) temp = "$ti.${int(r, "tempFloatValue")}".toDoubleOrNull()
                        // bloodSugarValue is ignored on purpose: the watch reports bloodSugar=0 (unsupported), so it is an estimate
                    }
                }
            }
            oneDone()
        }
    }

    private fun dayStart(offset: Int): Long = Calendar.getInstance().apply {
        add(Calendar.DAY_OF_YEAR, -offset)
        set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
    }.timeInMillis

    private fun readOrigin(days: List<Int>, result: MethodChannel.Result, single: Boolean) {
        if (0 !in days) return readOriginDays(days, result, single)
        getNowStep { live ->
            if (live != null) liveSteps = live
            readOriginDays(days, result, single)
        }
    }

    private fun readOriginDays(days: List<Int>, result: MethodChannel.Result, single: Boolean) {
        val labels = { d: Int -> when (d) { 0 -> "Today"; 1 -> "Yesterday"; 2 -> "2 Days Ago"; else -> "$d Days Ago" } }
        readRecords({ recs ->
            val dateFmt = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val timeFmt = SimpleDateFormat("HH:mm", Locale.getDefault())
            val daily = days.map { d ->
                val from = dayStart(d)
                val to = from + 24L * 3600 * 1000
                val records = recs.filter { it.ts in from until to }.map { r ->
                    mapOf<String, Any?>(
                        "date" to dateFmt.format(Date(r.ts)), "time" to timeFmt.format(Date(r.ts)),
                        "heartRate" to r.heart?.takeIf { it > 0 }, "systolic" to r.sys?.takeIf { it > 0 },
                        "diastolic" to r.dia?.takeIf { it > 0 }, "temperature" to r.temp,
                        "bloodOxygen" to r.spo2, "steps" to r.steps?.takeIf { it > 0 },
                        "calories" to r.calories?.takeIf { it > 0 }, "distance" to r.distance?.takeIf { it > 0 }?.div(1000.0), // Veepoo reports km; YC reports metres
                        "bloodGlucose" to r.glucose, "respirationRate" to r.resp, "hrvValue" to r.hrv,
                    )
                }
                val day = aggregateDailyData(d, records) + ("dayLabel" to labels(d))
                val live = liveSteps
                if (d == 0 && live != null && live.first > ((day["totalSteps"] as? Number)?.toInt() ?: 0)) {
                    day + mapOf(
                        "totalSteps" to live.first,
                        "totalDistance" to live.second / 1000.0, // km, like Veepoo
                        "totalCalories" to live.third.toDouble(),
                    )
                } else day
            }
            main.post { if (single) result.success(daily.first()) else result.success(daily) }
        }, progress = { p ->
            emit("originProgress", mapOf("progress" to p, "day" to 0, "dayLabel" to labels(0), "totalDays" to days.size))
        })
    }

    // ---------------------------------------------------------------- steps / sleep

    private fun readStepData(result: MethodChannel.Result, from: Long = dayStart(0), to: Long? = null) {
        if (to != null) return readStepHistory(result, from, to) // past day: history only
        getNowStep { live ->
            if (live != null) liveSteps = live
            readStepHistory(result, from, to)
        }
    }

    /** The watch's own step counter for today. Keys are tolerant: firmwares differ. */
    private fun getNowStep(cb: (Triple<Int, Int, Int>?) -> Unit) {
        var done = false
        main.postDelayed({ if (!done) { done = true; cb(null) } }, 4_000)
        YCBTClient.getNowStep(BleDataResponse { code, _, map ->
            VPLogger.d("YC getNowStep code=$code map=$map")
            main.post {
                if (done) return@post
                done = true
                val d = (map?.get("data") as? Map<*, *>) ?: map
                fun pick(vararg keys: String) = keys.firstNotNullOfOrNull { k -> (d?.get(k) as? Number)?.toInt() } ?: 0
                val steps = pick("sportStep", "step", "steps", "nowStep")
                cb(if (code == 0 && steps > 0) Triple(steps, pick("nowDistance", "sportDistance", "distance"), pick("nowCalorie", "sportCalorie", "calorie", "calories")) else null)
            }
        })
    }

    private fun readStepHistory(result: MethodChannel.Result, from: Long, to: Long?) {
        history(Constants.DATATYPE.Health_HistorySport) { rows ->
            var steps = 0; var meters = 0; var kcal = 0; var seconds = 0L
            rows.forEach { r ->
                val start = num(r, "sportStartTime")?.toLong() ?: return@forEach
                if (toMillis(start) < from || (to != null && toMillis(start) >= to)) return@forEach
                steps += int(r, "sportStep"); meters += int(r, "sportDistance"); kcal += int(r, "sportCalorie")
                seconds += ((num(r, "sportEndTime")?.toLong() ?: start) - start).coerceAtLeast(0)
            }
            // The live counter is fresher than stored segments; never report fewer steps than it knows.
            if (to == null) liveSteps?.let { (s, d, c) -> if (s > steps) { steps = s; meters = d; kcal = c } }
            result.success(
                mapOf<String, Any?>(
                    // distanceMeters carries km (Veepoo's unit, shown as km by the app)
                    "steps" to steps, "distanceMeters" to meters / 1000.0, "calories" to kcal.toDouble(),
                    "activeMinutes" to (seconds / 60).toInt(), "timestamp" to now(),
                ),
            )
        }
    }

    private fun readSleepData(result: MethodChannel.Result) {
        history(Constants.DATATYPE.Health_HistorySleep) { rows ->
            // Most recent session that ended within the last 36 h.
            val cutoff = now() - 36L * 3600 * 1000
            val session = rows.filter { toMillis(num(it, "endTime")?.toLong() ?: 0) >= cutoff }
                .maxByOrNull { num(it, "endTime")?.toLong() ?: 0 }
            if (session == null) {
                result.success(null)
                return@history
            }
            val deep = int(session, "deepSleepTotal")
            val light = int(session, "lightSleepTotal")
            val rem = int(session, "rapidEyeMovementTotal")
            val awake = int(session, "wakeDuration")
            val total = deep + light + rem
            // 0 = awake, 1 = light, 2 = deep (the digits Veepoo's sleep line uses); REM counts as light.
            val curve = ArrayList<Int>()
            (session["sleepData"] as? List<*>)?.filterIsInstance<Map<*, *>>()?.forEach { seg ->
                val level = when (int(seg, "sleepType")) { 0xF1 -> 2; 0xF2, 0xF3 -> 1; else -> 0 }
                repeat((int(seg, "sleepLen") / 60).coerceAtLeast(0)) { curve.add(level) }
            }
            // YC has no quality score: derive one from the 8 h target (stand-in, not a vendor value).
            val quality = (total * 100 / 480).coerceIn(0, 100)
            result.success(
                mapOf<String, Any?>(
                    "totalSleepMinutes" to total, "deepSleepMinutes" to deep, "lightSleepMinutes" to light + rem,
                    "awakeMinutes" to awake, "sleepQuality" to quality,
                    "sleepStartTime" to toMillis(num(session, "startTime")?.toLong() ?: 0),
                    "sleepEndTime" to toMillis(num(session, "endTime")?.toLong() ?: 0),
                    "sleepCurve" to curve,
                ),
            )
        }
    }

    // ---------------------------------------------------------------- auto measure (read / set)

    private fun autoMap(type: Int, on: Boolean, interval: Int, success: Boolean? = null) = mapOf<String, Any?>(
        "type" to type, "isSwitchOpen" to on, "stepUnit" to 1, "isSlotModify" to false,
        "isIntervalModify" to true, "supportStartMinute" to 0, "supportEndMinute" to 1439,
        "measureInterval" to interval, "currentStartMinute" to 0, "currentEndMinute" to 1439, "success" to success,
    )

    private fun autoList() = auto.map { (type, v) -> autoMap(type, v.first, v.second) }

    private fun setAutoMeasure(call: MethodCall, result: MethodChannel.Result) {
        val type = call.argument<Int>("type")
        val enabled = call.argument<Boolean>("enabled")
        if (type == null || enabled == null) return result.error("INVALID_ARGUMENT", "type and enabled are required", null)
        val interval = call.argument<Int>("measureInterval") ?: auto[type]?.second ?: 10
        val command: ((BleDataResponse) -> Unit) = when (type) {
            0 -> { r: BleDataResponse -> YCBTClient.settingHeartMonitor(if (enabled) 1 else 0, interval, r) }
            5 -> { r: BleDataResponse -> YCBTClient.settingTemperatureMonitor(enabled, interval, r) }
            4 -> { r: BleDataResponse -> YCBTClient.settingBloodOxygenModeMonitor(enabled, interval, r) }
            else -> return result.error("UNSUPPORTED_BRAND", "Auto measure type $type is not supported on YC", null)
        }
        command(BleDataResponse { code, _, _ ->
            main.post {
                val ok = code == 0
                if (ok) auto[type] = enabled to interval
                result.success(autoMap(type, if (ok) enabled else auto[type]?.first ?: false, interval, ok))
            }
        })
    }

    // ---------------------------------------------------------------- HRV

    private fun readHrv(days: Int, startDay: Int, result: MethodChannel.Result) {
        readRecords({ recs ->
            val from = dayStart(startDay + days - 1)
            val to = dayStart(startDay - 1)
            val fmt = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
            val list = recs.filter { it.hrv != null && it.ts in from until to }.map {
                mapOf<String, Any?>(
                    "date" to fmt.format(Date(it.ts)), "hrvValue" to it.hrv, "heartRate" to it.heart,
                    "rrValues" to null, "hrvType" to null, "timestamp" to fmt.format(Date(it.ts)),
                )
            }
            main.post { result.success(mapOf("hrvDataList" to list, "dayHrvScore" to null, "totalRecords" to list.size)) }
        })
    }

    // ---------------------------------------------------------------- blood / body component

    private fun emitBlood(state: String, uric: Double? = null, chol: Double? = null, progress: Int = 0) = emit(
        "bloodComponent",
        mapOf(
            "uricAcid" to uric, "totalCholesterol" to chol, "triglyceride" to null, "hdl" to null, "ldl" to null,
            "state" to state, "isMeasuring" to (state == "measuring"), "progress" to progress, "timestamp" to now(),
        ),
    )

    /**
     * YC reports no live lipid / uric-acid value: the watch measures, then stores a "comprehensive"
     * record. So: start the uric-acid measurement and poll that history for a record newer than the start.
     */
    private fun startBloodComponent(result: MethodChannel.Result) {
        supports("uricAcid") { uric ->
            supports("bloodFat") { fat ->
                if (uric || fat) doStartBloodComponent(result)
                else {
                    emitNotSupported("bloodComponent")
                    result.error("UNSUPPORTED_BRAND", "This watch cannot measure blood components", null)
                }
            }
        }
    }

    private fun doStartBloodComponent(result: MethodChannel.Result) {
        val gen = ++bloodPollGen
        val startedAt = now()
        emitBlood("measuring")
        ack(result, "MEASURE_FAILED") { YCBTClient.appStartMeasurement(1, 6, it) }
        fun poll(attempt: Int) {
            if (gen != bloodPollGen) return
            if (attempt > 9) { emitBlood("failed"); return } // ~90 s
            main.postDelayed({
                if (gen != bloodPollGen) return@postDelayed
                history(Constants.DATATYPE.Health_HistoryComprehensiveMeasureData) { rows ->
                    val latest = rows.filter { toMillis(num(it, "time")?.toLong() ?: 0) >= startedAt - 5_000 }
                        .maxByOrNull { num(it, "time")?.toLong() ?: 0 }
                    if (latest == null) { emitBlood("measuring", progress = (attempt + 1) * 10); poll(attempt + 1); return@history }
                    val chol = "${int(latest, "cholesterolInteger")}.${int(latest, "cholesterolFloat")}".toDoubleOrNull()?.takeIf { it > 0 }
                    val uric = int(latest, "uricAcid").takeIf { it > 0 }?.toDouble()
                    emitBlood("complete", uric, chol, 100)
                }
            }, 10_000)
        }
        poll(0)
    }

    /** YC has no body-scan feature; the only body value is body-fat inside the combined history. */
    private fun startBodyComponent(result: MethodChannel.Result) {
        emit("bodyComponent", mapOf("state" to "measuring", "isMeasuring" to true, "progress" to 0, "timestamp" to now()))
        result.success(null)
        history(Constants.DATATYPE.Health_HistoryAll) { rows ->
            val fat = rows.filter { int(it, "bodyFatIntValue") > 0 }
                .maxByOrNull { num(it, "startTime")?.toLong() ?: 0 }
                ?.let { "${int(it, "bodyFatIntValue")}.${int(it, "bodyFatFloatValue")}".toDoubleOrNull() }
            val bmi = if (profileHeightCm > 0 && profileWeightKg > 0) {
                val m = profileHeightCm / 100.0
                profileWeightKg / (m * m)
            } else null
            if (fat == null && bmi == null) {
                emit("bodyComponent", mapOf("state" to "failed", "isMeasuring" to false, "progress" to 100, "timestamp" to now()))
            } else {
                emit(
                    "bodyComponent",
                    mapOf(
                        "bmi" to bmi, "bodyFatRate" to fat, "state" to "complete",
                        "isMeasuring" to false, "progress" to 100, "timestamp" to now(),
                    ),
                )
            }
        }
    }

    // ---------------------------------------------------------------- debug probe

    /** Logs what the watch supports and every live-data frame for ~25 s (debug aid, see tool/yc_probe.dart). */
    private fun probe(result: MethodChannel.Result) {
        probeLog = true
        YCBTClient.getMeasurementFunction(BleDataResponse { code, _, map ->
            VPLogger.d("YC probe getMeasurementFunction code=$code map=$map")
            YCBTClient.appRealDataFromDevice(1, 0x01, BleDataResponse { c, _, m ->
                VPLogger.d("YC probe appRealDataFromDevice(heart) code=$c map=$m")
            })
        })
        YCBTClient.getAllRealDataFromDevice(BleDataResponse { code, _, map ->
            VPLogger.d("YC probe getAllRealDataFromDevice code=$code map=$map")
        })
        main.postDelayed({
            YCBTClient.appRealDataFromDevice(0, 0x01, BleDataResponse { _, _, _ -> })
            probeLog = false
            result.success("probe finished")
        }, 25_000)
    }
}

/** Forwards only the first reply; later ones are dropped. */
private class OnceResult(private val delegate: MethodChannel.Result) : MethodChannel.Result {
    private var used = false
    override fun success(result: Any?) { if (!used) { used = true; delegate.success(result) } }
    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        if (!used) { used = true; delegate.error(errorCode, errorMessage, errorDetails) }
    }
    override fun notImplemented() { if (!used) { used = true; delegate.notImplemented() } }
}
