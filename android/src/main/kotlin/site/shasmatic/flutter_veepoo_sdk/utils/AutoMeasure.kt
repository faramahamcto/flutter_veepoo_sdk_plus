package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IBleWriteResponse
import com.veepoo.protocol.listener.data.IAutoMeasureSettingDataListener
import com.veepoo.protocol.model.datas.AllSetData
import com.veepoo.protocol.model.datas.AutoMeasureData
import com.veepoo.protocol.model.enums.EAllSetType
import com.veepoo.protocol.model.enums.EBloodGlucoseUnit
import com.veepoo.protocol.model.enums.EFunctionStatus
import com.veepoo.protocol.model.settings.AllSetSetting
import com.veepoo.protocol.model.settings.CustomSetting
import com.veepoo.protocol.model.settings.CustomSettingData
import com.veepoo.protocol.shareprence.VpSpGetUtil
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import site.shasmatic.flutter_veepoo_sdk.VPLogger

/**
 * Reads and writes the device's automatic (background) measurement settings.
 * One instance serves exactly one method call and completes [result] once.
 */
class AutoMeasure(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
    private val vpSpGetUtil: VpSpGetUtil,
) {
    private val scope = CoroutineScope(Dispatchers.Main + Job())

    companion object {
        private const val TIMEOUT_MS = 10000L
    }

    fun readSettings() = ifSupported {
        read { list -> if (list == null) fail("AUTO_MEASURE_READ_FAILED", "Failed to read automatic measurement settings") else result.success(list.map(::toMap)) }
    }

    /** Changes one type; null args keep the device's current value. */
    fun setSetting(type: Int, open: Boolean, interval: Int?, startMinute: Int?, endMinute: Int?) = ifSupported {
        read { list ->
            val item = list?.firstOrNull { it.funType.value == type }
            if (item == null) {
                fail("AUTO_MEASURE_UNSUPPORTED_TYPE", "Device does not support automatic measurement type $type")
                return@read
            }
            item.isSwitchOpen = open
            interval?.let { item.measureInterval = it }
            startMinute?.let { item.currentStartMinute = it }
            endMinute?.let { item.currentEndMinute = it }
            write(item) { ok ->
                if (ok) result.success(toMap(item)) else fail("AUTO_MEASURE_SET_FAILED", "Failed to set automatic measurement type $type")
            }
        }
    }

    /**
     * Switches on every type the device supports. Newer firmware uses the 0xB3 auto-measure API;
     * older watches (isSupportAutoMeasure == false) use personalization settings + SpO2 auto-detect.
     */
    fun enableAll() {
        try {
            if (vpSpGetUtil.isSupportAutoMeasure) enableAllNew() else enableAllLegacy()
        } catch (e: Exception) {
            fail("AUTO_MEASURE_ERROR", "Automatic measurement error: ${e.message}")
        }
    }

    // Plugin-defined type ids beyond the vendor's EAutoMeasureType (0-8): 9 = scientific sleep (PPG).
    private fun enableAllLegacy() {
        once<CustomSettingData>({ f -> vpManager.readCustomSetting(writeResponse) { f(it) } }) { data ->
            if (data == null) {
                fail("AUTO_MEASURE_READ_FAILED", "Failed to read personalization settings")
                return@once
            }
            val s = CustomSetting(data)
            // (type, getter, setter, extra support flag). The settings read can report UNSUPPORT for
            // features the device does have (seen with temperature/glucose/blood components), so the
            // SDK's own capability flags are accepted as well.
            val fns = listOf<Quad>(
                Quad(2, { s.getIsOpenBloodGlucoseDetect() }, { s.setIsOpenBloodGlucoseDetect(it) },
                    // This watch reports glucose as UNSUPPORT until a unit is set (it then reports SUPPORT_CLOSE),
                    // so always attempt it; the confirmed state in the reply tells us whether it took.
                    true),
                Quad(3, { s.getStressDetect() }, { s.setStressDetect(it) }, true) // read says UNSUPPORT on some watches; attempt anyway, reply confirms,
                Quad(5, { s.getIsOpenAutoTemperatureDetect() }, { s.setIsOpenAutoTemperatureDetect(it) }, vpSpGetUtil.isSupportReadTempture),
                Quad(7, { s.getIsOpenAutoHRV() }, { s.setIsOpenAutoHRV(it) }, false),
                Quad(8, { s.getIsOpenBloodComponentDetect() }, { s.setIsOpenBloodComponentDetect(it) }, vpSpGetUtil.isSupportBloodComponent),
                Quad(9, { s.getIsOpenPPG() }, { s.setIsOpenPPG(it) }, false),
            )
            if (s.getBloodGlucoseUnit() == null || s.getBloodGlucoseUnit() == EBloodGlucoseUnit.NONE) {
                s.setBloodGlucoseUnit(EBloodGlucoseUnit.mmol_L) // glucose switch is paired with a unit
            }
            val types = mutableListOf(0, 1) // heart rate / blood pressure are plain booleans
            s.setOpenAutoHeartDetect(true)
            s.setOpenAutoBpDetect(true)
            for ((type, get, set, flag) in fns) {
                VPLogger.d("auto measure legacy type $type: status=${get()}, sdkFlag=$flag")
                if (get()?.isHaveFunction == true || flag) {
                    set(EFunctionStatus.SUPPORT_OPEN)
                    types.add(type)
                }
            }
            once<CustomSettingData>({ f -> vpManager.changeCustomSetting(writeResponse, { f(it) }, s) }) { written ->
                VPLogger.d("auto measure legacy written settings: $written")
                // Report the state the watch confirmed, not just that the write was acknowledged
                val confirmed = written?.let {
                    mapOf(
                        0 to it.autoHeartDetect, 1 to it.autoBpDetect, 2 to it.bloodGlucoseDetection,
                        3 to it.stressDetect, 5 to it.autoTemperatureDetect, 7 to it.autoHrv,
                        8 to it.bloodComponentDetect, 9 to it.ppg,
                    )
                }
                val out = types.map {
                    val on = confirmed?.get(it)?.isOpen == true
                    mapOf("type" to it, "isSwitchOpen" to on, "success" to on)
                }.toMutableList()
                // All-day SpO2 is a separate command (00:00-23:59)
                val spo2 = AllSetSetting(EAllSetType.SPO2H_NIGHT_AUTO_DETECT, 0, 0, 23, 59, 0, 1)
                once<AllSetData>({ f -> vpManager.settingSpo2hAutoDetect(writeResponse, { f(it) }, spo2) }) { r ->
                    out.add(mapOf("type" to 4, "isSwitchOpen" to (r != null), "success" to (r != null)))
                    result.success(out)
                }
            }
        }
    }

    private data class Quad(val type: Int, val get: () -> EFunctionStatus?, val set: (EFunctionStatus) -> Unit, val flag: Boolean)

    private fun <T> once(start: ((T?) -> Unit) -> Unit, done: (T?) -> Unit) {
        var finished = false
        var timeout: Job? = null
        val finish: (T?) -> Unit = { v ->
            if (!finished) {
                finished = true
                timeout?.cancel()
                done(v)
            }
        }
        timeout = scope.launch { delay(TIMEOUT_MS); VPLogger.w("auto measure legacy call timeout"); finish(null) }
        start(finish)
    }

    private fun enableAllNew() {
        read { list ->
            if (list == null) {
                fail("AUTO_MEASURE_READ_FAILED", "Failed to read automatic measurement settings")
                return@read
            }
            val outcome = mutableListOf<Map<String, Any?>>()
            fun next(i: Int) {
                if (i == list.size) {
                    result.success(outcome)
                    return
                }
                val item = list[i]
                if (item.isSwitchOpen) {
                    outcome.add(toMap(item))
                    next(i + 1)
                    return
                }
                item.isSwitchOpen = true
                write(item) { ok ->
                    if (!ok) item.isSwitchOpen = false
                    outcome.add(toMap(item) + ("success" to ok))
                    next(i + 1)
                }
            }
            next(0)
        }
    }

    private fun ifSupported(block: () -> Unit) {
        try {
            if (!vpSpGetUtil.isSupportAutoMeasure) {
                fail("AUTO_MEASURE_NOT_SUPPORTED", "This device does not support automatic measurement")
                return
            }
            block()
        } catch (e: Exception) {
            fail("AUTO_MEASURE_ERROR", "Automatic measurement error: ${e.message}")
        }
    }

    private fun read(done: (List<AutoMeasureData>?) -> Unit) {
        var finished = false
        var timeout: Job? = null
        fun finish(list: List<AutoMeasureData>?) {
            if (finished) return
            finished = true
            timeout?.cancel()
            done(list)
        }
        timeout = scope.launch { delay(TIMEOUT_MS); VPLogger.w("auto measure read timeout"); finish(null) }
        vpManager.readAutoMeasureSettingData(writeResponse, object : IAutoMeasureSettingDataListener {
            override fun onSettingDataChange(list: List<AutoMeasureData>) = finish(list)
            override fun onSettingDataChangeFail() = finish(null)
            override fun onSettingDataChangeSuccess() {}
        })
    }

    private fun write(item: AutoMeasureData, done: (Boolean) -> Unit) {
        var finished = false
        var timeout: Job? = null
        fun finish(ok: Boolean) {
            if (finished) return
            finished = true
            timeout?.cancel()
            done(ok)
        }
        timeout = scope.launch { delay(TIMEOUT_MS); VPLogger.w("auto measure write timeout"); finish(false) }
        vpManager.setAutoMeasureSettingData(writeResponse, item, object : IAutoMeasureSettingDataListener {
            override fun onSettingDataChange(list: List<AutoMeasureData>) {}
            override fun onSettingDataChangeFail() = finish(false)
            override fun onSettingDataChangeSuccess() = finish(true)
        })
    }

    private val writeResponse = IBleWriteResponse { code -> VPLogger.d("auto measure write response: $code") }

    private fun fail(code: String, message: String) = result.error(code, message, null)

    private fun toMap(d: AutoMeasureData): Map<String, Any?> = mapOf(
        "type" to d.funType.value,
        "isSwitchOpen" to d.isSwitchOpen,
        "stepUnit" to d.stepUnit,
        "isSlotModify" to d.isSlotModify,
        "isIntervalModify" to d.isIntervalModify,
        "supportStartMinute" to d.supportStartMinute,
        "supportEndMinute" to d.supportEndMinute,
        "measureInterval" to d.measureInterval,
        "currentStartMinute" to d.currentStartMinute,
        "currentEndMinute" to d.currentEndMinute,
    )
}
