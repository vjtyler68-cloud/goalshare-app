import Flutter
import UIKit

// Minimal app delegate. The Flutter engine + plugin registration now live in the
// SceneDelegate (the official iOS-26 UIScene pattern for an explicit engine with
// no storyboard). See SceneDelegate.swift.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
