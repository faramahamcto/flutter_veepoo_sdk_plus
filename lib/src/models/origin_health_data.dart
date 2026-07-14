part of '../../flutter_veepoo_sdk.dart';

/// Origin health data model representing 5-minute interval health data
class OriginHealthData extends Equatable {
  final String? date;
  final String? time;
  // Heart Rate
  final int? heartRate;
  // Blood Pressure
  final int? systolic;
  final int? diastolic;
  // Temperature
  final double? temperature;
  // Blood Oxygen
  final int? bloodOxygen;
  // Activity
  final int? steps;
  final double? calories;
  final double? distance;
  final int? sportValue;
  // Blood Glucose
  final int? bloodGlucose;
  // Respiration Rate
  final int? respirationRate;
  // ECG Heart Rate
  final int? ecgHeartRate;
  // Blood Components
  final double? uricAcid;           // μmol/L
  final double? totalCholesterol;   // mmol/L
  final double? triglyceride;       // mmol/L
  final double? hdl;                // mmol/L (High-density lipoprotein)
  final double? ldl;                // mmol/L (Low-density lipoprotein)
  // HRV (Heart Rate Variability)
  final int? hrvValue;              // HRV value in milliseconds
  // Raw device wear-detection code. The vendor doesn't document the exact value
  // mapping (e.g. worn/not-worn/uncertain) — exposed as-is for filtering.
  final int? wear;

  // ==================== Remaining raw fields ====================
  // Everything below is exposed as-is from the device; the vendor doesn't document
  // these beyond their names. Prefer the reduced fields above (bloodOxygen,
  // respirationRate, ecgHeartRate, heartRate) unless you specifically need the raw,
  // undivided per-minute detail.

  /// Raw dual-sensor temperature readings that [temperature] is derived from.
  final int? tempOne;
  final int? tempTwo;

  /// Calorie calculation type/version used by the device.
  final int? calcType;

  /// Baseline body temperature, distinct from [temperature].
  final double? baseTemperature;

  /// Hydration-tracking fields, on devices that support drink reminders/logging.
  final String? drinkPartOne;
  final String? drinkPartTwo;

  /// Raw wrist-gesture codes.
  final List<int>? gesture;

  /// Raw per-minute PPG readings within this 5-minute window (heartRate is derived
  /// from the first valid — non-sentinel — entry in this array).
  final List<int>? ppgValues;

  /// Raw per-minute ECG readings within this 5-minute window ([ecgHeartRate] is
  /// derived from the first valid entry in this array).
  final List<int>? ecgValues;

  /// Raw per-minute respiration readings within this 5-minute window
  /// ([respirationRate] is derived from the first valid entry in this array).
  final List<int>? respirationRateValues;

  /// Raw per-minute SpO2 readings within this 5-minute window ([bloodOxygen] is
  /// derived from the first valid entry in this array).
  final List<int>? oxygenValues;

  /// Raw sleep-stage codes for this window.
  final List<int>? sleepStates;

  /// Raw counts per sleep status for this window.
  final List<int>? sleepStatusQuantity;

  /// Raw sleep/activity codes for this window.
  final List<int>? sleepSports;

  /// Raw reset-marker content.
  final List<int>? resetTagContent;

  /// Raw sleep apnea detection results for this window.
  final List<int>? apneaResults;

  /// Raw hypoxia event timings for this window.
  final List<int>? hypoxiaTimes;

  /// Raw cardiac load/strain readings for this window.
  final List<int>? cardiacLoads;

  /// Raw per-minute hypoxia flags for this window.
  final List<int>? isHypoxias;

  /// Raw correction/adjustment flags for this window.
  final List<int>? corrects;

  /// Blood glucose risk level, as reported by the device (enum name, e.g. "NONE").
  final String? bloodGlucoseRiskLevel;

  /// Stress/pressure level reading.
  final int? pressure;

  /// Metabolic equivalent (MET) value.
  final double? met;

