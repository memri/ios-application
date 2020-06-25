//
//  SettingCollection.swift
//  memri
//
//  Created by Ruben Daniels on 6/25/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

extension SettingCollection {
    
    /// get setting for given path
    /// - Parameter path: path for the setting
    /// - Returns: setting value
    public func getSetting<T:Decodable>(_ path:String) throws -> T? {
        let needle = self.type + (path.first == "/" ? "" :"/") + path
        
        let item = self.settings.filter("key = '\(needle)'").first
        if let item = item {
            let output:T? = try unserialize(item.json)
            return output
        }
        else {
            return nil
        }
    }
    
    /// Get setting as String for given path
    /// - Parameter path: path for the setting
    /// - Returns: setting value as String
    public func getSettingString(_ path:String) throws -> String {
        return try getSetting(path) ?? ""
    }
    
    /// Sets a setting to the value passed.Also responsible for saving the setting to the permanent storage
    /// - Parameters:
    ///   - path: path of the setting
    ///   - value: setting Value
    public func setSetting(_ path:String, _ value:AnyCodable) throws {
        let key = self.type + (path.first == "/" ? "" :"/") + path
        
        func saveState() throws {
            let s = Setting(value: [
                "key": key,
                "json": try serialize(value),
                "memriID": "setting:\(self.type):\(key)"
            ])
            
            realmWriteIfAvailable(realm) {
                if let realm = realm {
                    realm.add(s, update: .modified)
                }
            }
            if settings.index(of: s) == nil { settings.append(s) }
            
            if let syncState = syncState {
                syncState.actionNeeded = "update"
            }
            else{
                debugHistory.error("No syncState available for settings")
            }
        }
        
        realmWriteIfAvailable(realm) {
            try saveState()
        }
    }
}
