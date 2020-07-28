//
// Installer.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift
import XCTest

public class Installer: ObservableObject {
    @Published var isInstalled: Bool = false
    @Published var debugMode: Bool = false

    private var readyCallback: () throws -> Void = {}

    init() {
        if let _ = LocalSetting.get("memri/installed") {
            isInstalled = true
        }
        debugMode = CrashObserver.shared.didCrashLastTime
    }

    public func await(_ callback: @escaping () throws -> Void) throws {
        if isInstalled && !debugMode {
            try callback()
            return
        }

        readyCallback = callback
    }

    public func ready() {
        isInstalled = true

        LocalSetting.set("memri/installed", Date().description)

        do {
            try readyCallback()
            readyCallback = {}
        }
        catch {
            debugHistory.error("\(error)")
        }
    }
    
    public func installLocalAuthForNewPod(
        _ context:MemriContext,
        areYouSure: Bool,
        host: String
    ) {
//        self.context.installer.clearDatabase(self.context)
        
        Authentication.installRootKey(areYouSure: areYouSure) { error in
            guard error == nil else {
                debugHistory.error("\(error!)") // TODO: show this to the user
                return
            }
            
            Authentication.generateOwnerAndDBKey { error in
                if let error = error {
                    // TODO Error Handling - show to the user
                    debugHistory.warn("\(error)")
                    return
                }
                
                self.installDefaultDatabase(context) { error in
                    if let error = error {
                        // TODO Error Handling - show to the user
                        debugHistory.warn("\(error)")
                        return
                    }
                    
                    Settings.shared.set("user/pod/host", host)
                    self.ready()
                    context.cache.sync.schedule()
                }
            }
        }
    }
    
    public func installLocalAuthForExistingPod(
        _ context:MemriContext,
        areYouSure: Bool,
        host: String,
        ownerKey: String,
        databaseKey: String
    ) {
        context.podAPI.host = host
        
        Authentication.installRootKey(areYouSure: areYouSure) { error in
            guard error == nil else {
                debugHistory.error("\(error!)") // TODO: show this to the user
                return
            }
            
            Authentication.setOwnerAndDBKey(
                ownerKey: ownerKey,
                databaseKey: databaseKey
            ) { error in
                if let error = error {
                    // TODO Error Handling - show to the user
                    debugHistory.warn("\(error)")
                    return
                }
                
                context.cache.sync.syncAllFromPod { // TODO error handling
                    Settings.shared.set("user/pod/host", host)
                    self.ready()
                }
            }
        }
    }
    
    public var testRoot: RootContext? = nil
    public func installForTesting(boot:Bool = true) throws -> RootContext? {
        if testRoot == nil {
            DatabaseController.realmTesting = true
            Settings.shared = Settings()
            
            testRoot = try RootContext(name: "")
            
            try await {
                if boot {
                    self.testRoot!.boot(isTesting: true) { error in
                        if let error = error {
                            XCTFail("\(error)")
                        }
                    }
                }
            }
            
            if let _ = LocalSetting.get("memri/installed") {
                isInstalled = true
            }
            
            if isInstalled { ready() }
            else {
                clearDatabase(testRoot!)
                installDefaultDatabase(testRoot!) { error in
                    if let error = error {
                        XCTFail("\(error)")
                    }
                }
            }
        }
        
        return testRoot
    }
    
    public func handleInstallError(error:Error?) {
        // TODO ERror handling - report to the user
        debugHistory.warn("\(error!)")
    }

    public func installDefaultDatabase(_ context: MemriContext,
                                       _ callback:((Error?) -> Void)? = nil) {
        debugHistory.info("Installing defaults in the database")
        install(context, dbName: "default_database", callback ?? handleInstallError)
    }

    public func installDemoDatabase(_ context: MemriContext,
                                    _ callback:((Error?) -> Void)? = nil) {
        debugHistory.info("Installing demo database")
        install(context, dbName: "demo_database", callback ?? handleInstallError)
    }

    private func install(_ context: MemriContext, dbName: String, _ callback:@escaping (Error?) -> Void) {
        do {
            // Load default objects in database
            try context.cache.install(dbName) { error in
                
                if let error = error {
                    callback(error)
                    return
                }

                // Load default views in database
                context.views.context = context
                context.views.install { error in
                    
                    if let error = error {
                        callback(error)
                        return
                    }

                    // Load default sessions in database
                    context.sessions.install(context) { error in
                        if let error = error {
                            callback(error)
                            return
                        }
                        
                        // Installation complete
                        LocalSetting.set("memri/installed", Date().description)
                        
                        callback(nil)
                    }
                }
            }
        }
        catch {
            callback(error)
        }
    }

    public func continueAsNormal(_ context: MemriContext) {
        debugMode = false
        ready()
        context.scheduleUIUpdate(immediate: true)
    }

    public func clearDatabase(_ context: MemriContext) {
        DatabaseController.current(write:true) { realm in
            realm.deleteAll()
        }
        
        Cache.cacheUIDCounter = -1

        isInstalled = false
        debugMode = false
        context.scheduleUIUpdate(immediate: true)
    }

    public func clearSessions(_ context: MemriContext) {
        DatabaseController.current(write:true) { _ in
            // Create a new default session
            context.sessions.install(context) { error in
                if let error = error {
                    // TODO Error Handling - show to the user
                    debugHistory.warn("\(error)")
                    return
                }
                
                self.debugMode = false
                self.ready()
            }
        }
    }
}
