package site.shasmatic.flutter_veepoo_sdk.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import com.inuker.bluetooth.library.connect.response.BleNotifyResponse
import com.inuker.bluetooth.library.jieli.dial.JLWatchFaceManager
import com.inuker.bluetooth.library.jieli.dial.JLWatchHolder
import com.inuker.bluetooth.library.jieli.response.RcspAuthResponse
import com.jieli.jl_fatfs.model.FatFile
import com.jieli.jl_rcsp.model.base.BaseError
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.customui.WatchUIType
import com.veepoo.protocol.listener.data.IUiUpdateListener
import com.veepoo.protocol.listener.oad.OnDownLoadListener
import com.veepoo.protocol.model.datas.UICustomSetData
import com.veepoo.protocol.model.datas.UIDataCustom
import com.veepoo.protocol.model.datas.UIDataServer
import com.veepoo.protocol.model.enums.EUIFromType
import com.veepoo.protocol.model.enums.EUiUpdateError
import com.veepoo.protocol.model.enums.EWatchUIElementPosition
import com.veepoo.protocol.model.enums.EWatchUIElementType
import com.veepoo.protocol.shareprence.VpSpGetUtil
import com.veepoo.protocol.util.UiServerHttpUtil
import com.veepoo.protocol.util.UiUpdateUtil
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import java.io.File
import java.util.UUID
import kotlin.concurrent.thread

/**
 * Photo (custom) watch face: read its layout and set background photo + elements.
 * Market (server) watch faces: list them from the Veepoo server and install one.
 *
 * Positions and elements cross the channel as enum ordinals, which match the Dart
 * `WatchFacePosition` / `WatchFaceElement` order (and the iOS raw values).
 *
 * Two transfer paths, picked by chip:
 * - Veepoo chip: elements via [UiUpdateUtil.setCustomWacthUi], then photo via [UiUpdateUtil.startSetUiStream].
 * - JieLi chip: JieLi auth + file system, photo via [VPOperateManager.setJLWatchPhotoDial], then
 *   elements again (the JL photo transfer resets them).
 * Market faces use the same split: [UiUpdateUtil.startSetUiStream] vs [VPOperateManager.setJLWatchDial].
 */
