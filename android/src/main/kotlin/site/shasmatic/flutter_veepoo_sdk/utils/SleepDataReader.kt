package site.shasmatic.flutter_veepoo_sdk.utils

import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.data.ISleepDataListener
import com.veepoo.protocol.model.datas.SleepData
import site.shasmatic.flutter_veepoo_sdk.VPLogger
import site.shasmatic.flutter_veepoo_sdk.VPWriteResponse
import site.shasmatic.flutter_veepoo_sdk.exceptions.VPException
import java.lang.reflect.InvocationTargetException

/**
 * Utility class for reading sleep data from the device.
 *
 * @constructor Creates a new [SleepDataReader] instance with VPOperateManager.
 * @param vpManager The [VPOperateManager] used to control device operations.
 */
class SleepDataReader(
    private val vpManager: VPOperateManager,
) {

    private val writeResponse: VPWriteResponse = VPWriteResponse()
    private var currentSleepData: SleepData? = null

    /**
     * Reads sleep data from the device.
     *
     * @return Map containing sleep data
     */
    fun readSleepData(): Map<String, Any?>? {
        executeSleepOperation {
            vpManager.readSleepData(writeResponse, sleepDataListener)
        }

        // Wait a bit for data to be received
        Thread.sleep(1000)

        return currentSleepData?.let { sleepData ->
            mapOf<String, Any?>(
                "totalSleepMinutes" to sleepData.totalSleepTime,
                "deepSleepMinutes" to sleepData.deepSleepTime,
                "lightSleepMinutes" to sleepData.lightSleepTime,
                "awakeMinutes" to sleepData.awakeTime,
                "sleepQuality" to sleepData.sleepQuality,
                "sleepStartTime" to sleepData.sleepStartTime,
                "sleepEndTime" to sleepData.sleepEndTime,
                "sleepCurve" to sleepData.sleepCurve
            )
        }
    }

    /**
     * Reads sleep history for a date range.
     *
     * @param startTimestamp Start date in milliseconds
     * @param endTimestamp End date in milliseconds
     * @return List of sleep data maps
     */
    fun readSleepHistory(startTimestamp: Long, endTimestamp: Long): List<Map<String, Any?>> {
        val sleepHistory = mutableListOf<Map<String, Any?>>()

        executeSleepOperation {
            vpManager.readSleepDataByDate(
                writeResponse,
                startTimestamp,
                endTimestamp
            ) { sleepDataList ->
                sleepDataList?.forEach { sleepData ->
                    sleepHistory.add(
                        mapOf(
                            "totalSleepMinutes" to sleepData.totalSleepTime,
                            "deepSleepMinutes" to sleepData.deepSleepTime,
                            "lightSleepMinutes" to sleepData.lightSleepTime,
                            "awakeMinutes" to sleepData.awakeTime,
                            "sleepQuality" to sleepData.sleepQuality,
                            "sleepStartTime" to sleepData.sleepStartTime,
                            "sleepEndTime" to sleepData.sleepEndTime,
                            "sleepCurve" to sleepData.sleepCurve
                        )
                    )
                }
            }
        }

        // Wait for data
        Thread.sleep(2000)

        return sleepHistory
    }

    private fun executeSleepOperation(operation: () -> Unit) {
        try {
            operation()
        } catch (e: InvocationTargetException) {
            throw VPException("Error during sleep operation: ${e.targetException.message}", e.targetException.cause)
        } catch (e: Exception) {
            throw VPException("Error during sleep operation: ${e.message}", e.cause)
        }
    }

    private val sleepDataListener = ISleepDataListener { sleepData ->
        currentSleepData = sleepData
        VPLogger.d("Sleep data received: $sleepData")
    }
}
