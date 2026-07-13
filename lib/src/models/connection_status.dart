part of '../../flutter_veepoo_sdk.dart';

/// Connection status values matching the SDK's Constants
enum DeviceConnectionState {
  /// Device is connected
  connected,
  /// Device is disconnected
  disconnected,
  /// Unknown connection state
  unknown;

  /// Creates a [DeviceConnectionState] from an integer status code
  static DeviceConnectionState fromCode(int? code) {
    switch (code) {
      case 2: // Constants.STATUS_CONNECTED
        return DeviceConnectionState.connected;
      case 0: // Constants.STATUS_DISCONNECTED
        return DeviceConnectionState.disconnected;
      default:
        return DeviceConnectionState.unknown;
    }
  }

  /// Creates a [DeviceConnectionState] from a string
  static DeviceConnectionState fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'connected':
        return DeviceConnectionState.connected;
      case 'disconnected':
        return DeviceConnectionState.disconnected;
      default:
        return DeviceConnectionState.unknown;
    }
  }
}

/// {@template flutter_veepoo_sdk.connection_status}
/// A class that represents the connection status of a Bluetooth device.
/// {@endtemplate}
final class ConnectionStatus extends Equatable {
  /// {@macro flutter_veepoo_sdk.connection_status}
  const ConnectionStatus({
    required this.state,
    this.address,
    this.timestamp,
  });

  /// The connection state of the device
  final DeviceConnectionState state;

  /// The MAC address of the device (if available)
  final String? address;

  /// The timestamp when the status changed
  final int? timestamp;

  /// Whether the device is currently connected
  bool get isConnected => state == DeviceConnectionState.connected;

  /// Whether the device is currently disconnected
  bool get isDisconnected => state == DeviceConnectionState.disconnected;

  /// Creates a [ConnectionStatus] from a map
  factory ConnectionStatus.fromMap(Map<String, dynamic> map) {
    return ConnectionStatus(
      state: map['state'] is int
          ? DeviceConnectionState.fromCode(map['state'] as int)
          : DeviceConnectionState.fromString(map['state'] as String?),
      address: map['address'] as String?,
      timestamp: map['timestamp'] as int?,
    );
  }

  /// Converts this [ConnectionStatus] to a map
  Map<String, dynamic> toMap() {
    return {
      'state': state.name,
      'address': address,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [state, address, timestamp];

  @override
  String toString() =>
      'ConnectionStatus(state: $state, address: $address, timestamp: $timestamp)';
}
