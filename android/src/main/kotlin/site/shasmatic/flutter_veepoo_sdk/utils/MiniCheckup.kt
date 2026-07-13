package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.IMiniCheckupOptListener
import com.veepoo.protocol.model.datas.MiniCheckupBPAirPump
import com.veepoo.protocol.model.datas.MiniCheckupBPPhotoelectric
import com.veepoo.protocol.model.datas.MiniCheckupBasePersonalInfo
import com.veepoo.protocol.model.datas.MiniCheckupBloodComponent
import com.veepoo.protocol.model.datas.MiniCheckupBodyComponent
import com.veepoo.protocol.model.datas.MiniCheckupDetailData
import com.veepoo.protocol.model.datas.MiniCheckupResultData
import com.veepoo.protocol.model.datas.MiniCheckupSkinElectricity
import com.veepoo.protocol.model.enums.EMiniCheckupTestErrorCode
import io.flutter.plugin.common.EventChannel
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for running a Mini Checkup: a single guided, multi-sensor health check that
 * reports heart rate, SpO2, stress, emotion, fatigue, blood glucose, body temperature, blood
 * pressure and HRV, and optionally a more detailed report also covering blood composition,
 * body composition ([MiniCheckupBodyComponent]) and skin electricity.
 *
 * @constructor Creates a new [MiniCheckup] instance.
 * @param miniCheckupEventSink The sink that receives Mini Checkup events.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class MiniCheckup(
    private val miniCheckupEventSink: EventChannel.EventSink?,
    private val vpManager: VPOperateManager,
) {

    private val sendEvent: SendEvent = SendEvent(miniCheckupEventSink)
    private val writeResponse: VPWriteResponse = VPWriteResponse()
    private var isRunning = false

    /**
     * Starts a Mini Checkup session.
     */
    fun startMiniCheckup() {
        if (isRunning) {
            VPLogger.w("Mini Checkup already in progress, stopping first...")
            stopMiniCheckup()
            Thread.sleep(300)
        }

        executeMiniCheckupOperation {
            isRunning = true
            VPLogger.d("Starting Mini Checkup")
            vpManager.startMiniCheckup(writeResponse, miniCheckupOptListener)
        }
    }

    /**
     * Stops the current Mini Checkup session.
     */
    fun stopMiniCheckup() {
        if (!isRunning) {
            VPLogger.w("Mini Checkup not running, nothing to stop")
            return
        }

        executeMiniCheckupOperation {
            VPLogger.d("Stopping Mini Checkup")
            vpManager.stopMiniCheckup(writeResponse, miniCheckupOptListener)
        }
    }

    private fun executeMiniCheckupOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            isRunning = false
            throw VPException("Error during Mini Checkup operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            isRunning = false
            VPLogger.e("Error during Mini Checkup operation: ${e.message}")
            throw VPException("Error during Mini Checkup operation: ${e.message}", e.cause)
        }
    }

    private val miniCheckupOptListener = object : IMiniCheckupOptListener {
        override fun onMiniCheckupTestProgress(progress: Int) {
            VPLogger.d("Mini Checkup progress: $progress")
            sendEvent.sendMiniCheckupEvent(
                mapOf(
                    "type" to "progress",
                    "progress" to progress,
                    "timestamp" to System.currentTimeMillis()
                )
            )
        }

        override fun onMiniCheckupStopSuccess() {
            VPLogger.d("Mini Checkup stopped")
            isRunning = false
            sendEvent.sendMiniCheckupEvent(
                mapOf(
                    "type" to "stopped",
                    "timestamp" to System.currentTimeMillis()
                )
            )
        }

        override fun onMiniCheckupTestFailed(errorCode: EMiniCheckupTestErrorCode) {
            VPLogger.e("Mini Checkup failed: ${errorCode.name}")
            isRunning = false
            sendEvent.sendMiniCheckupEvent(
                mapOf(
                    "type" to "error",
                    "errorCode" to errorCode.name,
                    "errorMessage" to errorCode.name,
                    "timestamp" to System.currentTimeMillis()
                )
            )
        }

        override fun onMiniCheckupSuccess(resultData: MiniCheckupResultData) {
            VPLogger.d("Mini Checkup success: $resultData")
            isRunning = false
            sendEvent.sendMiniCheckupEvent(
                mapOf(
                    "type" to "result",
                    "result" to resultData.toMap(),
                    "timestamp" to System.currentTimeMillis()
                )
            )
        }

        override fun onMiniCheckupDetailTestSuccess(detailData: MiniCheckupDetailData) {
            VPLogger.d("Mini Checkup detail success: $detailData")
            isRunning = false
            sendEvent.sendMiniCheckupEvent(
                mapOf(
                    "type" to "detail",
                    "detail" to detailData.toMap(),
                    "timestamp" to System.currentTimeMillis()
                )
            )
        }
    }
}

