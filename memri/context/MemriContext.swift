import Foundation
import Combine
import SwiftUI
import RealmSwift

/*
 Notes on documentation
 
 We use the following documentation keywords
 - bug
 - Remark
 - Requires
 - See also
 - warning

 Also remember, when using markdown in your documentation
 - Use backticks for code
 */


// TODO Remove this and find a solution for Edges
var globalCache:Cache? = nil


public class MemriContext: ObservableObject {
 
    public var name: String = ""
    /// The current session that is active in the application
    @Published public var currentSession: Session = Session()
 
    @Published public var cascadingView: CascadingView
 
    @Published public var sessions: Sessions
 
    public var views: Views
 
    public var settings: Settings
 
    public var installer: Installer
 
    public var podAPI: PodAPI
 
    public var cache: Cache
 
    public var realm: Realm
 
    public var navigation: MainNavigation
 
    public var renderers: Renderers
 
    public var items: [DataItem] {
        get {
            self.cascadingView.resultSet.items
        }
        set {
            // Do nothing
            print("THIS SHOULD NEVER BE PRINTED2")
        }
    }
 
    public var item: DataItem? {
        get {
            self.cascadingView.resultSet.singletonItem
        }
        set {
            // Do nothing
            print("THIS SHOULD NEVER BE PRINTED")
        }
    }
    
    public var closeStack = [() -> Void]() // A stack of close actions of global popups
    
    private var scheduled: Bool = false
    private var scheduledComputeView: Bool = false
    
    func scheduleUIUpdate(_ check:(_ context:MemriContext) -> Bool){
        // Don't schedule when we are already scheduled
        if !scheduled && check(self) {
            
            // Prevent multiple calls to the dispatch queue
            scheduled = true
            
            // Schedule update
            DispatchQueue.main.async {
                
                // Reset scheduled
                self.scheduled = false
                
                // Update UI
                self.objectWillChange.send()
            }
        }
    }
    
    func scheduleCascadingViewUpdate(){
        // Don't schedule when we are already scheduled
        if !scheduledComputeView {
            
            // Prevent multiple calls to the dispatch queue
            scheduledComputeView = true
            
            // Schedule update
            DispatchQueue.main.async {
                
                // Reset scheduled
                self.scheduledComputeView = false
                
                // Update UI
                do { try self.updateCascadingView() }
                catch {
                    // TODO User error handling
                    // TODO Error Handling
                    errorHistory.error("Could not update CascadingView: \(error)")
                }
            }
        }
    }
    
    public func updateCascadingView() throws {
        self.maybeLogUpdate()
        
        // Fetch datasource if not yet parsed yet
        let currentView = self.sessions.currentView
        if currentView.datasource == nil {
            if let parsedDef = try views.parseDefinition(currentView.viewDefinition) {
                if let ds = parsedDef["datasourceDefinition"] as? CVUParsedDatasourceDefinition {
                    realmWriteIfAvailable(realm) {
                        // TODO this is at the wrong moment. Should be done after cascading
                        
                        currentView.datasource =
                            try Datasource.fromCVUDefinition(ds, currentView.viewArguments)
                    }
                }
                else {
                    throw "Exception: Missing datasource in session view"
                }
            }
            else {
                throw "Exception: Unable to parse view definition"
            }
        }
        
        if let datasource = currentView.datasource {
            // Fetch the resultset associated with the current view
            let resultSet = cache.getResultSet(datasource)
            
            // If we can guess the type of the result based on the query, let's compute the view
            if resultSet.determinedType != nil {
                
                if self is RootContext { // if type(of: self) == RootMain.self {
                    errorHistory.info("Computing view "
                        + (currentView.name ?? currentView.viewDefinition?.selector ?? ""))
                }
                
                do {
                    // Calculate cascaded view
                    let cascadingView = try self.views.createCascadingView() // TODO handle errors better
                
                    // Update current session
                    self.currentSession = self.sessions.currentSession // TODO filter to a single property
                    
                    // Set the newly computed view
                    self.cascadingView = cascadingView
                    
                    // Load data in the resultset of the computed view
                    try self.cascadingView.resultSet.load { (error) in
                        if let error = error {
                            // TODO Refactor: Log warning to user
                            print("Error: could not load result: \(error)")
                        }
                        else {
                            maybeLogRead()
                            
                            // Update the UI
                            scheduleUIUpdate{_ in true}
                        }
                    }
                }
                catch let error {
                    // TODO Error handling
                    // TODO User Error handling
                    errorHistory.error("\(error)")
                }
                
                // Update the UI
                scheduleUIUpdate{_ in true}
            }
            // Otherwise let's execute the query first
            else {
                
                // Updating the data in the resultset of the session view
                try resultSet.load { (error) in
                    
                    // Only update when data was retrieved successfully
                    if let error = error {
                        // TODO Error handling
                        print("Error: could not load result: \(error)")
                    }
                    else {
                        // Update the current view based on the new info
                        scheduleUIUpdate{_ in true} // TODO shouldn't this be setCurrentView??
                    }
                }
            }
        }
        else {
            throw "Exception: Missing datasource in session view"
        }
    }
    
