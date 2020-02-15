/*
 * PodAPI
 */
PodAPI(String key) // Constructor
.remove(_ id:String,_ callback: (success:Boolean, error:Error) -> Void)
.get(_ id:String,_ callback: (item:DataItem, error:Error) -> Void)
.update(_ id:String,_ item:DataItem,_ callback: (success:Boolean, error:Error) -> Void)
// Sets the .id property on DataItem
.create(_ item:DataItem,_ callback: (success:Boolean, error:Error) -> Void)
.link(_ id:String | item:DataItem, _ id:String | item:DataItem, _ predicate:String, _ callback: (created:Boolean, error:Error) -> Void)
.unlink(_ id:String | item:DataItem, _ id:String | item:DataItem, _ predicate:String, _ callback: (success:Boolean, error:Error) -> Void)
.query(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void)
.queryNLP(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void)
.queryDSL(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void)
.queryRAW(_ query:String,_ options:QueryOptions, _ callback: (result:SearchResult, error:Error) -> Void)
// Returns a read-only SettingsData object.
.getDefaultSettings(_ callback: (result:SettingsData, error:Error) -> Void)
// Returns a read-write SettingsData object.
.getDeviceSettings(_ callback: (result:SettingsData, error:Error) -> Void)
// Returns a read-write SettingsData object when admin, otherwise read-only.
.getGroupSettings(_ groupId:String, _ callback: (result:SettingsData, error:Error) -> Void)
// Returns a read-write SettingsData object.
.getUserSettings(_ callback: (result:SettingsData, error:Error) -> Void)
.import()
.export()
.sync()
.index()
.convert()
.augment()
.automate()
streamResource(_ URI:String, _ options:StreamOptions, _ callback: (stream:Stream, error:Error) -> Void)
