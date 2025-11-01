package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IAdjustListener
import com.veepoo.protocol.model.datas.PersonInfoData
import io.flutter.plugin.common.MethodChannel
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for managing user profile (PersonInfo).
 *
 * @constructor Creates a new [UserProfileManager] instance.
 * @param result The result channel to return data to Flutter.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class UserProfileManager(
    private val result: MethodChannel.Result,
    private val vpManager: VPOperateManager,
) {

    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Sets user profile information on the device.
     *
     * @param heightCm User height in cm
     * @param weightKg User weight in kg
     * @param age User age in years
     * @param sex User sex (0 = female, 1 = male)
     * @param targetSteps Daily step goal
     * @param targetSleepMinutes Daily sleep goal in minutes
     */
    fun setUserProfile(
        heightCm: Int?,
        weightKg: Double?,
        age: Int?,
        sex: Int?,
        targetSteps: Int?,
        targetSleepMinutes: Int?
    ) {
        if (heightCm == null || weightKg == null || age == null || sex == null) {
            result.error("INVALID_ARGUMENT", "Height, weight, age, and sex are required", null)
            return
        }

        executeProfileOperation {
            val personInfo = PersonInfoData(
                heightCm,
                weightKg.toInt(),
                age,
                sex,
                targetSteps ?: 10000,
                targetSleepMinutes ?: 480 // Default 8 hours
            )
            vpManager.syncPersonInfo(writeResponse, adjustListener, personInfo)
        }
    }

    /**
     * Reads user profile information from the device.
     */
    fun getUserProfile() {
        executeProfileOperation {
            vpManager.readPersonInfo(writeResponse) { personData ->
                if (personData == null) {
                    result.error("NO_DATA", "No person info available", null)
                    return@readPersonInfo
                }

                val profileData = mapOf<String, Any?>(
                    "heightCm" to personData.height,
                    "weightKg" to personData.weight?.toDouble(),
                    "age" to personData.age,
                    "gender" to if (personData.sex == 0) "female" else if (personData.sex == 1) "male" else "other",
                    "targetSteps" to personData.targetStepCount,
                    "targetSleepMinutes" to personData.targetSleepTime
                )

                result.success(profileData)
            }
        }
    }

    private fun executeProfileOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            result.error("OPERATION_ERROR", "Error during profile operation: ${e.targetException.message}", null)
        } catch (e: Exception) {
            result.error("OPERATION_ERROR", "Error during profile operation: ${e.message}", null)
        }
    }

    private val adjustListener = IAdjustListener { state ->
        // Callback when setting is complete
        if (state == 0) {
            result.success(true)
        } else {
            result.error("OPERATION_FAILED", "Failed to set user profile", null)
        }
    }
}