    private func maybeLogRead(){
        if let item = self.cascadingView.resultSet.singletonItem{
            realmWriteIfAvailable(realm) {
                self.realm.add(AuditItem(action: "read", appliesTo: [item]))
            }
        }
    }
    
    private func maybeLogUpdate(){
        if self.cascadingView.context == nil { return }
        
        let syncState = self.cascadingView.resultSet.singletonItem?.syncState
        if let syncState = syncState, syncState.changedInThisSession {
            let fields = syncState.updatedFields
            realmWriteIfAvailable(realm) {
                // TODO serialize
                if let item = self.cascadingView.resultSet.singletonItem{
                    self.realm.add(AuditItem(contents: serialize(AnyCodable(Array(fields))),
                                             action: "update", appliesTo: [item]))
                    syncState.changedInThisSession = false
                }
                else {
                    print("Could not log update, no Item found")
                }
            }
        }
    }
    
    public func getPropertyValue(_ name:String) -> Any {
        let type: Mirror = Mirror(reflecting:self)

        for child in type.children {
            if child.label == name || child.label == "_" + name {
                return child.value
            }
        }
        
        return ""
    }
    
    struct Alias {
        var key:String
        var type:String
        var on:(() -> Void)?
        var off:(() -> Void)?
    }
    
    var aliases:[String:Alias] = [:]
    
    subscript(propName:String) -> Any? {
        get {
            if let alias = aliases[propName] {
                switch alias.type {
                case "bool":
                    let value:Bool? = settings.get(alias.key)
                    return value ?? false
                case "string":
                    let value:String? = settings.get(alias.key)
                    return value ?? ""
                case "int":
                    let value:Int? = settings.get(alias.key)
                    return value ?? 0
                case "double":
                    let value:Double? = settings.get(alias.key)
                    return value ?? 0
                default:
                    return nil
                }
            }
            
            return nil
        }
        set(newValue) {
            if let alias = aliases[propName]{
                settings.set(alias.key, AnyCodable(newValue))
                
                if let x = newValue as? Bool { x ? alias.on?() : alias.off?() }
                
                
                scheduleUIUpdate{_ in true}
            }
            else {
                print("Cannot set property \(propName), does not exist on context")
            }
        }
    }
    
    public var showSessionSwitcher:Bool {
        get { return self["showSessionSwitcher"] as? Bool == true }
        set(value) { self["showSessionSwitcher"] = value }
    }
    
    // TODO Refactor: use a property wrapper to apply state recording in settings
    public var showNavigationBinding = Binding<Bool>(
        get: { return true },
        set: { let _ = $0 }
    )
    
    public var showNavigation:Bool {
        get { return self["showNavigation"] as? Bool == true }
        set(value) { self["showNavigation"] = value }
    }
    
    init(
        name: String,
        podAPI: PodAPI,
        cache: Cache,
        realm: Realm,
        settings: Settings,
        installer: Installer,
        sessions: Sessions,
        views: Views,
        cascadingView: CascadingView,
        navigation: MainNavigation,
        renderers: Renderers
    ) {
        self.name = name
        self.podAPI = podAPI
        self.cache = cache
        self.realm = realm
        self.settings = settings
        self.installer = installer
        self.sessions = sessions
        self.views = views
        self.cascadingView = cascadingView
        self.navigation = navigation
        self.renderers = renderers
        
        // TODO: FIX
        self.cascadingView.context = self
    }
}

