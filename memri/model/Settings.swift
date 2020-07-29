//
// Settings.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift

/// This class stores the settings used in the memri app. Settings may include things like how to format dates, whether to show certain
/// buttons by default, etc.
public class Settings {
    /// Shared settings that can be used from the main thread
    static var shared: Settings = Settings()
    /// Default settings
    var settings: Results<Setting>? = nil

    private var listeners = [String: [UUID]]()
    private var callbacks = [UUID: (Any?) -> Void]()

    /// Init settings with the relam database
    /// - Parameter rlm: realm database object
    init() {
        
    }
    
    public func load(){
        settings = try? DatabaseController.tryCurrent { realm in
            realm.objects(Setting.self)
        }
    }

    // TODO: Refactor this so that the default settings are always used if not found in Realm.
    // Otherwise anytime we add a new setting the get function will return nil instead of the default

    /// Get setting from path
    /// - Parameter path: path of the setting
    /// - Returns: setting value
    public func get<T: Decodable>(_ path: String, type _: T.Type = T.self) -> T? {
        do {
            for path in try getSearchPaths(path) {
                if let value: T = try getSetting(path) {
                    return value
                }
            }
        }
        catch {
            print("Could not fetch setting '\(path)': \(error)")
        }

        return nil
    }

    /// get settings from path as String
    /// - Parameter path: path of the setting
    /// - Returns: setting value as String
    public func getString(_ path: String) -> String {
        get(path) ?? ""
    }

    /// get settings from path as Bool
    /// - Parameter path: path of the setting
    /// - Returns: setting value as Bool
    public func getBool(_ path: String) -> Bool? {
        get(path) ?? nil
    }

    /// get settings from path as Int
    /// - Parameter path: path of the setting
    /// - Returns: setting value as Int
    public func getInt(_ path: String) -> Int? {
        get(path) ?? nil
    }

    private func getSearchPaths(_ path: String) throws -> [String] {
        let p = path.first == "/" ? String(path.suffix(path.count - 1)) : path
        let splits = p.split(separator: "/")
        let type = splits.first
        let query = splits.dropFirst().joined(separator: "/")

        if type == "device" {
            return ["\(try Cache.getDeviceID())/\(query)", "defaults/\(query)"]
        }
        else if type == "user" {
            return ["user/\(query)", "defaults/\(query)"]
        }
        else {
            return ["defaults/\(query)"]
        }
    }

    /// Sets the value of a setting for the given path. Also responsible for saving the setting to the permanent storage
    /// - Parameters:
    ///   - path: path used to store the setting
    ///   - value: setting value
    public func set(_ path: String, _ value: Any) {
        do {
            let searchPaths = try getSearchPaths(path)
            if searchPaths.count == 1 {
                throw "Missing scope 'user' or 'device' as the start of the path"
            }
            try setSetting(searchPaths[0], value as? AnyCodable ?? AnyCodable(value))
            fire(searchPaths[0], (value as? AnyCodable)?.value ?? value)
        }
        catch {
            debugHistory.error("\(error)")
            print(error)
        }
    }

    /// get setting for given path
    /// - Parameter path: path for the setting
    /// - Returns: setting value
    public func getSetting<T: Decodable>(_ path: String, type: T.Type = T.self) throws -> T? {
        let item = settings?.first(where: { $0.key == path })

        if let item = item, let json = item.json {
            let output: T? = try unserialize(json)
            return output
        }
        else {
            return nil
        }
    }

    /// Get setting as String for given path
    /// - Parameter path: path for the setting
    /// - Returns: setting value as String
    public func getSettingString(_ path: String) throws -> String {
        String(try getSetting(path) ?? "")
    }

    /// Sets a setting to the value passed.Also responsible for saving the setting to the permanent storage
    /// - Parameters:
    ///   - path: path of the setting
    ///   - value: setting Value
    public func setSetting(_ path: String, _ value: AnyCodable) throws {
        try DatabaseController.tryCurrent(write:true) { realm in
            if let s = realm.objects(Setting.self).first(where: { $0.key == path }) {
                s.json = try serialize(value)

                if s._action != "create" {
                    s._action = "update"
                    if !s._updated.contains("json") {
                        s._updated.append("json")
                    }
                    #warning("Missing AuditItem for the change")
                }
            }
            else {
                _ = try Cache.createItem(
                    Setting.self,
                    values: ["key": path, "json": serialize(value)]
                )
            }
        }
    }

    private func fire(_ path: String, _ value: Any?) {
        if let list = listeners[path] {
            for id in list {
                if let f = callbacks[id] {
                    f(value)
                }
            }
        }
    }

    func addListener<T: Decodable>(
        _ path: String,
        _ id: UUID,
        type: T.Type = T.self,
        _ f: @escaping (Any?) -> Void
    ) throws {
        guard let normalizedPath = try getSearchPaths(path).first else {
            throw "Invalid path"
        }

        if listeners[normalizedPath] == nil { listeners[normalizedPath] = [] }
        if !(listeners[normalizedPath]?.contains(id) ?? false) {
            listeners[normalizedPath]?.append(id)
            callbacks[id] = f

            if let value = get(path, type: T.self) {
                fire(normalizedPath, value)
            }
        }
    }

    func removeListener(_ path: String, _ id: UUID) {
        listeners[path]?.removeAll(where: { $0 == id })
        callbacks.removeValue(forKey: id)
    }
}
