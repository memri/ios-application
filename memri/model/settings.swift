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
    
    private var callback:(() -> Void)? = nil
    private var _ready:Bool = false
    var ready:(() -> Void)? {
        get {
            return callback
        }
        set(f) {
            callback = f
            if _ready && callback != nil { callback!() }
        }
    }
    
    init(_ rlm:Realm) {
        realm = rlm
        
        // TODO: This could probably be optimized, but lets first get familiar with the process
        
        let allSettings = realm.objects(SettingCollection.self)
        if (allSettings.count == 0) {
            defaults = SettingCollection(value: ["type": "defaults"])
            device = SettingCollection(value: ["type": "device"])
            user = SettingCollection(value: ["type": "user"])
            
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
            let values = try! JSONDecoder().decode([String:AnyCodable].self, from: jsonData)
            for (key, value) in values {
                defaults.set(key, value)
            }
        }
        else {
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
        
        _ready = true
        if let callback = callback { callback() }
    }
    
    /**
     *
     */
    public func get<T:Decodable>(_ path:String) -> T? {
        let (collection, query) = parse(path)
        return collection!.get(query) ?? defaults.get(query)
    }

    public func getString(_ path:String) -> String {
        return get(path) ?? ""
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
}

class SettingCollection:Object {
    @objc dynamic var type:String = ""
    
    let settings = List<Setting>()
    @objc dynamic var loadState:DataItemState? = DataItemState()
    
    override static func primaryKey() -> String? {
        return "type"
    }
    
    private func unserialize<T:Decodable>(_ s:String) -> T {
        let data = s.data(using: .utf8)!
        let output:T = try! JSONDecoder().decode(T.self, from: data)
        return output
    }
    
    private func serialize(_ a:AnyCodable) -> String {
        let data = try! JSONEncoder().encode(a)
        let string = String(data: data, encoding: .utf8)!
        return string
    }
    
    /**
     *
     */
    public func get<T:Decodable>(_ path:String) -> T? {
        let item = self.settings.filter("key = '\(path)'").first
        if let item = item {
            return unserialize(item.json)
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
        try! self.realm!.write {
            let s = Setting(value: ["key": path, "json": serialize(value)])
            self.realm!.add(s, update: .modified)
            if settings.index(of: s) == nil { settings.append(s) }
            
            loadState!.actionNeeded = .update
        }
    }
}

class Setting:Object {
    @objc dynamic var key:String = ""
    @objc dynamic var json:String = ""
    
    override static func primaryKey() -> String? {
        return "key"
    }
}
