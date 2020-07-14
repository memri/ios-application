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

			try super.superDecode(from: decoder)
		}

		postInit()
	}

	private var rlmTokens: [NotificationToken] = []
	private var cancellables: [AnyCancellable] = []

	func postInit() {
		guard let sessions = sessions else { return }

		for session in sessions {
			decorate(session)
			session.postInit()
		}
	}

	func decorate(_ session: Session) {
		if realm != nil {
			rlmTokens.append(session.observe { objectChange in
				if case .change = objectChange {
					#warning("Modify this to support Combine properly")
//					self.objectWillChange.send()
				}
            })
		}
	}

	var currentSession: Session? {
		sessions?[currentSessionIndex]
	}

	var currentView: SessionView? {
		currentSession?.currentView
	}

	public required init() {
		super.init()
		postInit()
	}

	public func setCurrentSession(_ session: Session) {
		realmWriteIfAvailable(realm) {
			if let edge = try link(session, type: "session", order: .last),
				let index = edges("session")?.index(of: edge) {
				// Update the index pointer
				currentSessionIndex = index
			} else {
				debugHistory.error("Unable to switch sessions")
				return
			}
		}

		decorate(session)
	}

	public func install(_ context: MemriContext) throws {
		let storedDef = context.realm.objects(CVUStoredDefinition.self)
			.filter("selector = '[sessions = defaultSessions]'").first

		guard let uid = uid.value else {
			throw "Unable to find uid of sessions"
		}

		if let storedDef = storedDef {
			if let parsed = try context.views.parseDefinition(storedDef) {
				let defs = (parsed["sessionDefinitions"] as? [CVUParsedSessionDefinition] ?? [])
				let allSessions = try defs.map { try Session.fromCVUDefinition($0) }

				// Load default sessions from the package and store in the database
				let sessions = try Cache.createItem(Sessions.self, values: [
					"uid": uid,
					//                    "selector": "[sessions = '\(uid)']",
					"currentSessionIndex": Int(parsed["sessionsDefinition"] as? Double ?? 0),
				])
				for session in allSessions {
					_ = try sessions.link(session, type: "session")
				}

				postInit()

				return
			}
		}

		throw "Installation is corrupt. Cannot recover."
	}

	public func merge(_ sessions: Sessions) throws {
		func doMerge() {
			let properties = objectSchema.properties
			for prop in properties {
				self[prop.name] = sessions[prop.name]
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
