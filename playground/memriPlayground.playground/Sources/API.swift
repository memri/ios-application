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

// @TODO 
public class Stream {

}

// @TODO 
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
    public let uid: String // @koen why .uid iso .id?
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

/**
 * Responsible for loading and saving as well
 * @event onsettingschange
 */
// @TODO
public class Settings {
    public func init(_ cache:Cache) {}
} 

/**
 * Responsible for loading and saving as the navigation settings
 * @event onsettingschange
 */
public class NavigationSettings {
    /**
     * Ordered list of navigation items
     */
    var items: [NavigationItem]
    /**
     * The currently selected navigation item
     */
    var currentItem: NavigationItem 
    /**
     * The scroll position of the navigation
     */
    var scrollState: ScrollState 
    /**
     * The selection in the navigation. Only relevant when in edit mode.
     */
    var selection: [NavigationItem] 
    /**
     * Toggle the UI into edit mode
     */
    var editMode: Bool // stored in settings.editMode

    public func init(_ cache:Cache) {}
}

/**
 * Responsible for loading and saving as well
 * @event onsessionchange
 */
public class Sessions: Event {
    /**
     * The current session that the user is using (similar to active tab in an internet browser)
     */
    public var currentSession: Session
    /**
     * All sessions that are open
     */
    public var sessions: [Session]
    /**
     * Find a session using text
     */
    public func findSession(_ query:String) -> Void
    /**
     * Clear all sessions and create a new one
     */
    public func clear() -> Void
    /**
     * set the current session
     * @TODO or should this just be by session .currentSession ?
     */
    public func setCurrentSession(_ session:Session) -> Void
} 

/**
 * Think of sessions as tabs in an internet browser. Each tab has a little 
 * bit of state such as the current page that is being looked at and a list 
 * of all pages visited in the past. This is similar with a session. Instead 
 * of pages, the Memri sessions consist of views.
 * 
 * @event onswitch — or using observable...
 */
public class Session: Observable {
    /**
     *  The active sessionview
     */
    public var currentView: SessionView
    /**
     * The index of the active sessionview in the list of views
     */
    public var currentViewIndex: Int
    /**
     * The list of all sessionviews in this session
     */
    public var views: [SessionView]

    public func init(_ cache:Cache) {}

    public func back() -> Void {}
    public func forward() -> Void {}
    public func bookmark(_ item:SessionView) -> Void {}
    public func gotoBookmark() -> Void {}

    /**
     * set the current session
     * @TODO or should this just be by session .currentView ?
     */
    public func setCurrentView(_ session:SessionView) -> Void
}

/**
 * Describes a view that can be displayed in a renderer. 
 */
public class SessionView: Observable { // @TODO should this be a struct?
    /**
     * Reference to the search result used by this view
     * @TODO is this needed? If cache has all recent search results, this should be fairly easy to look up. TBD
     */
    public var searchResult: SearchResult
    /**
     * The title of the view.
     */
    public var title: String
    /**
     * The subtitle of the the view.
     */
    public var subtitle: String
    /**
     * List of actions that are used to instantiate the buttons in the top navigation
     */
    public var editButtons: [ActionDescription]
    /**
     * List of actions that are used to instantiate the buttons in the search box
     */
    public var filterButtons: [ActionDescription]
    /**
     * List of actions that are used in the top of the context pane
     */
    public var contextButtons: [ActionDescription]
    /**
     * List of actions that are used in the action section of the context pane
     */
    public var actionItems: [ActionDescription]
    /**
     * List of actions that are used in the navigation section of the context pane
     */
    public var navigateItems: [ActionDescription]
    /**
     * The active renderer for this view
     */
    public var rendererName: String
    /**
     * A dictionary of render configurations based on the name of the renderer
     */
    public var renderConfig: [String:RenderConfig]
    /**
     * A list of uids representing the selection in the view
     */
    public var selection: String[]
    /**
     * Whether the view is in edit mode
     */
    public var editMode: Boolean
    /**
     * Whether the label section in the context panel is shown
     */
    public var hideLabels: Boolean
    /**
     * Whether the context pane is shown
     */
    public var contextMode: Boolean
    /**
     * Whether the fileter pane is shown
     */
    public var filterMode: Boolean
    /**
     * An icon for this view
     */
    public var icon: String
    /**
     * The type of browsing mode for this view
     * Options: "default", "type", "labels"
     */
    public var browsingMode: String

}
public class ActionDescription {
    public var icon: String
    public var title: String

