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
    var currentSessionIndex:Int {
        get { parsed["currentSessionIndex"] as? Int ?? 0 }
        set (value) { parsed["currentSessionIndex"] = value }
    }
    
    var uid: Int
    var parsed: CVUParsedSessionsDefinition
    var stored: CVUStoredDefinition? {
        try withRealm { realm in
            realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
        } as? CVUStoredDefinition
    }

    /// TBD
    var sessions = [Session]()
    
    private var cancellables: [AnyCancellable] = []
    private var views: Views
    
	var currentSession: Session? {
        sessions[safe: currentSessionIndex]
	}

	var currentView: CascadingView? {
		currentSession?.currentView
	}

    init(_ state: CVUStateDefinition, _ views: Views) throws {
        guard let uid = state.uid.value else {
            throw "CVU state object is unmanaged"
        }
        
        self.uid = uid
        self.views = views
        
        // Only load if installation has run
        if state.definition != nil {
            try load()
        }
    }
    
    private func load() throws {
        _ = try withRealm { realm in
            guard
                let state = realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid),
                let p = try views.parseDefinition(state) as? CVUParsedSessionsDefinition
            else {
                throw "Unable to fetch CVU state definition"
            }
            
            self.parsed = p
            
            guard let storedSessionStates = state.edges("session")?
                .sorted(byKeyPath: "sequence").items(type: CVUStateDefinition.self) else {
                    throw "No sessions found. Aborting" // TODO should this initialize a default session?
            }
            
            for sessionState in storedSessionStates {
                sessions.append(Session(sessionState))
            }
            
            try setCurrentSession()
        }
    }
    
	public func setCurrentSession(_ session: Session? = nil) throws {
        guard
            let currentSession = session ?? self.currentSession,
            let stored = self.stored,
            let storedSession = currentSession.stored
        else {
            throw "Exception: Unable fetch stored CVU state"
        }
        
        if
            let edge = try stored.link(storedSession, type: "session", sequence: .last),
            let index = stored.edges("session")?.index(of: edge)
        {
            // Update the index pointer
            currentSessionIndex = index
        } else {
            debugHistory.error("Unable to switch sessions")
            return
        }
	}
    
    public func persist() throws {
        _ = try withRealm { realm in
            var stored = realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
            if stored == nil {
                stored = try Cache.createItem(CVUStateDefinition.self, values: [:])
                
                guard let uid = stored?.uid.value else {
                    throw "Exception: could not create stored definition"
                }
                
                self.uid = uid
                
                // TODO Warn??
            }
            
            stored?.set("definition", parsed.toCVUString(0, "    "))
            
            for session in sessions {
                try session.persist()
                
                if let s = session.stored {
                    _ = try stored?.link(s, type: "session", sequence: .last, overwrite: false)
                }
                else {
                    debugHistory.warn("Unable to store session. Missing stored CVU")
                }
            }
        }
    }

	public func install(_ context: MemriContext) throws {
        _ = try withRealm { realm in
            
            let templateQuery = "selector = '[sessions = defaultSessions]'"
            guard
                let template = realm.objects(CVUStoredDefinition.self).filter(templateQuery).first,
                let parsed = try context.views.parseDefinition(template),
                let stored = realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
            else {
                throw "Installation is corrupt. Cannot recover."
            }
            
            let defs = (parsed["sessionDefinitions"] as? [CVUParsedSessionDefinition] ?? [])
            let allSessions = try defs.map { try CVUStateDefinition.fromCVUParsedDefinition($0) }

            for session in allSessions {
                _ = try stored.link(session, type: "session", sequence: .last)
            }
            
            try load()
        }
	}

	/// Clear all sessions and create a new one
	public func clear() {}
}
