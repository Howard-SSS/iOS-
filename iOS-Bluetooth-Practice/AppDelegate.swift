//
//  AppDelegate.swift
//  iOS-Bluetooth-Practice
//
//  Created by Howard-Zjun on 2024/03/06.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UICollectionViewDelegateFlowLayout {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let navi = UINavigationController(rootViewController: ViewController())
        navi.navigationBar.isHidden = true
        window.rootViewController = navi
        window.makeKeyAndVisible()
        self.window = window
        return true
        
    }
}

