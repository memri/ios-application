import Foundation
import Combine
import SwiftUI

/**
 * Represents the entire application user interface.
 * One can imagine in the future there being multiple applications,
 * each aimed at a different way to represent the data. For instance
 * an application that is focussed on voice-first instead of gui-first.
 */
public class Main: Event, ObservableObject {
    public let name:String = "GUI"

    /**
     * The current session that is active in the application
     */
    @Published public var currentSession:Session = Session()
    @Published public var currentView:SessionView = SessionView()
    
    @Published public var browserEditMode:Bool = false
    @Published public var navigationEditMode:Bool = false
    @Published public var showOverlay:String? = nil
    @Published public var showNavigation:Bool? = nil

//    public let settings: Settings
    @Published public var sessions:Sessions = Sessions()
//    public let navigationCache: NavigationCache
    
    var cancellable:AnyCancellable? = nil
    
    private var views:[String:[String:SessionView]] = [:]
    
    public var podApi:PodAPI
    public var cache:Cache
    
    init(name:String, key:String) {
        // Instantiate api
        podApi = PodAPI(key)
        cache = Cache(podApi)
        
        super.init()
    }
    
    public func boot(_ callback: (_ error:Error?, _ success:Bool) -> Void) {
        // Load settings (from cache and/or api)
        
        // Load NavigationCache (from cache and/or api)
        
        
        // Load view configuration (from cache and/or api)
        podApi.get("views") { (error, item) in // TODO store in database objects in the dgraph??
            if error != nil { return }
            
            let jsonData = try! jsonDataFromFile("views_from_server")
            self.views = try! JSONDecoder().decode([String:[String:SessionView]].self, from: jsonData)
        }
        
        // Load sessions (from cache and/or api)
        podApi.get("sessions") { (error, item) in // TODO store in database objects in the dgraph??
            if error != nil { return }
            
            sessions = try! Sessions.fromJSONString(item.properties["json"]?.value as! String)
            
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

        // Fire ready event
        self.fire("ready")
        
        callback(nil, true)
    }
    
    public func mockBoot() -> Main {
        self.sessions = try! Sessions.fromJSONFile("empty_sessions")
        
        self.cancellable = self.sessions.objectWillChange.sink {
            DispatchQueue.main.async {
                self.setCurrentView()
            }
        }
        
        return self
    }
    
    public func setCurrentView(){
        // Set on sessions
        self.currentSession = self.sessions.currentSession // TODO filter to a single property
        self.currentView = cascadeView(self.sessions.currentSession.currentView)
        
        // Load data
        let searchResult = self.currentView.searchResult
        
        if searchResult.loading == 0 && searchResult.query.query != "" {
            cache.loadPage(searchResult, 0, { (error) in
                self.setCurrentView()
            })
        }
    }
    
    public func cascadeView(_ session:SessionView) -> SessionView {
        let cascadeOrder = ["datatype", "renderer"]
        let searchOrder = ["defaults", "user"]
        
        let cascadedView = SessionView()
        
        let isList = !session.searchResult.query.query!.starts(with: "0x")
        
        var type:String? = nil
        if (session.searchResult.data.count > 0 ) {
            type = session.searchResult.data[0].type
        }

        /*
         "{type:Note}"
         "{renderer:list}"
         "{[type:Note]}"
         */
        for viewDomain in searchOrder {
            for orderType in cascadeOrder {
                if orderType == "renderer" {
                    // TODO the renderer may only be specified by the datatype, and this will fail when the renderer is first in order
                    let renderName:String? = session.rendererName ?? cascadedView.rendererName ?? nil
                    if let renderName = renderName {
                        let needle = "{renderer:\(renderName)}"
                        let rendererView = self.views[viewDomain]![needle]
                        if let rendererView = rendererView { cascadedView.merge(rendererView) }
                    }
                }
                else if orderType == "datatype" && type != nil {
                    var needle:String
                    if (isList) { needle = "{[type:\(type!)]}" }
                    else { needle = "{type:\(type!)}" }
                    
                    let datatypeView = self.views[viewDomain]![needle]
                    if let datatypeView = datatypeView { cascadedView.merge(datatypeView) }
                }
            }
        }
        
        cascadedView.merge(session)
        
        session.searchResult.query = cascadedView.searchResult.query
        cascadedView.searchResult = session.searchResult
        
        dump(cascadedView.searchResult)
        
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
        
        var existingSR:SearchResult?
        if item.uid != nil {
            existingSR = cache.findCachedResult(query: item.uid!)
        }
        if let existingSR = existingSR {
            searchResult = existingSR
        }
        else {
            var xxid = item.uid ?? ""
            if xxid == "" { xxid = "0x???" } // Big Hack - need to find better way to understand the type of query | See also hack in api.swift
            searchResult = SearchResult(QueryOptions(query: xxid), [item])
            searchResult.loading = 0 // Force to load the first time
            cache.addToCache(searchResult)
        }
        
        view.searchResult = searchResult
//        view = cascadeView(view)
        
        // Hack!!
        view.backButton = ActionDescription(icon: "chevron.left", title: "Back", actionName: "back", actionArgs: [])
        
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
        self.currentView.searchResult.data.append(realItem) // TODO
        self.openView(realItem)
    }

    /**
     * Executes the action as described in the action description
     */
    public func executeAction(_ action:ActionDescription, _ item:DataItem? = nil) -> Void {
        let params = action.actionArgs
        
        switch action.actionName {
        case "back":
            back()
        case "add":
            let param0 = params[0].value as! DataItem
            let item = DataItem()
            try! item.merge(param0)
            add(item)
        case "openView":
            if let item = item{
                openView(item)
            }else{
                let param0 = params[0].value as! SessionView
                openView(param0)
            }
        case "toggleEdit":
            toggleEditMode()
        case "toggleFilterPanel":
            toggleFilterPanel()
        case "star":
            star()
        case "exampleUnpack":
            let (_, _) = (params[0].value, params[1].value) as! (String, Int)
            break
        default:
            print("UNDEFINED ACTION \(action.actionName), NOT EXECUTING")
        }
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
    
    func changeRenderer(rendererName: String){
        let session = currentSession
        session.currentView.rendererName = rendererName
        session.objectWillChange.send()
    }
    
    func star(){
        let starButton = self.currentView.filterButtons!.filter{$0.actionName == "star"}[0]
        toggleColor(object: starButton, color1: .gray, color2: .systemYellow)
        self.objectWillChange.send()
    }
    
    func toggleColor(object: ActionDescription, color1: UIColor, color2: UIColor){
        switch object.color{
            case color1: object.color = color2
            case color2: object.color = color1
            default: object.color = color1
        }
    }
    
    func toggleEditMode(){
        //currently handled in browser
    }
    
    func toggleFilterPanel(){
        self.currentView.showFilterPanel!.toggle()
        self.objectWillChange.send()
    }
}

/**
 *
 */

public class Event {
    private var events:[String:[(_ event:EventObject) -> Void]] = [:]
    
    /**
     *
     */
    public func fire(_ name:String, _ value:String="") {
        let list = events[name]
        
        if let list = list {
            let e = EventObject(value: value)
            for i in 0...list.count {
                list[i](e)
            }
        }
    }
    /**
     *
     */
    public func on(_ name:String, _ callback:@escaping (_ event:EventObject) -> Void) {
        if events[name] == nil { events[name] = [] }
        events[name]!.append(callback)
    }
//    /**
//     *
//     */
//    public func off(_ name:String, _ callback:@escaping (_ event:EventObject) -> Void) {
//        if events[name] == nil { return }
//
//        let list = events[name]
//        for i in 0...list!.count {
//            if list[i] == callback { events[name]!.remove(at: i) }
//        }
//    }
}

public struct EventObject {
    var value:String = ""
}
