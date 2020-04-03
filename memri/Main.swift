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
    public let name:String = "GUI"

    /**
     *
     */
    @Published public var sessions:Sessions
    /**
     * The current session that is active in the application
     */
    @Published public var currentSession:Session = Session()
    /**
     *
     */
    @Published public var computedView:ComputedView
    /**
     *
     */
    public var settings:Settings
    /**
     *
     */
    public var installer:Installer
    /**
     *
     */
    public var podApi:PodAPI
    /**
     *
     */
    public var cache:Cache
    /**
     *
     */
    public var realm:Realm
    
    
//    public let navigationCache: NavigationCache
    
    private var cancellable:AnyCancellable? = nil
    
    init(name:String, key:String) {
        podApi = PodAPI(key)
        cache = Cache(podApi)
        realm = cache.realm
        settings = Settings(realm)
        installer = Installer(realm)
        sessions = Sessions(realm)
        computedView = ComputedView(cache)
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
                    var isCalled:Bool = false
                    self.cancellable = self.sessions.objectWillChange.sink {
                        isCalled = false
                        DispatchQueue.main.async {
                            if !isCalled { self.setCurrentView() }
                            else { isCalled = true }
                        }
                    }
                    
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
    
    /*
        - resultSet.type should return the type of the result or "_mixed_"
        - resultSet.isList should return true if the query could return more than 1 item
            - Based on the query if there is no data yet
        - computeView and setCurrentView should not be called until there is data
        - resultSet should contain all the logic to load its data (??)
        - setCurrentView should be called directly instead of through bindings, and should trigger the bindings update itself
        -
     
     */
    
    public func setCurrentView(){
        // we never have to call this manually (it will be called automatically
        // when sessions changes), except for booting
        
        // Calculate cascaded view
        if let computedView = self.sessions.computeView() {
            
            // Set current session
            self.currentSession = self.sessions.currentSession // TODO filter to a single property
            
            // Set new view
            self.computedView = computedView
        }
//        else {
//            self.currentView.merge(self.currentView)
//        }
        
        // Load data
        let resultSet = self.computedView.resultSet
        
        // TODO: create enum for loading
        if resultSet.loading == 0 && resultSet.queryOptions.query != "" {
            cache.loadPage(resultSet, 0, { (error) in
                if error == nil {
                    // call again when data is loaded, so the view can adapt to the data
                    self.setCurrentView()
                }
            })
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
        
        // Make sure to listen to changes in the view
        // TODO Will this be set more than once on a view???
        session.cancellables.append(view.objectWillChange.sink { (_) in
            session.objectWillChange.send()
        })
        
        sessions.objectWillChange.send()
    }
    
    func openView(_ item:DataItem){
        let view = SessionView()
        let queryOptions = view.queryOptions!
        queryOptions.query = item.getString("uid")
        let resultSet = cache.getResultSet(queryOptions)
        
        // TODO: This is still a hack. ResultSet should fetch the data based on the query
        resultSet.data = [item]
        
        // TODO move this to resultSet
        // Only load the item if it is partially loaded
        if item.loadState!.isPartiallyLoaded {
            resultSet.loading = 0
        }
        else {
            resultSet.loading = -1
        }
        
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
        
        // Open view with cached version of copy
        self.openView(self.cache.addToCache(copy))
    }

    /**
     * Executes the action as described in the action description
     */
    public func executeAction(_ action:ActionDescription, _ item:DataItem? = nil) -> Void {
        let params = action.actionArgs
        
        switch action.actionName {
        case .back:
            back()
        case .add:
            addFromTemplate(params[0].value as! DataItem)
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
    private var lastSearchResult:SearchResult?
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
                
                sessions.objectWillChange.send()
            }
            return
        }

        if lastSearchResult == nil {
            lastSearchResult = self.computedView.resultSet
            lastTitle = self.computedView.title
        }
        
        let searchResult = self.cache.filter(lastSearchResult!, needle)
        self.computedView.resultSet = searchResult
        if searchResult.data.count == 0 {
            self.computedView.title = "No results"
        }
        else {
            self.computedView.title = "\(searchResult.data.count) items found"
        }
        
        sessions.objectWillChange.send()
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
            sessions.objectWillChange.send()
        }
    }
    
    func showNavigation(){
        try! realm.write {
            self.sessions.showNavigation = true
        }
        sessions.objectWillChange.send()
    }
    
    func changeRenderer(rendererName: String){
        let session = currentSession
        try! realm.write {
            session.currentView.rendererName = rendererName
        }
        sessions.objectWillChange.send()
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
            let view = self.sessions.computeView()!
            self.computedView = view
            
            // filter the results based on the starred property
            var results:[DataItem] = []
            let data = lastStarredView!.resultSet.data
            // TODO: Change to filter
            for i in 0...data.count - 1 {
                let isStarred = data[i]["starred"] as? Bool ?? false
                if isStarred { results.append(data[i]) }
            }
            
            // Add searchResult to view
            view.resultSet.data = results
            view.title = "Starred \(view.title)"
            
            sessions.objectWillChange.send()
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
        sessions.objectWillChange.send()
    }
    
    func toggleEditMode(){
        let editMode = self.currentSession.currentView.isEditMode.value ?? false
        try! realm.write {
            self.currentSession.currentView.isEditMode.value = !editMode
        }
        sessions.objectWillChange.send()
    }
    
    func toggleFilterPanel(){
        try! realm.write {
            self.currentSession.showFilterPanel.toggle()
        }
        sessions.objectWillChange.send()
    }

    func openContextPane() {
        try! realm.write {
            self.currentSession.showContextPane.toggle()
        }
        sessions.objectWillChange.send()
    }

    func showSharePanel() {
        print("shareNote")
    }

    func addToList() {
        print("addToList")
    }
}
