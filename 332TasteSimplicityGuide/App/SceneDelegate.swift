import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {return}
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UIHostingController(rootView: ContentView())
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        tap.cancelsTouchesInView = false
        tap.requiresExclusiveTouchType = false
        window?.addGestureRecognizer(tap)
        window?.makeKeyAndVisible()
    }

    @objc private func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        guard let root = window else { return }
        let point = gesture.location(in: root)
        var node = root.hitTest(point, with: nil)
        while let current = node {
            if current is UITextField || current is UITextView {
                return
            }
            node = current.superview
        }
        root.endEditing(true)
    }
}
