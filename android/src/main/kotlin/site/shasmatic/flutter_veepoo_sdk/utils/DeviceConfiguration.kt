package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IAdjustListener
import com.veepoo.protocol.model.settings.ScreenSetting
import com.veepoo.protocol.model.settings.TimeFormat
import com.veepoo.protocol.model.settings.LanguageSetting
import com.veepoo.protocol.model.settings.WristScreenSetting
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for device configuration and settings.
 *
 * @constructor Creates a new [DeviceConfiguration] instance with VPOperateManager.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class DeviceConfiguration(
    private val vpManager: VPOperateManager,
) {

    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Sets screen brightness.
     *
     * @param brightness Brightness level (0-5)
     */
    fun setScreenBrightness(brightness: Int) {
        executeConfigOperation {
            val screenSetting = ScreenSetting()
            screenSetting.screenLight = brightness
            vpManager.settingScreenLight(writeResponse, adjustListener, screenSetting)
        }
    }

    /**
     * Sets screen duration.
     *
     * @param seconds Duration in seconds
     */
    fun setScreenDuration(seconds: Int) {
        executeConfigOperation {
            val screenSetting = ScreenSetting()
            screenSetting.screenDuration = seconds
            vpManager.settingScreenDuration(writeResponse, adjustListener, screenSetting)
        }
    }

    /**
     * Sets time format (12h/24h).
     *
     * @param is24Hour True for 24-hour format, false for 12-hour
     */
    fun setTimeFormat(is24Hour: Boolean) {
        executeConfigOperation {
            val timeFormat = if (is24Hour) TimeFormat.HOURS_24 else TimeFormat.HOURS_12
            vpManager.settingTimeFormat(writeResponse, adjustListener, timeFormat)
        }
    }

    /**
     * Sets device language.
     *
     * @param languageCode Language code (e.g., "en", "zh", "ja")
     */
    fun setLanguage(languageCode: String) {
        executeConfigOperation {
            val language = LanguageSetting.fromCode(languageCode)
            vpManager.settingDeviceLanguage(writeResponse, adjustListener, language)
        }
    }

    /**
     * Sets wrist raise to wake feature.
     *
     * @param enabled Enable or disable wrist raise
     * @param sensitivity Sensitivity level (0=low, 1=medium, 2=high)
     */
    fun setWristRaiseToWake(enabled: Boolean, sensitivity: Int) {
        executeConfigOperation {
            val wristSetting = WristScreenSetting()
            wristSetting.isOpen = enabled
            wristSetting.sensitivity = sensitivity
            vpManager.settingWristScreen(writeResponse, adjustListener, wristSetting)
        }
    }

    /**
     * Sets do not disturb mode.
     *
     * @param enabled Enable or disable DND
     * @param startMinutes Start time in minutes from midnight
     * @param endMinutes End time in minutes from midnight
     */
    fun setDoNotDisturb(enabled: Boolean, startMinutes: Int, endMinutes: Int) {
        executeConfigOperation {
            vpManager.settingDoNotDisturb(
                writeResponse,
                adjustListener,
                enabled,
                startMinutes,
                endMinutes
            )
        }
    }

    /**
     * Sets comprehensive device settings.
     *
     * @param settingsMap Map containing all settings
     */
    fun setDeviceSettings(settingsMap: Map<String, Any?>) {
        executeConfigOperation {
            // Screen brightness
            (settingsMap["screenBrightness"] as? Int)?.let { brightness ->
                setScreenBrightness(brightness)
            }

            // Screen duration
            (settingsMap["screenDurationSeconds"] as? Int)?.let { duration ->
                setScreenDuration(duration)
            }

            // Time format
            (settingsMap["is24HourFormat"] as? Boolean)?.let { is24h ->
                setTimeFormat(is24h)
            }

            // Language
            (settingsMap["language"] as? String)?.let { lang ->
                setLanguage(lang)
            }

            // Wrist raise
            val wristEnabled = settingsMap["wristRaiseToWake"] as? Boolean ?: false
            val wristSensitivity = settingsMap["wristRaiseSensitivity"] as? Int ?: 1
            setWristRaiseToWake(wristEnabled, wristSensitivity)

            // Do not disturb
            val dndEnabled = settingsMap["doNotDisturb"] as? Boolean ?: false
            val dndStart = settingsMap["doNotDisturbStart"] as? Int ?: 0
            val dndEnd = settingsMap["doNotDisturbEnd"] as? Int ?: 0
            setDoNotDisturb(dndEnabled, dndStart, dndEnd)
        }
    }

    /**
     * Gets device settings.
     *
     * @return Map containing device settings
     */
    fun getDeviceSettings(): Map<String, Any?> {
        // This is a simplified version - actual implementation would read from device
        return mapOf(
            "screenBrightness" to 3,
            "screenDurationSeconds" to 10,
            "is24HourFormat" to true,
            "language" to "en",
            "wristRaiseToWake" to true,
            "wristRaiseSensitivity" to 1
        )
    }

    private fun executeConfigOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            throw VPException("Error during configuration operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            throw VPException("Error during configuration operation: ${e.message}", e.cause)
        }
    }

    private val adjustListener = IAdjustListener { adjustType ->
        VPLogger.d("Device configuration adjusted: $adjustType")
    }
}
