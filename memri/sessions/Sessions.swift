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

public final class Sessions : Equatable {
    /// TBD
    var currentSessionIndex:Int {
        get { parsed["currentSessionIndex"] as? Int ?? 0 }
        set (value) { parsed["currentSessionIndex"] = value }
    }
    
    var uid: Int
    var parsed: CVUParsedSessionsDefinition
    var state: CVUStateDefinition? {
        try withRealm { realm in
            realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
        } as? CVUStateDefinition
    }

    /// TBD
    var sessions = [Session]()
    var context: MemriContext? = nil
    
    private var cancellables: [AnyCancellable] = []
    
	var currentSession: Session? {
        sessions[safe: currentSessionIndex]
	}

	var currentView: CascadingView? {
		currentSession?.currentView
	}

    init(_ state: CVUStateDefinition) throws {
        guard let uid = state.uid.value else {
            throw "CVU state object is unmanaged"
        }
        
        self.uid = uid
    }
    
    private func load(_ context:MemriContext) throws {
        self.context = context
        
        _ = try withRealm { realm in
            guard
                let state = realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid),
                let p = try context.views.parseDefinition(state) as? CVUParsedSessionsDefinition
            else {
                throw "Unable to fetch CVU state definition"
            }
            
            self.parsed = p
            
            guard let storedSessionStates = state.edges("session")?
                .sorted(byKeyPath: "sequence").items(type: CVUStateDefinition.self) else {
                    throw "No sessions found. Aborting" // TODO should this initialize a default session?
            }
            
            for sessionState in storedSessionStates {
                sessions.append(try Session(sessionState, self))
            }
            
            try setCurrentSession()
        }
    }
    
	public func setCurrentSession(_ state: CVUStateDefinition? = nil) throws {
        guard let storedSession = state ?? self.currentSession?.state else {
            throw "Exception: Unable fetch stored CVU state"
        }
        
        // If the session already exists, we simply update the session index
        if let index = sessions.firstIndex(where: { session in
            session.uid == storedSession.uid.value
        }) {
            currentSessionIndex = index
        }
        // Otherwise lets create a new session
        else {
            // Add session to list
            sessions.append(try Session(storedSession, self))
            currentSessionIndex = sessions.count - 1
        }
        
        storedSession.accessed()
	}
    
    #warning("Move to separate thread")
    public func persist() throws {
        _ = try withRealm { realm in
            var state = realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
            if state == nil {
                debugHistory.warn("Could not find stored CVU. Creating a new one.")
                
                state = try Cache.createItem(CVUStateDefinition.self, values: [:])
                
                guard let uid = state?.uid.value else {
                    throw "Exception: could not create stored definition"
                }
                
                self.uid = uid
            }
            
            state?.set("definition", parsed.toCVUString(0, "    "))
            
            for session in sessions {
                try session.persist()
                
                if let s = session.state {
                    _ = try state?.link(s, type: "session", sequence: .last, overwrite: false)
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
            
            try load(context)
        }
	}

	/// Clear all sessions and create a new one
	public func clear() {}
}
