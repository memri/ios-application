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

public final class Sessions {
    /// TBD
    var currentSessionIndex:Int = 0
    
    var uid: Int
    var parsed: CVUParsedSessionsDefinition

    /// TBD
    var sessions: [Session]
//        Results<Session>? {
//        edges("session")?.sorted(byKeyPath: "sequence").items(type:Session.self)
//    }
    
    private var cancellables: [AnyCancellable] = []
    
	var currentSession: Session? {
        sessions[safe: currentSessionIndex]
	}

	var currentView: CascadingView? {
		currentSession?.currentView
	}

    init(_ state: CVUStateDefinition, _ views: Views) throws {
        self.uid = state.uid.value
        
        parsed = try views.parseDefinition(state)
        parsed.domain = "state"
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

	/// Clear all sessions and create a new one
	public func clear() {}
}
