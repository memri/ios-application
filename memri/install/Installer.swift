//
//  Installer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class Installer {
    private var realm:Realm
    
    init(_ rlm:Realm) {
        realm = rlm
    }
    
    public func install(_ main:MemriContext) {
        
    }
    
    public func installIfNeeded(_ main:MemriContext, _ callback: () throws -> Void) throws {
        
        let installLogs = realm.objects(AuditItem.self).filter("action = 'install'")
        
        // TODO Refactor: check version??
        if (installLogs.count == 0) {
            print("Installing defaults in the database")
            
            // Load default navigation items in database
            main.navigation.install()
            
            // Load default objects in database
            main.cache.install()
            
            // Load default settings in database
            main.settings.install()
            
            // Load default views in database
            main.views.main = main
            try main.views.install()
            
            // Load default sessions in database
            try main.sessions.install(main)
            
            // Installation complete
            try realm.write {
                realm.create(AuditItem.self, value: [
                    "action": "install",
                    "date": Date(),
                    "contents": serialize(["version": "1.0"])
                ])
            }
        }
        
        try callback()
    }
}
