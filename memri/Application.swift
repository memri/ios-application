import Foundation
import Combine
import SwiftUI

/**
 * Represents the entire application user interface.
 * One can imagine in the future there being multiple applications,
 * each aimed at a different way to represent the data. For instance
 * an application that is focussed on voice-first instead of gui-first.
 */
public class Application: Event, ObservableObject {
    public let name: String = "GUI"

    /**
     * The current session that is active in the application
     */
    @Published public var currentSession: Session? = nil

//    public let settings: Settings
    public var sessions: Sessions
//    public let navigationCache: NavigationCache
    
    public var podApi:PodAPI
    public var cache:Cache
    
    /**
     * All available renderers by name
     */
//    public let renderers: [String: Renderer]
    
    // These variables stay private to prevent tampering which can cause backward incompatibility
//    var navigationPane: Navigation
//    var browserPane: ModifiedContent<Browser, _EnvironmentKeyWritingModifier<Optional<Sessions>>>
    var browserPane: ModifiedContent<Browser, _EnvironmentKeyWritingModifier<Optional<Sessions>>>

//    var sessionPane: SessionSwitcher
    
    // Overlays
//    var settingsPane: SettingsPane
//    var schedulePane: SchedulePane
//    var sharingPane: SharingPane

    init(name:String, key:String, browser: ModifiedContent<Browser, _EnvironmentKeyWritingModifier<Optional<Sessions>>>) {
        // Instantiate api
        podApi = PodAPI(key)
        cache = Cache(podApi)
        sessions = Sessions()
        browserPane=browser
        

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
        super.init()

        
        // Hook current session
        currentSession = sessions.currentSession
        let _ = sessions.objectWillChange.sink {
            self.currentSession = self.sessions.currentSession // TODO filter to a single property
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
    }
    
    public func setCurrentView(){
        // Load data
        
        
        // Set on sessions
        
    }

    /**
     * Adds a view to the history of the currentSession and displays it.
     * If the view was already part of the currentSession.views it reorders it on top
     */
    public func openView(_ view: SessionView) {}
    public func openView(_ view: String) {}
    public func openView(_ items: [DataItem]) {}
    public func openView(_ item: DataItem) {}

    /**
     * Add a new data item and displays that item in the UI
     * in edit mode
     */
    public func add(_ item:DataItem) -> DataItem {
        return DataItem()
    }

    /**
     * Executes the action as described in the action description
     */
    public func executeAction(_ action:ActionDescription, _ data:DataItem) -> Bool {
        return true
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
