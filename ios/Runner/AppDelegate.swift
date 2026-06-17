import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Strongly held for the app's lifetime; shared with SceneDelegate.
  lazy var flutterEngine = FlutterEngine(name: "goalshare_engine")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Start the engine early so its platform task runner is initializing well
    // before any FlutterViewController loads (this is what fixes the ProMotion
    // VSync launch crash, #183900, together with the deferred VC in SceneDelegate).
    flutterEngine.run()

    // IMPORTANT: do NOT register plugins here. At didFinishLaunching there is no
    // scene/FlutterViewController yet, so the engine's Swift-plugin registrar
    // bridge is nil -> registering connectivity_plus would null-deref
    // (swift_getObjectType at 0x0). And register(with: self) would secretly bind
    // plugins to a separate auto-spawned engine. Registration happens in
    // SceneDelegate against THIS engine, after the FlutterViewController exists.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
