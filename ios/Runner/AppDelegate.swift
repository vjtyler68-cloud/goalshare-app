import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

// Standard Flutter (3.41) implicit-engine app delegate — the `flutter create`
// default for this SDK.
//
// Why this replaced the old hand-rolled pre-warmed engine (the bug history):
// the camera preview is a Flutter EXTERNAL TEXTURE. Under the previous custom
// setup (an explicit FlutterEngine run() in SceneDelegate, hosting the
// FlutterViewController as a child view controller) those textures never
// composited — the scanner showed a black/blank preview even though the camera
// was running (run=true, perm=true, real frame size, no error). The same custom
// engine also made SafeArea report a 0 inset and stopped firebase_messaging's
// auto-registration from firing. Reverting to the framework-managed implicit
// engine fixes all three at once. Push is fully preserved: the APNs -> FCM
// bridge stays here, and the registration MethodChannel is recreated on the
// implicit engine in didInitializeImplicitFlutterEngine below.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Last APNs registration outcome, surfaced to Dart over the push channel
  // ("pending" / "ok:<len>" / "fail:<why>") for diagnostics.
  static var apnsStatus: String = "pending"

  // If the APNs callback beats Firebase configuration (iOS can re-deliver a
  // cached token during launch, before Dart runs initializeApp), stash the token
  // and flush it once Firebase is up — Messaging.messaging() asserts a configured
  // FirebaseApp.
  static var pendingApnsToken: Data?

  // Retained so its method-call handler stays alive for the app's lifetime.
  static var pushChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required by flutter_local_notifications so scheduled reminders present
    // correctly (incl. while the app is foregrounded on iOS 10+).
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Called by FlutterAppDelegate once the framework-managed (implicit) engine
  // exists. This is where plugins register now — replacing the old
  // GeneratedPluginRegistrant.register(with: flutterEngine) that ran in
  // SceneDelegate. We also (re)create the push MethodChannel on the same engine's
  // messenger so PushNotificationService keeps working unchanged.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GoalSharePush") {
      let channel = FlutterMethodChannel(
        name: "com.goal.share/push",
        binaryMessenger: registrar.messenger())
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
      AppDelegate.pushChannel = channel
    }
  }

  // iOS always delivers the APNs device-token callback to the app delegate, which
  // has no knowledge of the engine-registered firebase_messaging plugin — so hand
  // the token to FCM explicitly.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    AppDelegate.apnsStatus = "ok:\(deviceToken.count)"
    AppDelegate.applyApnsToken(deviceToken)
    super.application(
      application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // APNs registration failed — record why so diagnostics can distinguish a code
  // problem from an Apple-portal / provisioning problem.
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    AppDelegate.apnsStatus = "fail:\(error.localizedDescription)"
    super.application(
      application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Set the APNs token on FCM once Firebase is configured; otherwise stash it.
  static func applyApnsToken(_ token: Data) {
    if FirebaseApp.app() != nil {
      Messaging.messaging().apnsToken = token
      pendingApnsToken = nil
    } else {
      pendingApnsToken = token
    }
  }
}
