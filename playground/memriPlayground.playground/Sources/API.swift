/*
 * PodAPI
 */
public class PodAPI {
    public func init(_ key:String) {}

    // Sets the .id property on DataItem
    public func create(_ item:DataItem,_ callback: (success:Bool, error:Error) -> Void) -> Void {}
    public func get(_ id:String,_ callback: (item:DataItem, error:Error) -> Void) -> Void {}
    public func update(_ id:String,_ item:DataItem,_ callback: (success:Bool, error:Error) -> Void) -> Void {}
    public func remove(_ id:String,_ callback: (success:Bool, error:Error) -> Void) -> Void {}
    
    public func link(_ id:String | item:DataItem, _ id:String | item:DataItem, _ predicate:String, _ callback: (created:Bool, error:Error) -> Void) -> Void {}
    public func unlink(_ id:String | item:DataItem, _ id:String | item:DataItem, _ predicate:String, _ callback: (success:Bool, error:Error) -> Void) -> Void {}

    public func query(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    public func queryNLP(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    public func queryDSL(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    public func queryRAW(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}

    // Returns a read-only SettingsData object.
    public func getDefaultSettings(_ callback: (result:SettingsData, error:Error) -> Void) -> Void {}
    // Returns a read-write SettingsData object.
    public func getDeviceSettings(_ callback: (result:SettingsData, error:Error) -> Void) -> Void {}
    // Returns a read-write SettingsData object when admin, otherwise read-only.
    public func getGroupSettings(_ groupId:String, _ callback: (result:SettingsData, error:Error) -> Void) -> Void {}
    // Returns a read-write SettingsData object.
    public func getUserSettings(_ callback: (result:SettingsData, error:Error) -> Void) -> Void {}

    public func import() -> Void {}
    public func export() -> Void {}
    public func sync() -> Void {}
    public func index() -> Void {}
    public func convert() -> Void {}
    public func augment() -> Void {}
    public func automate() -> Void {}

    public func streamResource(_ URI:String, _ options:StreamOptions, _ callback: (stream:Stream, error:Error) -> Void) -> Void {}
}

public struct QueryOptions {
    /**
     * Name of the property to sort on
     */
    public var sortProperty: String
    /**
     * Name of the property to sort on
     */
    public var sortAscending: Bool

    public var pageNr:Int

    public var pageSize:Int
}

public class SettingsData {
    public func init(_ type:String) {}

    /**
     * Possible values: "default", "device", "group", "user"
     */
    public var type: String

    /**
     * Used by device and group (and perhaps user)
     */
    public var name: String

    public func get(_ path:String) -> AnyObject {} 

    /**
     * Also responsible for saving the setting to the permanent storage
     */
    public func set(_ path:String, _ value:AnyObject) -> AnyType {} 
}

public class Stream {

}

public struct StreamOptions {

}

/**
 * Updates elements that are updated elsewhere, such as on the server, by other clients and automation.
 */
public class StateSyncAPI {
    public func init(_ cache:Cache, _ api:PodAPI) {}
}

public class Cache {
    public func init(_ api:PodAPI) {}

    public func findQueryResult(_ query:String, _ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    public func queryLocal(_ query:String, _ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    public func getByType(_ query:String, _ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    public func getById(_ query:String, _ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}

    /**
     * Loads data from the pod. Returns SearchResult.
     * -> Calls callback twice, once for cache, once for real data [??]
     */
    public func query(_ query:String, _ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}

    public fromJSON(_ file: String, _ ext: String = "json") throws -> [DataItem] {}
}

public class Event {
    public func fire(_ name:String) {}
    public func on(_ name:String, _ callback:() -> Void)
    public func off(_ name:String, _ callback:() -> Void)
}

/**
 * Fires load event when new data is received
 */
public class SearchResult: Event {
    /**
     * Retrieves the query which is used to load data from the pod
     */
    public let query:String
    /**
     * Retrieves the property that is used to sort on
     */
    public let sortProperty:String
    /**
     * Retrieves whether the sort direction
     *   -1 no sorting is applied
     *    0 sort descending
     *    1 sort ascending
     */
    public let sortAscending:Bool
    public var pageCount:Int
    /**
     * Retrieves the number of items per page
     */
    public let pageSize:Int
    /**
     * Retrieves the data loaded from the pod
     */
    public let data: [DataItem]

    /**
     * Returns the loading state
     *  0 loading complete
     *  1 loading data from server
     */
    public var loading:Bool

    /**
     * Sets the constants above
     */
    public func init(_ options:QueryOptions) {}
    
    /**
     * Client side filter, with a fallback to the server
     */
    public func filter(_ query:String) {}
    /**
     * Executes the query again
     */
    public func reload() {}
    
    public func resort(_ options:QueryOptions) {}
    public func loadPage(_ pageNr:Int) {}
}

public struct Predicate {
    public let name: String
    public let target: DataItem
    public func unlink() -> Void {}
}

public class DataItem: Observable { // @TODD figure out how to implement observable
    public let uid: String
    public let type: String
    public let predicates: [Predicate]
    public let properties: [String: String]
    public var deleted = false // This variable should only be settable by delete() and readable by everyone
    
    public init(_ uid: String, _ type:String, _ predicates = [Predicate](),  _ properties = [String: String]()) {}
    public init(_ type:String, _ predicates = [Predicate](),  _ properties = [String: String]()) {}

    public func findProperty(_ name:String) -> AnyObject {}
    public func findPredicateByType(_ type:String) -> [Predicate] {}
    public func findPredicateByTarget(_ item:DataItem) -> [Predicate] {}

    /**
     * Does not copy the uid property
     */
    public func duplicate() -> DataItem {}
    /**
     * Sets deleted to true
     * All methods and properties must throw when deleted = true;
     */
    public func delete() -> DataItem {}
}


class Settings {} // @TODO  // Responsible for loading and saving as well
class NavigationSettings {} // @TODO  // Responsible for loading and saving as well
class Sessions {} // @TODO  // Responsible for loading and saving as well

class Session {} // @TODO
class SessionView {} // @TODO
class ActionDescription {} // @TODO
class ScheduleOptions {} // @TODO
protocol RenderConfig {} // @TODO
class InterfaceListRenderConfig: RenderConfig {} // @TODO
class ThumbnailRenderConfig: RenderConfig {} // @TODO
class CalendarRenderConfig: RenderConfig {} // @TODO
class ChartRenderConfig: RenderConfig {} // @TODO
class BarChartRenderConfig: RenderConfig {} // @TODO
class LineChartRenderConfig: RenderConfig {} // @TODO
class PieChartRenderConfig: RenderConfig {} // @TODO
class MapRenderConfig: RenderConfig {} // @TODO
class TimelineRenderConfig: RenderConfig {} // @TODO

/**
 * Represents the entire application user interface.
 * One can imagine in the future there being multiple applications, 
 * each aimed at a different way to represent the data. For instance
 * an application that is focussed on voice-first instead of gui-first.
 */
class Application: View, Event {
    public let name: String

    /**
     * The current session that is active in the application
     */
    public var currentSession: Session

    public let settings: Settings
    public let sessions: Sessions
    public let navigation: NavigationSettings
    
    // These variables stay private to prevent tampering which can cause backward incompatibility
    var navigationPane: Navigation
    var browserPane: Browser
    var sessionPane: SessionSwitcher
    
    // Overlays
    var settingsPane: SettingsPane
    var schedulePane: SchedulePane
    var sharingPane: SharingPane

    public func init(_ name:String, _ api: PodAPI, _ cache Cache) {
        // Instantiate view objects

        // Load settings (from cache and/or api)
        // Load navigationSettings (from cache and/or api)
        // Load sessions (from cache and/or api)

        // Fire ready event

        // When session are loaded, load the current view in the browser
        // If there are no pre-existing sessions, load the default view in the browser
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
    public func add(_ item:DataItem) -> DataItem {}
}

class Navigation: View {
    public var items: [NavigationItem]
    public var currentItem: NavigationItem
    public var scrollState: Int
    public var editMode: Bool
    public var selection: [NavigationItem]
    /**
     * Toggle the UI into edit mode
     */
    public var editMode: Bool

    var search: NavigationSearch

    public func init(_ settings: NavigationSettings){ }
    
    public func filter(_ query:String) -> Void {}
    public func add(_ item:NavigationItem) -> Bool {}
    public func remove(_ item:NavigationItem) -> Bool {}

    /**
     * Act as if the user clicked on the navigation item
     */
    public func trigger(_ item:NavigationItem)
    public func trigger(_ viewName:String)
}

struct NavigationItem: Observable { // Should this be a class ??
    /**
     * Used as the caption in the navigation
     */
    public var title: String
    /**
     * Name of the view it opens
     */
    public var view: String
    /**
     * Defines the position in the navigation
     */
    public var count: Int
    /**
     *  0 = Item
     *  1 = Heading
     *  2 = Line
     */
    public var type: Int
}

public class NavigationSearch {} // @TODO

/**
 * Represents the part of the user interface that displays SessionViews
 * @event onviewchange
 */
public class Browser: View {
    /**
     * The current session of the view that is displayed in the browser
     */
    public var currentSession: Session

    /**
     * The current view that is displayed in the browser
     */
    public var currentView: SessionView

    /**
     * Toggle the UI into edit mode
     */
    public var editMode: Bool

    /**
     * All available renderers by name
     */
    public let renderers: [String: Renderer]

    var topNavigation: TopNavigation
    var currentRenderer: Renderer
    var searchPane: SearchPane

    /**
     * Set the currentView of a session as the view displayed in the browser. 
     */
    public func setCurrentView(_ session:Session, _ callback:(success:Bool, error:Error) -> Void) {}
}

/**
 * The top navigation of the browser that shows the user where they are, 
 * and show navigational items that are ever present in all views in the application.
 *
 * @event onrefresh
 * @event ontitletyping
 * @event onnavigate
 */
public class TopNavigation: View, Event {
    /**
     * Sets or retrieves the title displayed in the top navigation
     */
    public var title: String
    /**
     * Sets or retrieves the sub title displayed in the top navigation
     */
    public var subTitle: String
    /**
     * Sets or retrieves the title displayed near the back button in the top navigation
     */
    public var backTitle: String
    /**
     * Toggle the UI into edit mode
     */
    public var editMode = false
    /**
     * Toggle the UI into navigation mode
     */
    public var navigationMode = false

    /**
     * Sets the action button in the top navigation
     */
    public var actionButton: ActionDescription
    /**
     * Sets the action button displayed during edit mode in the top navigation
     */
    public var editActionButton: ActionDescription
    /**
     * Trigger the rename UI to show that enables a user to set the name of a view
     */
    public func startRename()
}

/**
 * Renders content in the browser
 */
public prototype Renderer {
    /**
     * Name of the renderer
     */
    public var name: String
    /**
     * Icon of the renderer used to display in the filter view
     */
    public var icon: String
    /**
     * All renderers with the same category string are displayed 
     * under the icon of the first renderer that lists in that
     * category
     */
    public var category: String
    /**
     * The render modes add to the modes available under the category
     * e.g. under the list category, one may add an alphabetic list view
     */
    public var renderModes: [ActionDescription]
    /**
     * A set of actions that let's the user configure an aspect of the renderer
     */
    public var options1: [ActionDescription]
    /**
     * A set of actions that let's the user configure an aspect of the renderer
     */
    public var options2: [ActionDescription]
    /**
     * Toggle the UI into edit mode
     */
    public var editMode = false
    /**
     * The render config that is used to render this renderer
     */
    public var renderConfig: renderConfig
    
    /**
     * Sets the state of the renderer (e.g. scroll position, zoom position, etc)
     */
    public func setState(_ state:RenderState) -> Boolean
    public func getState() -> RenderState

    /**
     * Set the currentView of a session as the view displayed in the browser. 
     */
    public func setCurrentView(_ session:Session, _ callback:(success:Bool, error:Error) -> Void) {}
}

/**
 * Records the state of the renderer. Each Renderer will have it's own 
 * RenderState struct that is base classed from RenderState
 * @TODO add renderState as a dict to the view
 */
struct RenderState {
    struct ScrollState {
        var x = 0
        var y = 0
    }

    /**
     * The scroll position of the renderer
     */
    public var scrollState: ScrollState

    /**
     * Whether the UI is in edit mode
     */
    public var editMode: Boolean
}

public protocol MultiItemView: Renderer {
    /**
     * The selected items in the view (only relevant for edit mode)
     */
    public var selection: [DataItem]

    /**
     * The render config that is used to render this renderer
     */
    public var data: [DataItem]

    /**
     * Loads the data to be rendered
     */
    public func loadData(_ data:[DataItem])
}

public protocol SingleItemView: Renderer {
    /**
     * The render config that is used to render this renderer
     */
    public var data: DataItem

    /**
     * Loads the data to be rendered
     */
    public func loadData(_ data:DataItem)
}

/**
 * The editor is responsible for changing the data item in ways 
 * directed by the user, and then updating them in the cache. 
 */
public protocol Editor: SingleItemView {

}

/**
 * Search controls the searching process, as well as the searchbox area on 
 * the screen. When the user uses the searchbox, the current view is temporary 
 * replaced by another view that displays search results. When the searchbox is 
 * cleared, the original view is showed again. The new view is temporarily inserted 
 * into the Session. When the the user clicks on a sub item to load another view, 
 * the search view becomes a more permanent part of the session history.
 */
public class Search: View {
    /**
    * Records the state of the searchbox
    */
    struct SearchState {
        var text: String
        var cursorPosition: Int
        var scrollState: Int
    }

    /**
     * The text in the search box (i.e. the query)
     */
    public var text: String
    /**
     * The text displayed in the search box when the search box is empty
     * e.g. "Search in this note"
     */
    public var emptyText: String
    /**
     * The buttons displayed in the search panel
     */
    public var buttons: ActionDescription[]
    
    var filterPanel: FilterPanel

    public func init(_ renderers:[Renderers]) {}

    /**
     * Set the currentView of a session as the view displayed in the browser. 
     */
    public func setCurrentView(_ view:SessionView) {}
   
    /**
     * Show the filter panel
     */
    public func toggleFilterPanel(_ force:Bool) -> Void // argument should be optional

    // @TODO should there be a toggle for the keyboard as well?
}

public class FilterPanel: View {
    /**
     * Display the filter panel
     */
    public func show() -> Void
    /**
     * Hide the filter panel
     */
    public func hide() -> Void

    public func init(_ renderers:[Renderers]) {}

    /**
     * Set the currentView of a session as the view displayed in the browser. 
     */
    public func setCurrentView(_ view:SessionView) {}
}

public class ContextPane: View {
    /**
     * Sets/retrieves text of the title displayed in the context pane
     */
    public var title: String
    /**
     * Sets/retrieves text of the subtitle displayed in the context pane
     */
    public var subtitle: String
    /**
     * Sets/retrieves the buttons to be displayed in the top of the context pane
     */
    public var buttons: ActionDescription[]
    /**
     * Sets/retrieves the text buttons in the action section of the context pane
     */
    public var actions: ActionDescription[]
    /**
     * Sets/retrieves the text buttons in the navigation section of the context pane
     */
    public var navigate: ActionDescription[]
    /**
     * Sets/retrieves whether the label section is hidden
     */
    public var hideLabels = false

    /**
     * Display the filter panel
     */
    public func show() -> Void
    /**
     * Hide the filter panel
     */
    public func hide() -> Void

    /**
     * Set the currentView of a session as the view displayed in the browser. 
     */
    public func setCurrentView(_ view:SessionView) {}
}