import Flutter
import UIKit

public class IacDeviceInfoExtPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "iac_device_info_ext", binaryMessenger: registrar.messenger())
    let instance = IacDeviceInfoExtPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getTotalRam":
      result(ProcessInfo.processInfo.physicalMemory)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
