import Flutter
import UIKit
import UserNotifications

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
}
