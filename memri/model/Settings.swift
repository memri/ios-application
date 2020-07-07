//
//  settings.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

/// This class stores the settings used in the memri app. Settings may include things like how to format dates, whether to show certain
/// buttons by default, etc.
public class Settings {
	/// Realm database object
	let realm: Realm
	/// Default settings
	var settings: Results<Setting>

	/// Init settings with the relam database
	/// - Parameter rlm: realm database object
	init(_ realm: Realm) {
		self.realm = realm
		settings = realm.objects(Setting.self)
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
		} catch {
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
		let splits = path.split(separator: "/")
		let type = splits.first
		let query = splits.dropFirst().joined(separator: "/")

		if type == "device" {
			return ["\(try Cache.getDeviceID())/\(query)", "defaults/\(query)"]
		} else if type == "user" {
			return ["user/\(query)", "defaults/\(query)"]
		} else {
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
		} catch {
			debugHistory.error("\(error)")
			print(error)
		}
	}

	/// get setting for given path
	/// - Parameter path: path for the setting
	/// - Returns: setting value
	public func getSetting<T: Decodable>(_ path: String) throws -> T? {
		let item = settings.first(where: { $0.key == path })

		if let item = item, let json = item.json {
			let output: T? = try unserialize(json)
			return output
		} else {
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
		realmWriteIfAvailable(realm) {
			if let s = realm.objects(Setting.self).first(where: { $0.key == path }) {
				s.json = try serialize(value)
				s.syncState?.actionNeeded = "update"
				if !(s.syncState?.updatedFields.contains("settings") ?? false) {
					s.syncState?.updatedFields.append("settings")
				}

				#warning("Missing AuditItem for the change")
			} else {
				_ = try Cache.createItem(Setting.self, values: ["key": path, "json": serialize(value)])
			}
		}
	}

	/// Get *global* setting value for given path
	/// - Parameter path: global setting path
	/// - Returns: setting value
	public class func get<T: Decodable>(_ path: String, type _: T.Type = T.self) -> T? {
		globalSettings?.get(path)
	}

	/// Get *global* setting value for given path
	/// - Parameter path: global setting path
	///   - value: setting value for the given path
	public class func set(_ path: String, _ value: Any) {
		if let globalSettings = globalSettings {
			return globalSettings.set(path, value)
		} else {
			debugHistory.error("Failed to set setting with path \(path) and value \(value) on globalSettings (nil)")
		}
	}
}

var globalSettings: Settings?
