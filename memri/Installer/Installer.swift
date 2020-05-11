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
    
    public func install(_ main:Main) {
        
    }
    
    public func installIfNeeded(_ main:Main, _ callback: () -> Void) {
        
        let installLogs = realm.objects(LogItem.self).filter("action = 'install'")
        
        if (installLogs.count == 0) {
            print("Installing defaults in the database")
            
            // Load default navigation items in database
            main.navigation.install()
            
            // Load default objects in database
            main.cache.install()
            
            // Load default settings in database
            main.settings.install()
            
            // Load default views in database
            main.views.install()
            
            // Load default sessions in database
            main.sessions.install(main.realm)
            
            // Installation complete
            try! realm.write {
                realm.add(LogItem(value: [
                    "action": "install",
                    "date": Date(),
                    "contents": serialize(["version": "1.0"])]))
            }
        }
        
        callback()
    }
}
