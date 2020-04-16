//
//  settings.swift
//  memri
//
//  Created by Ruben Daniels on 4/1/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class Settings {
    let realm:Realm
    
    var defaults:SettingCollection = SettingCollection()
    var device:SettingCollection = SettingCollection()
    var user:SettingCollection = SettingCollection()
    
    init(_ rlm:Realm) {
        realm = rlm
    }
    
    public func load(_ callback: () -> Void) {
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
        
        callback()
    }
    
    /**
     *
     */
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
        let jsonData = try! jsonDataFromFile("default_settings")
        let values = try! MemriJSONDecoder.decode([String:AnyCodable].self, from: jsonData)
        for (key, value) in values {
            defaults.set(key, value)
        }
        
        device.set("/name", "iphone")
    }
    
    /**
     *
     */
    public func get<T:Decodable>(_ path:String) -> T? {
        let (collection, query) = parse(path)
        
        if let value:T = collection!.get(query) {
            return value
        }
        else if let value:T = defaults.get(query) {
            return value
        }
        return nil
    }

    public func getString(_ path:String) -> String {
        return get(path) ?? ""
    }
    
    public func getBool(_ path:String) -> Bool? {
        return get(path) ?? nil
    }
    
    public func getInt(_ path:String) -> Int? {
        return get(path) ?? nil
    }
    
    private func parse(_ path:String) -> (collection:SettingCollection?, rest:String) {
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

    /**
     * Also responsible for saving the setting to the permanent storage
     */
    public func set(_ path:String, _ value:AnyCodable) -> Void {
        let (collection, query) = parse(path)
        collection!.set(query, value)
    }
    
    
    public class func get<T:Decodable>(_ path:String) -> T? {
        return globalSettings!.get(path)
    }
    
    public class func set(_ path:String, _ value:AnyCodable) -> Void {
        return globalSettings!.set(path, value)
    }
}

class SettingCollection:Object {
    @objc dynamic var type:String = ""
    
    let settings = List<Setting>()
    @objc dynamic var syncState:SyncState? = SyncState()
    
    override static func primaryKey() -> String? {
        return "type"
    }
    
    /**
     *
     */
    public func get<T:Decodable>(_ path:String) -> T? {
        let needle = self.type + (path.first == "/" ? "" :"/") + path
        
        let item = self.settings.filter("key = '\(needle)'").first
        if let item = item {
            let output:T = unserialize(item.json)
            return output
        }
        else {
            return nil
        }
    }
    
    public func getString(_ path:String) -> String {
        return get(path) ?? ""
    }

    /**
     * Also responsible for saving the setting to the permanent storage
     */
    public func set(_ path:String, _ value:AnyCodable) -> Void {
        let key = self.type + (path.first == "/" ? "" :"/") + path
        
        func saveState(){
            let s = Setting(value: ["key": key, "json": serialize(value)])
            self.realm!.add(s, update: .modified)
            if settings.index(of: s) == nil { settings.append(s) }
            
            syncState!.actionNeeded = "update"
        }
        
        if self.realm!.isInWriteTransaction { saveState() }
        else { try! self.realm!.write { saveState() } }
    }
}

class Setting:Object {
    @objc dynamic var key:String = ""
    @objc dynamic var json:String = ""
    
    override static func primaryKey() -> String? {
        return "key"
    }
}

var globalSettings:Settings? = nil