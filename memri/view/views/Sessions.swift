//
//  Session.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

public class Sessions: DataItem {
 
    override var genericType:String { "Sessions" }
 
    @objc dynamic var currentSessionIndex: Int = 0
 
    let sessions = RealmSwift.List<Session>()
 
    var currentSession: Session {
        return sessions.count > 0 ? sessions[currentSessionIndex] : Session()
    }
 
    var currentView: SessionView {
        return currentSession.currentView
    }
    
    private var rlmTokens: [NotificationToken] = []
    private var cancellables: [AnyCancellable] = []
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            currentSessionIndex = try decoder.decodeIfPresent("currentSessionIndex") ?? currentSessionIndex
            
            decodeIntoList(decoder, "sessions", self.sessions)
            
            try! super.superDecode(from:decoder)
        }
        
        self.postInit()
    }
    
    public convenience init(_ realm:Realm) {
        self.init()
        
        fetchUID(realm)
        
        self.postInit()
    }
    
    required init() {
        super.init()
    }
    
    private func postInit(){
        for session in sessions {
            decorate(session)
            session.postInit()
        }
    }
    
    private func decorate(_ session:Session) {
        if realm != nil {
            rlmTokens.append(session.observe({ (objectChange) in
                if case .change = objectChange {
                    self.objectWillChange.send()
                }
            }))
        }
    }
    
    private func fetchUID(_ realm:Realm){
        // When the uid is not yet set
        if self.uid.contains("0xNEW") {
            
            // Fetch device name
            let setting = realm.objects(Setting.self).filter("key = 'device/name'").first
            if let setting = setting {
                
                // Set it as the uid
                self.uid = unserialize(setting.json)
            }
        }
    }
    
    public func setCurrentSession(_ session:Session) {
        try! realm!.write {
            
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
    
 
    public func load(_ realm:Realm, _ ch:Cache, _ callback: () -> Void) throws {
        
        // Determine self.uid
        fetchUID(realm)
        
        if self.uid == "" {
            print("Error: installation has been corrupted")
            uid = "unknown"
        }
        
        // Activate this session to make sure its stored in realm
        if let fromCache = realm.object(ofType: Sessions.self, forPrimaryKey: self.uid) {
            // Sync with the cached version
            try! self.merge(fromCache)
            
            // Turn myself in a managed object by realm
            try! realm.write { realm.add(self, update: .modified) }
            
            // Add listeners to all session objects
            postInit()
            
            // Notify Main of any changes
            rlmTokens.append(self.observe({ (objectChange) in
                if case .change = objectChange {
                    self.objectWillChange.send()
                }
            }))
        }
        else {
            throw "Exception: Could not initialize sessions"
        }

        // Done
        callback()
    }
    
 
    public func install(_ realm:Realm) {
        // Load default sessions from the package
        let defaultSessions:Sessions = try! Sessions.fromJSONFile("default_sessions")
        
        fetchUID(realm)
        
        // Force same primary key
        defaultSessions.uid = self.uid
        
        // Store session
        try! realm.write {
            realm.add(defaultSessions, update: .modified)
        }
    }
    
    public func merge(_ sessions:Sessions) throws {
        func doMerge() {
            let properties = self.objectSchema.properties
            for prop in properties {
                if prop.name == "sessions" {
                    self.sessions.append(objectsIn: sessions.sessions)
                }
                else {
                    self[prop.name] = sessions[prop.name]
                }
            }
        }

        if let realm = realm { try! realm.write { doMerge() } }
        else { doMerge() }
    }
    
    /// Find a session using text
    public func findSession(_ query:String) -> Void {}

    /// Clear all sessions and create a new one
    public func clear() -> Void {}
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> Sessions {
        let jsonData = try jsonDataFromFile(file, ext)
        let sessions:Sessions = try MemriJSONDecoder.decode(Sessions.self, from: jsonData)
        return sessions
    }
    
    public class func fromJSONString(_ json: String) throws -> Sessions {
        let sessions:Sessions = try MemriJSONDecoder.decode(Sessions.self, from: Data(json.utf8))
        return sessions
    }
}
