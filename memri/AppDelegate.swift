//
//  AppDelegate.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		CrashObserver.shared.onLaunch()
		
		// Override point for customization after application launch.
        MapHelper.shared.onAppStart()
        
        // This works for normal app startup and background location event startups (testing for the launch "location" key not necessary)
        SensorManager.shared.onAppStart()
        
        return true
    }
	
	func applicationWillTerminate(_ application: UIApplication) {
		CrashObserver.shared.onTerminate()
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
}


class CrashObserver {
	static var shared = CrashObserver()
	
	var didCrashLastTime: Bool
	
	static let defaultsKey = "memri.crashObserver.didCrash"
	
	private init() {
		didCrashLastTime = (UserDefaults.standard.value(forKey: CrashObserver.defaultsKey) as? Bool) ?? false
	}
	
	func onLaunch() {
		// This will be overridden before the app launches again - ie. assume crash until we record otherwise
		UserDefaults.standard.setValue(true, forKey: CrashObserver.defaultsKey)
	}
	
	func onTerminate() {
		// Called when the app closes through normal methods (ie. not a crash)
		UserDefaults.standard.setValue(false, forKey: CrashObserver.defaultsKey)
	}
}
