//
//  Session.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import Foundation
import Combine
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
    let sessions = List<Session>() // @Published
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
    
    private var cancellables: [AnyCancellable] = []
    private var defaultViews: [String:[String:SessionView]] = [:]
    
    private var cache:Cache? = nil
    
    public override static func primaryKey() -> String? {
        return "uid"
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            uid = try decoder.decodeIfPresent("uid") ?? uid
            currentSessionIndex = try decoder.decodeIfPresent("currentSessionIndex") ?? currentSessionIndex
            
//            if self.realm != nil {
//                try! self.realm!.write {
//                    decodeIntoList(decoder, "sessions", self.sessions)
//                }
//            }
//            else {
                decodeIntoList(decoder, "sessions", self.sessions)
//            }
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
        self.cancellables = []
        for session in sessions{
            self.cancellables.append(session.objectWillChange.sink { (_) in
                print("session \(session) was changed")
                self.objectWillChange.send()
            })
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
    
    /**
     *
     */
    public func load(_ realm:Realm, _ ch:Cache, _ callback: () -> Void) throws {
        // Store cache for use within computeView()
        self.cache = ch
        
        // Load the default views from the package
        let jsonData = try! jsonDataFromFile("views_from_server")
        self.defaultViews = try! JSONDecoder()
            .decode([String:[String:SessionView]].self, from: jsonData)
        
        fetchUID(realm)
        
        if self.uid == "" {
            print("Error: installation has been corrupted")
            uid = "unknown"
        }
        
        // Activate this session to make sure its stored in realm
        try! realm.write {
            if let fromCache = realm.objects(Sessions.self).filter("uid = '\(self.uid)'").first {
                // Sync with the cached version
                self.merge(fromCache)
                
                // Turn myself in a managed object by realm
                realm.add(self, update: .modified)
            }
            else {
                throw "Exception: Could not initialize sessions"
            }
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
    
    public func merge(_ sessions:Sessions) {
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

    /*
    "{type:Note}"
    "{renderer:list}"
    "{[type:Note]}"
    */
    public func computeView(_ argView:SessionView? = nil) throws -> ComputedView {
        let viewFromSession = argView == nil
            ? self.currentSession.currentView
            : argView!
        
        // Create a new view
        let computedView = ComputedView(self.cache!)
        let previousView = self.currentSession.currentView
        
        var isList:Bool = true
        var type:String = ""
        
        // Fetch query from the view from session
        if let queryOptions = viewFromSession.queryOptions {
            
            // Look up the associated result set
            let resultSet = cache!.getResultSet(queryOptions)
            
            // Determine whether this is a list or a single item resultset
            isList = resultSet.isList
            
            // Fetch the type of the results
            if let determinedType = resultSet.determinedType {
                type = determinedType
            }
            else {
                throw "Exception: ResultSet does not know the type of its data"
            }
        }
        else {
            throw "Exception: Cannot compute a view without a query to fetch data"
        }

        // Helper lists
        var renderViews:[SessionView] = []
        var datatypeViews:[SessionView] = []
        var rendererNames:[String] = []
        var cascadeOrders:[String:[List<String>]] = ["defaults":[List()], "user":[]]
        let searchOrder = ["defaults", "user"]
        var rendererName:String
        
        cascadeOrders["defaults"]![0].append(objectsIn: ["renderer", "datatype"])
        
        // If we know the type of data we are rendering use it to determine the view
        if type != "mixed" {
            // Determine query
            let needle = isList ? "{[type:\(type)]}" : "{type:\(type)}"
            
            // Find views based on datatype
            for key in searchOrder {
                if let datatypeView = self.defaultViews[key]![needle] {
                    datatypeViews.append(datatypeView)
                    
                    if let S = datatypeView.rendererName { rendererNames.append(S) }
                    if datatypeView.cascadeOrder.count > 0 {
                        cascadeOrders[key]?.append(datatypeView.cascadeOrder)
                    }
                }
            }
            
            rendererName = rendererNames[rendererNames.count - 1]
        }
        // Otherwise default to what we know from the view from the session
        else {
            rendererName = viewFromSession.rendererName ?? ""
        }
        
        // Find renderer views
        if rendererName != "" {
            // Determine query
            let needle = "{renderer:\(rendererName)}"
            
            for key in searchOrder {
                if let rendererView = self.defaultViews[key]![needle] {
                    renderViews.append(rendererView)
                    
                    if rendererView.cascadeOrder.count > 0 {
                        cascadeOrders[key]?.append(rendererView.cascadeOrder)
                    }
                }
            }
        }
        else {
            throw "Exception: Could not find which renderer to use. renderName not set in this view"
        }

        // Choose cascade order
        let preferredCascadeOrder = (cascadeOrders["user"]!.count > 0
            ? cascadeOrders["user"]
            : cascadeOrders["defaults"]) ?? []
        
        var cascadeOrder = preferredCascadeOrder[preferredCascadeOrder.count - 1]
        if (cascadeOrder.count == 0) {
            cascadeOrder = List()
            cascadeOrder.append(objectsIn: ["renderer", "datatype"])
        }
        
        if (Set(preferredCascadeOrder).count > 1) {
            print("Warn: Found multiple cascadeOrders when cascading view. Choosing \(cascadeOrder)")
        }
        
        // Cascade the different views
        for key in cascadeOrder {
            var views:[SessionView]
            
            if key == "renderer" { views = renderViews }
            else if key == "datatype" { views = datatypeViews }
            else {
                throw ("Exception: Unknown cascadeOrder type specified: \(key)")
            }
            
            for view in views {
                computedView.merge(view)
            }
        }
        
        // Cascade the view from the session
        // Loads user interactions, e.g. selections, scrollstate, changes of renderer, etc.
        computedView.finalMerge(viewFromSession)
        
        do {
            try computedView.validate()
        }
        catch {
            throw "Exception: Invalid Computed View: \(error)"
        }
        
        // turn off editMode when navigating
        if previousView.isEditMode.value == true {
            try! realm!.write {
                previousView.isEditMode.value = false
            }
        }
        
        // hide filterpanel if view doesnt have a button to open it
        if self.currentSession.showFilterPanel {
            if computedView.filterButtons.filter({ $0.actionName == .toggleFilterPanel }).count == 0 {
                try! realm!.write {
                    self.currentSession.showFilterPanel = false
                }
            }
        }
        
        return computedView
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
    let views = List<SessionView>() // @Published
    /**
     *
     */
    @objc dynamic var showFilterPanel:Bool = false
    /**
     *
     */
    @objc dynamic var showContextPane:Bool = false
    
    var cancellables: [AnyCancellable] = []

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
            
            decodeIntoList(decoder, "views", self.views)
        }
    }
    
    required init() {
        super.init()
        self.postInit()
    }
    
//    deinit {
//        if let realm = self.realm {
//            try! realm.write {
//                realm.delete(self)
//            }
//        }
//    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> Session {
        let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
        let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
        let jsonData = jsonString.data(using: .utf8)!
        let session: Session = try! JSONDecoder().decode(Session.self, from: jsonData)
        return session
    }
    
    public func postInit(){
        for sessionView in views{
            cancellables.append(sessionView.objectWillChange.sink { (_) in
                self.objectWillChange.send()
            })
        }
    }

    public static func == (lt: Session, rt: Session) -> Bool {
        return lt.id == rt.id
    }
}