private fun MiniCheckupResultData.toMap(): Map<String, Any?> = mapOf(
    "heartRate" to heartRate,
    "bloodOxygen" to bloodOxygen,
    "stress" to stress,
    "emotion" to emotion,
    "fatigue" to fatigue,
    "bloodGlucose" to bloodGlucose.toDouble(),
    "bodyTemperature" to bodyTemperature.toDouble(),
    "systolicBloodPressure" to systolicBloodPressure,
    "diastolicBloodPressure" to diastolicBloodPressure,
    "hrv" to hrv
)

private fun MiniCheckupDetailData.toMap(): Map<String, Any?> = mapOf(
    "basePersonalInfo" to basePersonalInfo?.toMap(),
    "heartRate" to heartRate,
    "bloodOxygen" to bloodOxygen,
    "stress" to stress,
    "emotion" to emotion,
    "fatigue" to fatigue,
    "bloodGlucoseType" to bloodGlucoseType,
    "bloodGlucose" to bloodGlucose.toDouble(),
    "bodyTemperature" to bodyTemperature.toDouble(),
    "originalTemperature" to originalTemperature.toDouble(),
    "bpAirPump" to bpAirPump?.toMap(),
    "bpPhotoelectric" to bpPhotoelectric?.toMap(),
    "hrv" to hrv,
    "bloodComponent" to bloodComponent?.toMap(),
    "bodyComponent" to bodyComponent?.toMap(),
    "skinElectricity" to skinElectricity?.toMap()
)

private fun MiniCheckupBasePersonalInfo.toMap(): Map<String, Any?> = mapOf(
    "gender" to gender,
    "age" to age,
    "height" to height,
    "weight" to weight
)

private fun MiniCheckupBPAirPump.toMap(): Map<String, Any?> = mapOf(
    "systolicBloodPressure" to systolicBloodPressure,
    "diastolicBloodPressure" to diastolicBloodPressure
)

private fun MiniCheckupBPPhotoelectric.toMap(): Map<String, Any?> = mapOf(
    "systolicBloodPressure" to systolicBloodPressure,
    "diastolicBloodPressure" to diastolicBloodPressure
)

private fun MiniCheckupBloodComponent.toMap(): Map<String, Any?> = mapOf(
    "uricAcid" to uricAcid.toDouble(),
    "totalCholesterol" to tCHO.toDouble(),
    "triglyceride" to tAG.toDouble(),
    "hdl" to hDL.toDouble(),
    "ldl" to lDL.toDouble()
)

private fun MiniCheckupBodyComponent.toMap(): Map<String, Any?> = mapOf(
    "gender" to gender,
    "age" to age,
    "height" to height,
    "weight" to weight,
    // Kotlin keeps BMI/FFM uppercase when synthesizing properties from getBMI()/getFFM().
    "bmi" to BMI.toDouble(),
    "bodyFatRate" to bodyFatRate.toDouble(),
    "fatRate" to fatRate.toDouble(),
    "ffm" to FFM.toDouble(),
    "muscleRate" to muscleRate.toDouble(),
    "muscleMass" to muscleMass.toDouble(),
    "subcutaneousFat" to subcutaneousFat.toDouble(),
    "bodyWater" to bodyWater.toDouble(),
    "waterContent" to waterContent.toDouble(),
    "skeletalMuscleRate" to skeletalMuscleRate.toDouble(),
    "boneMass" to boneMass.toDouble(),
    "proteinProportion" to proteinProportion.toDouble(),
    "proteinMass" to proteinMass.toDouble(),
    "basalMetabolicRate" to basalMetabolicRate.toDouble()
)

private fun MiniCheckupSkinElectricity.toMap(): Map<String, Any?> = mapOf(
    "emotion" to emotion,
    "skinMoistureContent" to skinMoistureContent,
    "depressionRisk" to depressionRisk,
    "sympatheticActivity" to sympatheticActivity,
    "cortisolConcentration" to cortisolConcentration
)