    /**
     * Arguments can template the data through “{.prop} or {global} or {global.prop}”
     * 
     * actionName              actionArgs
     * ---------------------   -------------------------------------------------------------------------------------------------------------------
     * openView                String viewName    
     * openView                View view    
     * openViewInNewSession    String viewName                
     * openViewInNewSession    View view                
     * saveView                View view, [String, title]    // Will ask for title input when title already exists or is not specified.
     * deleteView              View view        
     * updateView              View view        
     * add                     DataItem item
     * search                  String query    
     * globalSearch            String query        
     * select                  DataItem[] items    
     * cancelEditMode          -            
     * showSessionSwitch       -                
     * showFilterPanel         -            
     * transformView           View source, View changes            
     * schedule                DataItem[] items, [ScheduleOptions options]    // Will show the schedule screen if options are omitted.
     * editMode                Boolean enable     // Will toggle edit mode if no argument is given
     * showContextPane         -            
     * showEditOptions         -            
     * remove                  DataItem item | String id | DataItem[] items | String[] ids    
     * addTo                   DataItem item, String type, String id    // Will show the addToPanel if id is omitted
     * shareWith               DataItem item, String type, String id    // Will show the shareWithPanel if id is omitted
     * showOverlay             String name    // e.g. viewOptions, addToPanel, shareWithPanel, scheduleOptions
     * showStarred             View view        
     * showTimeline            View view        
     * bulkEdit                DataItem[] items | String[] ids    
     * star                    DataItem item | String id
     * addToList               DataItem item | String id, String listId        
     * duplicate               DataItem item | String id, [String newTitle]        
     * setBookmark             View view        
     * gotoBookmark            -        
     * duplicateView           View view, [String newTitle]            
     * renameView              View view, [String newTitle]        // Will ask for title input when title already exists or is not specified.
     * copyProperty            DataItem item | String id, String propertyName        
     * addToNav                View view, [String newTitle], [View beforeView]    
     * removeFromNav           View view, [String title]            
     * renameNav               View view, [String newTitle]        
     * automate                ?    
     * import                  ?    
     * export                  ?    
     * augment                 ?    
     * convert                 ?    
     * index                   ?    
     * update                  DataItem item | String id, DataItem changes    
     * addReminder             DataItem item, [String description]        
     * %name                   Type value    // Sets a property or calls a method on the related object
     */
    public var actionName: String
    public var actionArgs: [Any]

}
public class ScheduleOptions {} // @TODO
public protocol RenderConfig {} // @TODO
public class InterfaceListRenderConfig: RenderConfig {} // @TODO
public class ThumbnailRenderConfig: RenderConfig {} // @TODO
public class CalendarRenderConfig: RenderConfig {} // @TODO
public class ChartRenderConfig: RenderConfig {} // @TODO
public class BarChartRenderConfig: RenderConfig {} // @TODO
public class LineChartRenderConfig: RenderConfig {} // @TODO
public class PieChartRenderConfig: RenderConfig {} // @TODO
public class MapRenderConfig: RenderConfig {} // @TODO
public class TimelineRenderConfig: RenderConfig {} // @TODO

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

struct ScrollState {
    var x = 0
    var y = 0
}

class Navigation: View {
    /**
     * Ordered list of navigation items displayed in the view
     */
    public var items: [NavigationItem] // stored in settings.items
    /**
     * The currently selected navigation item
     */
    public var currentItem: NavigationItem // stored in settings.currentItem
    /**
     * The scroll position of the navigation
     */
    public var scrollState: ScrollState // stored in settings.scrollState
    /**
     * The selection in the navigation. Only relevant when in edit mode.
     */
    public var selection: [NavigationItem] // stored in settings.selection
    /**
     * Toggle the UI into edit mode
     */
    public var editMode: Bool // stored in settings.editMode

    var search: NavigationSearch

    public func init(_ settings: NavigationSettings){ }
    
    public func filter(_ query:String) -> Void {}
    public func add(_ item:NavigationItem) -> Bool {}
    public func remove(_ item:NavigationItem) -> Bool {}

    /**
     * Act as if the user clicked on the navigation item
     */
    public func trigger(_ item:NavigationItem) {}
    public func trigger(_ viewName:String) {}
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
    public func startRename() -> Void {}
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
    public func setState(_ state:RenderState) -> Boolean {}
    public func getState() -> RenderState {}

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
    public func loadData(_ data:[DataItem]) -> Boolean
}

public protocol SingleItemView: Renderer {
    /**
     * The render config that is used to render this renderer
     */
    public var data: DataItem

    /**
     * Loads the data to be rendered
     */
    public func loadData(_ data:DataItem) -> Boolean {}
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
    public func toggleFilterPanel(_ force:Bool) -> Void {} // argument should be optional

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
    public func setCurrentView(_ view:SessionView) -> Boolean {}
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
    public func setCurrentView(_ view:SessionView) -> Boolean {}
}

public protocol Overlay: View {
    /**
     * Display the overlay panel
     */
    public func show() -> Void
    /**
     * Hide the overlay panel
     */
    public func hide() -> Void
}

public class SessionSwitcher: View {
    /**
     * The scroll state in the session switcher
     */
    public var scrollState: ScrollState

    var sessions: [Sessions]

    public func init(_ sessions:[Sessions])
    /**
     * Display the overlay panel
     */
    public func show() -> Void
    /**
     * Hide the overlay panel
  S   */
    public func hide() -> Void
}

public class SettingsPane: View {
    /**
     * List of templates that define how a setting is rendered.
     * e.g. a label and a textbox, a label and a checkbox, etc
     */
    var templates: [String:String]

    public func init(_ settigns:Settings)

    public func createSection(_ id:String, _ title: String) -> SettingsSection {}
    public func getSection(_ id:String) -> SettingsSection {}
    public func addSettingItem(_ item:SettingsItem) -> Bool {}
}

public class SettingsSection {
    /**
     * The title of the section
     */
    public var title: String

    public func init(_ title:String) {}

    /**
     * Add a setting to the section
     */
    public func addSettingItem(_ item:SettingsItem) -> Void {}
}

public struct SettingsItem {
    public var itemRenderer: String
    public var variables: [String:AnyObject]

    public func init(_ itemRenderer: String)
}