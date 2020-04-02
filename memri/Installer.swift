//
//  Installer.swift
//  memri
//
//  Created by Ruben Daniels on 4/2/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class Installer {
    private var realm:Realm
    
    init(_ rlm:Realm) {
        realm = rlm
    }
    
    public func installIfNeeded(_ main:Main, _ callback: () -> Void) {
        
        let installLogs = realm.objects(LogItem.self).filter("action = 'install'")
        
        if (installLogs.count == 0) {
            // Load default objects in database
            
            // Load default settings in database
            main.settings.install()
            
            // Load default views in database
            
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
