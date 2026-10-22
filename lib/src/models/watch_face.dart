part of '../../flutter_veepoo_sdk.dart';

/// Where the clock sits on the photo watch face. Index order is the native wire format.
enum WatchFacePosition { top, middle, bottom, leftTop, rightTop, leftBottom, rightBottom }

/// What is shown above / below the clock. Index order is the native wire format.
enum WatchFaceElement { none, date1, date2, steps, sleep, heartRate, calories, distance, battery }

/// {@template flutter_veepoo_sdk.custom_watch_face}
/// The watch's photo (custom) watch face: screen size and current layout.
/// {@endtemplate}
final class CustomWatchFace extends Equatable {
  /// {@macro flutter_veepoo_sdk.custom_watch_face}
  const CustomWatchFace({
    required this.width,
    required this.height,
    required this.isRound,
    required this.isJL,
    required this.positions,
    required this.timePosition,
    required this.upElement,
    required this.downElement,
    required this.color,
    required this.isDefaultBackground,
  });

  /// Screen width in pixels. Background photos must be cropped to [width] x [height].
  final int width;

  /// Screen height in pixels.
  final int height;

  /// Round screen.
  final bool isRound;

  /// JieLi chip (different transfer path natively; informational only).
  final bool isJL;

  /// Clock positions this screen supports.
  final List<WatchFacePosition> positions;

  /// Current clock position.
  final WatchFacePosition timePosition;

  /// Element above the clock.
  final WatchFaceElement upElement;

  /// Element below the clock.
  final WatchFaceElement downElement;

  /// Text color as 0xRRGGBB. The watch shows RGB565, so it may look slightly different.
  final int color;

  /// The watch shows its built-in background rather than a user photo.
  final bool isDefaultBackground;

  /// Converts a channel map to a [CustomWatchFace].
  factory CustomWatchFace.fromMap(Map<String, dynamic> map) {
    T at<T>(List<T> values, Object? index) =>
        index is int && index >= 0 && index < values.length ? values[index] : values.first;

    return CustomWatchFace(
      width: map['width'] as int? ?? 0,
      height: map['height'] as int? ?? 0,
      isRound: map['isRound'] as bool? ?? false,
      isJL: map['isJL'] as bool? ?? false,
      positions: [
        for (final i in (map['positions'] as List?) ?? const []) at(WatchFacePosition.values, i),
      ],
      timePosition: at(WatchFacePosition.values, map['timePosition']),
      upElement: at(WatchFaceElement.values, map['upElement']),
      downElement: at(WatchFaceElement.values, map['downElement']),
      color: map['color'] as int? ?? 0xFFFFFF,
      isDefaultBackground: map['isDefaultBackground'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        width,
        height,
        isRound,
        isJL,
        positions,
        timePosition,
        upElement,
        downElement,
        color,
        isDefaultBackground,
      ];
}

/// {@template flutter_veepoo_sdk.market_watch_face}
/// A ready-made watch face from the Veepoo server that fits the connected watch.
/// {@endtemplate}
final class MarketWatchFace extends Equatable {
  /// {@macro flutter_veepoo_sdk.market_watch_face}
  const MarketWatchFace({required this.previewUrl, required this.fileUrl});

  /// Preview image URL.
  final String previewUrl;

  /// Watch face file URL; pass it to `installMarketWatchFace`.
  final String fileUrl;

  /// Converts a channel map to a [MarketWatchFace].
  factory MarketWatchFace.fromMap(Map<dynamic, dynamic> map) => MarketWatchFace(
        previewUrl: map['previewUrl'] as String? ?? '',
        fileUrl: map['fileUrl'] as String? ?? '',
      );

  @override
  List<Object?> get props => [previewUrl, fileUrl];
}
