import Flutter
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)

    // STEP 1: plain placeholder first (no Flutter), so makeKeyAndVisible does NOT
    // load a FlutterViewController during the launch call stack — that would run
    // viewDidLoad before the engine's task runner is ready (ProMotion VSync crash,
    // #183900).
    let placeholder = UIViewController()
    placeholder.view.backgroundColor = UIColor(red: 0.84, green: 0.18, blue: 0.18, alpha: 1.0)
    window.rootViewController = placeholder
    self.window = window
    window.makeKeyAndVisible()

    // STEP 2: one run-loop turn later, the engine's task runner is ready. Build the
    // FlutterViewController on `flutterEngine`, then register plugins against THAT
    // SAME engine. Registering here (after the VC exists) means the engine's
    // Swift-plugin registrar bridge is materialized -> connectivity_plus gets a
    // valid (non-null) registrar -> no swift_getObjectType crash. And because we
    // register against the engine the VC uses, all plugin channels actually work.
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let engine = (UIApplication.shared.delegate as? AppDelegate)?.flutterEngine else {
        return
      }
      let flutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
      GeneratedPluginRegistrant.register(with: engine)
      self.window?.rootViewController = flutterViewController
    }
  }
}
