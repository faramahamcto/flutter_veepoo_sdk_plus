package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IAdjustListener
import com.veepoo.protocol.listener.data.ICustomSettingDataListener
import com.veepoo.protocol.model.settings.CustomSetting
import io.flutter.plugin.common.MethodChannel
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for managing device settings.
 *
 * @constructor Creates a new [DeviceSettings] instance.
 * @param result The result channel to return data to Flutter.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class DeviceSettings(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
) {

    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Reads current device settings.
     */
    fun getDeviceSettings() {
        executeSettingsOperation {
            vpManager.readCustomSetting(writeResponse, customSettingDataListener)
        }
    }

    /**
     * Sets device settings.
     */
    fun setDeviceSettings(
        screenBrightness: Int?,
        screenDurationSeconds: Int?,
        is24HourFormat: Boolean?,
        languageCode: Int?,
        temperatureUnit: Int?, // 0 = Celsius, 1 = Fahrenheit
        distanceUnit: Int?, // 0 = Metric, 1 = Imperial
        wristRaiseToWake: Boolean?,
        doNotDisturb: Boolean?,
        doNotDisturbStart: Int?, // Minutes from midnight
        doNotDisturbEnd: Int? // Minutes from midnight
    ) {
        executeSettingsOperation {
            vpManager.readCustomSetting(writeResponse) { currentSetting ->
                if (currentSetting == null) {
                    result.error("NO_DATA", "Cannot read current settings", null)
                    return@readCustomSetting
                }

                // Update only provided values
                val newSetting = CustomSetting().apply {
                    // Copy current values
                    screenAutoBrightness = currentSetting.screenAutoBrightness
                    screenBrightnessValue = screenBrightness ?: currentSetting.screenBrightnessValue
                    screenTime = screenDurationSeconds ?: currentSetting.screenTime
                    isMainSportAutoRecognition = currentSetting.isMainSportAutoRecognition
                    isTemptureOpen = currentSetting.isTemptureOpen
                    isGpsRun = currentSetting.isGpsRun
                    unitState = distanceUnit ?: currentSetting.unitState
                    timeMode = if (is24HourFormat != null) {
                        if (is24HourFormat) 0 else 1
                    } else currentSetting.timeMode
                    isOpenWrist = wristRaiseToWake ?: currentSetting.isOpenWrist
                    isAutoHeartDetect = currentSetting.isAutoHeartDetect
                    isAutoBpDetect = currentSetting.isAutoBpDetect
                    temptrueMode = temperatureUnit ?: currentSetting.temptrueMode
                    skinType = currentSetting.skinType

                    // Do Not Disturb settings
                    if (doNotDisturb != null) {
                        noDisturbState = if (doNotDisturb) 1 else 0
                    } else {
                        noDisturbState = currentSetting.noDisturbState
                    }
                    noDisturbStartHour = (doNotDisturbStart?.div(60)) ?: currentSetting.noDisturbStartHour
                    noDisturbStartMinute = (doNotDisturbStart?.rem(60)) ?: currentSetting.noDisturbStartMinute
                    noDisturbEndHour = (doNotDisturbEnd?.div(60)) ?: currentSetting.noDisturbEndHour
                    noDisturbEndMinute = (doNotDisturbEnd?.rem(60)) ?: currentSetting.noDisturbEndMinute
                }

                vpManager.changeCustomSetting(writeResponse, adjustListener, newSetting)
            }
        }
    }

    private fun executeSettingsOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            result.error("OPERATION_ERROR", "Error during settings operation: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("OPERATION_ERROR", "Error during settings operation: ${e.message}", null)
        }
    }

    private val customSettingDataListener = ICustomSettingDataListener { setting ->
        if (setting == null) {
            result.error("NO_DATA", "No settings data available", null)
            return@ICustomSettingDataListener
        }

        val settingsData = mapOf<String, Any?>(
            "screenBrightness" to setting.screenBrightnessValue,
            "screenDurationSeconds" to setting.screenTime,
            "is24HourFormat" to (setting.timeMode == 0),
            "language" to mapLanguageCode(setting.languageState),
            "temperatureUnit" to if (setting.temptrueMode == 0) "celsius" else "fahrenheit",
            "distanceUnit" to if (setting.unitState == 0) "metric" else "imperial",
            "wristRaiseToWake" to setting.isOpenWrist,
            "wristRaiseSensitivity" to null, // Not available in CustomSetting
            "doNotDisturb" to (setting.noDisturbState == 1),
            "doNotDisturbStart" to (setting.noDisturbStartHour * 60 + setting.noDisturbStartMinute),
            "doNotDisturbEnd" to (setting.noDisturbEndHour * 60 + setting.noDisturbEndMinute)
        )

        result.success(settingsData)
    }

    private val adjustListener = IAdjustListener { state ->
        if (state == 0) {
            result.success(true)
        } else {
            result.error("OPERATION_FAILED", "Failed to set device settings", null)
        }
    }

    private fun mapLanguageCode(code: Int?): String {
        return when (code) {
            0 -> "english"
            1 -> "chinese"
            2 -> "japanese"
            3 -> "korean"
            4 -> "german"
            5 -> "french"
            6 -> "spanish"
            7 -> "italian"
            8 -> "portuguese"
            9 -> "russian"
            else -> "english"
        }
    }
}
