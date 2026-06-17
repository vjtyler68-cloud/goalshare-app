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

    // STEP 1: show a plain placeholder (GoalShare red) immediately. Crucially this
    // does NOT load a FlutterViewController during the launch call stack — loading
    // it there runs -[FlutterViewController viewDidLoad] before the engine's platform
    // task runner is ready, which null-derefs in createTouchRateCorrectionVSyncClientIfNeeded
    // on 120Hz ProMotion devices (Flutter #183900).
    let placeholder = UIViewController()
    placeholder.view.backgroundColor = UIColor(red: 0.84, green: 0.18, blue: 0.18, alpha: 1.0)
    window.rootViewController = placeholder
    self.window = window
    window.makeKeyAndVisible()

    // STEP 2: create the FlutterViewController one run-loop turn LATER. By now the
    // explicit engine (started in AppDelegate.didFinishLaunching) has finished
    // initializing its task runner, so viewDidLoad / the VSync setup is safe.
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let engine = (UIApplication.shared.delegate as? AppDelegate)?.flutterEngine else {
        return
      }
      let flutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
      self.window?.rootViewController = flutterViewController
    }
  }
}
