part of '../../flutter_veepoo_sdk.dart';

/// Origin health data model representing 5-minute interval health data
/// from the Veepoo device.
class OriginHealthData extends Equatable {
  /// Date of the record (format: YYYY-MM-DD)
  final String? date;

  /// Time of the record (format: HH:mm)
  final String? time;

  /// Heart rate value (30-200 bpm)
  final int? heartRate;

  /// Step count for this 5-minute interval
  final int? steps;

  /// Systolic blood pressure (mmHg)
  final int? systolic;

  /// Diastolic blood pressure (mmHg)
  final int? diastolic;

  /// Temperature value in Celsius
  final double? temperature;

  /// Calories burned
  final double? calories;

  /// Distance in kilometers
  final double? distance;

  /// Sport/exercise intensity value (0-65536)
  final int? sportValue;

  /// Blood oxygen percentage
  final int? bloodOxygen;

  const OriginHealthData({
    this.date,
    this.time,
    this.heartRate,
    this.steps,
    this.systolic,
    this.diastolic,
    this.temperature,
    this.calories,
    this.distance,
    this.sportValue,
    this.bloodOxygen,
  });

  factory OriginHealthData.fromMap(Map<String, dynamic> map) {
    return OriginHealthData(
      date: map['date'] as String?,
      time: map['time'] as String?,
      heartRate: map['heartRate'] as int?,
      steps: map['steps'] as int?,
      systolic: map['systolic'] as int?,
      diastolic: map['diastolic'] as int?,
      temperature: (map['temperature'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toDouble(),
      distance: (map['distance'] as num?)?.toDouble(),
      sportValue: map['sportValue'] as int?,
      bloodOxygen: map['bloodOxygen'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'time': time,
      'heartRate': heartRate,
      'steps': steps,
      'systolic': systolic,
      'diastolic': diastolic,
      'temperature': temperature,
      'calories': calories,
      'distance': distance,
      'sportValue': sportValue,
      'bloodOxygen': bloodOxygen,
    };
  }

  @override
  List<Object?> get props => [
        date,
        time,
        heartRate,
        steps,
        systolic,
        diastolic,
        temperature,
        calories,
        distance,
        sportValue,
        bloodOxygen,
      ];
}

/// Daily health data summary containing aggregated data for a day
class DailyHealthData extends Equatable {
  /// Date of the data (format: YYYY-MM-DD)
  final String? date;

  /// Day label (Today, Yesterday, 2 Days Ago)
  final String? dayLabel;

  /// Total steps for the day
  final int? totalSteps;

  /// Average heart rate for the day
  final int? avgHeartRate;

  /// Maximum heart rate for the day
  final int? maxHeartRate;

  /// Minimum heart rate for the day (non-zero values)
  final int? minHeartRate;

  /// Average systolic blood pressure
  final int? avgSystolic;

  /// Average diastolic blood pressure
  final int? avgDiastolic;

  /// Total calories burned
  final double? totalCalories;

  /// Total distance in kilometers
  final double? totalDistance;

  /// Average blood oxygen percentage
  final int? avgBloodOxygen;

  /// List of hourly health data
  final List<HourlyHealthData>? hourlyData;

  const DailyHealthData({
    this.date,
    this.dayLabel,
    this.totalSteps,
    this.avgHeartRate,
    this.maxHeartRate,
    this.minHeartRate,
    this.avgSystolic,
    this.avgDiastolic,
    this.totalCalories,
    this.totalDistance,
    this.avgBloodOxygen,
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
      totalSteps: map['totalSteps'] as int?,
      avgHeartRate: map['avgHeartRate'] as int?,
      maxHeartRate: map['maxHeartRate'] as int?,
      minHeartRate: map['minHeartRate'] as int?,
      avgSystolic: map['avgSystolic'] as int?,
      avgDiastolic: map['avgDiastolic'] as int?,
      totalCalories: (map['totalCalories'] as num?)?.toDouble(),
      totalDistance: (map['totalDistance'] as num?)?.toDouble(),
      avgBloodOxygen: map['avgBloodOxygen'] as int?,
      hourlyData: hourlyData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'dayLabel': dayLabel,
      'totalSteps': totalSteps,
      'avgHeartRate': avgHeartRate,
      'maxHeartRate': maxHeartRate,
      'minHeartRate': minHeartRate,
      'avgSystolic': avgSystolic,
      'avgDiastolic': avgDiastolic,
      'totalCalories': totalCalories,
      'totalDistance': totalDistance,
      'avgBloodOxygen': avgBloodOxygen,
      'hourlyData': hourlyData?.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        date,
        dayLabel,
        totalSteps,
        avgHeartRate,
        maxHeartRate,
        minHeartRate,
        avgSystolic,
        avgDiastolic,
        totalCalories,
        totalDistance,
        avgBloodOxygen,
        hourlyData,
      ];
}

/// Hourly health data containing aggregated data for one hour
class HourlyHealthData extends Equatable {
  /// Hour of the day (0-23)
  final int? hour;

  /// Formatted hour label (e.g., "09:00", "14:00")
  final String? hourLabel;

  /// Steps for this hour
  final int? steps;

  /// Average heart rate for this hour
  final int? avgHeartRate;

  /// Maximum heart rate for this hour
  final int? maxHeartRate;

  /// Minimum heart rate for this hour (non-zero)
  final int? minHeartRate;

  /// Average systolic blood pressure for this hour
  final int? avgSystolic;

  /// Average diastolic blood pressure for this hour
  final int? avgDiastolic;

  /// Calories burned in this hour
  final double? calories;

  /// Distance in this hour
  final double? distance;

  /// Average blood oxygen for this hour
  final int? avgBloodOxygen;

  /// List of 5-minute interval data for this hour
  final List<OriginHealthData>? records;

  const HourlyHealthData({
    this.hour,
    this.hourLabel,
    this.steps,
    this.avgHeartRate,
    this.maxHeartRate,
    this.minHeartRate,
    this.avgSystolic,
    this.avgDiastolic,
    this.calories,
    this.distance,
    this.avgBloodOxygen,
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
      hour: map['hour'] as int?,
      hourLabel: map['hourLabel'] as String?,
      steps: map['steps'] as int?,
      avgHeartRate: map['avgHeartRate'] as int?,
      maxHeartRate: map['maxHeartRate'] as int?,
      minHeartRate: map['minHeartRate'] as int?,
      avgSystolic: map['avgSystolic'] as int?,
      avgDiastolic: map['avgDiastolic'] as int?,
      calories: (map['calories'] as num?)?.toDouble(),
      distance: (map['distance'] as num?)?.toDouble(),
      avgBloodOxygen: map['avgBloodOxygen'] as int?,
      records: records,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'hourLabel': hourLabel,
      'steps': steps,
      'avgHeartRate': avgHeartRate,
      'maxHeartRate': maxHeartRate,
      'minHeartRate': minHeartRate,
      'avgSystolic': avgSystolic,
      'avgDiastolic': avgDiastolic,
      'calories': calories,
      'distance': distance,
      'avgBloodOxygen': avgBloodOxygen,
      'records': records?.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        hour,
        hourLabel,
        steps,
        avgHeartRate,
        maxHeartRate,
        minHeartRate,
        avgSystolic,
        avgDiastolic,
        calories,
        distance,
        avgBloodOxygen,
        records,
      ];
}
