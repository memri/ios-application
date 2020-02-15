/*
 * PodAPI
 */
public class PodAPI {
    public func init(_ key:String) {}

    public func remove(_ id:String,_ callback: (success:Bool, error:Error) -> Void) -> Void {}
    public func get(_ id:String,_ callback: (item:DataItem, error:Error) -> Void) -> Void {}
    public func update(_ id:String,_ item:DataItem,_ callback: (success:Bool, error:Error) -> Void) -> Void {}
    // Sets the .id property on DataItem
    public func create(_ item:DataItem,_ callback: (success:Bool, error:Error) -> Void) -> Void {}
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
     *  0 loading comppublic lete
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
protocol RenderOptions {} // @TODO
class InterfaceListRenderOptions: RenderOptions {} // @TODO
class ThumbnailRenderOptions: RenderOptions {} // @TODO
class CalendarRenderOptions: RenderOptions {} // @TODO
class ChartRenderOptions: RenderOptions {} // @TODO
class BarChartRenderOptions: RenderOptions {} // @TODO
class LineChartRenderOptions: RenderOptions {} // @TODO
class PieChartRenderOptions: RenderOptions {} // @TODO
class MapRenderOptions: RenderOptions {} // @TODO
class TimelineRenderOptions: RenderOptions {} // @TODO

/**
 * Represents the entire application.
 * One can imagine in the future there being multiple applications, 
 * each aimed at a different way to represent the data. For instance
 * an application that is focussed on voice-first instead of gui-first.
 */
class Application: View, Event {
    public let name: String

    public let settings: Settings
    public let sessions: Sessions
    public let navigation: NavigationSettings
    
    // These variables stay private to prevent tampering which can cause backward incompatibility
    var navigationPane: Navigation
    var browserPane: Browser
    var sessionPane: SessionSwitcher
    var overlayPane: Overlay

    public func init(_ name:String, _ api: PodAPI, _ cache Cache) {
        // Instantiate view objects

        // Load settings (from cache and/or api)
        // Load navigationSettings (from cache and/or api)
        // Load sessions (from cache and/or api)

        // Fire ready event

        // When session are loaded, load the current view
        // If there are no pre-existing sessions, load the default view
    }
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
}

struct NavigationItem: Observable { // Should this be a class ??
    /**
     * Used as the caption in the navigation
     */
    public var title:String
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


