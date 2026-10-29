import Flutter
import UIKit
import VeepooBleSDK

/// Photo (custom) watch face (Android: WatchFace). Positions cross the channel as Dart
/// `WatchFacePosition` indexes (= VPPhotoDialTimePosition raw value - 1); elements as Dart
/// `WatchFaceElement` indexes (= VPPhotoDialTimeTopAndBottomElement raw value).
/// Also lists and installs market (server) watch faces.
final class VPWatchFace {
  private let progressEvents: EventStream
  /// Last market list by fileUrl; the download API needs the server model, not just the URL.
  private var marketFaces: [String: VPServerMarketDialModel] = [:]

  init(progressEvents: EventStream) {
    self.progressEvents = progressEvents
  }

  private var isJL: Bool { VPSdk.ble.peripheralModel?.cpuType == 1 }

  func read(_ reply: Reply) {
    reply.timeout(after: 15, code: "WATCH_FACE_TIMEOUT", "Reading watch face timed out")
    readModel(reply) { model in
      let size = model.configModel?.screenSize ?? .zero
      let raw = NSNumber(value: model.screenType.rawValue)
      let positions: [Int]
      if VPPhotoDialModel.topMiddleBottomTypes().contains(raw) {
        positions = [0, 1, 2]
      } else if VPPhotoDialModel.allAroundTypes().contains(raw) {
        positions = [3, 4, 5, 6]
      } else {
        positions = Array(0...6)
      }
      reply(payload([
        "width": Int(size.width),
        "height": Int(size.height),
        "isRound": model.configModel?.isCircle ?? false,
        "isJL": self.isJL,
        "positions": positions,
        "timePosition": max(Int(model.timePosition.rawValue) - 1, 0),
        "upElement": Int(model.timeTopPosition.rawValue),
        "downElement": Int(model.timeBottomPosition.rawValue),
        "color": Int(model.deviceColor.filter(\.isHexDigit), radix: 16),
        "isDefaultBackground": model.isDefaultBG,
      ]))
    }
  }

  func set(_ args: [String: Any], _ reply: Reply) {
    let imagePath = args["imagePath"] as? String
    let image = imagePath.flatMap { UIImage(contentsOfFile: $0) }
    if imagePath != nil && image == nil {
      return reply.error("WATCH_FACE_IMAGE", "Cannot decode \(imagePath!)")
    }
    reply.timeout(after: 200, code: "WATCH_FACE_TIMEOUT", "Watch face transfer timed out")

    readModel(reply) { model in
      model.timePosition = VPPhotoDialTimePosition(rawValue: UInt((args["timePosition"] as? Int ?? 0) + 1)) ?? .top
      model.timeTopPosition = VPPhotoDialTimeTopAndBottomElement(rawValue: UInt(args["upElement"] as? Int ?? 0)) ?? .hidden
      model.timeBottomPosition = VPPhotoDialTimeTopAndBottomElement(rawValue: UInt(args["downElement"] as? Int ?? 0)) ?? .hidden
      model.setColor = String(format: "%06X", args["color"] as? Int ?? 0xFFFFFF)
      model.isDefaultBG = image == nil && (args["useDefaultBackground"] as? Bool ?? false)
      if let image = image, let size = model.configModel?.screenSize {
        model.transformImage = Self.resize(image, to: size)
      }

      let transfer = {
        // ponytail: the SDK documents `result` as unused for setupPhotoDial, so success is
        // progress reaching 1 (photo) or a quiet 4s (elements only). Confirm on a real watch.
        if image == nil {
          DispatchQueue.main.asyncAfter(deadline: .now() + 4) { reply(nil) }
        }
        VPSdk.manage.veepooSDK_dialChannel(with: .setupPhotoDial, dialType: .photo, photoDialModel: model, result: { _, _, error in
          if let error = error { reply.error("WATCH_FACE_TRANSFER", error.localizedDescription) }
        }, transformProgress: { progress in
          self.progressEvents.send(Int(progress * 100))
          if progress >= 1 { reply(nil) }
        })
      }

      guard self.isJL, image != nil else { return transfer() }
      VPMarketDialManager.share().openJLDialFileSystem { ok in
        ok ? transfer() : reply.error("WATCH_FACE_JL_INIT", "JieLi file system failed")
      }
    }
  }

