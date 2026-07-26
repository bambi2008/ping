import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "ping/notifications",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleNotificationCall(call, result: result)
    }
    let shareChannel = FlutterMethodChannel(
      name: "ping/share",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    shareChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleShareCall(call, result: result)
    }
  }

  private func handleShareCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      call.method == "shareText",
      let arguments = call.arguments as? [String: Any],
      let text = arguments["text"] as? String
    else {
      result(FlutterMethodNotImplemented)
      return
    }
    let controller = UIActivityViewController(
      activityItems: [text],
      applicationActivities: nil
    )
    guard let root = window?.rootViewController else {
      result(FlutterError(code: "share_unavailable", message: nil, details: nil))
      return
    }
    controller.popoverPresentationController?.sourceView = root.view
    controller.popoverPresentationController?.sourceRect = CGRect(
      x: root.view.bounds.midX,
      y: root.view.bounds.midY,
      width: 1,
      height: 1
    )
    root.present(controller, animated: true) { result(nil) }
  }

  private func handleNotificationCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    let center = UNUserNotificationCenter.current()
    switch call.method {
    case "requestPermission":
      center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
        DispatchQueue.main.async { result(granted) }
      }
    case "schedule":
      guard
        let arguments = call.arguments as? [String: Any],
        let id = arguments["id"] as? Int,
        let title = arguments["title"] as? String,
        let body = arguments["body"] as? String,
        let epochMillis = arguments["epochMillis"] as? NSNumber
      else {
        result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
        return
      }
      let date = Date(timeIntervalSince1970: epochMillis.doubleValue / 1000)
      let interval = date.timeIntervalSinceNow
      guard interval > 0 else {
        result(nil)
        return
      }
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default
      let request = UNNotificationRequest(
        identifier: String(id),
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
      )
      center.add(request) { error in
        DispatchQueue.main.async {
          if let error {
            result(FlutterError(
              code: "schedule_failed",
              message: error.localizedDescription,
              details: nil
            ))
          } else {
            result(nil)
          }
        }
      }
    case "cancel":
      guard
        let arguments = call.arguments as? [String: Any],
        let id = arguments["id"] as? Int
      else {
        result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
        return
      }
      let identifiers = [String(id)]
      center.removePendingNotificationRequests(withIdentifiers: identifiers)
      center.removeDeliveredNotifications(withIdentifiers: identifiers)
      result(nil)
    case "cancelAll":
      center.removeAllPendingNotificationRequests()
      center.removeAllDeliveredNotifications()
      result(nil)
    case "showNow":
      guard
        let arguments = call.arguments as? [String: Any],
        let id = arguments["id"] as? Int,
        let title = arguments["title"] as? String,
        let body = arguments["body"] as? String
      else {
        result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
        return
      }
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default
      center.add(
        UNNotificationRequest(
          identifier: String(id),
          content: content,
          trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
      )
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
