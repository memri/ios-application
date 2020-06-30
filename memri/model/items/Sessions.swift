//
//  Session.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Combine
import Foundation
import RealmSwift
import SwiftUI

public class Sessions: SchemaSessions {
	public required convenience init(from decoder: Decoder) throws {
		self.init()

		jsonErrorHandling(decoder) {
			currentSessionIndex = try decoder.decodeIfPresent("currentSessionIndex") ?? currentSessionIndex

			decodeIntoList(decoder, "sessions", self.sessions)

			try super.superDecode(from: decoder)
		}

		postInit()
	}

	private var rlmTokens: [NotificationToken] = []
	private var cancellables: [AnyCancellable] = []

	func postInit() {
		for session in sessions {
			decorate(session)
			session.postInit()
		}
	}

	func decorate(_ session: Session) {
		if realm != nil {
			rlmTokens.append(session.observe { objectChange in
				if case .change = objectChange {
					self.objectWillChange.send()
				}
            })
		}
	}

	var currentSession: Session {
		sessions.count > 0 ? sessions[currentSessionIndex] : Session()
	}

	var currentView: SessionView {
		currentSession.currentView
	}

	public convenience init(_ realm: Realm) {
		self.init()

		fetchMemriID(realm)

		postInit()
	}

	private func fetchMemriID(_ realm: Realm) {
		// When the memriID is not yet set
		if memriID.starts(with: "Memri") {
			// Fetch device name
			let setting = realm.objects(Setting.self).filter("key = 'device/name'").first
			if let setting = setting {
				// Set it as the memriID
				do {
					let memriID: String? = try unserialize(setting.json)
					self.memriID = memriID ?? ""
				} catch {
					print(error)
					debugHistory.error("\(error)")
				}
			}
		}
	}

	public func setCurrentSession(_ session: Session) {
		realmWriteIfAvailable(realm) {
			if let index = sessions.firstIndex(of: session) {
				sessions.remove(at: index)
			}

			// Add session to array
			sessions.append(session)

			// Update the index pointer
			currentSessionIndex = sessions.count - 1
		}

		decorate(session)
	}

	public func load(_ realm: Realm, _: Cache, _ callback: () throws -> Void) throws {
		// Determine self.memriID
		fetchMemriID(realm)

		if memriID == "" {
			throw ("Exception: installation has been corrupted. Could not determine memriID for sessions.")
		}

		// Activate this session to make sure its stored in realm
		if let fromCache = realm.object(ofType: Sessions.self, forPrimaryKey: memriID) {
			// Sync with the cached version
			try merge(fromCache)

			// Turn myself in a managed object by realm
			try realm.write { realm.add(self, update: .modified) }

			// Add listeners to all session objects
			postInit()

			// Notify MemriContext of any changes
			rlmTokens.append(observe { objectChange in
				if case .change = objectChange {
					self.objectWillChange.send()
				}
            })
		} else {
			throw "Exception: Could not initialize sessions"
		}

		// Done
		try callback()
	}

	public func install(_ context: MemriContext) throws {
		fetchMemriID(context.realm)

		let storedDef = context.realm.objects(CVUStoredDefinition.self)
			.filter("selector = '[sessions = defaultSessions]'").first

		if let storedDef = storedDef {
			if let parsed = try context.views.parseDefinition(storedDef) {
				try context.realm.write {
					// Load default sessions from the package and store in the database
					context.realm.create(Sessions.self, value: [
						"memriID": self.memriID,
						"selector": "[sessions = '\(self.memriID)']",
						"name": self.memriID,
						"currentSessionIndex": Int(parsed["sessionsDefinition"] as? Double ?? 0),
						"sessions": try (parsed["sessionDefinitions"] as? [CVUParsedSessionDefinition] ?? [])
							.map { try Session.fromCVUDefinition($0) },
					])
				}
				return
			}
		}

		throw "Installation is corrupt. Cannot recover."
	}

	public func merge(_ sessions: Sessions) throws {
		func doMerge() {
			let properties = objectSchema.properties
			for prop in properties {
				if prop.name == "sessions" {
					self.sessions.append(objectsIn: sessions.sessions)
				} else {
					self[prop.name] = sessions[prop.name]
				}
			}
		}

		realmWriteIfAvailable(realm) {
			doMerge()
		}
	}

	/// Find a session using text
	public func findSession(_: String) {}

	/// Clear all sessions and create a new one
	public func clear() {}

	public class func fromJSONFile(_ file: String, ext: String = "json") throws -> Sessions {
		let jsonData = try jsonDataFromFile(file, ext)
		let sessions: Sessions = try MemriJSONDecoder.decode(Sessions.self, from: jsonData)
		return sessions
	}

	public class func fromJSONString(_ json: String) throws -> Sessions {
		let sessions: Sessions = try MemriJSONDecoder.decode(Sessions.self, from: Data(json.utf8))
		return sessions
	}
}