public class SubContext: MemriContext {
    
    let parent: MemriContext
    
    init(name:String, _ context:MemriContext, _ session:Session) {
        let views = Views(context.realm)
        
        parent = context
        
        super.init(
            name: name,
            podAPI: context.podAPI,
            cache: context.cache,
            realm: context.realm,
            settings: context.settings,
            installer: context.installer,
            sessions: Sessions(context.realm),
            views: views,
            cascadingView: context.cascadingView,
            navigation: context.navigation,
            renderers: context.renderers
        )
        
        self.closeStack = context.closeStack
        
        views.context = self
        
        // For now sessions is unmanaged. TODO: Refactor: we may want to change this.
        sessions.sessions.append(session)
        sessions.currentSessionIndex = 0
    }
}


/// Represents the entire application user interface. One can imagine in the future there being multiple applications, each aimed at a
///  different way to represent the data. For instance an application that is focussed on voice-first instead of gui-first.
public class RootContext: MemriContext {
    private var cancellable: AnyCancellable? = nil
    
    // TODO Refactor: Should installer be moved to rootmain?
    
    init (name: String, key: String) {
        let podAPI = PodAPI(key)
        let cache = Cache(podAPI)
        let realm = cache.realm
        
        globalCache = cache // TODO remove this and fix edges
        
        super.init(
            name: name,
            podAPI: podAPI,
            cache: cache,
            realm: realm,
            settings: Settings(realm),
            installer: Installer(realm),
            sessions: Sessions(realm),
            views: Views(realm),
            cascadingView: CascadingView(SessionView(), []),
            navigation: MainNavigation(realm),
            renderers: Renderers()
        )
        
        self.cascadingView.context = self
        
        let takeScreenShot = {
            // Make sure to record a screenshot prior to session switching
            self.currentSession.takeScreenShot() // Optimize by only doing this when a property in session/view/dataitem has changed
        }
        
        // TODO Refactor: This is a mess. Create a nice API, possible using property wrappers
        aliases = [
           "showSessionSwitcher": Alias(key:"device/gui/showSessionSwitcher", type:"bool", on:takeScreenShot),
           "showNavigation": Alias(key:"device/gui/showNavigation", type:"bool", on:{
                self.showNavigationBinding.wrappedValue = true
                takeScreenShot()
           }, off: {
                self.showNavigationBinding.wrappedValue = false
           })
       ]
        
        cache.scheduleUIUpdate = scheduleUIUpdate
        navigation.scheduleUIUpdate = scheduleUIUpdate
        
        // Make settings global so it can be reached everywhere
        globalSettings = settings
    }
    
    // TODO Refactor: This is a mess.
    public func initNavigation(_ showNav:Binding<Bool>) {
        self.showNavigationBinding = showNav
        if self.showNavigation {
            DispatchQueue.main.async {
                showNav.wrappedValue = true
            }
        }
    }
    
    public func createSubContext(_ session:Session) -> MemriContext {
        return SubContext(name: "Proxy", self, session)
    }
    
    public func boot() throws {
        // Make sure memri is installed properly
        try self.installer.installIfNeeded(self) {

            // Load settings
            try self.settings.load() {
                
                // Load NavigationCache (from cache and/or api)
                try self.navigation.load() {
                
                    #if targetEnvironment(simulator)
                        // Reload for easy adjusting
                        self.views.context = self
                        try self.views.install()
                    #endif
                    
                    // Load views configuration
                    try self.views.load(self) {
                    
                        // Load sessions configuration
                        try self.sessions.load(realm, cache) {
                            
                            // Update view when sessions changes
                            self.cancellable = self.sessions.objectWillChange.sink { (_) in
                                self.scheduleUIUpdate{_ in true}
                            }
                            
                            self.currentSession.access()
                            self.currentSession.currentView.access()
                            
                            // Load current view
                            try self.updateCascadingView()
                        }
                    }
                }
            }
        }
    }
    
    public func mockBoot() -> MemriContext {
        do {
            try self.boot()
            return self
        }
        catch let error { print(error) }
        
        return self
    }
}