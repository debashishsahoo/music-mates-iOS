//
//  SceneDelegate.swift
//  MusicMates
//
//  Created by Debashish Sahoo on 30/4/2023.
//
//  References:
//  "How to transition from login screen to tab bar controller": https://fluffy.es/how-to-transition-from-login-screen-to-tab-bar-controller/

import UIKit
import Firebase
import FirebaseFirestoreSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    var authController: Auth?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        authController = Auth.auth()
        let isLoggedIn = authController?.currentUser != nil
//        let isLoggedin = UserDefaults.standard.bool(forKey: "isLoggedinKey")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if isLoggedIn {
            // Set the tab bar controller as the root view controller
            let mainTabBarController = storyboard.instantiateViewController(identifier: "TabBarController")
            window?.rootViewController = mainTabBarController
        } else {
            // Set the intial login navigation controller as the root view controller
            let loginNavController = storyboard.instantiateViewController(identifier: "InitialNavController")
            window?.rootViewController = loginNavController
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    // Function to change root view controller on login/logout to the tab bar controller/initial login navigation controller
    func changeRootViewController(_ vc: UIViewController, animated: Bool = true) {
        guard let window = self.window else {
            return
        }
        
        window.rootViewController = vc
        
        // Add Animation
        UIView.transition(with: window,
                          duration: 0.9,
                          options: [.transitionCurlUp],
                          animations: nil,
                          completion: nil)
    }

}

