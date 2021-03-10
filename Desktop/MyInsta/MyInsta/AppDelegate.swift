//
//  AppDelegate.swift
//  MyInsta
//
//  Created by 山下雄大 on 2020/11/24.
//

import UIKit
import NCMB

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        NCMB.setApplicationKey("6f4191b969668cfa944ef093b31115bb38a65e2e0487f2d8ae0eca7df23183ae", clientKey: "82c203c6191b9106442ecaa96717c4d8cd4a1c93c2b892dfa7136d8d4a962023")
        
        return true
    }
    
    
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    static var standard: AppDelegate {
      return UIApplication.shared.delegate as! AppDelegate
    }
    
    
    
}


