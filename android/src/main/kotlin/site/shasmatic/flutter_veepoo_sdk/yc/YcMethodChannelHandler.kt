package site.shasmatic.flutter_veepoo_sdk.yc

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.yucheng.ycbtsdk.Constants
import com.yucheng.ycbtsdk.YCBTClient
import com.yucheng.ycbtsdk.bean.ScanDeviceBean
import com.yucheng.ycbtsdk.response.BleConnectResponse
import com.yucheng.ycbtsdk.response.BleDataResponse
import com.yucheng.ycbtsdk.response.BleScanResponse
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger

/**
 * Yucheng (YC) backend for the same Dart API. Selected with `setBrand(yc)`.
 *
 * Results use the exact map shapes the Veepoo handler produces, so the Dart models don't change.
 * Methods not listed in [supports] answer with `UNSUPPORTED_BRAND` (not ported yet).
 *
 * The YC SDK is callback based: scan results arrive through [BleScanResponse], connection state
 * through the global [BleConnectResponse] registered in [start].
 */
class YcMethodChannelHandler(
    private val context: Context,
    private val scanSink: () -> EventChannel.EventSink?,
    private val connectionSink: () -> EventChannel.EventSink?,
) {
    private val main = Handler(Looper.getMainLooper())
    private val discovered = LinkedHashMap<String, Map<String, Any?>>()
    private var pendingConnect: MethodChannel.Result? = null
    private var pendingAddress: String? = null
    private var started = false

    companion object {
        // Veepoo's Constants.STATUS_* — the Dart side decodes these codes.
        private const val VP_CONNECTED = 2
        private const val VP_DISCONNECTED = 0
        private const val SCAN_SECONDS = 10
        private const val CONNECT_TIMEOUT_MS = 20_000L

        val supports = setOf(
            "scanDevices", "stopScanDevices", "connectDevice", "disconnectDevice", "bindDevice",
            "getCurrentStatus", "getCurrentDeviceAddress", "getAddress", "isDeviceConnected",
            "isDeviceBinded", "readBattery", "getDeviceInfo",
        )
    }

    /** Initializes the YC client once (safe to call repeatedly). */
    fun start() {
        if (started) return
        started = true
        // Same init as the vendor demo (initClient(ctx, true)); no setReconnect override.
        YCBTClient.initClient(context, true)
        YCBTClient.registerBleStateChange(stateResponse)
    }

    private val isConnected get() = YCBTClient.connectState() == Constants.BLEState.ReadWriteOK

    private val stateResponse = BleConnectResponse { code ->
        VPLogger.i("YC connection state=$code")
        val connected = code == Constants.BLEState.ReadWriteOK
        // TimeOut (1) is emitted transiently at the start of a connect (seen on E810: 4,5,1,6..10),
        // so it is not a failure; real timeouts are handled by connectTimeout.
        val disconnected = code == Constants.BLEState.Disconnect
        if (connected) main.removeCallbacks(connectTimeout)
        if (connected || disconnected) {
            val address = pendingAddress ?: YCBTClient.getBindDeviceMac()
            val event = mapOf<String, Any?>(
                "state" to if (connected) VP_CONNECTED else VP_DISCONNECTED,
                "address" to address,
                "timestamp" to System.currentTimeMillis(),
            )
            main.post { connectionSink()?.success(event) }
            pendingConnect?.let { r ->
                pendingConnect = null
                main.post {
                    if (connected) r.success(null)
                    else r.error("CONNECT_FAILED", "YC connection failed (state=$code)", null)
                }
            }
        }
    }

    private val connectTimeout = Runnable {
        pendingConnect?.let {
            pendingConnect = null
            YCBTClient.disconnectBle()
            it.error("CONNECT_FAILED", "YC connection timed out", null)
        }
    }

    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        start()
        try {
            when (call.method) {
                "scanDevices" -> scan(result)
                "stopScanDevices" -> { YCBTClient.stopScanBle(); result.success(null) }
                "connectDevice" -> connect(call.argument<String>("address"), result)
                "disconnectDevice" -> { YCBTClient.disconnectBle(); result.success(null) }
                // YC has no password bind step: a ready connection is the bound state.
                "bindDevice" ->
                    if (isConnected) result.success("CHECK_AND_TIME_SUCCESS")
                    else result.error("NOT_CONNECTED", "Device is not connected", null)
                "getCurrentStatus" ->
                    result.success(if (isConnected) VP_CONNECTED else VP_DISCONNECTED)
                "getCurrentDeviceAddress", "getAddress" ->
                    result.success(if (isConnected) YCBTClient.getBindDeviceMac() else null)
                "isDeviceConnected" -> {
                    val a = call.argument<String>("address")
                    result.success(isConnected && (a == null || a.equals(YCBTClient.getBindDeviceMac(), true)))
                }
                "isDeviceBinded" -> result.success(isConnected)
                "readBattery" -> readBattery(result)
                "getDeviceInfo" -> getDeviceInfo(result)
                else -> result.error("UNSUPPORTED_BRAND", "${call.method} is not supported for the YC brand yet", null)
            }
        } catch (e: Exception) {
            result.error("YC_ERROR", "${call.method} failed: ${e.message}", null)
        }
    }

    private fun scan(result: MethodChannel.Result) {
        discovered.clear()
        YCBTClient.startScanBle(BleScanResponse { _, bean: ScanDeviceBean? ->
            val mac = bean?.deviceMac ?: return@BleScanResponse
            discovered[mac] = mapOf("name" to bean.deviceName, "address" to mac, "rssi" to bean.deviceRssi)
            val list = discovered.values.toList()
            main.post { scanSink()?.success(list) }
        }, SCAN_SECONDS)
        result.success(null)
    }

    private fun connect(address: String?, result: MethodChannel.Result) {
        if (address == null) return result.error("INVALID_ARGUMENT", "MAC address is required", null)
        YCBTClient.stopScanBle()
        pendingConnect?.error("CONNECT_CANCELLED", "Superseded by a new connect", null)
        pendingConnect = result
        pendingAddress = address
        main.removeCallbacks(connectTimeout)
        main.postDelayed(connectTimeout, CONNECT_TIMEOUT_MS)
        // The per-call callback is unused: the global stateResponse decides the outcome.
        YCBTClient.connectBle(address, BleConnectResponse { })
    }

    /** YC reports battery + version inside getDeviceInfo's `data` map. */
    private fun deviceInfoData(onData: (Map<*, *>?) -> Unit) {
        YCBTClient.getDeviceInfo(BleDataResponse { code, _, map ->
            val data = if (code == Constants.CODE.Code_OK) map?.get("data") as? Map<*, *> else null
            main.post { onData(data) }
        })
    }

    private fun readBattery(result: MethodChannel.Result) = deviceInfoData { d ->
        val value = d?.get("deviceBatteryValue")?.toString()?.toDoubleOrNull()?.toInt()
        if (value == null) {
            result.error("BATTERY_ERROR", "Failed to read battery", null)
            return@deviceInfoData
        }
        val state = d["deviceBatteryState"]?.toString()?.toDoubleOrNull()?.toInt()
        result.success(
            mapOf<String, Any?>(
                "level" to null, "percent" to value, "powerModel" to null, "state" to state,
                "bat" to value, "isLow" to (value <= 15), "isPercent" to true,
            )
        )
    }

    private fun getDeviceInfo(result: MethodChannel.Result) = deviceInfoData { d ->
        result.success(
            mapOf<String, Any?>(
                "modelName" to (YCBTClient.getBindDeviceName() ?: "Unknown"),
                "hardwareVersion" to "Unknown",
                "softwareVersion" to (d?.get("deviceVersion")?.toString() ?: "Unknown"),
                "macAddress" to (YCBTClient.getBindDeviceMac() ?: "Unknown"),
                "manufacturer" to "Yucheng",
            )
        )
    }
}
