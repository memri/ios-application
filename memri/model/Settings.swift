//
//  settings.swift
//  memri
//
//  Created by Ruben Daniels on 4/1/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

/// This class stores the settings used in the memri app. Settings may include things like how to format dates, whether to show certain
/// buttons by default, etc.
public class Settings {
    /// Realm database object
    let realm:Realm
    /// Default settings
    var defaults:SettingCollection = SettingCollection()
    /// Device settings
    var device:SettingCollection = SettingCollection()
    /// User defined settings
    var user:SettingCollection = SettingCollection()
    
    /// Init settings with the relam database
    /// - Parameter rlm: realm database object
    init(_ realm:Realm) {
        self.realm = realm
    }
    
    /// Load all settings from the local realm database
    /// - Parameter callback: function that is called after completing loading the settings
    public func load(_ callback: () throws -> Void) throws {
        // TODO: This could probably be optimized, but lets first get familiar with the process
        
        let allSettings = realm.objects(SettingCollection.self)
        if (allSettings.count > 0) {
            for i in 0...allSettings.count - 1 {
                switch allSettings[i].type {
                    case "defaults": defaults = allSettings[i]
                    case "device": device = allSettings[i]
                    case "user": user = allSettings[i]
                    default:
                        print ("Error: Invalid settings found \(allSettings[i].type)")
                }
            }
        }
        else {
            print("Error: Settings are not initialized")
        }
        
        try callback()
    }
    
    
    /// Initialize SettingsCollection objects for default, device and user-settings. Populate them by reading the default settings from
    /// disk and updating the empty SettingCollections.
    public func install() {
        let defaults = SettingCollection(value: ["type": "defaults"])
        let device = SettingCollection(value: ["type": "device"])
        let user = SettingCollection(value: ["type": "user"])
        
        do {
            try realm.write() {
                realm.add(defaults, update: .modified)
                realm.add(device, update: .modified)
                realm.add(user, update: .modified)
            }
        }
        catch {
            print(error)
        }
        
        // Load default settings from disk
        do {
            let jsonData = try jsonDataFromFile("default_settings")
            let values = try MemriJSONDecoder.decode([String:AnyCodable].self, from: jsonData)
            for (key, value) in values {
                defaults.set(key, value)
            }
        }
        catch {
            print("Failed to install settings: \(error)")
        }
        
        device.set("/name", "iphone")
    }
    
    
    /// Get setting from path
    /// - Parameter path: path of the setting
    /// - Returns: setting value
    public func get<T:Decodable>(_ path:String) -> T? {
        let (collection, query) = parse(path)
        
        if let collection = collection {
            if let value:T = collection.get(query) {
                return value
            }
            else if let value:T = defaults.get(query) {
                return value
            }
            return nil
        }
        else {
            return nil
        }
    }
    
    /// get settings from path as String
    /// - Parameter path: path of the setting
    /// - Returns: setting value as String
    public func getString(_ path:String) -> String {
        return get(path) ?? ""
    }
    
    /// get settings from path as Bool
    /// - Parameter path: path of the setting
    /// - Returns: setting value as Bool
    public func getBool(_ path:String) -> Bool? {
        return get(path) ?? nil
    }
    
    /// get settings from path as Int
    /// - Parameter path: path of the setting
    /// - Returns: setting value as Int
    public func getInt(_ path:String) -> Int? {
        return get(path) ?? nil
    }
    
    private func parse(_ path:String) -> (collection:SettingCollection?, query:String) {
        let splits = path.split(separator: "/")
        let type = splits.first
        let query = splits.dropFirst().joined(separator: "/")
        var collection:SettingCollection? = nil
        if let type = type {
            if (type == "user") {
                collection = user
            }
            else if (type == "device") {
                collection = device
            }
            else {
                print("Could not find settings collection: \(type)")
            }
        }
        else {
            collection = user
        }
        
        return (collection, query)
    }

    /// Sets the value of a setting for the given path. Also responsible for saving the setting to the permanent storage
    /// - Parameters:
    ///   - path: path used to store the setting
    ///   - value: setting value
    public func set(_ path:String, _ value:Any) {
        let (collection, query) = parse(path)
        
        var codableValue = value as? AnyCodable
        if codableValue == nil {
            codableValue = AnyCodable(value)
        }
        
        if let collection = collection, let codableValue = codableValue {
            collection.set(query, codableValue)
        }
        else {
            print("failed to set setting with path \(path) and value \(value)")
        }
    }
    
    
    /// Get *global* setting value for given path
    /// - Parameter path: global setting path
    /// - Returns: setting value
    public class func get<T:Decodable>(_ path:String) -> T? {
        return globalSettings?.get(path)
    }
    
    /// Get *global* setting value for given path
    /// - Parameter path: global setting path
    ///   - value: setting value for the given path
    public class func set(_ path:String, _ value:Any) {
        if let globalSettings = globalSettings {
            return globalSettings.set(path, value)
        }
        else {
            print("Failed to set setting with path \(path) and value \(value) on globalSettings (nil)")
        }
    }
}

/// Collection of settings that are grouped based on who defined them
class SettingCollection:Object {
    /// Type that represent who created the setting: Default/User/Device
    @objc dynamic var type:String = ""
    
    /// Setting in this collection
    let settings = List<Setting>()
    /// SyncState for this colleciton
    @objc dynamic var syncState:SyncState? = SyncState()
    
    /// primary key for the local realm database
    override static func primaryKey() -> String? {
        return "type"
    }
    
    
    /// get setting for given path
    /// - Parameter path: path for the setting
    /// - Returns: setting value
    public func get<T:Decodable>(_ path:String) -> T? {
        let needle = self.type + (path.first == "/" ? "" :"/") + path
        
        let item = self.settings.filter("key = '\(needle)'").first
        if let item = item {
            let output:T? = unserialize(item.json)
            return output
        }
        else {
            return nil
        }
    }
    
    /// Get setting as String for given path
    /// - Parameter path: path for the setting
    /// - Returns: setting value as String
    public func getString(_ path:String) -> String {
        return get(path) ?? ""
    }
    
    /// Sets a setting to the value passed.Also responsible for saving the setting to the permanent storage
    /// - Parameters:
    ///   - path: path of the setting
    ///   - value: setting Value
    public func set(_ path:String, _ value:AnyCodable) {
        let key = self.type + (path.first == "/" ? "" :"/") + path
        
        func saveState(){
            let s = Setting(value: ["key": key, "json": serialize(value)])
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
                print("No syncState available for settings")
            }
        }
        
        realmWriteIfAvailable(realm) {
            saveState()
        }
    }
}

/// Single setting object, persisted to disk
class Setting:Object {
    /// key of the setting
    @objc dynamic var key:String = ""
    /// json value of the setting
    @objc dynamic var json:String = ""
    
    /// primary key for the setting object in the realm database
    override static func primaryKey() -> String? {
        return "key"
    }
}

var globalSettings:Settings? = nil
