part of '../../flutter_veepoo_sdk.dart';

/// Body composition detection/measurement state
enum BodyComponentState {
  /// Idle state
  idle,

  /// Measuring
  measuring,

  /// Measurement complete
  complete,

  /// Measurement failed
  failed,

  /// Device is busy with another operation
  busy,

  /// Device battery is too low to measure
  lowPower,

  /// Unknown state
  unknown,
}

/// Body composition data model.
///
/// Used both for live detection results ([VeepooSDK.startDetectBodyComponent] /
/// [VeepooSDK.bodyComponent]) and for historical records read from the device
/// ([VeepooSDK.readBodyComponentData]). Historical records additionally populate
/// [date], [id], [idType] and [duration]; live detection additionally populates
/// [state], [isMeasuring], [progress] and [timestamp].
class BodyComponent extends Equatable {
  /// Body Mass Index
  final double? bmi;

  /// Body fat rate (%)
  final double? bodyFatRate;

  /// Fat rate (%)
  final double? fatRate;

  /// Fat-free mass (kg)
  final double? ffm;

  /// Muscle rate (%)
  final double? muscleRate;

  /// Muscle mass (kg)
  final double? muscleMass;

  /// Subcutaneous fat (%)
  final double? subcutaneousFat;

  /// Body water (%)
  final double? bodyWater;

  /// Water content (%)
  final double? waterContent;

  /// Skeletal muscle rate (%)
  final double? skeletalMuscleRate;

  /// Bone mass (kg)
  final double? boneMass;

  /// Protein proportion (%)
  final double? proteinProportion;

  /// Protein mass (kg)
  final double? proteinMass;

  /// Basal metabolic rate (kcal)
  final double? basalMetabolicRate;

  /// Date of a historical record (YYYY-MM-DD HH:mm:ss format)
  final String? date;

  /// Record identifier (historical records only)
  final int? id;

  /// Record ID type (historical records only)
  final int? idType;

  /// Measurement duration in seconds (historical records only)
  final int? duration;

  /// Measurement state (live detection only)
  final BodyComponentState? state;

  /// Whether a measurement is currently in progress (live detection only)
  final bool? isMeasuring;

  /// Measurement progress, 0-100 (live detection only)
  final int? progress;

  /// Raw per-step code reported by the device while measuring (live
  /// detection only). Unlike ECG's waveform-derived signal quality, the
  /// vendor doesn't document what this value means beyond "still
  /// measuring" — there's no true signal-quality metric for body
  /// composition. Shown as a coarse, undocumented diagnostic only.
  final int? detectStep;

  /// Timestamp of this event
  final int? timestamp;

  const BodyComponent({
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
    this.date,
    this.id,
    this.idType,
    this.duration,
    this.state,
    this.isMeasuring,
    this.progress,
    this.detectStep,
    this.timestamp,
  });

  factory BodyComponent.fromMap(Map<String, dynamic> map) {
    return BodyComponent(
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
      date: map['date'] as String?,
      id: (map['id'] as num?)?.toInt(),
      idType: (map['idType'] as num?)?.toInt(),
      duration: (map['duration'] as num?)?.toInt(),
      state: map['state'] != null
          ? BodyComponentState.values.firstWhere(
              (e) => e.name == map['state'],
              orElse: () => BodyComponentState.unknown,
            )
          : null,
      isMeasuring: map['isMeasuring'] as bool?,
      progress: (map['progress'] as num?)?.toInt(),
      detectStep: (map['detectStep'] as num?)?.toInt(),
      timestamp: (map['timestamp'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bmi': bmi,
      'bodyFatRate': bodyFatRate,
      'fatRate': fatRate,
      'ffm': ffm,
      'muscleRate': muscleRate,
      'muscleMass': muscleMass,
      'subcutaneousFat': subcutaneousFat,
      'bodyWater': bodyWater,
      'waterContent': waterContent,
      'skeletalMuscleRate': skeletalMuscleRate,
      'boneMass': boneMass,
      'proteinProportion': proteinProportion,
      'proteinMass': proteinMass,
      'basalMetabolicRate': basalMetabolicRate,
      'date': date,
      'id': id,
      'idType': idType,
      'duration': duration,
      'state': state?.name,
      'isMeasuring': isMeasuring,
      'progress': progress,
      'detectStep': detectStep,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [
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
        date,
        id,
        idType,
        duration,
        state,
        isMeasuring,
        progress,
        detectStep,
        timestamp,
      ];
}
