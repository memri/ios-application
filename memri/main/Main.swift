import Foundation
import Combine
import SwiftUI
import RealmSwift

/**
 * Represents the entire application user interface.
 * One can imagine in the future there being multiple applications,
 * each aimed at a different way to represent the data. For instance
 * an application that is focussed on voice-first instead of gui-first.
 */
public class Main: ObservableObject {
    /**
     *
     */
    public let name: String = "GUI"
    /**
     * The current session that is active in the application
     */
    @Published public var currentSession: Session = Session()
    /**
     *
     */
    @Published public var computedView: ComputedView
    /**
     *
     */
    @Published public var sessions: Sessions
    /**
     *
     */
    public var views: Views
    /**
     *
     */
    public var settings: Settings
    /**
     *
     */
    public var installer: Installer
    /**
     *
     */
    public var podApi: PodAPI
    /**
     *
     */
    public var cache: Cache
    /**
     *
     */
    public var realm: Realm
    /**
     *
     */
    public var navigation: MainNavigation
    /**
     *
     */
    public var renderers: Renderers
    /**
     *
     */
    public var currentRendererView: AnyView {
        self.renderers.allViews[self.computedView.rendererName]!
    }
    /**
     *
     */
    public var items: [DataItem] {
        get {
            self.computedView.resultSet.items
        }
        set { 
            // Do nothing
            print("THIS SHOULD NEVER BE PRINTED2")
        }
    }
    /**
     *
     */
    public var item: DataItem? {
        get {
            self.computedView.resultSet.item
        }
        set {
            // Do nothing
            print("THIS SHOULD NEVER BE PRINTED")
        }
    }
    
    struct Alias {
        var key:String
        var type:String
    }
    
    let aliases:[String:Alias] = [
        "showSessionSwitcher": Alias(key:"device/gui/showSessionSwitcher", type:"bool"),
        "showNavigation": Alias(key:"device/gui/showNavigation", type:"bool")
    ]
    
    subscript(propName:String) -> Any? {
        get {
            let alias = aliases[propName]!
            
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
        set(newValue) {
            settings.set(aliases[propName]!.key, AnyCodable(newValue))
            
            scheduleUIUpdate()
        }
    }
    
    public var showSessionSwitcher:Bool {
        get { return self["showSessionSwitcher"] as! Bool }
        set(value) { self["showSessionSwitcher"] = value }
    }
    
    public var showNavigation:Bool {
        get { return self["showNavigation"] as! Bool }
        set(value) { self["showNavigation"] = value }
    }
    
    private var cancellable: AnyCancellable? = nil
    private var scheduled: Bool = false
    private var scheduledComputeView: Bool = false
    
    init(name:String, key:String) {
        podApi = PodAPI(key)
        cache = Cache(podApi)
        realm = cache.realm
        settings = Settings(realm)
        installer = Installer(realm)
        sessions = Sessions(realm)
        views = Views(realm)
        computedView = ComputedView(cache)
        navigation = MainNavigation(realm)
        renderers = Renderers()
        
        cache.scheduleUIUpdate = scheduleUIUpdate
    }
    
    public func boot(_ callback: @escaping (_ error:Error?, _ success:Bool) -> Void) -> Main {
        
        // Make sure memri is installed properly
        self.installer.installIfNeeded(self) {

            // Load settings
            self.settings.load() {
                
                // Load NavigationCache (from cache and/or api)
                self.navigation.load() {
                
                    // Load views configuration
                    try! self.views.load(self) {
                    
                        // Load sessions configuration
                        try! self.sessions.load(realm, cache) {
                            
                            // Update view when sessions changes
                            self.cancellable = self.sessions.objectWillChange.sink { (_) in
                                self.scheduleUIUpdate()
                            }
                            
                            // Load current view
                            self.setComputedView()
                            
                            // Done
                            callback(nil, true)
                        }
                    }
                }
            }
        }
        
        return self
    }
    
    public func mockBoot() -> Main {
        return self.boot({_,_ in })
    }
    
    public func setComputedView(){
        // Fetch the resultset associated with the current view
        let resultSet = cache.getResultSet(self.currentSession.currentView.queryOptions!)
        
        // If we can guess the type of the result based on the query, let's compute the view
        if resultSet.determinedType != nil {
            
            // Calculate cascaded view
            let computedView = try! self.views.computeView() // TODO handle errors better
                
            // Update current session
            self.currentSession = self.sessions.currentSession // TODO filter to a single property
            
            // Set the newly computed view
            self.computedView = computedView
            
            // Load data in the resultset of the computed view
            try! self.computedView.resultSet.load { (error) in
                if error != nil {
                    print("Error: could not load result: \(error!)")
                }
                else {
                    // Update the UI
                    scheduleUIUpdate()
                }
            }
            
            // Update the UI
            scheduleUIUpdate()
        }
        // Otherwise let's execute the query first
        else {
            
            // Updating the data in the resultset of the session view
            try! resultSet.load { (error) in
                
                // Only update when data was retrieved successfully
                if error != nil {
                    print("Error: could not load result: \(error!)")
                }
                else {
                    // Update the current view based on the new info
                    scheduleUIUpdate() // TODO shouldn't this be setCurrentView??
                }
            }
        }
    }
    
    func scheduleUIUpdate(){
        // Don't schedule when we are already scheduled
        if !scheduled {
            
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
    
    func scheduleComputeView(){
        // Don't schedule when we are already scheduled
        if !scheduledComputeView {
            
            // Prevent multiple calls to the dispatch queue
            scheduledComputeView = true
            
            // Schedule update
            DispatchQueue.main.async {
                
                // Reset scheduled
                self.scheduledComputeView = false
                
                // Update UI
                self.setComputedView()
            }
        }
    }
    
    public func getPropertyValue(_ name:String) -> Any {
        let type: Mirror = Mirror(reflecting:self)

        for child in type.children {
            if child.label! == name || child.label! == "_" + name {
                return child.value
            }
        }
        
        return ""
    }
}
