//
// Installer.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift

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
                self.installDefaultDatabase(context)
                Settings.shared.set("user/pod/host", host)
                
                self.ready()
                context.cache.sync.schedule()
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
                context.cache.sync.syncAllFromPod {
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
                    try self.testRoot!.boot(isTesting: true)
                }
            }
            
            if let _ = LocalSetting.get("memri/installed") {
                isInstalled = true
            }
            
            if isInstalled { ready() }
            else {
                clearDatabase(testRoot!)
                installDefaultDatabase(testRoot!)
            }
        }
        
        return testRoot
    }

    public func installDefaultDatabase(_ context: MemriContext) {
        debugHistory.info("Installing defaults in the database")

        do { try install(context, dbName: "default_database") }
        catch {
            debugHistory.error("Unable to load: \(error)")
        }
    }

    public func installDemoDatabase(_ context: MemriContext) {
        debugHistory.info("Installing demo database")

        do { try install(context, dbName: "demo_database") }
        catch {
            debugHistory.error("Unable to load: \(error)")
        }
    }

    private func install(_ context: MemriContext, dbName: String) throws {
        // Load default objects in database
        try context.cache.install(dbName)

        // Load default views in database
        context.views.context = context
        try context.views.install()

        // Load default sessions in database
        try context.sessions.install(context)

        // Installation complete
        LocalSetting.set("memri/installed", Date().description)
    }

    public func continueAsNormal(_ context: MemriContext) {
        debugMode = false
        ready()
        context.scheduleUIUpdate(immediate: true)
    }

    public func clearDatabase(_ context: MemriContext) {
        DatabaseController.writeSync { realm in
            realm.deleteAll()
        }
        
        Cache.cacheUIDCounter = -1

        isInstalled = false
        debugMode = false
        context.scheduleUIUpdate(immediate: true)
    }

    public func clearSessions(_ context: MemriContext) {
        DatabaseController.writeSync { _ in
            // Create a new default session
            try context.sessions.install(context)
        }

        debugMode = false
        ready()
    }
}