class WatchFace(
    private val context: Context,
    private val vpManager: VPOperateManager,
    private val progressSink: EventChannel.EventSink?,
) {
    private val ui = UiUpdateUtil.getInstance()
    private val main = Handler(Looper.getMainLooper())

    fun read(result: MethodChannel.Result) {
        val reply = Once(result)
        readInfo(reply) { data, type -> reply.success(data.toMap(type)) }
    }

    fun set(
        result: MethodChannel.Result,
        timePosition: Int,
        upElement: Int,
        downElement: Int,
        color: Int,
        useDefaultBackground: Boolean,
        imagePath: String?,
    ) {
        val reply = Once(result)
        readInfo(reply) { _, type ->
            val elements = UICustomSetData(
                useDefaultBackground && imagePath == null,
                EWatchUIElementPosition.values()[timePosition],
                EWatchUIElementType.values()[upElement],
                EWatchUIElementType.values()[downElement],
                color,
            )
            val bitmap = imagePath?.let { BitmapFactory.decodeFile(it) }
            if (imagePath != null && bitmap == null) return@readInfo reply.error("WATCH_FACE_IMAGE", "Cannot decode $imagePath")

            when {
                bitmap == null -> applyElements(elements) { reply.success(null) }
                vpManager.isJLDevice -> setJLPhoto(reply, type, bitmap) {
                    // JL docs: re-apply elements ~150ms after the photo lands.
                    main.postDelayed({ applyElements(elements) { reply.success(null) } }, 150)
                }
                else -> applyElements(elements) { setPhoto(reply, type, bitmap) }
            }
        }
    }

    fun readMarket(result: MethodChannel.Result) {
        val reply = Once(result)
        readServerInfo(reply) { data ->
            // Network call; must not run on the main thread.
            thread {
                try {
                    val sp = VpSpGetUtil.getVpSpVariInstance(context)
                    val appVersion = context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: ""
                    val themes = UiServerHttpUtil().getThemeInfo(data, sp.deviceNumber, sp.testVersion, context.packageName, appVersion)
                    reply.success(themes.orEmpty().map { mapOf("previewUrl" to it.previewUrl, "fileUrl" to it.fileUrl) })
                } catch (e: Exception) {
                    reply.error("WATCH_FACE_MARKET", "Fetching market watch faces failed: ${e.message}")
                }
            }
        }
    }

    fun installMarket(result: MethodChannel.Result, fileUrl: String) {
        val reply = Once(result)
        // Server transfer needs the server info read first (else NEED_READ_BASE_INFO).
        readServerInfo(reply) {
            // Keep the server's file name: the watch validates it.
            val file = File(context.cacheDir, fileUrl.substringAfterLast('/'))
            thread {
                try {
                    file.delete()
                    UiServerHttpUtil().downloadFile(fileUrl, file.absolutePath, object : OnDownLoadListener {
                        override fun onProgress(progress: Float) {}
                        override fun onFinish() {
                            main.post {
                                if (file.length() == 0L) reply.error("WATCH_FACE_DOWNLOAD", "Download failed: $fileUrl")
                                else transferMarket(reply, file)
                            }
                        }
                    })
                } catch (e: Exception) {
                    reply.error("WATCH_FACE_DOWNLOAD", "Download failed: ${e.message}")
                }
            }
        }
    }

    private fun transferMarket(reply: Once, file: File) {
        if (!vpManager.isJLDevice) {
            return ui.startSetUiStream(EUIFromType.SERVER, file.inputStream(), uiUpdateListener(reply))
        }
        openJLFileSystem(reply) {
            vpManager.setJLWatchDial(file.absolutePath, object : JLWatchHolder.OnSetJLWatchDialListener {
                override fun onStart() {}
                override fun onProgress(progress: Int) = sendProgress(progress)
                override fun onComplete(watchPath: String?) = reply.success(null)
                override fun onFiled(code: Int, msg: String?) =
                    reply.error("WATCH_FACE_TRANSFER", "JL transfer failed ($code): $msg")
            })
        }
    }

    private fun readServerInfo(reply: Once, onInfo: (UIDataServer) -> Unit) {
        ui.init(context)
        if (!ui.isSupportChangeServerUi) return reply.success(null)
        ui.getServerWatchUiInfo { data ->
            main.post {
                if (data == null) reply.error("WATCH_FACE_UNSUPPORTED", "No server watch face info")
                else onInfo(data)
            }
        }
    }

    private fun readInfo(reply: Once, onInfo: (UIDataCustom, WatchUIType) -> Unit) {
        ui.init(context)
        if (!ui.isSupportChangeCustomUi) return reply.success(null)
        ui.getCustomWatchUiInfo { data ->
            main.post {
                val type = data?.customUIType?.let { WatchUIType.getInstance(it) }
                if (data == null || type == null) reply.error("WATCH_FACE_UNSUPPORTED", "Unknown screen type ${data?.customUIType}")
                else onInfo(data, type)
            }
        }
    }

    private fun applyElements(elements: UICustomSetData, done: () -> Unit) {
        ui.setCustomWacthUi(elements) { main.post(done) }
    }

    private fun setPhoto(reply: Once, type: WatchUIType, bitmap: Bitmap) {
        ui.startSetUiStream(EUIFromType.CUSTOM, type.getSendInputStream(context, bitmap), uiUpdateListener(reply))
    }

    private fun uiUpdateListener(reply: Once) = object : IUiUpdateListener {
        override fun onUiUpdateStart() {}
        override fun onStartClearCache(sumCount: Int) {}
        override fun onClearCacheProgress(currentCount: Int, sumCount: Int, progress: Int) {}
        override fun onFinishClearCache() {}
        override fun onUiUpdateProgress(currentBlock: Int, sumBlock: Int, progress: Int) = sendProgress(progress)
        override fun onUiUpdateSuccess() = reply.success(null)
        override fun onUiUpdateFail(error: EUiUpdateError?) = when (error) {
            EUiUpdateError.LOW_BATTERY -> reply.error("WATCH_FACE_LOW_BATTERY", "Watch battery is too low")
            // Same file already on the watch: nothing to send.
            EUiUpdateError.APP_CRC_SAME_DEVICE_CRC -> reply.success(null)
            else -> reply.error("WATCH_FACE_TRANSFER", "Transfer failed: $error")
        }
    }

    private fun setJLPhoto(reply: Once, type: WatchUIType, bitmap: Bitmap, done: () -> Unit) {
        // JL rejects photos that aren't exactly the screen size.
        val sized = Bitmap.createScaledBitmap(bitmap, type.bigBitmapWidth, type.bigBitmapHeight, true)
        val file = File(context.cacheDir, "watch_face_photo.png")
        file.outputStream().use { sized.compress(Bitmap.CompressFormat.PNG, 100, it) }

        openJLFileSystem(reply) {
            vpManager.setJLWatchPhotoDial(file.absolutePath, object : JLWatchFaceManager.JLTransferPicDialListener {
                override fun onLowPower() = reply.error("WATCH_FACE_LOW_BATTERY", "Watch battery is too low")
                override fun onJLTransferPicDialStart() {}
                override fun onTransferPicDialProgress(progress: Int) = sendProgress(progress)
                override fun onScaleBGPFileTransferComplete() {}
                override fun onAIPreviewTransferComplete() {}
                override fun onBigBGPFileTransferComplete() {}
                override fun onTransferComplete() { main.post(done) }
                override fun onTransferError(code: Int, msg: String?) =
                    reply.error("WATCH_FACE_TRANSFER", "JL transfer failed ($code): $msg")
            })
        }
    }

    /** JL notify → MTU → device auth → file system. Skipped once the file system is open. */
    private fun openJLFileSystem(reply: Once, onReady: () -> Unit) {
        if (vpManager.isJLSDKFileSystemInit) return onReady()
        val fail = { step: String -> reply.error("WATCH_FACE_JL_INIT", "JieLi $step failed") }
        vpManager.openJLDataNotify(object : BleNotifyResponse {
            override fun onNotify(service: UUID?, character: UUID?, value: ByteArray?) {}
            override fun onResponse(code: Int) {
                vpManager.changeMTU(247) {
                    vpManager.startJLDeviceAuth(object : RcspAuthResponse {
                        override fun onRcspAuthStart() {}
                        override fun onRcspAuthFailed() = fail("auth")
                        override fun onRcspAuthSuccess() {
                            vpManager.listJLWatchList(object : JLWatchFaceManager.OnWatchDialInfoGetListener {
                                override fun onGettingWatchDialInfo() {}
                                override fun onWatchDialInfoGetStart() {}
                                override fun onWatchDialInfoGetComplete() {}
                                override fun onWatchDialInfoGetSuccess(system: MutableList<FatFile>?, server: MutableList<FatFile>?, pic: FatFile?) {
                                    main.post(onReady)
                                }
                                override fun onWatchDialInfoGetFailed(error: BaseError?) = fail("file system")
                            })
                        }
                    })
                }
            }
        })
    }

    private fun sendProgress(progress: Int) {
        main.post { progressSink?.success(progress) }
    }

    private fun UIDataCustom.toMap(type: WatchUIType) = mapOf<String, Any?>(
        "width" to type.bigBitmapWidth,
        "height" to type.bigBitmapHeight,
        "isRound" to (type.isRoundScreen ?: false),
        "isJL" to vpManager.isJLDevice,
        "positions" to type.supportPosition.map { it.ordinal },
        "timePosition" to timePosition?.ordinal,
        "upElement" to upTimeType?.ordinal,
        "downElement" to downTimeType?.ordinal,
        "color" to color888,
        "isDefaultBackground" to isDefalutUI,
    )

    /** SDK callbacks can fire more than once; Flutter crashes on a second reply. */
    private inner class Once(private val result: MethodChannel.Result) {
        private var done = false

        fun success(value: Any?) {
            main.post { if (!done) { done = true; result.success(value) } }
        }

        fun error(code: String, message: String) {
            main.post {
                if (!done) {
                    done = true
                    VPLogger.e("$code: $message")
                    result.error(code, message, null)
                }
            }
        }
    }
}
