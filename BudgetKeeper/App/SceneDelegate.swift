import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: scene)
        let root: UIViewController
        if DataStore.shared.isPINSet {
            root = PINUnlockViewController()
        } else {
            root = OnboardingViewController()
        }
        window.rootViewController = root
        window.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: DataStore.shared.themeStyle) ?? .unspecified
        window.makeKeyAndVisible()
        self.window = window
    }
}

