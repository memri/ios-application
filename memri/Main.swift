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
    
    public var podApi:PodAPI
    public var cache:Cache
    
    /**
     * All available renderers by name
     */
//    public let renderers: [String: Renderer]
    
    // These variables stay private to prevent tampering which can cause backward incompatibility
//    var navigationPane: Navigation
//    var browserPane: ModifiedContent<Browser, _EnvironmentKeyWritingModifier<Optional<Sessions>>>
//    var browserPane: ModifiedContent<Browser, _EnvironmentKeyWritingModifier<Optional<Sessions>>>

//    var sessionPane: SessionSwitcher
    
    // Overlays
//    var settingsPane: SettingsPane
//    var schedulePane: SchedulePane
//    var sharingPane: SharingPane

    init(name:String, key:String) {
        // Instantiate api
        podApi = PodAPI(key)
        cache = Cache(podApi)
        
        super.init()
    }
    
    public func boot(_ callback: (_ error:Error?, _ success:Bool) -> Void) {
//        cache = Cache(<#T##podAPI: PodAPI##PodAPI#>, queryCache: <#T##[String : SearchResult]#>, typeCache: <#T##[String : SearchResult]#>, idCache: <#T##[String : SearchResult]#>)
        // Load settings (from cache and/or api)
        
        // Load NavigationCache (from cache and/or api)
        // Load sessions (from cache and/or api)
//        podApi.get("sessions") { (error, dataitem) in // TODO store in database objects in the dgraph??
//            if error != nil { return }
//
//            sessions = try! Sessions.fromJSONString(dataitem.properties["json"]?.value as! String)
//
//            print(sessions.sessions[0].views.count)
//        }
        
        // Instantiate view objects
//        self.browserPane = Browser()

//        browserPane = Browser().environmentObject(sessions) as! ModifiedContent<Browser, _EnvironmentKeyWritingModifier<Optional<Sessions>>>

        self.sessions = try! Sessions.fromJSONFile("empty_sessions")
        
        // Hook current session
        self.currentSession = sessions.currentSession
        self.currentView = sessions.currentSession.currentView
        self.cancellable = self.sessions.objectWillChange.sink {
            DispatchQueue.main.async {
                self.currentSession = self.sessions.currentSession // TODO filter to a single property
                self.currentView = self.sessions.currentSession.currentView
            }
        }

        // Fire ready event
        self.fire("ready")

//        // When session are loaded, load the current view in the browser
//        if !currentSession.views.isEmpty {
//            browserPane.
//        }
//        // If there are no pre-existing sessions, load the default view in the browser
//        else {
//            // TODO
//        }
        
        callback(nil, true)
    }
    
    public func mockBoot() -> Main {
        self.sessions = try! Sessions.fromJSONFile("empty_sessions")
        
        self.cancellable = self.sessions.objectWillChange.sink {
              DispatchQueue.main.async {
                  self.currentSession = self.sessions.currentSession // TODO filter to a single property
                  self.currentView = self.sessions.currentSession.currentView
            }
        }
        
        
        return self
    }
    
    public func setCurrentView(){
        // Load data
        
        
        // Set on sessions
        
    }

    /**
     * Adds a view to the history of the currentSession and displays it.
     * If the view was already part of the currentSession.views it reorders it on top
     */
    func openView(_ view:SessionView){
        let session = self.currentSession
        
        session.views.append(view)
        session.currentViewIndex = session.views.count - 1
        
        session.cancellables?.append(view.objectWillChange.sink { (_) in
            session.objectWillChange.send()
        })
    }
    
    func openView(_ item:DataItem){
        let session = self.currentSession
        let view = SessionView.fromSearchResult(searchResult: SearchResult.fromDataItems([item]),
                rendererName: "richTextEditor")
    
        session.views.append(view)
        session.currentViewIndex = session.views.count - 1
        
        session.cancellables?.append(view.objectWillChange.sink { (_) in
            session.objectWillChange.send()
        })
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
        
        self.currentView.searchResult.data.append(item) // TODO
        
        let sr = SearchResult()
        let sv = SessionView()
        
        sr.data = [item]
        sv.searchResult = sr
        sv.rendererName = "richTextEditor"
        sv.title = "new note"
        sv.backButton = ActionDescription(icon: "chevron.left", title: "Back", actionName: "back", actionArgs: [])
        
        self.openView(sv)
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
            add(param0)
        case "openView":
            if let item = item {
                openView(item)
            }
            else {
                let param0 = params[0].value as! SessionView
                openView(param0)
            }

        case "exampleUnpack":
            let (_, _) = (params[0].value, params[1].value) as! (String, Int)
            break
        default:
            print("UNDEFINED ACTION, NOT EXECUTING")
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
