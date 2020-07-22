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

	init() {
        let realm = DatabaseController.getRealm()
        if let _ = realm.object(ofType: AuditItem.self, forPrimaryKey: -2) {
            isInstalled = true
        }
	}
    
    public func boot(_ context: MemriContext){
        try context.boot() {
            self.settingWatcher = context.settings.subscribe("device/sensors/location/track", type:Bool.self).sink {
                if let value = $0 as? Bool {
                    if value { SensorManager.shared.locationTrackingEnabledByUser() }
                    else { SensorManager.shared.locationTrackingDisabledByUser() }
                }
            }
        }
    }

	public func installDefaultDatabase(_ context: MemriContext, _ callback: () throws -> Void) throws {
        debugHistory.info("Installing defaults in the database")
        try install(context, dbName: "default_database")
        try callback()
    }
    
    public func installDemoDatabase(_ context: MemriContext, _ callback: () throws -> Void) throws {
        debugHistory.info("Installing demo database")
        try install(context, dbName: "demo_database")
        try callback()
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
        _ = try Cache.createItem(AuditItem.self, values: [
            "uid": -2,
            "action": "install",
            "dateCreated": Date(),
            "contents": try serialize(["version": "1.0"]),
        ])
        
        isInstalled = true
    }
    
    public func clearDatabase(_ context: MemriContext, _ callback: () throws -> Void) throws {
        DatabaseController.writeSync { realm in
            realm.deleteAll()
        }
    }
    
    public func clearSessions(_ context: MemriContext) throws {
        DatabaseController.writeSync { realm in
            guard let sessionState = try realm.object(
                ofType: CVUStateDefinition.self,
                forPrimaryKey: Cache.getDeviceID()
            ) else { return }
            
            // Create a backup of the session
            _ = try context.cache.duplicate(sessionState)
            
            // Delete old session
            context.cache.delete(sessionState)
            
            // Create a new default session
            try context.sessions.install(context)
        }
    }
}

struct SetupWizard: View {
    @EnvironmentObject var context: MemriContext

    var body: some View {
        VStack {
            if !context.installer.isInstalled {
                Text("What would you like to do?")
                Divider()
                Button(action: {}) {
                    Text("Connect to a new pod")
                }
                Divider()
                Button(action: {}) {
                    Text("Connect to an existing pod")
                }
                Divider()
                Button(action: {}) {
                    Text("Use memri without a pod")
                }
                Divider()
                Button(action: {}) {
                    Text("Use memri with a demo database")
                }
            }
            if context.installer.debugMode {
                Divider()
                Button(action: {}) {
                    Text("Delete the local database and start over")
                }
                Divider()
                Button(action: {}) {
                    Text("Clear the session history (to recover from an issue)")
                }
            }
        }
    }
}
