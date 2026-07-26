import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

// Minimal app delegate. The Flutter engine + plugin registration now live in the
// SceneDelegate (the official iOS-26 UIScene pattern for an explicit engine with
// no storyboard). See SceneDelegate.swift.
@main
@objc class AppDelegate: FlutterAppDelegate {
  // Last APNs registration outcome, surfaced to Dart over the push MethodChannel
  // (SceneDelegate) so /push/debug can show whether THE DEVICE ever registered
  // with Apple:
  //   "pending"    — iOS hasn't called back yet
  //   "ok:<len>"   — APNs issued a device token (len bytes)
  //   "fail:<why>" — registration failed (classic cause: the App ID is missing
  //                  the Push Notifications capability, or the signing profile
  //                  doesn't include it — no code change fixes that).
  static var apnsStatus: String = "pending"

  // If the APNs callback ever beats Firebase configuration (possible when iOS
  // re-delivers a cached token during launch, before Dart runs initializeApp),
  // stash the token and let SceneDelegate flush it once Firebase is up —
  // Messaging.messaging() asserts a configured FirebaseApp.
  static var pendingApnsToken: Data?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required by flutter_local_notifications so scheduled reminders present
    // correctly (incl. while the app is in the foreground on iOS 10+).
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Hand the APNs device token to Firebase Cloud Messaging EXPLICITLY.
  //
  // Why this is required here (the push bug): this app registers its Flutter
  // plugins on the explicit engine inside SceneDelegate, NOT on the AppDelegate.
  // But iOS always delivers the APNs device-token callback to the *app*
  // delegate — which has no knowledge of the engine-registered firebase_messaging
  // plugin, so the token never reached FCM on its own. Setting it directly on the
  // Messaging singleton closes that gap. (Registration itself is now triggered
  // explicitly from Dart via the push MethodChannel — see SceneDelegate — because
  // the plugin's auto-registration wasn't firing under the explicit-engine setup,
  // so getAPNSToken() stayed null and the device never registered for push.)
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    AppDelegate.apnsStatus = "ok:\(deviceToken.count)"
    AppDelegate.applyApnsToken(deviceToken)
    super.application(
      application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // APNs registration failed. Record why so /push/debug can distinguish a code
  // problem (registration never triggered) from an Apple-portal / provisioning
  // problem (registration triggered but rejected).
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    AppDelegate.apnsStatus = "fail:\(error.localizedDescription)"
    super.application(
      application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Set the APNs token on FCM, but only once Firebase is configured; otherwise
  // stash it for SceneDelegate to flush after the engine + Firebase are up.
  static func applyApnsToken(_ token: Data) {
    if FirebaseApp.app() != nil {
      Messaging.messaging().apnsToken = token
      pendingApnsToken = nil
    } else {
      pendingApnsToken = token
    }
  }
}
