package site.shasmatic.flutter_veepoo_sdk.utils

import com.inuker.bluetooth.library.Code
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IBleWriteResponse
import com.veepoo.protocol.listener.data.IBodyComponentReadDataListener
import com.veepoo.protocol.listener.data.IBodyComponentReadIdListener
import com.veepoo.protocol.model.datas.BodyComponent
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import site.shasmatic.flutter_veepoo_sdk.VPLogger

/**
 * Utility class for reading previously stored body composition measurements from the device.
 *
 * Records are read in two steps, per the SDK: first the list of record IDs ([readBodyComponentId]),
 * then the record data for some or all of those IDs ([readBodyComponentData]).
 *
 * For live/on-demand measurement, see [BodyComponentDetection].
 *
 * @constructor Creates a new [BodyComponentReader] instance.
 * @param result The method channel result to return data to Flutter.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class BodyComponentReader(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
) {
    private var hasReturnedResult = false
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())
    private var timeoutJob: Job? = null

    companion object {
        private const val READ_TIMEOUT_MS = 30000L
    }

    /**
     * Reads the IDs of all body composition records stored on the device.
     */
    fun readBodyComponentId() {
        try {
            VPLogger.d("Starting to read body composition record IDs...")
            hasReturnedResult = false
            startTimeout()

            val writeResponse = IBleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    VPLogger.e("Body composition read-id request failed with code: $code")
                    returnError("BODY_COMPONENT_ID_REQUEST_FAILED", "Failed to request body composition IDs (code: $code)")
                }
            }

            vpManager.readBodyComponentId(writeResponse, idListener)
        } catch (e: Exception) {
            VPLogger.e("Error reading body composition IDs: ${e.message}")
            cancelTimeout()
            returnError("BODY_COMPONENT_ID_ERROR", "Error reading body composition IDs: ${e.message}")
        }
    }

    /**
     * Reads body composition record data.
     * @param ids Specific record IDs to read, as previously returned by [readBodyComponentId].
     * When null or empty, all stored records are read.
     */
    fun readBodyComponentData(ids: List<Int>?) {
        try {
            VPLogger.d("Starting to read body composition data for ids=$ids...")
            hasReturnedResult = false
            startTimeout()

            val writeResponse = IBleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    VPLogger.e("Body composition read-data request failed with code: $code")
                    returnError("BODY_COMPONENT_DATA_REQUEST_FAILED", "Failed to request body composition data (code: $code)")
                }
            }

            if (ids.isNullOrEmpty()) {
                vpManager.readBodyComponentData(writeResponse, dataListener)
            } else {
                vpManager.readBodyComponentData(writeResponse, dataListener, ArrayList(ids))
            }
        } catch (e: Exception) {
            VPLogger.e("Error reading body composition data: ${e.message}")
            cancelTimeout()
            returnError("BODY_COMPONENT_DATA_ERROR", "Error reading body composition data: ${e.message}")
        }
    }

    // IBodyComponentReadIdListener/IBodyComponentReadDataListener are Kotlin-compiled interfaces
    // (not plain Java SAMs), so they're implemented with object expressions rather than lambdas
    // to avoid relying on whether the vendor declared them as `fun interface`.
    private val idListener = object : IBodyComponentReadIdListener {
        override fun readIdFinish(ids: ArrayList<Int>) {
            VPLogger.d("Body composition IDs received: ${ids.size}")
            returnSuccess(ids.toList())
        }
    }

    private val dataListener = object : IBodyComponentReadDataListener {
        override fun readBodyComponentDataFinish(bodyComponentList: List<BodyComponent>?) {
            VPLogger.d("Body composition data received: ${bodyComponentList?.size} records")
            returnSuccess((bodyComponentList ?: emptyList()).map { bodyComponentToMap(it) })
        }
    }

    private fun startTimeout() {
        timeoutJob?.cancel()
        timeoutJob = coroutineScope.launch {
            delay(READ_TIMEOUT_MS)
            VPLogger.w("Body composition read timeout after ${READ_TIMEOUT_MS}ms")
            returnError("BODY_COMPONENT_TIMEOUT", "Body composition read timed out.")
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

    private fun returnSuccess(data: Any) {
        cancelTimeout()
        if (!hasReturnedResult) {
            hasReturnedResult = true
            result.success(data)
        }
    }
}