  func readMarket(_ reply: Reply) {
    reply.timeout(after: 35, code: "WATCH_FACE_TIMEOUT", "Reading market watch faces timed out")
    readMarketModel(reply) { device in
      VPMarketDialManager.share().getVeepooServerAllMarketDials(withDeviceInfo: device, success: { faces in
        onMain {
          let faces = faces ?? []
          self.marketFaces = Dictionary(faces.map { ($0.fileUrl, $0) }, uniquingKeysWith: { first, _ in first })
          reply(faces.map { ["previewUrl": $0.previewUrl, "fileUrl": $0.fileUrl] })
        }
      }, failure: { error, code in
        reply.error("WATCH_FACE_MARKET", "Fetching market watch faces failed (\(code)): \(error?.localizedDescription ?? "")")
      })
    }
  }

  func installMarket(_ fileUrl: String?, _ reply: Reply) {
    guard let fileUrl = fileUrl, let face = marketFaces[fileUrl] else {
      return reply.error("INVALID_ARGUMENT", "Unknown fileUrl; call readMarketWatchFaces first")
    }
    reply.timeout(after: 300, code: "WATCH_FACE_TIMEOUT", "Watch face transfer timed out")
    readMarketModel(reply) { device in
      VPMarketDialManager.share().downloadMarketDialBinFile(with: face, deviceMarketDialModel: device, success: { path in
        guard let path = path else { return reply.error("WATCH_FACE_DOWNLOAD", "Download failed") }
        let transfer = {
          VPMarketDialManager.share().startTransfer(withFilePath: path, transformProgress: { progress in
            self.progressEvents.send(Int(progress * 100))
            if progress >= 1 { reply(nil) }
          }, failure: { error in
            if let error = error { reply.error("WATCH_FACE_TRANSFER", error.localizedDescription) }
          })
        }
        guard self.isJL else { return transfer() }
        VPMarketDialManager.share().openJLDialFileSystem { ok in
          ok ? transfer() : reply.error("WATCH_FACE_JL_INIT", "JieLi file system failed")
        }
      }, failure: { error, code in
        reply.error("WATCH_FACE_DOWNLOAD", "Download failed (\(code)): \(error?.localizedDescription ?? "")")
      })
    }
  }

  private func readMarketModel(_ reply: Reply, _ done: @escaping (VPDeviceMarketDialModel) -> Void) {
    guard VPSdk.connectedAddress != nil else { return reply.error("NOT_CONNECTED", "Device is not connected") }
    guard (VPSdk.ble.peripheralModel?.marketDialCount ?? 0) > 0 else { return reply(nil) }
    VPSdk.manage.veepooSDK_dialChannel(with: .read, dialType: .market, photoDialModel: nil, result: { _, device, error in
      onMain {
        guard let device = device, error == nil else {
          return reply.error("WATCH_FACE_READ", error?.localizedDescription ?? "No market dial data")
        }
        done(device)
      }
    }, transformProgress: nil)
  }

  private func readModel(_ reply: Reply, _ done: @escaping (VPPhotoDialModel) -> Void) {
    guard VPSdk.connectedAddress != nil else { return reply.error("NOT_CONNECTED", "Device is not connected") }
    guard (VPSdk.ble.peripheralModel?.photoDialCount ?? 0) > 0 else { return reply(nil) }
    VPSdk.manage.veepooSDK_dialChannel(with: .read, dialType: .photo, photoDialModel: nil, result: { model, _, error in
      onMain {
        guard let model = model, error == nil else {
          return reply.error("WATCH_FACE_READ", error?.localizedDescription ?? "No photo dial data")
        }
        done(model)
      }
    }, transformProgress: nil)
  }

  /// The watch only accepts photos at its exact screen size.
  private static func resize(_ image: UIImage, to size: CGSize) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
  }
}
