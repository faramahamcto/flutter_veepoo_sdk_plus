package site.shasmatic.flutter_veepoo_sdk.utils

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

// Shared by the Veepoo OriginDataReader and the YC backend so both produce the same daily/hourly shape.

internal fun aggregateDailyData(day: Int, records: List<Map<String, Any?>>): Map<String, Any?> {
    val calendar = Calendar.getInstance()
    calendar.add(Calendar.DAY_OF_YEAR, -day)
    val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
    val dateStr = dateFormat.format(calendar.time)

    val dayLabel = when (day) {
        0 -> "Today"
        1 -> "Yesterday"
        2 -> "2 Days Ago"
        else -> "$day Days Ago"
    }

    // Calculate aggregates for each category
    val heartRates = records.mapNotNull { it["heartRate"] as? Int }.filter { it > 0 }
    val systolics = records.mapNotNull { it["systolic"] as? Int }.filter { it > 0 }
    val diastolics = records.mapNotNull { it["diastolic"] as? Int }.filter { it > 0 }
    val temperatures = records.mapNotNull { (it["temperature"] as? Number)?.toDouble() }.filter { it > 0 }
    val oxygens = records.mapNotNull { it["bloodOxygen"] as? Int }.filter { it > 0 }
    val steps = records.mapNotNull { it["steps"] as? Int }
    val calories = records.mapNotNull { (it["calories"] as? Number)?.toDouble() }
    val distances = records.mapNotNull { (it["distance"] as? Number)?.toDouble() }
    val sports = records.mapNotNull { it["sportValue"] as? Int }.filter { it > 0 }
    val glucoses = records.mapNotNull { it["bloodGlucose"] as? Int }.filter { it > 0 }
    val respRates = records.mapNotNull { it["respirationRate"] as? Int }.filter { it > 0 }
    val ecgRates = records.mapNotNull { it["ecgHeartRate"] as? Int }.filter { it > 0 }
    // Blood Components
    val uricAcids = records.mapNotNull { (it["uricAcid"] as? Number)?.toDouble() }.filter { it > 0 }
    val cholesterols = records.mapNotNull { (it["totalCholesterol"] as? Number)?.toDouble() }.filter { it > 0 }
    val triglycerides = records.mapNotNull { (it["triglyceride"] as? Number)?.toDouble() }.filter { it > 0 }
    val hdls = records.mapNotNull { (it["hdl"] as? Number)?.toDouble() }.filter { it > 0 }
    val ldls = records.mapNotNull { (it["ldl"] as? Number)?.toDouble() }.filter { it > 0 }
    // HRV
    val hrvValues = records.mapNotNull { it["hrvValue"] as? Int }.filter { it > 0 }

    // Group by hour for hourly data
    val hourlyDataList = mutableListOf<Map<String, Any?>>()
    for (hour in 0..23) {
        val hourLabel = String.format("%02d:00", hour)
        val hourRecords = records.filter { record ->
            val time = record["time"] as? String
            time != null && time.startsWith(String.format("%02d:", hour))
        }

        if (hourRecords.isNotEmpty()) {
            val hourData = aggregateHourlyData(hour, hourLabel, hourRecords)
            hourlyDataList.add(hourData)
        }
    }

    return mapOf<String, Any?>(
        "date" to dateStr,
        "dayLabel" to dayLabel,
        // Heart Rate
        "avgHeartRate" to if (heartRates.isNotEmpty()) heartRates.average().toInt() else null,
        "maxHeartRate" to heartRates.maxOrNull(),
        "minHeartRate" to heartRates.minOrNull(),
        // Blood Pressure
        "avgSystolic" to if (systolics.isNotEmpty()) systolics.average().toInt() else null,
        "avgDiastolic" to if (diastolics.isNotEmpty()) diastolics.average().toInt() else null,
        "maxSystolic" to systolics.maxOrNull(),
        "minSystolic" to systolics.minOrNull(),
        // Temperature
        "avgTemperature" to if (temperatures.isNotEmpty()) temperatures.average() else null,
        "maxTemperature" to temperatures.maxOrNull(),
        "minTemperature" to temperatures.minOrNull(),
        // Blood Oxygen
        "avgBloodOxygen" to if (oxygens.isNotEmpty()) oxygens.average().toInt() else null,
        "minBloodOxygen" to oxygens.minOrNull(),
        // Steps & Activity
        "totalSteps" to steps.sum(),
        "totalCalories" to calories.sum(),
        "totalDistance" to distances.sum(),
        "avgSportValue" to if (sports.isNotEmpty()) sports.average().toInt() else null,
        // Blood Glucose
        "avgBloodGlucose" to if (glucoses.isNotEmpty()) glucoses.average().toInt() else null,
        // Respiration Rate
        "avgRespirationRate" to if (respRates.isNotEmpty()) respRates.average().toInt() else null,
        // ECG Heart Rate
        "avgEcgHeartRate" to if (ecgRates.isNotEmpty()) ecgRates.average().toInt() else null,
        // Blood Components
        "avgUricAcid" to if (uricAcids.isNotEmpty()) uricAcids.average() else null,
        "avgTotalCholesterol" to if (cholesterols.isNotEmpty()) cholesterols.average() else null,
        "avgTriglyceride" to if (triglycerides.isNotEmpty()) triglycerides.average() else null,
        "avgHdl" to if (hdls.isNotEmpty()) hdls.average() else null,
        "avgLdl" to if (ldls.isNotEmpty()) ldls.average() else null,
        // HRV
        "avgHrvValue" to if (hrvValues.isNotEmpty()) hrvValues.average().toInt() else null,
        "maxHrvValue" to hrvValues.maxOrNull(),
        "minHrvValue" to hrvValues.minOrNull(),
        // Hourly data
        "hourlyData" to hourlyDataList
    )
}

