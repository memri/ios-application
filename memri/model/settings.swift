//
//  settings.swift
//  memri
//
//  Created by Ruben Daniels on 4/1/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class SettingsData {
    /**
     * Possible values: "default", "device", "group", "user"
     */
    public var type: String

    /**
     * Used by device and group (and perhaps user)
     */
    public var name: String
    
    private var data:[String:AnyObject] = [:]
    
    public init(_ type:String, _ name:String) {
        self.type = type
        self.name = name
    }

    /**
     *
     */
    public func get(_ path:String) -> AnyObject? {
        return data[path] ?? nil
    }

    /**
     * Also responsible for saving the setting to the permanent storage
     */
    public func set(_ path:String, _ value:AnyObject) -> Void {
        data[path] = value
    }
}

class SettingCollection:Object {
    @objc dynamic var type:String = ""
    
    let settings = List<Setting>()
    
    override static func primaryKey() -> String? {
        return "type"
    }
    
    /**
     *
     */
    public func get(_ path:String) -> Results<Setting> {
        return self.settings.filter("name = '\(path)'")
    }

    /**
     * Also responsible for saving the setting to the permanent storage
     */
    public func set(_ path:String, _ value:Any) -> Void {
        let setting = self.settings.filter("key = '\(path)'").first
        
        try! self.realm!.write {
            if let setting = setting {
                setting.value = value
            }
            else {
                settings.append(Setting(value: ["key": path, "value": value]))
            }
        }
    }
}

class Setting:Object {
    @objc dynamic var key:String = ""
    @objc dynamic var value:String = ""
    
    override static func primaryKey() -> String? {
        return "key"
    }
}
