import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

// Official Flutter UIScene pattern for an EXPLICIT engine with NO storyboard, mirroring
// the Flutter SDK reference dev/integration_tests/ios_add2app_uiscene/native/
// SceneDelegate-FlutterSceneDelegate-MultiScene-NoStoryboard.swift.
//
// Why this shape matters (the bug history):
//  - Subclassing FlutterSceneDelegate + calling registerSceneLifeCycle(with:) + super.scene(...)
//    forwards the iOS scene lifecycle to the engine, so it KEEPS RUNNING. A plain
//    UIWindowSceneDelegate did not, so the app rendered one frame then FROZE.
//  - run() + register the plugins here (after the scene exists) -> a valid plugin registrar
//    (no connectivity_plus null-deref) and a ready platform task runner (no ProMotion
//    VSync launch crash, Flutter #183900).
class SceneDelegate: FlutterSceneDelegate {
  let flutterEngine = FlutterEngine(name: "goalshare_engine")
  // Retained so its method-call handler stays alive for the scene's lifetime.
  var pushChannel: FlutterMethodChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    window = UIWindow(windowScene: windowScene)

    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    self.registerSceneLifeCycle(with: flutterEngine)

    // Push registration bridge (the push fix). iOS only issues an APNs token
    // after the app explicitly calls registerForRemoteNotifications, and it must
    // be called on EVERY launch — not just the first permission grant. Under this
    // app's explicit-engine setup the firebase_messaging plugin's auto-trigger
    // wasn't firing, so getAPNSToken() stayed null and the device never
    // registered for push. Dart drives this from PushNotificationService AFTER
    // Firebase is configured, so the APNs callback always has a live Messaging
    // instance. Also lets Dart read back the registration outcome for diagnosis.
    let channel = FlutterMethodChannel(
      name: "com.goal.share/push",
      binaryMessenger: flutterEngine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "registerForRemoteNotifications":
        DispatchQueue.main.async {
          // Flush any APNs token that arrived before Firebase was configured.
          if let t = AppDelegate.pendingApnsToken, FirebaseApp.app() != nil {
            Messaging.messaging().apnsToken = t
            AppDelegate.pendingApnsToken = nil
          }
          UIApplication.shared.registerForRemoteNotifications()
        }
        result(true)
      case "getApnsStatus":
        result(AppDelegate.apnsStatus)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.pushChannel = channel

    let rootViewController = RootViewController(engine: flutterEngine)
    window?.rootViewController = rootViewController
    window?.makeKeyAndVisible()

    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}

// Hosts the FlutterViewController as a child view controller (the SDK's reference pattern).
class RootViewController: UIViewController {
  private let flutterEngine: FlutterEngine

  init(engine: FlutterEngine) {
    self.flutterEngine = engine
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let flutterViewController =
      FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    addChild(flutterViewController)
    flutterViewController.view.frame = view.bounds
    flutterViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(flutterViewController.view)
    flutterViewController.didMove(toParent: self)
  }
}
