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
                    
                    // Hook current session
//                    var isCalled:Bool = false
//                    self.cancellable = self.sessions.objectWillChange.sink {
//                        isCalled = false
//                        DispatchQueue.main.async {
//                            if !isCalled { self.setCurrentView() }
//                            else { isCalled = true }
//                        }
//                    }
                    
                    // Load current view
                    self.setCurrentView()
                    
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
    
    public func setCurrentView(){
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
                    scheduleUIUpdate()
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
                self.sessions.objectWillChange.send()
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
        
        setCurrentView()
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
        try! self.cache.addToCache(copy)
        
        // Open view with the now managed copy
        self.openView(copy)
    }

    /**
     * Executes the action as described in the action description
     */
    public func executeAction(_ action:ActionDescription, _ item:DataItem? = nil, _ items:[DataItem]? = nil) -> Void {
        let params = action.actionArgs
        
        switch action.actionName {
        case .back:
            back()
        case .add:
            addFromTemplate(params[0].value as! DataItem)
        case .delete:
            if let item = item {
                cache.delete(item)
            }
            else if let items = items {
                cache.delete(items)
            }
            
            // Update UI
            scheduleUIUpdate()
        case .openView:
            if let item = item {
                openView(item)
            } else {
                let param0 = params[0].value as! SessionView
                openView(param0)
            }
        case .toggleEditMode:
            toggleEditMode()
        case .toggleFilterPanel:
            toggleFilterPanel()
        case .star:
            star()
        case .showStarred:
            showStarred()
        case .showContextPane:
            openContextPane() // TODO @Jess
        case .showNavigation:
            showNavigation()
        case .openContextView:
            break
        case .share:
            showSharePanel()
        case .addToList:
            addToList()
        case .duplicate:
            if let item = item {
                addFromTemplate(item)
            }
        case .exampleUnpack:
            let (_, _) = (params[0].value, params[1].value) as! (String, Int)
            break
        default:
            print("UNDEFINED ACTION \(action.actionName), NOT EXECUTING")
        }
    }
    
    // TODO move this to searchResult, suggestion: change searchResult to
    // ResultSet (list, item, isList) and maintain only one per query. also add query to sessionview
    private var lastSearchResult:ResultSet?
    private var lastNeedle:String = ""
    private var lastTitle:String? = nil
    func search(_ needle:String) {
        if self.computedView.rendererName != "list" && self.computedView.rendererName != "thumbnail" {
            return
        }
        
        if lastNeedle == needle { return } // TODO removing this causes an infinite loop because onReceive is called based on the objectWillChange.send() - that is unexpected to me
        
        lastNeedle = needle
        
        if needle == "" {
            if lastSearchResult != nil {
                self.computedView.resultSet = lastSearchResult!
                lastSearchResult = nil
                self.computedView.title = lastTitle ?? ""
                
                scheduleUIUpdate()
            }
            return
        }

        if lastSearchResult == nil {
            lastSearchResult = self.computedView.resultSet
            lastTitle = self.computedView.title
        }
        
        let searchResult = lastSearchResult!.filter(lastSearchResult!, needle)
        self.computedView.resultSet = searchResult
        if searchResult.count == 0 {
            self.computedView.title = "No results"
        }
        else {
            self.computedView.title = "\(searchResult.count) items found"
        }
        
        scheduleUIUpdate()
    }
        
    func back(){
        let session = currentSession
        
        if session.currentViewIndex == 0 {
            print("Can't go back. Already at earliest view in session")
//            session.objectWillChange.send()
            return
        }
        else {
            try! realm.write {
                session.currentViewIndex -= 1
            }
            
            setCurrentView()
        }
    }
    
    func showNavigation(){
        try! realm.write {
            self.sessions.showNavigation = true
        }
        
        scheduleUIUpdate()
    }
    
    func changeRenderer(rendererName: String){
        let session = currentSession
        try! realm.write {
            session.currentView.rendererName = rendererName
        }
        
        setCurrentView()
    }
    
    func star() {
        
    }
    
    var lastStarredView:ComputedView?
    func showStarred(){
        if lastNeedle != "" {
            self.search("") // Reset search | should update the UI state as well. Don't know how
        }

        let starButton = self.computedView.filterButtons.filter{$0.actionName == .showStarred}[0] // HACK
        toggleActive(object: starButton)
        
        // If showing starred items, return to normal view
        if lastStarredView != nil {
            self.computedView = lastStarredView!
            lastStarredView = nil
            self.objectWillChange.send()
        }
        else {
            // Otherwise create a new searchResult, mark it as starred (query??)
            lastStarredView = self.computedView
            let view = try! self.sessions.computeView()
            self.computedView = view
            
            // filter the results based on the starred property
            var results:[DataItem] = []
            let data = lastStarredView!.resultSet.items
            // TODO: Change to filter
            for i in 0...data.count - 1 {
                let isStarred = data[i]["starred"] as? Bool ?? false
                if isStarred { results.append(data[i]) }
            }
            
            // Add searchResult to view
            view.resultSet.items = results
            view.title = "Starred \(view.title)"
            
            scheduleUIUpdate()
        }
    }
    
    func toggleActive(object: ActionDescription){
        if let state = object.state.value {
            switch state{
            case true: object.color = object.inactiveColor ?? object.color
            case false: object.color = object.activeColor ?? object.color
            }
            
            try! realm.write {
                object.state.value!.toggle()
            }
        }
        
        scheduleUIUpdate()
    }
    
    func toggleEditMode(){
        let editMode = self.currentSession.currentView.isEditMode.value ?? false
        try! realm.write {
            self.currentSession.currentView.isEditMode.value = !editMode
        }
        
        setCurrentView()
    }
    
    func toggleFilterPanel(){
        try! realm.write {
            self.currentSession.showFilterPanel.toggle()
        }
        
        scheduleUIUpdate()
    }

    func openContextPane() {
        try! realm.write {
            self.currentSession.showContextPane.toggle()
        }
        
        scheduleUIUpdate()
    }

    func showSharePanel() {
        print("shareNote")
    }

    func addToList() {
        print("addToList")
    }
}
