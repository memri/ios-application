//
// SceneDelegate.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Darwin
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var settingWatcher: AnyCancellable?

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        do {
            let context = try RootContext(name: "Memri GUI", key: "ABCDEF")
            let application = Application().environmentObject(context as MemriContext)

            try context.installer.await {
                try context.boot {
                    self.settingWatcher = context.settings.subscribe(
                        "device/sensors/location/track",
                        type: Bool.self
                    ).sink {
                        if let value = $0 as? Bool {
                            if value { SensorManager.shared.locationTrackingEnabledByUser() }
                            else { SensorManager.shared.locationTrackingDisabledByUser() }
                        }
                    }
                }
            }

            // Use a UIHostingController as window root view controller.
            guard let windowScene = scene as? UIWindowScene else { return }

            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: application)

            #if targetEnvironment(macCatalyst)
                if let titlebar = windowScene.titlebar {
                    titlebar.titleVisibility = .hidden
                    titlebar.toolbar = nil
                }
            #endif

            self.window = window
            window.makeKeyAndVisible()
        }
        catch {
            // TODO: Error Handling (show fatal error on screen)
            print(error)
            exit(1)
        }
    }

    func sceneDidDisconnect(_: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
