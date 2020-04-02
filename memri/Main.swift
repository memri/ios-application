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
     * The current session that is active in the application
     */
    @Published public var currentSession:Session = Session()
    @Published public var computedView:SessionView = SessionView()

    public var settings:Settings
    
    @Published public var sessions:Sessions = Sessions()
//    public let navigationCache: NavigationCache
    
    var cancellable:AnyCancellable? = nil
    
    private var defaultViews:[String:[String:SessionView]] = [:]
    
    public var podApi:PodAPI
    public var cache:Cache
    public var realm:Realm
    
    var renderers: [String: AnyView] = ["list": AnyView(ListRenderer(isEditMode: .constant(.inactive))),
                                        "richTextEditor": AnyView(RichTextRenderer()),
                                        "thumbnail": AnyView(ThumbnailRenderer())]
    
    var renderObjects: [String: RendererObject] = ["list": ListRendererObject(),
                                                   "richTextEditor": RichTextRendererObject(),
                                                   "thumbnail": ThumbnailRendererObject()]
    
    var renderObjectTuples: [(key: String, value: RendererObject)]{
        return renderObjects.sorted{$0.key < $1.key}
    }

    
    var currentRenderer: AnyView {
        self.renderers[self.computedView.rendererName ?? "", default: AnyView(ThumbnailRenderer())]
    }
    
    init(name:String, key:String) {
        // Instantiate api
        podApi = PodAPI(key)
        cache = Cache(podApi)
        realm = cache.realm
        settings = Settings(realm)
    }
    
    public func boot(_ callback: @escaping (_ error:Error?, _ success:Bool) -> Void) -> Main {
        // Load settings (from cache and/or api)
        self.settings.ready = {
            // Load NavigationCache (from cache and/or api)
            
            // Load view configuration (from cache and/or api)
            self.podApi.get("views") { (error, item) in // TODO store in database objects in the dgraph??
                if error != nil { return }
                
                let jsonData = try! jsonDataFromFile("views_from_server")
                self.defaultViews = try! JSONDecoder()
                    .decode([String:[String:SessionView]].self, from: jsonData)
            }
            
            // Load sessions (from cache and/or api)
            self.podApi.get("sessions") { (error, item) in // TODO store in database objects in the dgraph??
                if error != nil { return }
                
                self.sessions = try! Sessions.fromJSONString(item.getString("json"))
                
                // Hook current session
                var isCalled:Bool = false
                self.cancellable = self.sessions.objectWillChange.sink {
                    isCalled = false
                    DispatchQueue.main.async {
                        if !isCalled { self.setCurrentView() }
                        else { isCalled = true }
                    }
                }
                
                self.setCurrentView()
            }
            
            callback(nil, true)
        }
        
        return self
    }
    
    public func mockBoot() -> Main {
        return self.boot({_,_ in })
    }
    
    public func setCurrentView(){
        // we never have to call this manually (it will be called automatically
        // when sessions changes), except for booting
        
        // Calculate cascaded view
        let cascadedView = cascadeView(self.sessions.currentSession.currentView)
        if let cascadedView = cascadedView {
            
            // Set current session
            self.currentSession = self.sessions.currentSession // TODO filter to a single property
            
            // Set new view
            self.computedView = cascadedView
        }
//        else {
//            self.currentView.merge(self.currentView)
//        }
        
        // Load data
        let searchResult = self.computedView.searchResult
        
        // TODO: create enum for loading
        if searchResult.loading == 0 && searchResult.query.query != "" {
            cache.loadPage(searchResult, 0, { (error) in
                // call again when data is loaded, so the view can adapt to the data
                self.setCurrentView()
            })
        }
    }
    
    /*
    "{type:Note}"
    "{renderer:list}"
    "{[type:Note]}"
    */
    public func cascadeView(_ viewFromSession:SessionView) -> SessionView? {
        // Create a new view
        let cascadedView = SessionView()
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
                cascadedView.merge(view)
            }
        }
        
        // Cascade the view from the session
        // Loads user interactions, e.g. selections, scrollstate, changes of renderer, etc.
        cascadedView.merge(viewFromSession)
        
        // this is hacky now, will be solved later
        viewFromSession.searchResult.query = cascadedView.searchResult.query
        cascadedView.searchResult = viewFromSession.searchResult
        
        do {
            try cascadedView.validate()
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
            if cascadedView.filterButtons!.filter({ $0.actionName == .toggleFilterPanel }).count == 0 {
                self.currentSession.showFilterPanel = false
            }
        }
        
        
        
        return cascadedView
    }
    
    /**
     * Adds a view to the history of the currentSession and displays it.
     * If the view was already part of the currentSession.views it reorders it on top
     */
    func openView(_ view:SessionView){
        let session = self.currentSession
        
        // Remove all items after the current index
        session.views.removeSubrange((session.currentViewIndex + 1)...)
        
        // Add the view to the session
        session.views.append(view)
        
        // Update the index pointer
        session.currentViewIndex = session.views.count - 1
        
        // Make sure to listen to changes in the view
        // TODO Will this be set more than once on a view???
        session.cancellables?.append(view.objectWillChange.sink { (_) in
            session.objectWillChange.send()
        })
    }
    
    func openView(_ item:DataItem){
//        let session = self.currentSession
//        let view = SessionView.fromSearchResult(searchResult: SearchResult.fromDataItems([item]),
//                rendererName: "richTextEditor")
        
        var searchResult:SearchResult
        let view = SessionView()
        
        //TODO: Solve by creating ResultSet
        var existingSR:SearchResult?
        if item.getString("uid") != "" {
            existingSR = cache.findCachedResult(query: item.getString("uid"))
        }
        if let existingSR = existingSR {
            searchResult = existingSR
        }
        else {
            var xxid = item.getString("uid")
            if xxid == "" { xxid = "0x???" } // Big Hack - need to find better way to understand the type of query | See also hack in api.swift
            searchResult = SearchResult(QueryOptions(query: xxid), [item])
            searchResult.loading = 0 // Force to load the first time
            cache.addToCache(searchResult)
        }
        
        view.searchResult = searchResult
        
        // TODO: compute in topnav
//        view.backButton = ActionDescription(icon: "chevron.left", title: "Back", actionName: "back", actionArgs: [])
        
        self.openView(view)
    }
    
    public func openView(_ view: String) {}
    public func openView(_ items: [DataItem]) {}

    /**
     * Add a new data item and displays that item in the UI
     * in edit mode
     */
    public func add(_ item:DataItem) {
//        let n = self.currentSessionView.searchResult.data.count + 100
//        let dataItem = DataItem.fromUid(uid: "0x0\(n)")
//
//        dataItem.properties=["title": "new note", "content": ""]
        
        let realItem = self.cache.addToCache(item)
        self.computedView.searchResult.data.append(realItem) // TODO
        self.openView(realItem)
    }
    
    public func getRenderConfig(name: String) -> RenderConfig{
        return self.renderObjects[name]!.renderConfig
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
            let copy = self.cache.duplicate(params[0].value as! DataItem)
            add(copy)
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
            showStarred(starButton: action)
        case .showContextPane:
            openContextPane() // TODO @Jess
        case .showNavigation:
            showNavigation()
        case .openContextView:
            break
        case .share:
            showSharePanel()
        case .setRenderer:
            changeRenderer(rendererObject: action as! RendererObject)
        case .addToList:
            addToList()
        case .duplicate:
            if let item = item {
                add(self.cache.duplicate(item))
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
                self.computedView.searchResult = lastSearchResult!
                lastSearchResult = nil
                self.computedView.title = lastTitle
                self.objectWillChange.send() // TODO why is this not triggered
            }
            return
        }

        if lastSearchResult == nil {
            lastSearchResult = self.computedView.searchResult
            lastTitle = self.computedView.title
        }
        
        let searchResult = self.cache.filter(lastSearchResult!, needle)
        self.computedView.searchResult = searchResult
        if searchResult.data.count == 0 {
            self.computedView.title = "No results"
        }
        else {
            self.computedView.title = "\(searchResult.data.count) items found"
        }
        self.objectWillChange.send() // TODO why is this not triggered
    }
        
    func back(){
        let session = currentSession
        
        if session.currentViewIndex == 0 {
            print("returning")
            session.objectWillChange.send()
            return
        }
        else {
            session.currentViewIndex -= 1
            session.objectWillChange.send()
        }
    }
    
    func showNavigation(){
        self.sessions.showNavigation = true
        self.objectWillChange.send()
    }
    
    func changeRenderer(rendererObject: RendererObject){
        self.setInactive(objects: Array(self.renderObjects.values))
        setActive(object: rendererObject)
        currentSession.currentView.rendererName = rendererObject.name
        currentSession.objectWillChange.send()
    }
    
    func star() {
        
    }
    
    var lastStarredView:SessionView?
    func showStarred(starButton: ActionDescription){
        if lastNeedle != "" {
            self.search("") // Reset search | should update the UI state as well. Don't know how
        }
        
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
            let view = SessionView()
            view.merge(self.computedView)
            self.computedView = view
            
            // filter the results based on the starred property
            var results:[DataItem] = []
            let data = lastStarredView!.searchResult.data
            // TODO: Change to filter
            for i in 0...data.count - 1 {
                let isStarred = data[i]["starred"] as? Bool ?? false
                if isStarred { results.append(data[i]) }
            }
            
            // Add searchResult to view
            view.searchResult.data = results
            view.title = "Starred \(view.title ?? "")"
            
            self.objectWillChange.send()
        }
    }
    
    func toggleActive(object: ActionDescription){
        if object.state != nil{
            object.state!.toggle()
        }
    }
    
    func setActive(object: ActionDescription){
        object.color = object.activeColor ?? object.color
        object.state = true
    }
    
    func setInactive(objects: [ActionDescription]){
        for obj in renderObjects.values{
            obj.state = false
        }
    }
    
    func toggleEditMode(){
        let editMode = self.currentSession.currentView.isEditMode ?? false
        self.currentSession.currentView.isEditMode = !editMode
        self.currentSession.objectWillChange.send()
    }
    
    func toggleFilterPanel(){
        self.currentSession.showFilterPanel.toggle()
        self.objectWillChange.send()
    }

    func openContextPane() {
        self.currentSession.showContextPane.toggle()
    }

    func showSharePanel() {
        print("shareNote")
    }

    func addToList() {
        print("addToList")
    }
}
