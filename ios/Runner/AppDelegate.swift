import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Explicit FlutterEngine created and run at launch — BEFORE any FlutterViewController
  // loads its view. This guarantees the engine's platform task runner is non-null by the
  // time viewDidLoad runs, which avoids the iOS-26 / ProMotion crash in
  // -[FlutterViewController createTouchRateCorrectionVSyncClientIfNeeded] -> VSyncClient
  // (Flutter issue #183900). The implicit (storyboard) engine path triggers that crash.
  lazy var flutterEngine = FlutterEngine(name: "goalshare_engine")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
