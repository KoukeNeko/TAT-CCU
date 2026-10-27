import Cocoa
import FlutterMacOS
import WidgetKit

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // The sidebar runs up behind the window buttons, like Mail.
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)
    // An empty unified toolbar makes the title bar the tall kind, with the
    // window buttons set in from the corner as in Mail and Finder.
    let toolbar = NSToolbar(identifier: "main")
    toolbar.showsBaselineSeparator = false
    self.toolbar = toolbar
    self.toolbarStyle = .unified
    self.minSize = NSSize(width: 390, height: 600)

    RegisterGeneratedPlugins(registry: flutterViewController)
    Self.shareWithWidgets(flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }

  /// What the desktop widgets (TatWidgets) show, written where they read it;
  /// lib/ui/home_widgets on the other end. home_widget has no macOS side.
  private static func shareWithWidgets(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "tat_ccu/widgets", binaryMessenger: messenger)
    let group = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String ?? ""
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "save":
        guard let args = call.arguments as? [String: String], let key = args["key"],
          let defaults = UserDefaults(suiteName: group)
        else {
          return result(FlutterError(code: "save", message: "no app group \(group)", details: nil))
        }
        defaults.set(args["value"], forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
        result(nil)
      case "installed":
        WidgetCenter.shared.getCurrentConfigurations { configs in
          let count = (try? configs.get().count) ?? 0
          DispatchQueue.main.async { result(count > 0) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
