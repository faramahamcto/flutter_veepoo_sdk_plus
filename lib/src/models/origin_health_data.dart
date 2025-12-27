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
  });

  factory OriginHealthData.fromMap(Map<String, dynamic> map) {
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
    };
  }

  @override
  List<Object?> get props => [
        date, time, heartRate, systolic, diastolic, temperature,
        bloodOxygen, steps, calories, distance, sportValue,
        bloodGlucose, respirationRate, ecgHeartRate,
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
        avgBloodGlucose, avgRespirationRate, avgEcgHeartRate, hourlyData,
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
      'records': records?.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        hour, hourLabel, avgHeartRate, maxHeartRate, minHeartRate,
        avgSystolic, avgDiastolic, avgTemperature, avgBloodOxygen,
        steps, calories, distance, avgSportValue,
        avgBloodGlucose, avgRespirationRate, records,
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
