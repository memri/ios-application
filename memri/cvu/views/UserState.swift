//
//  UserState.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

public class UserState: SchemaItem, CVUToString {
	@objc dynamic var state: String = ""

	private var cacheID = UUID().uuidString

	/// Primary key used in the realm database of this Item
	override public static func primaryKey() -> String? {
		"uid"
	}

	convenience init(_ dict: [String: Any]) throws {
		self.init()
		try storeInCache(dict)
		persist()
	}

	private func storeInCache(_ dict: [String: Any]) throws {
		let id = uid.value != nil ? "\(uid.value ?? -99)" : cacheID
		return try InMemoryObjectCache.set("UserState:\(id)", dict)
	}

	private func getFromCache() -> [String: Any]? {
		let id = uid.value != nil ? "\(uid.value ?? -99)" : cacheID
		return InMemoryObjectCache.get("UserState:\(id)") as? [String: Any]
	}

	func get<T>(_ propName: String, type _: T.Type = T.self) -> T? {
		let dict = asDict()

		if dict[propName] == nil {
			return nil
		}

		return dict[propName] as? T
	}

	func set<T>(_ propName: String, _ newValue: T?, persist: Bool = true) {
		var dict = asDict()
		dict[propName] = newValue

		do { try storeInCache(dict) }
		catch {
			/* TODO: ERROR HANDLIGNN */
			debugHistory.warn("Unable to store user state property \(propName)")
			return
		}

		if persist { scheduleWrite() }
	}

	private func transformToDict() throws -> [String: Any] {
		if state == "" { return [String: Any]() }
		let stored: [String: AnyCodable] = try unserialize(state) ?? [:]
		var dict = [String: Any]()

		for (key, wrapper) in stored {
			if let lookup = wrapper.value as? [String: Any?], lookup["___"] != nil {
				if let itemType = lookup["_type"] as? String, let uid = lookup["_uid"] as? Int {
					dict[key] = getItem(itemType, uid)
				} else {
					debugHistory.warn("Could not expand item. View may not load as expected")
				}
			} else {
				dict[key] = wrapper.value
			}
		}

		try storeInCache(dict)
		return dict
	}

	var scheduled = false
	private func scheduleWrite() {
		// Don't schedule when we are already scheduled
		if !scheduled {
			// Prevent multiple calls to the dispatch queue
			scheduled = true

			// Schedule update
			DispatchQueue.main.async {
				// Reset scheduled
				self.scheduled = false

				// Update UI
				self.persist()
			}
		}
	}

	func persist() {
		if realm == nil { return }

		if let x = getFromCache() {
			realmWriteIfAvailable(realm) {
				do {
					var values: [String: AnyCodable?] = [:]

					for (key, value) in x {
						if let value = value as? Item {
							values[key] = ["_type": value.genericType,
										   "_uid": value.uid.value as Any,
										   "___": true]
						} else if let value = value as? AnyCodable {
							values[key] = value
						} else {
							values[key] = AnyCodable(value)
						}
					}

					let data = try MemriJSONEncoder.encode(values)
					self["state"] = String(data: data, encoding: .utf8) ?? ""
				} catch {
					debugHistory.error("Could not persist state object: \(error)")
				}
			}
		}
	}

	// Requires support for dataItem lookup.

	public func toggleState(_ stateName: String) {
		let x: Bool = get(stateName) ?? true
		set(stateName, !x)
	}

	public func hasState(_ stateName: String) -> Bool {
		let x: Bool = get(stateName) ?? false
		return x
	}

	public func asDict() -> [String: Any] {
		if let cached = getFromCache() {
			return cached
		} else {
			do {
				return try transformToDict()
			} catch {
				debugHistory.error("Could not unserialize state object: \(error)")
				return [:]
			} // TODO: refactor: handle error
		}
	}

	public func merge(_ state: UserState) throws {
		let dict = asDict().merging(state.asDict(), uniquingKeysWith: { _, new in new })
		try storeInCache(dict as [String: Any])
		persist()
	}

	func toCVUString(_ depth: Int, _ tab: String) -> String {
		CVUSerializer.dictToString(asDict(), depth, tab)
	}

	public class func clone(_ viewArguments: ViewArguments? = nil,
							_ values: [String: Any]? = nil,
							managed: Bool = true) throws -> UserState {
		var dict = viewArguments?.asDict() ?? [:]
		if let values = values {
			dict.merge(values, uniquingKeysWith: { _, r in r })
		}

		if managed { return try UserState.fromDict(dict) }
		else { return try UserState(dict) }
	}

	public class func fromDict(_ dict: [String: Any]) throws -> UserState {
		let userState = try Cache.createItem(UserState.self, values: [:])
        try userState.storeInCache(dict)
		userState.persist()
		return userState
	}
}

public typealias ViewArguments = UserState
