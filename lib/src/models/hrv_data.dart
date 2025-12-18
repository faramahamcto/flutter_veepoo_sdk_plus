part of '../../flutter_veepoo_sdk.dart';

/// Heart Rate Variability (HRV) data model
class HRVData extends Equatable {
  /// Date of HRV measurement (YYYY-MM-DD format)
  final String? date;

  /// HRV value (in milliseconds)
  final int? hrvValue;

  /// Heart rate during measurement (BPM)
  final int? heartRate;

  /// RR interval values (time between heartbeats in milliseconds)
  final List<int>? rrValues;

  /// HRV measurement type
  final int? hrvType;

  /// Timestamp string
  final String? timestamp;

  const HRVData({
    this.date,
    this.hrvValue,
    this.heartRate,
    this.rrValues,
    this.hrvType,
    this.timestamp,
  });

  factory HRVData.fromMap(Map<String, dynamic> map) {
    return HRVData(
      date: map['date'] as String?,
      hrvValue: map['hrvValue'] as int?,
      heartRate: map['heartRate'] as int?,
      rrValues: (map['rrValues'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      hrvType: map['hrvType'] as int?,
      timestamp: map['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'hrvValue': hrvValue,
      'heartRate': heartRate,
      'rrValues': rrValues,
      'hrvType': hrvType,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [
        date,
        hrvValue,
        heartRate,
        rrValues,
        hrvType,
        timestamp,
      ];
}
