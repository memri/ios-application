/*
 * PodAPI
 */
class PodAPI{
    func init(key:String) {} // Constructor

    func remove(_ id:String,_ callback: (success:Boolean, error:Error) -> Void) {}
    func get(_ id:String,_ callback: (item:DataItem, error:Error) -> Void) {}
    func update(_ id:String,_ item:DataItem,_ callback: (success:Boolean, error:Error) -> Void) {}
    // Sets the .id property on DataItem
    func create(_ item:DataItem,_ callback: (success:Boolean, error:Error) -> Void) {}
    func link(_ id:String | item:DataItem, _ id:String | item:DataItem, _ predicate:String, _ callback: (created:Boolean, error:Error) -> Void) {}
    func unlink(_ id:String | item:DataItem, _ id:String | item:DataItem, _ predicate:String, _ callback: (success:Boolean, error:Error) -> Void) {}
    func query(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) {}
    func queryNLP(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) {}
    func queryDSL(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) {}
    func queryRAW(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void) {}
    // Returns a read-only SettingsData object.
    func getDefaultSettings(_ callback: (result:SettingsData, error:Error) -> Void) {}
    // Returns a read-write SettingsData object.
    func getDeviceSettings(_ callback: (result:SettingsData, error:Error) -> Void) {}
    // Returns a read-write SettingsData object when admin, otherwise read-only.
    func getGroupSettings(_ groupId:String, _ callback: (result:SettingsData, error:Error) -> Void) {}
    // Returns a read-write SettingsData object.
    func getUserSettings(_ callback: (result:SettingsData, error:Error) -> Void) {}
    func import() {}
    func export() {}
    func sync() {}
    func index() {}
    func convert() {}
    func augment() {}
    func automate() {}
    func streamResource(_ URI:String, _ options:StreamOptions, _ callback: (stream:Stream, error:Error) -> Void) {}
}
