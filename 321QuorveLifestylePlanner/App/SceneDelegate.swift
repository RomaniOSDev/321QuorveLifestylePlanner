import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let rootView = ContentView()
        let hostingController = UIHostingController(rootView: rootView)
        let background = UIColor(named: "AppBackground") ?? UIColor(red: 0, green: 0.216, blue: 0.447, alpha: 1)
        hostingController.view.backgroundColor = background

        window = UIWindow(windowScene: windowScene)
        window?.backgroundColor = background
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
