import Flutter
import UIKit

// Standard framework-managed scene delegate — the `flutter create` default for
// this SDK. FlutterSceneDelegate instantiates the FlutterViewController from
// Main.storyboard (see Info.plist UISceneStoryboardFile=Main) as the window's
// ROOT view controller, backed by the implicit engine created in AppDelegate.
//
// This is deliberately empty. The previous version hand-rolled a pre-warmed
// FlutterEngine and hosted the FlutterViewController as a CHILD of a wrapper
// controller — which stopped the camera's external texture from compositing
// (black scanner) and made SafeArea report a 0 top inset. Letting the framework
// own the engine + root VC is what fixes both. Plugin registration and the push
// MethodChannel now live in AppDelegate.didInitializeImplicitFlutterEngine.
class SceneDelegate: FlutterSceneDelegate {
}
