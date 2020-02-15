/*
 * PodAPI
 */
class PodAPI {
    func init(_ key:String) {} // Constructor

    func remove(_ id:String,_ callback: (success:Boolean, error:Error) -> Void) -> Void {}
    func get(_ id:String,_ callback: (item:DataItem, error:Error) -> Void) -> Void {}
    func update(_ id:String,_ item:DataItem,_ callback: (success:Boolean, error:Error) -> Void) -> Void {}
    // Sets the .id property on DataItem
    func create(_ item:DataItem,_ callback: (success:Boolean, error:Error) -> Void) -> Void {}
    func link(_ id:String | item:DataItem, _ id:String | item:DataItem, _ predicate:String, _ callback: (created:Boolean, error:Error) -> Void) -> Void {}
    func unlink(_ id:String | item:DataItem, _ id:String | item:DataItem, _ predicate:String, _ callback: (success:Boolean, error:Error) -> Void) -> Void {}
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
    var sortAscending: Boolean
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