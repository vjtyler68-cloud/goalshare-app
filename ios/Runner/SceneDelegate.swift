import Flutter
import UIKit

// A plain UIWindowSceneDelegate (NOT a FlutterSceneDelegate subclass). It builds the
// window and a FlutterViewController backed by the EXPLICIT engine created in AppDelegate,
// so the engine/task-runner is already running before the view controller loads.
// (Subclassing FlutterSceneDelegate re-triggers the implicit-engine crash, so we don't.)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)

    let engine = (UIApplication.shared.delegate as? AppDelegate)?.flutterEngine
    let controller: UIViewController
    if let engine = engine {
      controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    } else {
      // Fallback: implicit engine (should not happen, but never leave a nil root).
      controller = FlutterViewController(project: nil, nibName: nil, bundle: nil)
    }

    window.rootViewController = controller
    self.window = window
    window.makeKeyAndVisible()
  }
}
