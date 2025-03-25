import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene).apply {
            $0.rootViewController = {
                return ViewController()
            }()
            $0.makeKeyAndVisible()
        }
        self.window = window
        
        print("SceneDelegate: willConnectTo")
    }
}

extension UIWindow {
    @discardableResult
    func apply(_ closure: (UIWindow) -> Void) -> UIWindow {
        closure(self)
        return self
    }
}
