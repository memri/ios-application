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
	let realm: Realm
	/// Default settings
	var defaults: SettingCollection = SettingCollection()
	/// Device settings
	var device: SettingCollection = SettingCollection()
	/// User defined settings
	var user: SettingCollection = SettingCollection()

	/// Init settings with the relam database
	/// - Parameter rlm: realm database object
	init(_ realm: Realm) {
		self.realm = realm
	}

	/// Load all settings from the local realm database
	/// - Parameter callback: function that is called after completing loading the settings
	public func load(_ callback: () throws -> Void) throws {
		// TODO: This could probably be optimized, but lets first get familiar with the process

		let allSettings = realm.objects(SettingCollection.self)
		if allSettings.count > 0 {
			for i in 0 ... allSettings.count - 1 {
				switch allSettings[i].type {
				case "defaults": defaults = allSettings[i]
				case "device": device = allSettings[i]
				case "user": user = allSettings[i]
				default:
					print("Error: Invalid settings found \(allSettings[i].type)")
				}
			}
		} else {
			debugHistory.error("Error: Settings are not initialized")
		}

		try callback()
	}

	// TODO: Refactor this so that the default settings are always used if not found in Realm.
	// Otherwise anytime we add a new setting the get function will return nil instead of the default

	/// Initialize SettingsCollection objects for default, device and user-settings. Populate them by reading the default settings from
	/// disk and updating the empty SettingCollections.
	public func install() throws {
		let defaults = SettingCollection(value: ["type": "defaults", "memriID": "settingsDefaults"])
		let device = SettingCollection(value: ["type": "device", "memriID": "settingsDevice"])
		let user = SettingCollection(value: ["type": "user", "memriID": "settingsUser"])

		do {
			try realm.write {
				realm.add(defaults, update: .modified)
				realm.add(device, update: .modified)
				realm.add(user, update: .modified)
			}
		} catch {
			debugHistory.error("\(error)")
		}

		// Load default settings from disk
		do {
			let jsonData = try jsonDataFromFile("default_settings")
			let values = try MemriJSONDecoder.decode([String: AnyCodable].self, from: jsonData)
			for (key, value) in values {
				try defaults.setSetting(key, value)
			}

			try device.setSetting("/name", "iphone")
		} catch {
			debugHistory.error("Failed to install settings: \(error)")
		}
		try load {}
	}

	/// Get setting from path
	/// - Parameter path: path of the setting
	/// - Returns: setting value
	public func get<T: Decodable>(_ path: String, type _: T.Type = T.self) -> T? {
		let (collection, query) = parse(path)

		do {
			if let collection = collection {
				if let value: T = try collection.getSetting(query) {
					return value
				} else if let value: T = try defaults.getSetting(query) {
					return value
				}
				return nil
			}
		} catch {
			debugHistory.error("Could not fetch setting: \(error)")
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

	private func parse(_ path: String) -> (collection: SettingCollection?, query: String) {
		let splits = path.split(separator: "/")
		let type = splits.first
		let query = splits.dropFirst().joined(separator: "/")
		var collection: SettingCollection?
		if let type = type {
			if type == "user" {
				collection = user
			} else if type == "device" {
				collection = device
			} else {
				debugHistory.warn("Could not find settings collection: \(type)")
			}
		} else {
			collection = user
		}

		return (collection, query)
	}

	/// Sets the value of a setting for the given path. Also responsible for saving the setting to the permanent storage
	/// - Parameters:
	///   - path: path used to store the setting
	///   - value: setting value
	public func set(_ path: String, _ value: Any) {
		let (collection, query) = parse(path)

		var codableValue = value as? AnyCodable
		if codableValue == nil {
			codableValue = AnyCodable(value)
		}

		if let collection = collection, let codableValue = codableValue {
			do {
				try collection.setSetting(query, codableValue)
			} catch {
				debugHistory.error("\(error)")
				print(error)
			}
		} else {
			debugHistory.warn("failed to set setting with path \(path) and value \(value)")
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
