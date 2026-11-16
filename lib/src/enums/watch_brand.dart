part of '../../flutter_veepoo_sdk.dart';

/// The watch vendor (and therefore the native SDK) the plugin talks to.
///
/// Pick one with [VeepooSDK.setBrand] before scanning; every other call then goes to that SDK.
enum WatchBrand {
  /// Veepoo watches (default). Android + iOS.
  veepoo,

  /// Yucheng (YC) watches. Android only for now.
  yc;
}
