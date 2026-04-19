import Flutter
import AMapFoundationKit
import MAMapKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let deviceChannelName = "aidrun/device"
  private var deviceChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureAMap()
    let didLaunch = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      configureDeviceChannel(using: controller.binaryMessenger)
    }
    return didLaunch
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func configureAMap() {
    let config = currentAMapConfig()
    guard let apiKey = config["iosKey"], !apiKey.isEmpty else {
      return
    }

    MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
    MAMapView.updatePrivacyAgree(.didAgree)
    AMapServices.shared().apiKey = apiKey
  }

  func configureDeviceChannel(using binaryMessenger: FlutterBinaryMessenger) {
    guard deviceChannel == nil else {
      return
    }

    let channel = FlutterMethodChannel(
      name: deviceChannelName,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "getAMapConfig":
        result(self?.currentAMapConfig() ?? [:])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    deviceChannel = channel
  }

  private func currentAMapConfig() -> [String: String] {
    var values: [String: String] = [:]
    if
      let encodedDefines = Bundle.main.object(forInfoDictionaryKey: "FlutterDartDefines") as? String,
      !encodedDefines.isEmpty
    {
      for encoded in encodedDefines.split(separator: ",") {
        guard let decoded = decodeDartDefine(String(encoded)) else {
          continue
        }

        let parts = decoded.split(separator: "=", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
          continue
        }

        switch parts[0] {
        case "AMAP_ANDROID_KEY":
          values["androidKey"] = parts[1]
        case "AMAP_IOS_KEY":
          values["iosKey"] = parts[1]
        case "AMAP_WEB_KEY":
          values["webKey"] = parts[1]
        default:
          continue
        }
      }
    }

    if values["iosKey"]?.isEmpty ?? true {
      if let plistKey = Bundle.main.object(forInfoDictionaryKey: "AMAP_IOS_KEY") as? String,
         !plistKey.isEmpty,
         plistKey != "$(AMAP_IOS_KEY)" {
        values["iosKey"] = plistKey
      }
    }

    if values["webKey"]?.isEmpty ?? true {
      if let plistKey = Bundle.main.object(forInfoDictionaryKey: "AMAP_WEB_KEY") as? String,
         !plistKey.isEmpty,
         plistKey != "$(AMAP_WEB_KEY)" {
        values["webKey"] = plistKey
      }
    }

    return values
  }

  private func decodeDartDefine(_ encoded: String) -> String? {
    var padded = encoded.replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    let remainder = padded.count % 4
    if remainder > 0 {
      padded.append(String(repeating: "=", count: 4 - remainder))
    }

    guard let data = Data(base64Encoded: padded) else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }
}
