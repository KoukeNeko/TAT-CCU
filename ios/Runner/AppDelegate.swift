import Flutter
import QuickLook
import UIKit
import WebKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Reminders.backgroundTask: plugins for its isolate, and the task itself.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "io.github.koukeneko.tatCcu.refresh",
      earliestBeginInSeconds: NSNumber(value: 60 * 60)
    )
    // Shows reminders while the app is open too.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CampusCookies") {
      CampusCookies.register(with: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PdfPreview") {
      PdfPreview.register(with: registrar.messenger())
    }
  }
}

/// Reads and restores the campus cookies in the WebViews' shared store.
/// webview_flutter can set cookies but not read them, and the portal and
/// CAS cookies are HttpOnly, so this goes to WKHTTPCookieStore directly.
enum CampusCookies {
  /// The campus systems, plus the library's Primo, whose own sign-in cookie
  /// outlives the CAS session.
  static let campusDomains = ["ccu.edu.tw", "ccu.primo.exlibrisgroup.com"]

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "tatccu/campus_cookies", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let store = WKWebsiteDataStore.default().httpCookieStore
      switch call.method {
      case "read":
        store.getAllCookies { cookies in
          result(cookies.filter { campusDomains.contains(where: $0.domain.hasSuffix) }.map { c -> [String: Any] in
            var m: [String: Any] = [
              "name": c.name, "value": c.value, "domain": c.domain, "path": c.path,
              "secure": c.isSecure, "httpOnly": c.isHTTPOnly,
            ]
            if let expires = c.expiresDate { m["expires"] = expires.timeIntervalSince1970 }
            return m
          })
        }
      case "write":
        let group = DispatchGroup()
        for m in call.arguments as? [[String: Any]] ?? [] {
          var props: [HTTPCookiePropertyKey: Any] = [
            .name: m["name"] as? String ?? "",
            .value: m["value"] as? String ?? "",
            .domain: m["domain"] as? String ?? "",
            .path: m["path"] as? String ?? "/",
          ]
          if m["secure"] as? Bool == true { props[.secure] = "TRUE" }
          if m["httpOnly"] as? Bool == true { props[HTTPCookiePropertyKey("HttpOnly")] = "TRUE" }
          if let expires = m["expires"] as? Double { props[.expires] = Date(timeIntervalSince1970: expires) }
          guard let cookie = HTTPCookie(properties: props) else { continue }
          group.enter()
          store.setCookie(cookie) { group.leave() }
        }
        group.notify(queue: .main) { result(nil) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// Shows a PDF in Quick Look, which draws the school's unembedded CJK fonts
/// with the system's and brings its own share button.
final class PdfPreview: NSObject, QLPreviewControllerDataSource {
  /// Quick Look keeps only a weak reference to its data source.
  private static var current: PdfPreview?

  private let item: Item

  private init(item: Item) { self.item = item }

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "tatccu/pdf_preview", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "show",
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else { return result(FlutterMethodNotImplemented) }
      let preview = PdfPreview(item: Item(url: URL(fileURLWithPath: path), title: args["title"] as? String))
      current = preview
      let controller = QLPreviewController()
      controller.dataSource = preview
      var top = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController
      while let presented = top?.presentedViewController { top = presented }
      top?.present(controller, animated: true)
      result(nil)
    }
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { item }

  final class Item: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    let previewItemTitle: String?

    init(url: URL, title: String?) {
      previewItemURL = url
      previewItemTitle = title
    }
  }
}
