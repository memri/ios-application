//
// Installer.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift
//import XCTest

public class Installer: ObservableObject {
    @Published var isInstalled: Bool = false
    @Published var debugMode: Bool = false

    private var readyCallback: () throws -> Void = {}

    init() {
        debugMode = CrashObserver.shared.didCrashLastTime
    }

    public func await(_ context:MemriContext, _ callback: @escaping () throws -> Void) throws {
        let authAtStartup = Settings.shared.get("device/auth/atStartup", type: Bool.self) ?? true
        
        func check() {
            if let _ = LocalSetting.get("memri/installed") {
                self.isInstalled = true
                
                if !self.debugMode {
                    self.ready(context)
                }
            }
        }
        
        self.readyCallback = callback
        
        if authAtStartup {
            Authentication.authenticateOwner { error in
                if let error = error {
                    fatalError("Unable to authenticate \(error)") // TODO report to user allow retry
                }
                    
                check()
            }
        }
        else {
            check()
        }
    }

    public func ready(_ context:MemriContext) {
        isInstalled = true

        LocalSetting.set("memri/installed", Date().description)

        do {
            try readyCallback()
            readyCallback = {}
            context.scheduleUIUpdate(immediate: true)
        }
        catch {
            debugHistory.error("\(error)")
        }
    }
    
    public func installLocalAuthForNewPod(
        _ context:MemriContext,
        areYouSure: Bool,
        host: String,
        _ callback: @escaping (Error?) -> Void
    ) {
        
        DatabaseController.deleteDatabase { error in
            do {
                if let error = error {
                    throw "\(error)"
                }
                
                _ = try Authentication.createRootKey(areYouSure: areYouSure)
                    
                self.installDefaultDatabase(context) { error in
                    if let error = error {
                        // TODO Error Handling - show to the user
                        debugHistory.warn("\(error)")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if let error = error {
                            // TODO Error Handling - show to the user
                            debugHistory.warn("\(error)")
                            return
                        }
                        
                        do {
                            print("KEY: \(try Authentication.getPublicRootKeySync().hexEncodedString(options: .upperCase))")
                            
                            try Authentication.createOwnerAndDBKey()
                        }
                        catch { callback(error) }
                        
                        Settings.shared.set("user/pod/host", host)
                        self.ready(context)
                        context.cache.sync.schedule()
                        
                        callback(nil)
                    }
                }
            }
            catch {
                callback(error)
            }
        }
    }
    
    public func installLocalAuthForExistingPod(
        _ context:MemriContext,
        areYouSure: Bool,
        host: String,
        privateKey: String,
        publicKey: String,
        dbKey: String,
        _ callback: @escaping (Error?) -> Void
    ) {
        
        DatabaseController.deleteDatabase { error in
            do {
                if let error = error {
                    throw "Unable to authenticate: \(error)"
                }
                
                context.podAPI.host = host
            
                _ = try Authentication.createRootKey(areYouSure: areYouSure)
                
                context.cache.sync.syncAllFromPod { // TODO error handling
                    Settings.shared.set("user/pod/host", host)
                    
                    do {
                        try Authentication.setOwnerAndDBKey(
                            privateKey: privateKey,
                            publicKey: publicKey,
                            dbKey: dbKey
                        )
                    }
                    catch { callback(error) }
                    
                    self.ready(context)
                    
                    callback(nil)
                }
            }
            catch {
                callback(error)
            }
        }
    }
    
    #if targetEnvironment(simulator)
    public var testRoot: RootContext? = nil
    public func installForTesting(boot:Bool = true,
                                  _ callback:@escaping (Error?, RootContext?) throws -> Void) {
        do {
            if let testRoot = testRoot {
                try callback(nil, testRoot)
                return
            }
            
            DatabaseController.realmTesting = true
            Settings.shared = Settings()
            
            testRoot = try RootContext(name: "")
            
            try await (testRoot!) {
                if boot {
                    self.testRoot!.boot(isTesting: true) { error in
                        if let error = error {
                            debugHistory.error("\(error)")
                            do { try callback(error, nil) }
                            catch { debugHistory.error("\(error)") }
                            return
                        }
                        
                        do { try callback(nil, self.testRoot) }
                        catch { debugHistory.error("\(error)") }
                    }
                }
                else {
                    do { try callback(nil, self.testRoot) }
                    catch { debugHistory.error("\(error)") }
                }
            }
            
            if let _ = LocalSetting.get("memri/installed") {
                isInstalled = true
            }
            
            if isInstalled {
                ready(testRoot!)
            }
            else {
                clearDatabase(testRoot!) { error in
                    if let error = error {
                        debugHistory.error("\(error)")
                        do { try callback(error, nil) }
                        catch { debugHistory.error("\(error)") }
                        return
                    }
                    
                    self.installDefaultDatabase(self.testRoot!) { error in
                        if let error = error {
                            debugHistory.error("\(error)")
                            do { try callback(error, nil) }
                            catch { debugHistory.error("\(error)") }
                            return
                        }
                        
                        self.ready(self.testRoot!)
                    }
                }
            }
        }
        catch {
            do { try callback(error, nil) }
            catch { debugHistory.error("\(error)") }
        }
    }
    #endif
    
    public func handleInstallError(error:Error?) {
        // TODO ERror handling - report to the user
        debugHistory.warn("\(error!)")
    }

    public func installDefaultDatabase(_ context: MemriContext,
                                       _ callback:@escaping (Error?) -> Void) {
        debugHistory.info("Installing defaults in the database")
        install(context, dbName: "default_database", callback)
    }

    public func installDemoDatabase(_ context: MemriContext,
                                    _ callback:@escaping (Error?) -> Void) {
        debugHistory.info("Installing demo database")
        install(context, dbName: "demo_database", callback)
    }

    private func install(_ context: MemriContext, dbName: String,
                         _ callback:@escaping (Error?) -> Void) {
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
        ready(context)
    }

    public func clearDatabase(_ context: MemriContext,
                              _ callback:@escaping (Error?) -> Void) {
        DatabaseController.current(write:true, error:callback) { realm in
            realm.deleteAll()
            
            Cache.cacheUIDCounter = -1

            self.isInstalled = false
            self.debugMode = false
            context.scheduleUIUpdate(immediate: true)
            
            callback(nil)
        }
    }

    public func clearSessions(_ context: MemriContext,
                              _ callback:@escaping (Error?) -> Void) {
        
        DatabaseController.current(write:true, error:callback) { _ in
            
            // Create a new default session
            context.sessions.install(context) { error in
                if let error = error {
                    // TODO Error Handling - show to the user
                    debugHistory.warn("\(error)")
                    callback(error)
                    return
                }
                
                self.debugMode = false
                self.ready(context)
                callback(nil)
            }
        }
    }
}
