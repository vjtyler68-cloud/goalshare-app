import Flutter
import UIKit

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
