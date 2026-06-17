import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Explicit engine, started at launch so its platform task runner is initializing
  // well before any FlutterViewController is shown (see SceneDelegate's deferred
  // presentation). This is the root fix for the ProMotion launch crash in
  // -[VSyncClient initWithTaskRunner:] (Flutter #183900).
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
