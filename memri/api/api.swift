import Foundation
import Combine
import RealmSwift

public class QueryOptions: Object, Codable {
    /**
     * Retrieves the query which is used to load data from the pod
     */
    @objc dynamic var query: String? = nil
    
    /**
     * Retrieves the property that is used to sort on
     */
    @objc dynamic var sortProperty: String? = nil
    /**
     * Retrieves whether the sort direction
     *   -1 no sorting is applied
     *    0 sort descending
     *    1 sort ascending
     */
    let sortAscending = RealmOptional<Int>()
    /**
     * Retrieves the number of items per page
     */
    let pageCount = RealmOptional<Int>() // Todo move to ResultSet
    /**
     *
     */
    let pageIndex = RealmOptional<Int>() // Todo move to ResultSet
    /**
     * Returns a string representation of the data in QueryOptions that is unique for that data
     * Each QueryOptions object with the same data will return the same uniqueString
     */
    var uniqueString:String {
        var result:[String] = []
        
        result.append((self.query ?? "").sha256())
        result.append(self.sortProperty ?? "")
        
        let sortAsc = self.sortAscending.value ?? -1
        result.append(String(sortAsc))
            
        return result.joined(separator: ":")
    }
    
    init(query:String) {
        super.init()
        
        self.query = query
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            query = try decoder.decodeIfPresent("query") ?? query
            sortProperty = try decoder.decodeIfPresent("sortProperty") ?? sortProperty
            sortAscending.value = try decoder.decodeIfPresent("sortAscending") ?? sortAscending.value
            pageCount.value = try decoder.decodeIfPresent("pageCount") ?? pageCount.value
        }
    }
    
    required init() {
        super.init()
    }
    
    public func merge(_ queryOptions:QueryOptions) {
        self.query = queryOptions.query ?? self.query ?? nil
        self.sortProperty = queryOptions.sortProperty ?? self.sortProperty ?? ""
        self.sortAscending.value = queryOptions.sortAscending.value ?? self.sortAscending.value ?? -1
        self.pageCount.value = queryOptions.pageCount.value ?? self.pageCount.value ?? 0
        self.pageIndex.value = queryOptions.pageIndex.value ?? self.pageIndex.value ?? 0
    }
}

class SessionResult:DataItem {
    @objc var json:String? = nil
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
    public func create(_ item:DataItem, _ callback: (_ error:Error?, _ id:String) -> Void) -> Void {
        print("created \(item)")
        callback(nil, "0x" + UUID().uuidString);
    }
    /**
     *
     */
    public func get(_ id:String, _ callback: (_ error:Error?, _ item:DataItem) -> Void) -> Void {
        if id == "sessions" {
            let jsonString = try! stringFromFile("default_sessions", "json")
            callback(nil, SessionResult(value: ["type": "sessions", "json": jsonString]))
            return
        }
        
//        let note = Note()
//        note.id = id
        
        callback(nil, Note(value: ["id": id]))
    }
    
    /**
     *
     */
    public func update(_ item:DataItem, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {
        print("updated \(item.id)")
        callback(nil, true);
    }
    /**
     *
     */
    public func remove(_ id:String, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {
        print("removed \(id)")
        callback(nil, true);
    }
    
    /**
     *
     */
    public func link(_ subjectId:String, _ entityId:String, _ predicate:String, _ callback: (_ error:Error?, _ created:Bool) -> Void) -> Void {
        print("linked \(subjectId) - \(predicate) > \(entityId)")
        callback(nil, true);
    }
    public func link(_ item:DataItem, _ item2:DataItem, _ predicate:String, _ callback: (_ error:Error?, _ created:Bool) -> Void) -> Void {}
    
    /**
     *
     */
    public func unlink(_ subjectId:String, _ entityId:String, _ predicate:String, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {
        print("unlinked \(subjectId) - \(predicate) > \(entityId)")
        callback(nil, true);
    }
    public func unlink(_ fromItem:DataItem, _ toItem:DataItem, _ predicate:String, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {}

    /**
     *
     */
    public func query(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]?) -> Void) -> Void {
        
        //        // this simulates async call
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        //            // get result
        //            // parse json
        //            searchResult.data = [DataItem("0x0"), DataItem("0x1")]
        //            searchResult.fire(event: "onload")
        //        }
        
        if query.query!.starts(with: "0xNEW") {
            callback("nothing to do", nil)
            return
        }
        if query.query!.starts(with: "0x") {
            callback(nil, try! DataItem.fromJSONFile(query.query!))
            return
        }
        if query.query!.prefix(4) == "note" {
            callback(nil, try! DataItem.fromJSONFile("notes_from_server"))
            return
        }
        
        let items:[DataItem] = try! DataItem.fromJSONFile("test_dataItems")
        callback(nil, items);
    }
    /**
     *
     */
    public func queryNLP(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
    /**
     *
     */
    public func queryDSL(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
    /**
     *
     */
    public func queryRAW(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}

    /**
     * Returns a read-only SettingsData object.
     */
    public func getDefaultSettings(_ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
    /**
     * Returns a read-write SettingsData object.
     */
    public func getDeviceSettings(_ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
    /**
     * Returns a read-write SettingsData object when admin, otherwise read-only.
     */
    public func getGroupSettings(_ groupId:String, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
    /**
     * Returns a read-write SettingsData object.
     */
    public func getUserSettings(_ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}

//    public func import() -> Void {}
//    public func export() -> Void {}
//    public func sync() -> Void {}
//    public func index() -> Void {}
//    public func convert() -> Void {}
//    public func augment() -> Void {}
//    public func automate() -> Void {}
//
//    public func streamResource(_ URI:String, _ options:StreamOptions, _ callback: (_ error:Error?, _ stream:Stream) -> Void) -> Void {}
}
