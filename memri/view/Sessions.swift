//
//  Session.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

public class Sessions: Object, ObservableObject, Decodable {
    /**
     *
     */
    @objc dynamic var uid:String = ""
    /**
     *
     */
    @objc dynamic var syncState:SyncState? = SyncState()
    /**
     *
     */
    @objc dynamic var currentSessionIndex: Int = 0
    /**
     *
     */
    @objc dynamic var showNavigation: Bool = false
    /**
     *
     */
    let sessions = RealmSwift.List<Session>() // @Published
    /**
     *
     */
    var currentSession: Session {
        return sessions.count > 0 ? sessions[currentSessionIndex] : Session()
    }
    /**
     *
     */
    var currentView: SessionView {
        return currentSession.currentView
    }
    
    private var rlmTokens: [NotificationToken] = []
    private var cancellables: [AnyCancellable] = []
    
    public override static func primaryKey() -> String? {
        return "uid"
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            uid = try decoder.decodeIfPresent("uid") ?? uid
            currentSessionIndex = try decoder.decodeIfPresent("currentSessionIndex") ?? currentSessionIndex
            
            decodeIntoList(decoder, "sessions", self.sessions)
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
        if self.uid == "" {
            
            // Fetch device name
            let setting = realm.objects(Setting.self).filter("key = 'device/name'").first
            if let setting = setting {
                
                // Set it as the uid
                self.uid = unserialize(setting.json)
            }
        }
    }
    
    public func addSession(_ session:Session) {
        // TODO: If session == nil session = Session()
        
        try! realm!.write {
        
            // Add session to array
            sessions.append(session)
            
            // Update the index pointer
            currentSessionIndex = sessions.count - 1
        }
        
        decorate(session)
    }
    
    /**
     *
     */
    public func load(_ realm:Realm, _ ch:Cache, _ callback: () -> Void) throws {
        
        // Determine self.uid
        fetchUID(realm)
        
        if self.uid == "" {
            print("Error: installation has been corrupted")
            uid = "unknown"
        }
        
        // Activate this session to make sure its stored in realm
        if let fromCache = realm.objects(Sessions.self).filter("uid = '\(self.uid)'").first {
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
    
    /**
     *
     */
    public func install(_ realm:Realm) {
        // Load default sessions from the package
        let defaultSessions = try! Sessions.fromJSONFile("default_sessions")
        
        fetchUID(realm)
        
        // Force same primary key
        defaultSessions.uid = self.uid
        
        // Store session
        try! realm.write {
            realm.add(defaultSessions, update: .modified)
        }
    }
    
    /**
     *
     */
    public func setCurrentSession(_ session:Session) throws -> Void {
        let index = sessions.firstIndex(of: session) ?? -1
        if (index > 0) { throw "Should never happen" } // Should never happen
        
        currentSessionIndex = index
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
    
    /**
     * Find a session using text
     */
    public func findSession(_ query:String) -> Void {}

    /**
     * Clear all sessions and create a new one
     */
    public func clear() -> Void {}
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> Sessions {
        let jsonData = try jsonDataFromFile(file, ext)
        let sessions:Sessions = try JSONDecoder().decode(Sessions.self, from: jsonData)
        return sessions
    }
    
    public class func fromJSONString(_ json: String) throws -> Sessions {
        let sessions:Sessions = try JSONDecoder().decode(Sessions.self, from: Data(json.utf8))
        return sessions
    }
}

public class Session: Object, ObservableObject, Decodable {
    var id: String = UUID().uuidString
    
    /**
     *
     */
    @objc dynamic var syncState:SyncState? = SyncState()
    /**
     *
     */
    @objc dynamic var currentViewIndex: Int = 0
    /**
     *
     */
    let views = RealmSwift.List<SessionView>() // @Published
    /**
     *
     */
    @objc dynamic var showFilterPanel:Bool = false
    /**
     *
     */
    @objc dynamic var showContextPane:Bool = false
    /**
     *
     */
    @objc dynamic var editMode:Bool = false
    
    /**
     *
     */
    var isEditMode: EditMode {
        get {
            if editMode { return .active }
            else { return .inactive }
        }
        set (value) {
            if value == .active { editMode = true }
            else { editMode = false }
        }
    }
    
    private var rlmTokens: [NotificationToken] = []
    private var cancellables: [AnyCancellable] = []

    var backButton: ActionDescription? {
        if self.currentViewIndex > 0 {
            return ActionDescription(icon: "chevron.left", actionName: .back)
        }
        else {
            return nil
        }
    }
    
    public var currentView: SessionView {
        return views.count > 0 ? views[currentViewIndex] : SessionView()
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            id = try decoder.decodeIfPresent("id") ?? id
            
            currentViewIndex = try decoder.decodeIfPresent("currentViewIndex") ?? currentViewIndex
            showFilterPanel = try decoder.decodeIfPresent("showFilterPanel") ?? showFilterPanel
            showContextPane = try decoder.decodeIfPresent("showContextPane") ?? showContextPane
            editMode = try decoder.decodeIfPresent("editMode") ?? editMode
            
            decodeIntoList(decoder, "views", self.views)
        }
    }
    
    required init() {
        super.init()
        self.postInit()
    }
    
    public func postInit(){
        for view in views{
            decorate(view)
        }
        
        if realm != nil {
            rlmTokens.append(self.observe({ (objectChange) in
                if case .change = objectChange {
                    self.objectWillChange.send()
                }
            }))
        }
    }
    
    private func decorate(_ view:SessionView) {
        rlmTokens.append(view.observe({ (objectChange) in
            if case .change = objectChange {
                self.objectWillChange.send()
            }
        }))
    }
    
//    deinit {
//        if let realm = self.realm {
//            try! realm.write {
//                realm.delete(self)
//            }
//        }
//    }
    
    public func addView(_ view:SessionView) {
        // Write updates to realm
        try! realm!.write {
        
            // Remove all items after the current index
            views.removeSubrange((currentViewIndex + 1)...)
            
            // Add the view to the session
            views.append(view)
            
            // Update the index pointer
            currentViewIndex = views.count - 1
        }
        
        decorate(view)
    }
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> Session {
        let jsonData = try jsonDataFromFile(file, ext)
        let session:Session = try JSONDecoder().decode(Session.self, from: jsonData)
        return session
    }
    
    public class func fromJSONString(_ json: String) throws -> Session {
        let session:Session = try JSONDecoder().decode(Session.self, from: Data(json.utf8))
        return session
    }

    public static func == (lt: Session, rt: Session) -> Bool {
        return lt.id == rt.id
    }
}
