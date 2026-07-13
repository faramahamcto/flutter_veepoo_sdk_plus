part of '../../flutter_veepoo_sdk.dart';

/// The kind of event carried by a [MiniCheckupEvent].
enum MiniCheckupEventType {
  /// Test is in progress; see [MiniCheckupEvent.progress].
  progress,

  /// The session was stopped (in response to [VeepooSDK.stopMiniCheckup]).
  stopped,

  /// The test failed; see [MiniCheckupEvent.errorCode].
  error,

  /// The basic summary result is ready; see [MiniCheckupEvent.result].
  result,

  /// The detailed report is ready; see [MiniCheckupEvent.detail].
  detail,

  /// Unrecognized event type.
  unknown,
}

/// Reason a Mini Checkup test failed.
enum MiniCheckupTestErrorCode {
  functionNotSupport,
  testCompleteNoResult,
  deviceBusy,
  lowPower,
  wearingAbnormality,
  ecgLeadDetachment,
  unknown;

  static MiniCheckupTestErrorCode fromCode(String? code) {
    switch (code) {
      case 'FUNCTION_NOT_SUPPORT':
        return MiniCheckupTestErrorCode.functionNotSupport;
      case 'TEST_COMPLETE_NO_RESULT':
        return MiniCheckupTestErrorCode.testCompleteNoResult;
      case 'DEVICE_BUSY':
        return MiniCheckupTestErrorCode.deviceBusy;
      case 'LOW_POWER':
        return MiniCheckupTestErrorCode.lowPower;
      case 'WEARING_ABNORMALITY':
        return MiniCheckupTestErrorCode.wearingAbnormality;
      case 'ECG_LEAD_DETACHMENT':
        return MiniCheckupTestErrorCode.ecgLeadDetachment;
      default:
        return MiniCheckupTestErrorCode.unknown;
    }
  }
}

/// A single event from an ongoing [VeepooSDK.miniCheckup] session.
///
/// Exactly one of [progress], [errorCode], [result] or [detail] is populated,
/// matching [type].
class MiniCheckupEvent extends Equatable {
  /// The kind of event this is.
  final MiniCheckupEventType type;

  /// Test progress, 0-100. Populated when [type] is [MiniCheckupEventType.progress].
  final int? progress;

  /// Failure reason. Populated when [type] is [MiniCheckupEventType.error].
  final MiniCheckupTestErrorCode? errorCode;

  /// Basic summary result. Populated when [type] is [MiniCheckupEventType.result].
  final MiniCheckupResult? result;

  /// Full detailed report. Populated when [type] is [MiniCheckupEventType.detail].
  final MiniCheckupDetail? detail;

  /// Timestamp when this event was emitted.
  final int? timestamp;

  const MiniCheckupEvent({
    required this.type,
    this.progress,
    this.errorCode,
    this.result,
    this.detail,
    this.timestamp,
  });

  factory MiniCheckupEvent.fromMap(Map<String, dynamic> map) {
    final typeString = map['type'] as String?;
    final type = MiniCheckupEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeString?.toLowerCase(),
      orElse: () => MiniCheckupEventType.unknown,
    );

