//
//  LocalSettings.swift
//  memri
//
//  Created by Ruben Daniels on 7/26/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class LocalSetting:Object {
    @objc var key: String? = nil
    @objc var value: String? = nil
    
    /// Primary key used in the realm database of this Item
    override public static func primaryKey() -> String? {
        "key"
    }
    
    public class func set(_ key:String, _ value:String) {
        DatabaseController.current(write:true) { realm in
            if let setting = realm.object(ofType: LocalSetting.self, forPrimaryKey: key) {
                setting.value = value
            }
            else {
                realm.create(LocalSetting.self, value: ["key": key, "value": value])
            }
        }
    }
    
    public class func get(_ key:String) -> String? {
        DatabaseController.current(write:true) { realm in
            if let setting = realm.object(ofType: LocalSetting.self, forPrimaryKey: key) {
                return setting.value
            }
            return nil
        }
    }
}