internal fun aggregateHourlyData(hour: Int, hourLabel: String, records: List<Map<String, Any?>>): Map<String, Any?> {
    val heartRates = records.mapNotNull { it["heartRate"] as? Int }.filter { it > 0 }
    val systolics = records.mapNotNull { it["systolic"] as? Int }.filter { it > 0 }
    val diastolics = records.mapNotNull { it["diastolic"] as? Int }.filter { it > 0 }
    val temperatures = records.mapNotNull { (it["temperature"] as? Number)?.toDouble() }.filter { it > 0 }
    val oxygens = records.mapNotNull { it["bloodOxygen"] as? Int }.filter { it > 0 }
    val steps = records.mapNotNull { it["steps"] as? Int }
    val calories = records.mapNotNull { (it["calories"] as? Number)?.toDouble() }
    val distances = records.mapNotNull { (it["distance"] as? Number)?.toDouble() }
    val sports = records.mapNotNull { it["sportValue"] as? Int }.filter { it > 0 }
    val glucoses = records.mapNotNull { it["bloodGlucose"] as? Int }.filter { it > 0 }
    val respRates = records.mapNotNull { it["respirationRate"] as? Int }.filter { it > 0 }
    // Blood Components
    val uricAcids = records.mapNotNull { (it["uricAcid"] as? Number)?.toDouble() }.filter { it > 0 }
    val cholesterols = records.mapNotNull { (it["totalCholesterol"] as? Number)?.toDouble() }.filter { it > 0 }
    val triglycerides = records.mapNotNull { (it["triglyceride"] as? Number)?.toDouble() }.filter { it > 0 }
    val hdls = records.mapNotNull { (it["hdl"] as? Number)?.toDouble() }.filter { it > 0 }
    val ldls = records.mapNotNull { (it["ldl"] as? Number)?.toDouble() }.filter { it > 0 }
    // HRV
    val hrvValues = records.mapNotNull { it["hrvValue"] as? Int }.filter { it > 0 }

    return mapOf<String, Any?>(
        "hour" to hour,
        "hourLabel" to hourLabel,
        // Heart Rate
        "avgHeartRate" to if (heartRates.isNotEmpty()) heartRates.average().toInt() else null,
        "maxHeartRate" to heartRates.maxOrNull(),
        "minHeartRate" to heartRates.minOrNull(),
        // Blood Pressure
        "avgSystolic" to if (systolics.isNotEmpty()) systolics.average().toInt() else null,
        "avgDiastolic" to if (diastolics.isNotEmpty()) diastolics.average().toInt() else null,
        // Temperature
        "avgTemperature" to if (temperatures.isNotEmpty()) temperatures.average() else null,
        // Blood Oxygen
        "avgBloodOxygen" to if (oxygens.isNotEmpty()) oxygens.average().toInt() else null,
        // Steps & Activity
        "steps" to steps.sum(),
        "calories" to calories.sum(),
        "distance" to distances.sum(),
        "avgSportValue" to if (sports.isNotEmpty()) sports.average().toInt() else null,
        // Blood Glucose
        "avgBloodGlucose" to if (glucoses.isNotEmpty()) glucoses.average().toInt() else null,
        // Respiration Rate
        "avgRespirationRate" to if (respRates.isNotEmpty()) respRates.average().toInt() else null,
        // Blood Components
        "avgUricAcid" to if (uricAcids.isNotEmpty()) uricAcids.average() else null,
        "avgTotalCholesterol" to if (cholesterols.isNotEmpty()) cholesterols.average() else null,
        "avgTriglyceride" to if (triglycerides.isNotEmpty()) triglycerides.average() else null,
        "avgHdl" to if (hdls.isNotEmpty()) hdls.average() else null,
        "avgLdl" to if (ldls.isNotEmpty()) ldls.average() else null,
        // HRV
        "avgHrvValue" to if (hrvValues.isNotEmpty()) hrvValues.average().toInt() else null,
        "maxHrvValue" to hrvValues.maxOrNull(),
        "minHrvValue" to hrvValues.minOrNull(),
        // Raw records
        "records" to records
    )
}

