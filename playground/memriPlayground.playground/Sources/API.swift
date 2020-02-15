/*
 * PodAPI
 */
class PodAPI {
    func init(_ key:String) {} // Constructor

    func remove(_ id:String,_ callback: (success:Bool, error:Error) -> Void) -> Void {}
    func get(_ id:String,_ callback: (item:DataItem, error:Error) -> Void) -> Void {}
    func update(_ id:String,_ item:DataItem,_ callback: (success:Bool, error:Error) -> Void) -> Void {}
    // Sets the .id property on DataItem
    func create(_ item:DataItem,_ callback: (success:Bool, error:Error) -> Void) -> Void {}
    func link(_ id:String | item:DataItem, _ id:String | item:DataItem, _ predicate:String, _ callback: (created:Bool, error:Error) -> Void) -> Void {}
    func unlink(_ id:String | item:DataItem, _ id:String | item:DataItem, _ predicate:String, _ callback: (success:Bool, error:Error) -> Void) -> Void {}
    func query(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    func queryNLP(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    func queryDSL(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    func queryRAW(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    // Returns a read-only SettingsData object.
    func getDefaultSettings(_ callback: (result:SettingsData, error:Error) -> Void) -> Void {}
    // Returns a read-write SettingsData object.
    func getDeviceSettings(_ callback: (result:SettingsData, error:Error) -> Void) -> Void {}
    // Returns a read-write SettingsData object when admin, otherwise read-only.
    func getGroupSettings(_ groupId:String, _ callback: (result:SettingsData, error:Error) -> Void) -> Void {}
    // Returns a read-write SettingsData object.
    func getUserSettings(_ callback: (result:SettingsData, error:Error) -> Void) -> Void {}
    func import() -> Void {}
    func export() -> Void {}
    func sync() -> Void {}
    func index() -> Void {}
    func convert() -> Void {}
    func augment() -> Void {}
    func automate() -> Void {}
    func streamResource(_ URI:String, _ options:StreamOptions, _ callback: (stream:Stream, error:Error) -> Void) -> Void {}
}

struct QueryOptions {
    /**
     * Name of the property to sort on
     */
    var sortProperty: String
    /**
     * Name of the property to sort on
     */
    var sortAscending: Bool

    var pageNr:Int

    var pageSize:Int
}

class SettingsData {
    func init(_ type:String) {}

    /**
     * Possible values: "default", "device", "group", "user"
     */
    var type: String

    /**
     * Used by device and group (and perhaps user)
     */
    var name: String

    func get(_ path:String) -> AnyObject {} 

    /**
     * Also responsible for saving the setting to the permanent storage
     */
    func set(_ path:String, _ value:AnyObject) -> AnyType {} 
}

class Stream {

}

struct StreamOptions {

}

/**
 * Updates elements that are updated elsewhere, such as on the server, by other clients and automation.
 */
class StateSyncAPI {
    func init(_ cache:Cache, _ api:PodAPI) {}
}

class Cache {
    func init(_ api:PodAPI) {}

    func findQueryResult(_ query:String, _ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    func queryLocal(_ query:String, _ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    func getByType(_ query:String, _ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
    func getById(_ query:String, _ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}

    /**
     * Loads data from the pod. Returns SearchResult.
     * -> Calls callback twice, once for cache, once for real data [??]
     */
    func query(_ query:String, _ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) -> Void {}
}

class Event {
    func fire(_ name:String) {}
    func on(_ name:String, _ callback:() -> Void)
    func off(_ name:String, _ callback:() -> Void)
}

/**
 * Fires load event when new data is received
 */
class SearchResult: Event {
    /**
     * Retrieves the query which is used to load data from the pod
     */
    let query:String
    /**
     * Retrieves the property that is used to sort on
     */
    let sortProperty:String
    /**
     * Retrieves whether the sort direction
     *   -1 no sorting is applied
     *    0 sort descending
     *    1 sort ascending
     */
    let sortAscending:Bool
    var pageCount:Int
    /**
     * Retrieves the number of items per page
     */
    let pageSize:Int
    /**
     * Retrieves the data loaded from the pod
     */
    let data: [DataItem]

    /**
     * Returns the loading state
     *  0 loading complete
     *  1 loading data from server
     */
    var loading:Bool

    /**
     * Sets the constants above
     */
    func init(_ options:QueryOptions) {}
    
    /**
     * Client side filter, with a fallback to the server
     */
    func filter(_ query:String) {}
    /**
     * Executes the query again
     */
    func reload() {}
    
    func resort(_ options:QueryOptions) {}
    func loadPage(_ pageNr:Int) {}
}