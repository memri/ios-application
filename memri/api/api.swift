import Foundation
import UIKit

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
    /**
     * Possible values: "default", "device", "group", "user"
     */
    public var type: String

    /**
     * Used by device and group (and perhaps user)
     */
    public var name: String
    
    private var data:[String:AnyObject]
    
    public init(_ type:String) {
        self.type = type
    }

    /**
     *
     */
    public func get(_ path:String) -> AnyObject {
        
    }

    /**
     * Also responsible for saving the setting to the permanent storage
     */
    public func set(_ path:String, _ value:AnyObject) -> AnyObject {
        
    }
}


/*
 * Retrieves data from the pod, or executes actions on the pod.
 */
public class PodAPI {
    var key: String

    public init(_ podkey: String){
        self.key = podkey
    }

    /**
     * Sets the .id property on DataItem
     */
    public func create(_ item:DataItem, _ callback: (_ error:Error, _ success:Bool) -> Void) -> Void {
        print("created \(item)")
    }
    /**
     *
     */
    public func get(_ id:String, _ callback: (_ error:Error, _ item:DataItem) -> Void) -> Void {
        return DataItem.fromUid(uid: id)
    }
    /**
     *
     */
    public func update(_ id:String, _ item:DataItem, _ callback: (_ error:Error, _ success:Bool) -> Void) -> Void {
        print("updated \(id)")
    }
    /**
     *
     */
    public func remove(_ id:String, _ callback: (_ error:Error, _ success:Bool) -> Void) -> Void {
        print("removed \(id)")
    }
    
    /**
     *
     */
    public func link(_ id:String, _ id2:String, _ predicate:String, _ callback: (_ error:Error, _ created:Bool) -> Void) -> Void {
        print("linked \(id) - \(predicate) > \(id2)")
    }
    public func link(_ item:DataItem, _ item2:DataItem, _ predicate:String, _ callback: (_ error:Error, _ created:Bool) -> Void) -> Void {}
    
    /**
     *
     */
    public func unlink(_ fromId:String, _ toId:String, _ predicate:String, _ callback: (_ error:Error, _ success:Bool) -> Void) -> Void {
        print("unlinked \(fromId) - \(predicate) > \(toId)")
    }
    public func unlink(_ fromItem:DataItem, _ toItem:DataItem, _ predicate:String, _ callback: (_ error:Error, _ success:Bool) -> Void) -> Void {}

    /**
     *
     */
    public func query(_ query:String, _ options:QueryOptions?, _ callback: (_ error:Error, _ result:SearchResult) -> Void) -> Void {
        var searchResult = SearchResult()
                
                searchResult.data = try! DataItem.from_json(file: "test_dataItems")

        //        // this simulates async call
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        //            // get result
        //            // parse json
        //            searchResult.data = [DataItem("0x0"), DataItem("0x1")]
        //            searchResult.fire(event: "onload")
        //        }
                return searchResult
    }
    /**
     *
     */
    public func queryNLP(_ query:String, _ options:QueryOptions=QueryOptions(), _ callback: (_ error:Error, _ result:SearchResult) -> Void) -> Void {}
    /**
     *
     */
    public func queryDSL(_ query:String, _ options:QueryOptions=QueryOptions(), _ callback: (_ error:Error, _ result:SearchResult) -> Void) -> Void {}
    /**
     *
     */
    public func queryRAW(_ query:String, _ options:QueryOptions=QueryOptions(), _ callback: (_ error:Error, _ result:SearchResult) -> Void) -> Void {}

    /**
     * Returns a read-only SettingsData object.
     */
    public func getDefaultSettings(_ callback: (_ error:Error, _ result:SettingsData) -> Void) -> Void {}
    /**
     * Returns a read-write SettingsData object.
     */
    public func getDeviceSettings(_ callback: (_ error:Error, _ result:SettingsData) -> Void) -> Void {}
    /**
     * Returns a read-write SettingsData object when admin, otherwise read-only.
     */
    public func getGroupSettings(_ groupId:String, _ callback: (_ error:Error, _ result:SettingsData) -> Void) -> Void {}
    /**
     * Returns a read-write SettingsData object.
     */
    public func getUserSettings(_ callback: (_ error:Error, _ result:SettingsData) -> Void) -> Void {}

//    public func import() -> Void {}
//    public func export() -> Void {}
//    public func sync() -> Void {}
//    public func index() -> Void {}
//    public func convert() -> Void {}
//    public func augment() -> Void {}
//    public func automate() -> Void {}
//
//    public func streamResource(_ URI:String, _ options:StreamOptions, _ callback: (_ error:Error, _ stream:Stream) -> Void) -> Void {}
}
