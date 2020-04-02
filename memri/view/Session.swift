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
    @objc dynamic var loadState:SyncState? = SyncState()
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
    
    public override static func primaryKey() -> String? {
        return "uid"
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            uid = try decoder.decodeIfPresent("uid") ?? uid
            currentSessionIndex = try decoder.decodeIfPresent("currentSessionIndex") ?? currentSessionIndex
            
            let sessions:[Session]? = try decoder.decodeIfPresent("sessions")
            if let sessions = sessions {
                for session in sessions { self.sessions.append(session) }
            }
        }
        
        self.postInit()
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
    
    public convenience init(_ realm:Realm) {
        self.init()
        
        fetchUID(realm)
        
        self.postInit()
    }
    
    required init() {
        super.init()
    }
    
    public func postInit(){
        self.cancellables = []
        for session in sessions{
            self.cancellables.append(session.objectWillChange.sink { (_) in
                print("session \(session) was changed")
                self.objectWillChange.send()
            })
        }
    }
    
    /**
     *
     */
    public func load(_ realm:Realm, _ callback: () -> Void) {
        // Load the default views from the package
        let jsonData = try! jsonDataFromFile("views_from_server")
        self.defaultViews = try! JSONDecoder()
            .decode([String:[String:SessionView]].self, from: jsonData)
        
        fetchUID(realm)
        
        if self.uid == "" {
            print("Error: installation has been corrupted")
            uid = "unknown"
        }
        
        // Active this session to make sure its stored in realm
        try! realm.write {
            realm.add(self, update: .modified)
        }
        
        // Expand all views
        self.expandAllViews()
        
        // Done
        callback()
    }
    
    /**
     *
     */
    public func install(_ realm:Realm) {
        // Load default sessions from the package
        let defaultSessions = try! Sessions.fromJSONFile("default_sessions")
        dump(defaultSessions.sessions[0].views[0])
        print("ZzZZZZZZZZZZZZ")
        
        for session in defaultSessions.sessions {
            for view in session.views {
                print(view.searchResult.query.query)
                print("--------------------")
            }
        }
        
        fetchUID(realm)
        
        for session in defaultSessions.sessions {
            for view in session.views {
                print(view.searchResult.query.query)
                print("--------------------")
            }
        }
        
        // Force same primary key
        defaultSessions.uid = self.uid
        
        for session in defaultSessions.sessions {
            for view in session.views {
                print(view.searchResult.query.query)
                print("--------------------")
            }
        }
        
        // Store session
        try! realm.write {
            realm.add(defaultSessions, update: .modified)
        }
        
        for session in defaultSessions.sessions {
            for view in session.views {
                print(view.searchResult.query.query)
                print("--------------------")
            }
        }
        
        // Store all views
        defaultSessions.persistAllViews()
    }
    
    /**
     *
     */
    public func setCurrentSession(_ session:Session) throws -> Void {
        let index = sessions.firstIndex(of: session) ?? -1
        if (index > 0) { throw "Should never happen" } // Should never happen
        
        currentSessionIndex = index
    }

    /*
    "{type:Note}"
    "{renderer:list}"
    "{[type:Note]}"
    */
    public func computeView(_ argView:SessionView? = nil) -> SessionView? {
        let viewFromSession = argView == nil
            ? self.currentSession.currentView
            : argView!
        
        dump(viewFromSession)
        
        // Create a new view
        let computedView = SessionView()
        let previousView = self.currentSession.currentView
        
        // TODO: infer from result
        let isList = !viewFromSession.searchResult.query.query!.starts(with: "0x")
        
        // TODO: infer from all results
        var type:String = ""
        if (viewFromSession.searchResult.data.count > 0 ) {
            type = viewFromSession.searchResult.data[0].type
        }

        // Helper lists
        var renderViews:[SessionView] = []
        var datatypeViews:[SessionView] = []
        var rendererNames:[String] = []
        var cascadeOrders:[String:[[String]]] = ["defaults":[["renderer", "datatype"]], "user":[]]
        let searchOrder = ["defaults", "user"]
        var rendererName:String
        
        // If we know the type of data we are rendering use it to determine the view
        if type != "" {
            // Determine query
            let needle = isList ? "{[type:\(type)]}" : "{type:\(type)}"
            
            // Find views based on datatype
            for key in searchOrder {
                if let datatypeView = self.defaultViews[key]![needle] {
                    datatypeViews.append(datatypeView)
                    
                    if let S = datatypeView.rendererName { rendererNames.append(S) }
                    if let S = datatypeView.cascadeOrder { cascadeOrders[key]?.append(S) }
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
                    
                    if let S = rendererView.cascadeOrder { cascadeOrders[key]?.append(S) }
                }
            }
        }

        // Choose cascade order
        let preferredCascadeOrder = (cascadeOrders["user"]!.count > 0
            ? cascadeOrders["user"]
            : cascadeOrders["defaults"]) ?? []
        
        var cascadeOrder = preferredCascadeOrder[preferredCascadeOrder.count - 1]
        if (cascadeOrder.count == 0) { cascadeOrder = ["renderer", "datatype"] }
        
        if (Set(preferredCascadeOrder).count > 1) {
            print("Found multiple cascadeOrders when cascading view. Choosing \(cascadeOrder)")
        }
        
        // Cascade the different views
        for key in cascadeOrder {
            var views:[SessionView]
            
            if key == "renderer" { views = renderViews }
            else if key == "datatype" { views = datatypeViews }
            else {
                print("Unknown cascadeOrder type found: \(key)")
                break
            }
            
            for view in views {
                computedView.merge(view)
            }
        }
        
        // Cascade the view from the session
        // Loads user interactions, e.g. selections, scrollstate, changes of renderer, etc.
        computedView.merge(viewFromSession)
        
        // this is hacky now, will be solved later
        viewFromSession.searchResult.query = computedView.searchResult.query
        computedView.searchResult = viewFromSession.searchResult
        
        do {
            try computedView.validate()
        }
        catch {
            print("View Cascading Error: \(error)")
//            return nil  // TODO look at this again after implementing resultset
        }
        
        // turn off editMode when navigating
        if previousView.isEditMode == true {
            previousView.isEditMode = false
        }
        
        // hide filterpanel if view doesnt have a button to open it
        if self.currentSession.showFilterPanel{
            if computedView.filterButtons!.filter({ $0.actionName == .toggleFilterPanel }).count == 0 {
                self.currentSession.showFilterPanel = false
            }
        }
        
        return computedView
    }
    
    /**
     *
     */
    public func persistAllViews(){
        for session in sessions {
            for view in session.views {
                dump(view)
                print("--------------------")
                view.persist()
            }
        }
    }
    
    /**
     *
     */
    public func expandAllViews(){
        for session in sessions {
            for view in session.views {
                view.expand()
            }
        }
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
    @objc dynamic var loadState:SyncState? = SyncState()
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
            
            let views:[SessionView]? = try decoder.decodeIfPresent("views")
            if let views = views {
                for view in views { self.views.append(view) }
            }
            
            showFilterPanel = try decoder.decodeIfPresent("showFilterPanel") ?? showFilterPanel
            showContextPane = try decoder.decodeIfPresent("showContextPane") ?? showContextPane
        }
    }
    
    required init() {
        super.init()
        self.postInit()
    }
    
    deinit {
        if let realm = self.realm {
            try! realm.write {
                realm.delete(self)
            }
        }
    }
    
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
