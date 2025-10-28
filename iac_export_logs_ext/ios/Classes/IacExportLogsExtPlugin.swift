import Flutter
import UIKit
import LinkPresentation

public class IacExportLogsExtPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "iac_export_logs_ext", binaryMessenger: registrar.messenger())
    let instance = IacExportLogsExtPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "shareFile":
      handleShareFile(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleShareFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let filePath = args["filePath"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS",
                         message: "filePath is required",
                         details: nil))
      return
    }

    let fileURL = URL(fileURLWithPath: filePath)

    // Check if file exists
    guard FileManager.default.fileExists(atPath: filePath) else {
      result(false)
      return
    }

    // Present share sheet with LinkPresentation
    DispatchQueue.main.async {
      guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
        result(false)
        return
      }

      let activityViewController = UIActivityViewController(
        activityItems: [fileURL],
        applicationActivities: nil
      )

      // For iPad support
      if let popoverController = activityViewController.popoverPresentationController {
        popoverController.sourceView = rootViewController.view
        popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                               y: rootViewController.view.bounds.midY,
                                               width: 0,
                                               height: 0)
        popoverController.permittedArrowDirections = []
      }

      // Completion handler to return result
      activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
        if error != nil {
          result(false)
        } else {
          result(completed)
        }
      }

      rootViewController.present(activityViewController, animated: true, completion: nil)
    }
  }
}
