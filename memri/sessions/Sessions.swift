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

public final class Sessions : ObservableObject, Equatable {
    /// TBD
    var currentSessionIndex:Int {
        get { Int(parsed?["currentSessionIndex"] as? Double ?? 0) }
        set (value) {
            setState("currentSessionIndex", Double(value))
        }
    }
    
    var uid: Int? = nil
    var parsed: CVUParsedSessionsDefinition? = nil
    var state: CVUStateDefinition? {
		DatabaseController.read { realm in
            realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
        }
    }

    /// TBD
    var context: MemriContext? = nil
    var isDefault: Bool = false
    
    private var sessions = [Session]()
    private var cancellables: [AnyCancellable] = []
    
    var count: Int {
        sessions.count
    }
    
	var currentSession: Session? {
        sessions[safe: currentSessionIndex]
	}

	var currentView: CascadableView? {
		currentSession?.currentView
	}
    
    subscript(index: Int) -> Session? {
        sessions[safe: index]
    }

    init(_ state: CVUStateDefinition? = nil, isDefault:Bool = false) throws {
        if let state = state {
            guard let uid = state.uid.value else {
                throw "CVU state object is unmanaged"
            }
            
            self.uid = uid
        }
        else if isDefault {
            self.isDefault = isDefault
            // Load default sessions for this device
            self.uid = Settings.shared.getInt("device/sessions/uid")
        }
        
        // Setup update publishers
        self.persistCancellable = persistSubject
            .throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] in
                DatabaseController.writeAsync { _ in
                    try self?.persist()
                }
            }
    }
    
    func load(_ context:MemriContext) throws {
        if self.isDefault && self.uid == nil {
            self.uid = Settings.shared.getInt("device/sessions/uid")
            
            guard self.uid != nil else {
                throw "Could not find stored sessions to load from"
            }
        }
        
        self.context = context
        self.sessions = []
        
        try DatabaseController.tryRead { realm in
            if let state = realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid) {
                guard let p = try context.views.parseDefinition(state) as? CVUParsedSessionsDefinition else {
                    throw "Unable to parse state definition"
                }
            
                self.parsed = p
                
                // Check if there are sessions in the db
                if
                    let storedSessionStates = state
                        .edges("session")?
                        .sorted(byKeyPath: "sequence")
                        .items(type: CVUStateDefinition.self),
                    storedSessionStates.count > 0
                {
                    for sessionState in storedSessionStates {
                        sessions.append(try Session(sessionState, self))
                    }
                }
                // Or if the sessions are encoded in the definition
                else if
                    let parsedSessions = p["sessionDefinitions"] as? [CVUParsedSessionDefinition],
                    parsedSessions.count > 0
                {
                    try DatabaseController.tryWriteSync { realm in
                        for parsed in parsedSessions {
                            let sessionState = try CVUStateDefinition.fromCVUParsedDefinition(parsed)
                            _ = try state.link(sessionState, type: "session", sequence: .last)
                            sessions.append(try Session(sessionState, self))
                        }
                    }
                    
                    self.parsed?["sessionDefinitions"] = nil
                }
                else {
                    throw "CVU state definition is missing sessions"
                }
            }
            // Create a default session
            else {
                sessions.append(try Session(nil, self))
            }
        }
    }
    
    private func setState(_ name:String, _ value: Any?) {
        if parsed == nil { parsed = CVUParsedSessionsDefinition() }
        parsed?[name] = value
        schedulePersist()
    }
    
	public func setCurrentSession(_ state: CVUStateDefinition? = nil) throws {
        guard let storedSession = state ?? self.currentSession?.state else {
            throw "Exception: Unable to fetch stored CVU state for session"
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
        
        schedulePersist()
	}
    
    private var persistSubject = PassthroughSubject<Void, Never>()
    private var persistCancellable: AnyCancellable?
    func schedulePersist() { persistSubject.send() }
    
    public func persist() throws {
        try DatabaseController.tryWriteSync { realm in
            var state = realm.object(ofType: CVUStateDefinition.self, forPrimaryKey: uid)
            if state == nil {
                debugHistory.warn("Could not find stored sessions CVU. Creating a new one.")
                
                state = try Cache.createItem(CVUStateDefinition.self, values: [:])
                
                guard let uid = state?.uid.value else {
                    throw "Exception: could not create stored definition"
                }
                
                self.uid = uid
            }
            
            state?.set("definition", self.parsed?.toCVUString(0, "    "))
            
            for session in self.sessions {
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
        try  DatabaseController.tryWriteSync { realm in
            let templateQuery = "selector = '[sessions = defaultSessions]'"
            guard
                let template = realm.objects(CVUStoredDefinition.self).filter(templateQuery).first,
                let parsed = try context.views.parseDefinition(template)
            else {
                throw "Installation is corrupt. Cannot recover."
            }
            
            let defs = (parsed["sessionDefinitions"] as? [CVUParsedSessionDefinition] ?? [])
            let allSessions = try defs.map {
                try CVUStateDefinition.fromCVUParsedDefinition($0)
            }

            let state = try Cache.createItem(CVUStateDefinition.self)
            for session in allSessions {
                _ = try state.link(session, type: "session", sequence: .last)
            }
            
            // uid is always set
            self.uid = state.uid.value
            Settings.shared.set("device/sessions/uid", state.uid.value ?? -1)
            
            self.parsed = parsed as? CVUParsedSessionsDefinition
            self.parsed?.parsed?.removeValue(forKey: "sessionDefinitions")
            
            try persist()
            try load(context)
        }
	}

	/// Clear all sessions and create a new one
	public func clear() {}
    
    public static func == (lt: Sessions, rt: Sessions) -> Bool {
        lt.uid == rt.uid
    }
}
