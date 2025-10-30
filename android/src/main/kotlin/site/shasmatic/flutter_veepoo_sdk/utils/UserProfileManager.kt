package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IAdjustListener
import com.veepoo.protocol.model.settings.PersonInfo
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for managing user profile information.
 *
 * @constructor Creates a new [UserProfileManager] instance with VPOperateManager.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class UserProfileManager(
    private val vpManager: VPOperateManager,
) {

    private val writeResponse: VPWriteResponse = VPWriteResponse()

    /**
     * Sets user profile information.
     *
     * @param profileMap Map containing user profile data
     */
    fun setUserProfile(profileMap: Map<String, Any?>) {
        executeProfileOperation {
            val personInfo = PersonInfo()

            // Height in cm
            (profileMap["heightCm"] as? Int)?.let { height ->
                personInfo.height = height
            }

            // Weight in kg
            (profileMap["weightKg"] as? Double)?.let { weight ->
                personInfo.weight = weight.toFloat()
            }

            // Age
            (profileMap["age"] as? Int)?.let { age ->
                personInfo.age = age
            }

            // Gender (0=female, 1=male, 2=other)
            (profileMap["gender"] as? String)?.let { genderStr ->
                personInfo.sex = when (genderStr.lowercase()) {
                    "male" -> 1
                    "female" -> 0
                    else -> 2
                }
            }

            // Target steps
            (profileMap["targetSteps"] as? Int)?.let { targetSteps ->
                personInfo.targetStep = targetSteps
            }

            // Target sleep minutes
            (profileMap["targetSleepMinutes"] as? Int)?.let { targetSleep ->
                personInfo.targetSleepTime = targetSleep
            }

            vpManager.settingPersonInfo(writeResponse, adjustListener, personInfo)
        }
    }

    /**
     * Gets user profile information.
     *
     * @return Map containing user profile data
     */
    fun getUserProfile(): Map<String, Any?>? {
        var profileData: Map<String, Any?>? = null

        executeProfileOperation {
            vpManager.readPersonInfo(writeResponse) { personInfo ->
                if (personInfo != null) {
                    profileData = mapOf(
                        "heightCm" to personInfo.height,
                        "weightKg" to personInfo.weight.toDouble(),
                        "age" to personInfo.age,
                        "gender" to when (personInfo.sex) {
                            1 -> "male"
                            0 -> "female"
                            else -> "other"
                        },
                        "targetSteps" to personInfo.targetStep,
                        "targetSleepMinutes" to personInfo.targetSleepTime
                    )
                }
                VPLogger.d("User profile received: $personInfo")
            }
        }

        // Wait for data
        Thread.sleep(1000)

        return profileData
    }

    private fun executeProfileOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            throw VPException("Error during profile operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            throw VPException("Error during profile operation: ${e.message}", e.cause)
        }
    }

    private val adjustListener = IAdjustListener { adjustType ->
        VPLogger.d("User profile adjusted: $adjustType")
    }
}