  const OriginHealthData({
    this.date,
    this.time,
    this.heartRate,
    this.systolic,
    this.diastolic,
    this.temperature,
    this.bloodOxygen,
    this.steps,
    this.calories,
    this.distance,
    this.sportValue,
    this.bloodGlucose,
    this.respirationRate,
    this.ecgHeartRate,
    this.uricAcid,
    this.totalCholesterol,
    this.triglyceride,
    this.hdl,
    this.ldl,
    this.hrvValue,
    this.wear,
    this.tempOne,
    this.tempTwo,
    this.calcType,
    this.baseTemperature,
    this.drinkPartOne,
    this.drinkPartTwo,
    this.gesture,
    this.ppgValues,
    this.ecgValues,
    this.respirationRateValues,
    this.oxygenValues,
    this.sleepStates,
    this.sleepStatusQuantity,
    this.sleepSports,
    this.resetTagContent,
    this.apneaResults,
    this.hypoxiaTimes,
    this.cardiacLoads,
    this.isHypoxias,
    this.corrects,
    this.bloodGlucoseRiskLevel,
    this.pressure,
    this.met,
  });

  factory OriginHealthData.fromMap(Map<String, dynamic> map) {
    List<int>? intList(String key) =>
        (map[key] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList();

    return OriginHealthData(
      date: map['date'] as String?,
      time: map['time'] as String?,
      heartRate: (map['heartRate'] as num?)?.toInt(),
      systolic: (map['systolic'] as num?)?.toInt(),
      diastolic: (map['diastolic'] as num?)?.toInt(),
      temperature: (map['temperature'] as num?)?.toDouble(),
      bloodOxygen: (map['bloodOxygen'] as num?)?.toInt(),
      steps: (map['steps'] as num?)?.toInt(),
      calories: (map['calories'] as num?)?.toDouble(),
      distance: (map['distance'] as num?)?.toDouble(),
      sportValue: (map['sportValue'] as num?)?.toInt(),
      bloodGlucose: (map['bloodGlucose'] as num?)?.toInt(),
      respirationRate: (map['respirationRate'] as num?)?.toInt(),
      ecgHeartRate: (map['ecgHeartRate'] as num?)?.toInt(),
      uricAcid: (map['uricAcid'] as num?)?.toDouble(),
      totalCholesterol: (map['totalCholesterol'] as num?)?.toDouble(),
      triglyceride: (map['triglyceride'] as num?)?.toDouble(),
      hdl: (map['hdl'] as num?)?.toDouble(),
      ldl: (map['ldl'] as num?)?.toDouble(),
      hrvValue: (map['hrvValue'] as num?)?.toInt(),
      wear: (map['wear'] as num?)?.toInt(),
      tempOne: (map['tempOne'] as num?)?.toInt(),
      tempTwo: (map['tempTwo'] as num?)?.toInt(),
      calcType: (map['calcType'] as num?)?.toInt(),
      baseTemperature: (map['baseTemperature'] as num?)?.toDouble(),
      drinkPartOne: map['drinkPartOne'] as String?,
      drinkPartTwo: map['drinkPartTwo'] as String?,
      gesture: intList('gesture'),
      ppgValues: intList('ppgValues'),
      ecgValues: intList('ecgValues'),
      respirationRateValues: intList('respirationRateValues'),
      oxygenValues: intList('oxygenValues'),
      sleepStates: intList('sleepStates'),
      sleepStatusQuantity: intList('sleepStatusQuantity'),
      sleepSports: intList('sleepSports'),
      resetTagContent: intList('resetTagContent'),
      apneaResults: intList('apneaResults'),
      hypoxiaTimes: intList('hypoxiaTimes'),
      cardiacLoads: intList('cardiacLoads'),
      isHypoxias: intList('isHypoxias'),
      corrects: intList('corrects'),
      bloodGlucoseRiskLevel: map['bloodGlucoseRiskLevel'] as String?,
      pressure: (map['pressure'] as num?)?.toInt(),
      met: (map['met'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'time': time,
      'heartRate': heartRate,
      'systolic': systolic,
      'diastolic': diastolic,
      'temperature': temperature,
      'bloodOxygen': bloodOxygen,
      'steps': steps,
      'calories': calories,
      'distance': distance,
      'sportValue': sportValue,
      'bloodGlucose': bloodGlucose,
      'respirationRate': respirationRate,
      'ecgHeartRate': ecgHeartRate,
      'uricAcid': uricAcid,
      'totalCholesterol': totalCholesterol,
      'triglyceride': triglyceride,
      'hdl': hdl,
      'ldl': ldl,
      'hrvValue': hrvValue,
      'wear': wear,
      'tempOne': tempOne,
      'tempTwo': tempTwo,
      'calcType': calcType,
      'baseTemperature': baseTemperature,
      'drinkPartOne': drinkPartOne,
      'drinkPartTwo': drinkPartTwo,
      'gesture': gesture,
      'ppgValues': ppgValues,
      'ecgValues': ecgValues,
      'respirationRateValues': respirationRateValues,
      'oxygenValues': oxygenValues,
      'sleepStates': sleepStates,
      'sleepStatusQuantity': sleepStatusQuantity,
      'sleepSports': sleepSports,
      'resetTagContent': resetTagContent,
      'apneaResults': apneaResults,
      'hypoxiaTimes': hypoxiaTimes,
      'cardiacLoads': cardiacLoads,
      'isHypoxias': isHypoxias,
      'corrects': corrects,
      'bloodGlucoseRiskLevel': bloodGlucoseRiskLevel,
      'pressure': pressure,
      'met': met,
    };
  }

  @override
  List<Object?> get props => [
        date, time, heartRate, systolic, diastolic, temperature,
        bloodOxygen, steps, calories, distance, sportValue,
        bloodGlucose, respirationRate, ecgHeartRate,
        uricAcid, totalCholesterol, triglyceride, hdl, ldl,
        hrvValue, wear,
        tempOne, tempTwo, calcType, baseTemperature, drinkPartOne, drinkPartTwo,
        gesture, ppgValues, ecgValues, respirationRateValues, oxygenValues,
        sleepStates, sleepStatusQuantity, sleepSports, resetTagContent,
        apneaResults, hypoxiaTimes, cardiacLoads, isHypoxias, corrects,
        bloodGlucoseRiskLevel, pressure, met,
      ];
}

/// Daily health data summary
class DailyHealthData extends Equatable {
  final String? date;
  final String? dayLabel;
  // Heart Rate
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int? minHeartRate;
  // Blood Pressure
  final int? avgSystolic;
  final int? avgDiastolic;
  final int? maxSystolic;
  final int? minSystolic;
  // Temperature
  final double? avgTemperature;
  final double? maxTemperature;
  final double? minTemperature;
  // Blood Oxygen
  final int? avgBloodOxygen;
  final int? minBloodOxygen;
  // Activity
  final int? totalSteps;
  final double? totalCalories;
  final double? totalDistance;
  final int? avgSportValue;
  // Blood Glucose
  final int? avgBloodGlucose;
  // Respiration Rate
  final int? avgRespirationRate;
  // ECG Heart Rate
  final int? avgEcgHeartRate;
  // Blood Components
  final double? avgUricAcid;           // μmol/L
  final double? avgTotalCholesterol;   // mmol/L
  final double? avgTriglyceride;       // mmol/L
  final double? avgHdl;                // mmol/L
  final double? avgLdl;                // mmol/L
  // HRV (Heart Rate Variability)
  final int? avgHrvValue;              // Average HRV in milliseconds
  final int? maxHrvValue;              // Maximum HRV in milliseconds
  final int? minHrvValue;              // Minimum HRV in milliseconds
  // Hourly data
  final List<HourlyHealthData>? hourlyData;

  const DailyHealthData({
    this.date,
    this.dayLabel,
    this.avgHeartRate,
    this.maxHeartRate,
    this.minHeartRate,
    this.avgSystolic,
    this.avgDiastolic,
    this.maxSystolic,
    this.minSystolic,
    this.avgTemperature,
    this.maxTemperature,
    this.minTemperature,
    this.avgBloodOxygen,
    this.minBloodOxygen,
    this.totalSteps,
    this.totalCalories,
    this.totalDistance,
    this.avgSportValue,
    this.avgBloodGlucose,
    this.avgRespirationRate,
    this.avgEcgHeartRate,
    this.avgUricAcid,
    this.avgTotalCholesterol,
    this.avgTriglyceride,
    this.avgHdl,
    this.avgLdl,
    this.avgHrvValue,
    this.maxHrvValue,
    this.minHrvValue,
    this.hourlyData,
  });

  factory DailyHealthData.fromMap(Map<String, dynamic> map) {
    List<HourlyHealthData>? hourlyData;
    if (map['hourlyData'] != null) {
      hourlyData = (map['hourlyData'] as List)
          .map((e) => HourlyHealthData.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    return DailyHealthData(
      date: map['date'] as String?,
      dayLabel: map['dayLabel'] as String?,
      avgHeartRate: (map['avgHeartRate'] as num?)?.toInt(),
      maxHeartRate: (map['maxHeartRate'] as num?)?.toInt(),
      minHeartRate: (map['minHeartRate'] as num?)?.toInt(),
      avgSystolic: (map['avgSystolic'] as num?)?.toInt(),
      avgDiastolic: (map['avgDiastolic'] as num?)?.toInt(),
      maxSystolic: (map['maxSystolic'] as num?)?.toInt(),
      minSystolic: (map['minSystolic'] as num?)?.toInt(),
      avgTemperature: (map['avgTemperature'] as num?)?.toDouble(),
      maxTemperature: (map['maxTemperature'] as num?)?.toDouble(),
      minTemperature: (map['minTemperature'] as num?)?.toDouble(),
      avgBloodOxygen: (map['avgBloodOxygen'] as num?)?.toInt(),
      minBloodOxygen: (map['minBloodOxygen'] as num?)?.toInt(),
      totalSteps: (map['totalSteps'] as num?)?.toInt(),
      totalCalories: (map['totalCalories'] as num?)?.toDouble(),
      totalDistance: (map['totalDistance'] as num?)?.toDouble(),
      avgSportValue: (map['avgSportValue'] as num?)?.toInt(),
      avgBloodGlucose: (map['avgBloodGlucose'] as num?)?.toInt(),
      avgRespirationRate: (map['avgRespirationRate'] as num?)?.toInt(),
      avgEcgHeartRate: (map['avgEcgHeartRate'] as num?)?.toInt(),
      avgUricAcid: (map['avgUricAcid'] as num?)?.toDouble(),
      avgTotalCholesterol: (map['avgTotalCholesterol'] as num?)?.toDouble(),
      avgTriglyceride: (map['avgTriglyceride'] as num?)?.toDouble(),
      avgHdl: (map['avgHdl'] as num?)?.toDouble(),
      avgLdl: (map['avgLdl'] as num?)?.toDouble(),
      avgHrvValue: (map['avgHrvValue'] as num?)?.toInt(),
      maxHrvValue: (map['maxHrvValue'] as num?)?.toInt(),
      minHrvValue: (map['minHrvValue'] as num?)?.toInt(),
      hourlyData: hourlyData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'dayLabel': dayLabel,
      'avgHeartRate': avgHeartRate,
      'maxHeartRate': maxHeartRate,
      'minHeartRate': minHeartRate,
      'avgSystolic': avgSystolic,
      'avgDiastolic': avgDiastolic,
      'maxSystolic': maxSystolic,
      'minSystolic': minSystolic,
      'avgTemperature': avgTemperature,
      'maxTemperature': maxTemperature,
      'minTemperature': minTemperature,
      'avgBloodOxygen': avgBloodOxygen,
      'minBloodOxygen': minBloodOxygen,
      'totalSteps': totalSteps,
      'totalCalories': totalCalories,
      'totalDistance': totalDistance,
      'avgSportValue': avgSportValue,
      'avgBloodGlucose': avgBloodGlucose,
      'avgRespirationRate': avgRespirationRate,
      'avgEcgHeartRate': avgEcgHeartRate,
      'avgUricAcid': avgUricAcid,
      'avgTotalCholesterol': avgTotalCholesterol,
      'avgTriglyceride': avgTriglyceride,
      'avgHdl': avgHdl,
      'avgLdl': avgLdl,
      'avgHrvValue': avgHrvValue,
      'maxHrvValue': maxHrvValue,
      'minHrvValue': minHrvValue,
      'hourlyData': hourlyData?.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        date, dayLabel, avgHeartRate, maxHeartRate, minHeartRate,
        avgSystolic, avgDiastolic, maxSystolic, minSystolic,
        avgTemperature, maxTemperature, minTemperature,
        avgBloodOxygen, minBloodOxygen,
        totalSteps, totalCalories, totalDistance, avgSportValue,
        avgBloodGlucose, avgRespirationRate, avgEcgHeartRate,
        avgUricAcid, avgTotalCholesterol, avgTriglyceride, avgHdl, avgLdl,
        avgHrvValue, maxHrvValue, minHrvValue,
        hourlyData,
      ];
}

/// Hourly health data
class HourlyHealthData extends Equatable {
  final int? hour;
  final String? hourLabel;
  // Heart Rate
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int? minHeartRate;
  // Blood Pressure
  final int? avgSystolic;
  final int? avgDiastolic;
  // Temperature
  final double? avgTemperature;
  // Blood Oxygen
  final int? avgBloodOxygen;
  // Activity
  final int? steps;
  final double? calories;
  final double? distance;
  final int? avgSportValue;
  // Blood Glucose
  final int? avgBloodGlucose;
  // Respiration Rate
  final int? avgRespirationRate;
  // Blood Components
  final double? avgUricAcid;           // μmol/L
  final double? avgTotalCholesterol;   // mmol/L
  final double? avgTriglyceride;       // mmol/L
  final double? avgHdl;                // mmol/L
  final double? avgLdl;                // mmol/L
  // HRV (Heart Rate Variability)
  final int? avgHrvValue;              // Average HRV in milliseconds
  final int? maxHrvValue;              // Maximum HRV in milliseconds
  final int? minHrvValue;              // Minimum HRV in milliseconds
  // Raw records
  final List<OriginHealthData>? records;

  const HourlyHealthData({
    this.hour,
    this.hourLabel,
    this.avgHeartRate,
    this.maxHeartRate,
    this.minHeartRate,
    this.avgSystolic,
    this.avgDiastolic,
    this.avgTemperature,
    this.avgBloodOxygen,
    this.steps,
    this.calories,
    this.distance,
    this.avgSportValue,
    this.avgBloodGlucose,
    this.avgRespirationRate,
    this.avgUricAcid,
    this.avgTotalCholesterol,
    this.avgTriglyceride,
    this.avgHdl,
    this.avgLdl,
    this.avgHrvValue,
    this.maxHrvValue,
    this.minHrvValue,
    this.records,
  });

  factory HourlyHealthData.fromMap(Map<String, dynamic> map) {
    List<OriginHealthData>? records;
    if (map['records'] != null) {
      records = (map['records'] as List)
          .map((e) => OriginHealthData.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    return HourlyHealthData(
      hour: (map['hour'] as num?)?.toInt(),
      hourLabel: map['hourLabel'] as String?,
      avgHeartRate: (map['avgHeartRate'] as num?)?.toInt(),
      maxHeartRate: (map['maxHeartRate'] as num?)?.toInt(),
      minHeartRate: (map['minHeartRate'] as num?)?.toInt(),
      avgSystolic: (map['avgSystolic'] as num?)?.toInt(),
      avgDiastolic: (map['avgDiastolic'] as num?)?.toInt(),
      avgTemperature: (map['avgTemperature'] as num?)?.toDouble(),
      avgBloodOxygen: (map['avgBloodOxygen'] as num?)?.toInt(),
      steps: (map['steps'] as num?)?.toInt(),
      calories: (map['calories'] as num?)?.toDouble(),
      distance: (map['distance'] as num?)?.toDouble(),
      avgSportValue: (map['avgSportValue'] as num?)?.toInt(),
      avgBloodGlucose: (map['avgBloodGlucose'] as num?)?.toInt(),
      avgRespirationRate: (map['avgRespirationRate'] as num?)?.toInt(),
      avgUricAcid: (map['avgUricAcid'] as num?)?.toDouble(),
      avgTotalCholesterol: (map['avgTotalCholesterol'] as num?)?.toDouble(),
      avgTriglyceride: (map['avgTriglyceride'] as num?)?.toDouble(),
      avgHdl: (map['avgHdl'] as num?)?.toDouble(),
      avgLdl: (map['avgLdl'] as num?)?.toDouble(),
      avgHrvValue: (map['avgHrvValue'] as num?)?.toInt(),
      maxHrvValue: (map['maxHrvValue'] as num?)?.toInt(),
      minHrvValue: (map['minHrvValue'] as num?)?.toInt(),
      records: records,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'hourLabel': hourLabel,
      'avgHeartRate': avgHeartRate,
      'maxHeartRate': maxHeartRate,
      'minHeartRate': minHeartRate,
      'avgSystolic': avgSystolic,
      'avgDiastolic': avgDiastolic,
      'avgTemperature': avgTemperature,
      'avgBloodOxygen': avgBloodOxygen,
      'steps': steps,
      'calories': calories,
      'distance': distance,
      'avgSportValue': avgSportValue,
      'avgBloodGlucose': avgBloodGlucose,
      'avgRespirationRate': avgRespirationRate,
      'avgUricAcid': avgUricAcid,
      'avgTotalCholesterol': avgTotalCholesterol,
      'avgTriglyceride': avgTriglyceride,
      'avgHdl': avgHdl,
      'avgLdl': avgLdl,
      'avgHrvValue': avgHrvValue,
      'maxHrvValue': maxHrvValue,
      'minHrvValue': minHrvValue,
      'records': records?.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        hour, hourLabel, avgHeartRate, maxHeartRate, minHeartRate,
        avgSystolic, avgDiastolic, avgTemperature, avgBloodOxygen,
        steps, calories, distance, avgSportValue,
        avgBloodGlucose, avgRespirationRate,
        avgUricAcid, avgTotalCholesterol, avgTriglyceride, avgHdl, avgLdl,
        avgHrvValue, maxHrvValue, minHrvValue,
        records,
      ];
}

/// Progress data for origin health data reading
class OriginDataProgress extends Equatable {
  /// Progress value from 0.0 to 1.0
  final double? progress;
  /// Current day being read (0=today, 1=yesterday, 2=2 days ago)
  final int? day;
  /// Label for the current day
  final String? dayLabel;
  /// Total number of days being read
  final int? totalDays;

  const OriginDataProgress({
    this.progress,
    this.day,
    this.dayLabel,
    this.totalDays,
  });

  factory OriginDataProgress.fromMap(Map<String, dynamic> map) {
    return OriginDataProgress(
      progress: (map['progress'] as num?)?.toDouble(),
      day: (map['day'] as num?)?.toInt(),
      dayLabel: map['dayLabel'] as String?,
      totalDays: (map['totalDays'] as num?)?.toInt(),
    );
  }

  /// Returns progress as percentage (0-100)
  int get progressPercent => ((progress ?? 0) * 100).round();

  @override
  List<Object?> get props => [progress, day, dayLabel, totalDays];
}
