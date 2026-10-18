import Flutter
import UIKit
import WebKit

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CampusCookies") {
      CampusCookies.register(with: registrar.messenger())
    }
  }
}

/// Reads and restores the campus cookies in the WebViews' shared store.
/// webview_flutter can set cookies but not read them, and the portal and
/// CAS cookies are HttpOnly, so this goes to WKHTTPCookieStore directly.
enum CampusCookies {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "tatccu/campus_cookies", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let store = WKWebsiteDataStore.default().httpCookieStore
      switch call.method {
      case "read":
        store.getAllCookies { cookies in
          result(cookies.filter { $0.domain.hasSuffix("ccu.edu.tw") }.map { c -> [String: Any] in
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
