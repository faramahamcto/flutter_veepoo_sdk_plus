package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IBleWriteResponse
import com.veepoo.protocol.listener.data.IAutoMeasureSettingDataListener
import com.veepoo.protocol.model.datas.AutoMeasureData
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

    /** Switches on every type the device supports, one write at a time. Returns the per-type outcome. */
    fun enableAll() = ifSupported {
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