    return MiniCheckupEvent(
      type: type,
      progress: (map['progress'] as num?)?.toInt(),
      errorCode: map['errorCode'] != null
          ? MiniCheckupTestErrorCode.fromCode(map['errorCode'] as String?)
          : null,
      result: map['result'] != null
          ? MiniCheckupResult.fromMap(
              Map<String, dynamic>.from(map['result'] as Map))
          : null,
      detail: map['detail'] != null
          ? MiniCheckupDetail.fromMap(
              Map<String, dynamic>.from(map['detail'] as Map))
          : null,
      timestamp: (map['timestamp'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props =>
      [type, progress, errorCode, result, detail, timestamp];
}

/// Basic Mini Checkup summary result.
class MiniCheckupResult extends Equatable {
  final int? heartRate;
  final int? bloodOxygen;
  final int? stress;
  final int? emotion;
  final int? fatigue;
  final double? bloodGlucose;
  final double? bodyTemperature;
  final int? systolicBloodPressure;
  final int? diastolicBloodPressure;
  final int? hrv;

  const MiniCheckupResult({
    this.heartRate,
    this.bloodOxygen,
    this.stress,
    this.emotion,
    this.fatigue,
    this.bloodGlucose,
    this.bodyTemperature,
    this.systolicBloodPressure,
    this.diastolicBloodPressure,
    this.hrv,
  });

  factory MiniCheckupResult.fromMap(Map<String, dynamic> map) {
    return MiniCheckupResult(
      heartRate: (map['heartRate'] as num?)?.toInt(),
      bloodOxygen: (map['bloodOxygen'] as num?)?.toInt(),
      stress: (map['stress'] as num?)?.toInt(),
      emotion: (map['emotion'] as num?)?.toInt(),
      fatigue: (map['fatigue'] as num?)?.toInt(),
      bloodGlucose: (map['bloodGlucose'] as num?)?.toDouble(),
      bodyTemperature: (map['bodyTemperature'] as num?)?.toDouble(),
      systolicBloodPressure: (map['systolicBloodPressure'] as num?)?.toInt(),
      diastolicBloodPressure:
          (map['diastolicBloodPressure'] as num?)?.toInt(),
      hrv: (map['hrv'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
        heartRate,
        bloodOxygen,
        stress,
        emotion,
        fatigue,
        bloodGlucose,
        bodyTemperature,
        systolicBloodPressure,
        diastolicBloodPressure,
        hrv,
      ];
}

/// Personal info the device used for a Mini Checkup report.
class MiniCheckupPersonalInfo extends Equatable {
  final int? gender;
  final int? age;
  final int? height;
  final int? weight;

  const MiniCheckupPersonalInfo({
    this.gender,
    this.age,
    this.height,
    this.weight,
  });

  factory MiniCheckupPersonalInfo.fromMap(Map<String, dynamic> map) {
    return MiniCheckupPersonalInfo(
      gender: (map['gender'] as num?)?.toInt(),
      age: (map['age'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      weight: (map['weight'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [gender, age, height, weight];
}

/// Blood pressure reading taken via the air-pump (cuff) method during a Mini Checkup.
class MiniCheckupBloodPressure extends Equatable {
  final int? systolicBloodPressure;
  final int? diastolicBloodPressure;

  const MiniCheckupBloodPressure({
    this.systolicBloodPressure,
    this.diastolicBloodPressure,
  });

  factory MiniCheckupBloodPressure.fromMap(Map<String, dynamic> map) {
    return MiniCheckupBloodPressure(
      systolicBloodPressure: (map['systolicBloodPressure'] as num?)?.toInt(),
      diastolicBloodPressure:
          (map['diastolicBloodPressure'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [systolicBloodPressure, diastolicBloodPressure];
}

/// Blood composition reading taken during a Mini Checkup.
class MiniCheckupBloodComponent extends Equatable {
  final double? uricAcid;
  final double? totalCholesterol;
  final double? triglyceride;
  final double? hdl;
  final double? ldl;

  const MiniCheckupBloodComponent({
    this.uricAcid,
    this.totalCholesterol,
    this.triglyceride,
    this.hdl,
    this.ldl,
  });

  factory MiniCheckupBloodComponent.fromMap(Map<String, dynamic> map) {
    return MiniCheckupBloodComponent(
      uricAcid: (map['uricAcid'] as num?)?.toDouble(),
      totalCholesterol: (map['totalCholesterol'] as num?)?.toDouble(),
      triglyceride: (map['triglyceride'] as num?)?.toDouble(),
      hdl: (map['hdl'] as num?)?.toDouble(),
      ldl: (map['ldl'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [uricAcid, totalCholesterol, triglyceride, hdl, ldl];
}

/// Body composition reading taken during a Mini Checkup.
class MiniCheckupBodyComponent extends Equatable {
  final int? gender;
  final int? age;
  final int? height;
  final int? weight;
  final double? bmi;
  final double? bodyFatRate;
  final double? fatRate;
  final double? ffm;
  final double? muscleRate;
  final double? muscleMass;
  final double? subcutaneousFat;
  final double? bodyWater;
  final double? waterContent;
  final double? skeletalMuscleRate;
  final double? boneMass;
  final double? proteinProportion;
  final double? proteinMass;
  final double? basalMetabolicRate;

  const MiniCheckupBodyComponent({
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.bmi,
    this.bodyFatRate,
    this.fatRate,
    this.ffm,
    this.muscleRate,
    this.muscleMass,
    this.subcutaneousFat,
    this.bodyWater,
    this.waterContent,
    this.skeletalMuscleRate,
    this.boneMass,
    this.proteinProportion,
    this.proteinMass,
    this.basalMetabolicRate,
  });

  factory MiniCheckupBodyComponent.fromMap(Map<String, dynamic> map) {
    return MiniCheckupBodyComponent(
      gender: (map['gender'] as num?)?.toInt(),
      age: (map['age'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      weight: (map['weight'] as num?)?.toInt(),
      bmi: (map['bmi'] as num?)?.toDouble(),
      bodyFatRate: (map['bodyFatRate'] as num?)?.toDouble(),
      fatRate: (map['fatRate'] as num?)?.toDouble(),
      ffm: (map['ffm'] as num?)?.toDouble(),
      muscleRate: (map['muscleRate'] as num?)?.toDouble(),
      muscleMass: (map['muscleMass'] as num?)?.toDouble(),
      subcutaneousFat: (map['subcutaneousFat'] as num?)?.toDouble(),
      bodyWater: (map['bodyWater'] as num?)?.toDouble(),
      waterContent: (map['waterContent'] as num?)?.toDouble(),
      skeletalMuscleRate: (map['skeletalMuscleRate'] as num?)?.toDouble(),
      boneMass: (map['boneMass'] as num?)?.toDouble(),
      proteinProportion: (map['proteinProportion'] as num?)?.toDouble(),
      proteinMass: (map['proteinMass'] as num?)?.toDouble(),
      basalMetabolicRate: (map['basalMetabolicRate'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        gender,
        age,
        height,
        weight,
        bmi,
        bodyFatRate,
        fatRate,
        ffm,
        muscleRate,
        muscleMass,
        subcutaneousFat,
        bodyWater,
        waterContent,
        skeletalMuscleRate,
        boneMass,
        proteinProportion,
        proteinMass,
        basalMetabolicRate,
      ];
}

/// Galvanic skin response reading taken during a Mini Checkup.
class MiniCheckupSkinElectricity extends Equatable {
  final int? emotion;
  final int? skinMoistureContent;
  final int? depressionRisk;
  final int? sympatheticActivity;
  final int? cortisolConcentration;

  const MiniCheckupSkinElectricity({
    this.emotion,
    this.skinMoistureContent,
    this.depressionRisk,
    this.sympatheticActivity,
    this.cortisolConcentration,
  });

  factory MiniCheckupSkinElectricity.fromMap(Map<String, dynamic> map) {
    return MiniCheckupSkinElectricity(
      emotion: (map['emotion'] as num?)?.toInt(),
      skinMoistureContent: (map['skinMoistureContent'] as num?)?.toInt(),
      depressionRisk: (map['depressionRisk'] as num?)?.toInt(),
      sympatheticActivity: (map['sympatheticActivity'] as num?)?.toInt(),
      cortisolConcentration: (map['cortisolConcentration'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [
        emotion,
        skinMoistureContent,
        depressionRisk,
        sympatheticActivity,
        cortisolConcentration,
      ];
}

/// Full detailed Mini Checkup report, covering every sensor the device ran during the session.
class MiniCheckupDetail extends Equatable {
  final MiniCheckupPersonalInfo? basePersonalInfo;
  final int? heartRate;
  final int? bloodOxygen;
  final int? stress;
  final int? emotion;
  final int? fatigue;
  final int? bloodGlucoseType;
  final double? bloodGlucose;
  final double? bodyTemperature;
  final double? originalTemperature;

  /// Blood pressure measured via the air-pump (cuff) method, if available.
  final MiniCheckupBloodPressure? bpAirPump;

  /// Blood pressure measured via the photoelectric (PPG) method, if available.
  final MiniCheckupBloodPressure? bpPhotoelectric;
  final int? hrv;
  final MiniCheckupBloodComponent? bloodComponent;
  final MiniCheckupBodyComponent? bodyComponent;
  final MiniCheckupSkinElectricity? skinElectricity;

  const MiniCheckupDetail({
    this.basePersonalInfo,
    this.heartRate,
    this.bloodOxygen,
    this.stress,
    this.emotion,
    this.fatigue,
    this.bloodGlucoseType,
    this.bloodGlucose,
    this.bodyTemperature,
    this.originalTemperature,
    this.bpAirPump,
    this.bpPhotoelectric,
    this.hrv,
    this.bloodComponent,
    this.bodyComponent,
    this.skinElectricity,
  });

  factory MiniCheckupDetail.fromMap(Map<String, dynamic> map) {
    return MiniCheckupDetail(
      basePersonalInfo: map['basePersonalInfo'] != null
          ? MiniCheckupPersonalInfo.fromMap(
              Map<String, dynamic>.from(map['basePersonalInfo'] as Map))
          : null,
      heartRate: (map['heartRate'] as num?)?.toInt(),
      bloodOxygen: (map['bloodOxygen'] as num?)?.toInt(),
      stress: (map['stress'] as num?)?.toInt(),
      emotion: (map['emotion'] as num?)?.toInt(),
      fatigue: (map['fatigue'] as num?)?.toInt(),
      bloodGlucoseType: (map['bloodGlucoseType'] as num?)?.toInt(),
      bloodGlucose: (map['bloodGlucose'] as num?)?.toDouble(),
      bodyTemperature: (map['bodyTemperature'] as num?)?.toDouble(),
      originalTemperature: (map['originalTemperature'] as num?)?.toDouble(),
      bpAirPump: map['bpAirPump'] != null
          ? MiniCheckupBloodPressure.fromMap(
              Map<String, dynamic>.from(map['bpAirPump'] as Map))
          : null,
      bpPhotoelectric: map['bpPhotoelectric'] != null
          ? MiniCheckupBloodPressure.fromMap(
              Map<String, dynamic>.from(map['bpPhotoelectric'] as Map))
          : null,
      hrv: (map['hrv'] as num?)?.toInt(),
      bloodComponent: map['bloodComponent'] != null
          ? MiniCheckupBloodComponent.fromMap(
              Map<String, dynamic>.from(map['bloodComponent'] as Map))
          : null,
      bodyComponent: map['bodyComponent'] != null
          ? MiniCheckupBodyComponent.fromMap(
              Map<String, dynamic>.from(map['bodyComponent'] as Map))
          : null,
      skinElectricity: map['skinElectricity'] != null
          ? MiniCheckupSkinElectricity.fromMap(
              Map<String, dynamic>.from(map['skinElectricity'] as Map))
          : null,
    );
  }

  @override
  List<Object?> get props => [
        basePersonalInfo,
        heartRate,
        bloodOxygen,
        stress,
        emotion,
        fatigue,
        bloodGlucoseType,
        bloodGlucose,
        bodyTemperature,
        originalTemperature,
        bpAirPump,
        bpPhotoelectric,
        hrv,
        bloodComponent,
        bodyComponent,
        skinElectricity,
      ];
}
