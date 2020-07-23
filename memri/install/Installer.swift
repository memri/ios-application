//
//  Installer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftUI

public class Installer : ObservableObject {
    
    @Published var isInstalled:Bool = false
    @Published var debugMode:Bool = false
    
    private var readyCallback: () throws -> Void = {}

	init() {
        let realm = DatabaseController.getRealm()
        if let _ = realm.object(ofType: AuditItem.self, forPrimaryKey: -2) {
            isInstalled = true
        }
        debugMode = CrashObserver.shared.didCrashLastTime
	}
    
    public func await(_ callback: @escaping () throws -> Void) throws {
        if isInstalled {
            try callback()
            return
        }
        
        readyCallback = callback
    }
    
    public func ready() {
        isInstalled = true
        
        do {
            try readyCallback()
            readyCallback = {}
        }
        catch let error {
            debugHistory.error("\(error)")
        }
    }
    
	public func installDefaultDatabase(_ context: MemriContext) {
        debugHistory.info("Installing defaults in the database")
        
        do { try install(context, dbName: "default_database") }
        catch let error {
            debugHistory.error("Unable to load: \(error)")
        }
        
    }
    
    public func installDemoDatabase(_ context: MemriContext) {
        debugHistory.info("Installing demo database")
        
        do { try install(context, dbName: "demo_database") }
        catch let error {
            debugHistory.error("Unable to load: \(error)")
        }
    }
    
    private func install(_ context: MemriContext, dbName:String) throws {
        // Load default objects in database
        try context.cache.install(dbName)

        // Load default views in database
        context.views.context = context
        try context.views.install()

        // Load default sessions in database
        try context.sessions.install(context)

        // Installation complete
        DatabaseController.writeSync { realm in
            _ = realm.create(AuditItem.self, value: [
                "uid": -2,
                "action": "install",
                "dateCreated": Date(),
                "contents": try serialize(["version": "1.0"]),
            ])
        }
        
        ready()
    }
    
    public func clearDatabase(_ context: MemriContext) {
        DatabaseController.writeSync { realm in
            realm.deleteAll()
        }
        
        isInstalled = false
    }
    
    public func clearSessions(_ context: MemriContext) {
        DatabaseController.writeSync { realm in
            // Create a new default session
            try context.sessions.install(context)
        }
        
        debugMode = false
    }
}

struct SetupWizard: View {
    @EnvironmentObject var context: MemriContext
    
    @State var host:String = "http://localhost:3030"
    @State var username:String = ""
    @State var password:String = ""

    var body: some View {
        NavigationView {
            Form {
                if !context.installer.isInstalled {
                    Text("Setup Wizard")
                        .font(.system(size: 22, weight: .bold))
                    
                    Section (
                        header: Text("Connect to a pod")
                    ) {
                        NavigationLink(destination: Form {
                            Section(
                                header: Text("Pod Connection"),
                                footer: Text("Never give out these details to anyone")
                                    .font(.system(size: 11, weight: .regular))
                            ) {
                                HStack {
                                    Text("Host:")
                                        .frame(width: 100, alignment: .leading)
                                    MemriTextField(value: $host)
                                }
                                HStack {
                                    Text("Username:")
                                        .frame(width: 100, alignment: .leading)
                                    MemriTextField(value: $username)
                                }
                                HStack {
                                    Text("Password:")
                                        .frame(width: 100, alignment: .leading)
                                    SecureField("Password", text: $password)
                                }
                                HStack {
                                    Button(action: {
                                        if self.host != "" {
//                                            self.context.installer.clearDatabase(self.context)
                                            self.context.installer.installDefaultDatabase(self.context)
                                            Settings.shared.set("user/pod/host", self.host)
                                            Settings.shared.set("user/pod/username", self.username)
                                            Settings.shared.set("user/pod/password", self.password)
                                            self.context.cache.sync.schedule()
                                        }
                                    }) {
                                        Text("Connect")
                                    }
                                }
                            }
                        }) {
                            Text("Connect to a new pod")
                        }
                        NavigationLink(destination: Form {
                            Section(
                                header: Text("Pod Connection"),
                                footer: Text("Never give out these details to anyone")
                                    .font(.system(size: 11, weight: .regular))
                            ) {
                                HStack {
                                    Text("Host:")
                                        .frame(width: 100, alignment: .leading)
                                    MemriTextField(value: $host)
                                }
                                HStack {
                                    Text("Username:")
                                        .frame(width: 100, alignment: .leading)
                                    MemriTextField(value: $username)
                                }
                                HStack {
                                    Text("Password:")
                                        .frame(width: 100, alignment: .leading)
                                    SecureField("Password", text: $password)
                                }
                                HStack {
                                    Button(action: {
                                        if self.host != "" {
                                            self.context.podAPI.host = self.host
                                            self.context.podAPI.username = self.username
                                            self.context.podAPI.password = self.password
                                            
                                            self.context.cache.sync.syncAllFromPod() {
                                                Settings.shared.set("user/pod/host", self.host)
                                                Settings.shared.set("user/pod/username", self.username)
                                                Settings.shared.set("user/pod/password", self.password)
                                                self.context.installer.ready()
                                            }
                                        }
                                    }) {
                                        Text("Connect")
                                    }
                                }
                            }
                        }) {
                            Text("Connect to an existing pod")
                        }
                    }
                    Section (
                        header: Text("Or use Memri locally")
                    ) {
                        Button(action: {
                            self.context.settings.set("user/pod/host", "")
                            self.context.installer.installDefaultDatabase(self.context)
                        }) {
                            Text("Use memri without a pod")
                        }
                        Button(action: {
                            self.context.settings.set("user/pod/host", "")
                            self.context.installer.installDemoDatabase(self.context)
                        }) {
                            Text("Play around with the DEMO database")
                        }
                    }
                }
                if context.installer.isInstalled && context.installer.debugMode {
                    Text("Recovery Wizard")
                        .font(.system(size: 22, weight: .bold))
                    
                    Section (
                        header: Text("Memri crashed last time. What would you like to do?")
                    ) {
                        Button(action: {
                            self.context.installer.debugMode = false
                        }) {
                            Text("Continue as normal)")
                        }
                        Button(action: {
                            self.context.installer.clearDatabase(self.context)
                        }) {
                            Text("Delete the local database and start over")
                        }
                        Button(action: {
                            self.context.installer.clearSessions(self.context)
                        }) {
                            Text("Clear the session history (to recover from an issue)")
                        }
                    }
                }
            }
        }
    }
}
