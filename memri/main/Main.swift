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
     *
     */
    @Published public var sessions: Sessions
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
    
    // TODO @koen these renderer objects seem slightly out of place here.
    // Could there be some kind of .renderers object that sits on main?
    var renderers: [String: AnyView] = [
        "list": AnyView(ListRenderer()),
        "richTextEditor": AnyView(RichTextRenderer()),
        "thumbnail": AnyView(ThumbnailRenderer())
    ]
    
    var renderObjects: [String: RendererObject] = [
        "list": ListRendererObject(),
        "richTextEditor": RichTextRendererObject(),
        "thumbnail": ThumbnailRendererObject()
    ]
    
    var renderObjectTuples: [(key: String, value: RendererObject)] {
        return renderObjects.sorted{$0.key < $1.key}
    }
    
    var currentRenderer: AnyView {
        self.renderers[self.computedView.rendererName, default: AnyView(ThumbnailRenderer())]
    }
    
//    public let navigationCache: NavigationCache
    
    private var cancellable: AnyCancellable? = nil
    private var scheduled: Bool = false
    
    init(name:String, key:String) {
        podApi = PodAPI(key)
        cache = Cache(podApi)
        realm = cache.realm
        settings = Settings(realm)
        installer = Installer(realm)
        sessions = Sessions(realm)
        computedView = ComputedView(cache)
        
        cache.scheduleUIUpdate = scheduleUIUpdate
    }
    
    public func boot(_ callback: @escaping (_ error:Error?, _ success:Bool) -> Void) -> Main {
        
        // Make sure memri is installed properly
        self.installer.installIfNeeded(self) {

            // Load settings
            self.settings.load() {
                
                // Load NavigationCache (from cache and/or api)
                // TODO
                
                // Load view configuration
                try! self.sessions.load(realm, cache) {
                    
                    // Load current view
                    self.setComputedView()
                    
                    // Done
                    callback(nil, true)
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
            let computedView = try! self.sessions.computeView() // TODO handle errors better
                
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
    
    /**
     * Adds a view to the history of the currentSession and displays it.
     * If the view was already part of the currentSession.views it reorders it on top
     */
    func openView(_ view:SessionView){
        let session = self.currentSession
        
        // Write updates to realm
        try! realm.write {
        
            // Remove all items after the current index
            session.views.removeSubrange((session.currentViewIndex + 1)...)
            
            // Add the view to the session
            session.views.append(view)
            
            // Update the index pointer
            session.currentViewIndex = session.views.count - 1
        }
        
        setComputedView()
    }
    
    func openView(_ item:DataItem){
        // Create a new view
        let view = SessionView()
        
        // Set the query options to load the item
        view.queryOptions!.query = item.getString("uid")
        
        // Open the view
        self.openView(view)
    }
    
    public func openView(_ view: String) {}
    public func openView(_ items: [DataItem]) {}

    /**
     * Add a new data item and displays that item in the UI
     * in edit mode
     */
    public func addFromTemplate(_ template:DataItem) {
        // Copy template
        let copy = self.cache.duplicate(template)
        
        // Add the new item to the cache
        _ = try! self.cache.addToCache(copy)
        
        // Open view with the now managed copy
        self.openView(copy)
    }

    /**
     * Executes the action as described in the action description
     */
  
}
