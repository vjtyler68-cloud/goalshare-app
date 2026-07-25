import Flutter
import UIKit
import UserNotifications
import FirebaseMessaging

// Minimal app delegate. The Flutter engine + plugin registration now live in the
// SceneDelegate (the official iOS-26 UIScene pattern for an explicit engine with
// no storyboard). See SceneDelegate.swift.
@main
@objc class AppDelegate: FlutterAppDelegate {
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
  // plugins on the explicit engine inside SceneDelegate
  // (`GeneratedPluginRegistrant.register(with: flutterEngine)`), NOT on the
  // AppDelegate. But iOS always delivers the APNs device-token callback to the
  // *app* delegate — which has no knowledge of the engine-registered
  // firebase_messaging plugin, so the token never reached FCM. With no APNs
  // token, FCM never issues a registration token, the device never registers
  // for push, and no notification is ever delivered (Firestore/chat kept
  // working because they don't use APNs). Setting it directly on the Messaging
  // singleton closes that gap.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(
      application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
