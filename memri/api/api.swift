import Foundation
import UIKit
import Combine

public struct QueryOptions {
    /**
     * Name of the property to sort on
     */
    public var sortProperty: String
    /**
     * Name of the property to sort on
     */
    public var sortAscending: Int

    public var pageIndex:Int

    public var pageCount:Int
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
    public func create(_ item:DataItem, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {
        print("created \(item)")
        callback(nil, true);
    }
    /**
     *
     */
    public func get(_ id:String, _ callback: (_ error:Error?, _ item:DataItem) -> Void) -> Void {
        callback(nil, DataItem(id: id, type: "note"))
    }
    /**
     *
     */
    public func update(_ id:String, _ item:DataItem, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {
        print("updated \(id)")
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
    public func link(_ id:String, _ id2:String, _ predicate:String, _ callback: (_ error:Error?, _ created:Bool) -> Void) -> Void {
        print("linked \(id) - \(predicate) > \(id2)")
        callback(nil, true);
    }
    public func link(_ item:DataItem, _ item2:DataItem, _ predicate:String, _ callback: (_ error:Error?, _ created:Bool) -> Void) -> Void {}
    
    /**
     *
     */
    public func unlink(_ fromId:String, _ toId:String, _ predicate:String, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {
        print("unlinked \(fromId) - \(predicate) > \(toId)")
        callback(nil, true);
    }
    public func unlink(_ fromItem:DataItem, _ toItem:DataItem, _ predicate:String, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {}

    /**
     *
     */
    public func query(_ query:String, _ options:QueryOptions?, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {
        let items:[DataItem] = try! DataItem.from_json(file: "test_dataItems")

        //        // this simulates async call
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        //            // get result
        //            // parse json
        //            searchResult.data = [DataItem("0x0"), DataItem("0x1")]
        //            searchResult.fire(event: "onload")
        //        }
        
        callback(nil, items);
    }
    /**
     *
     */
    public func queryNLP(_ query:String, _ options:QueryOptions?, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
    /**
     *
     */
    public func queryDSL(_ query:String, _ options:QueryOptions?, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
    /**
     *
     */
    public func queryRAW(_ query:String, _ options:QueryOptions?, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}

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

public class SearchResult: ObservableObject, Decodable {
    @EnvironmentObject var podApi: PodAPI
    
    /**
     * Retrieves the query which is used to load data from the pod
     */
    var query: String = ""
    /**
     * Retrieves the data loaded from the pod
     */
    @Published public var data: [DataItem] = []
    /**
     * Retrieves the property that is used to sort on
     */
    public var sortProperty: String? = ""
    /**
     * Retrieves whether the sort direction
     *   -1 no sorting is applied
     *    0 sort descending
     *    1 sort ascending
     */
    public var sortAscending: Int = 0
    /**
     * Returns the loading state
     *  -2 loading data failed
     *  -1 data is loaded from the server
     *  0 loading complete
     *  1 loading data from server
     */
    public var loading: Int = 0
    /**
     * Retrieves the number of items per page
     */
    public var pageCount: Int = 0
    /**
     *
     */
    public var pages: [Int] = []
    
    public convenience required init(_ query: String, _ options:QueryOptions? = nil, _ data:[DataItem]?) {
        self.query = query
        self.data = data ?? []
        
        sortProperty = options?.sortProperty
        sortAscending = options?.sortAscending ?? 0
        pageCount = options?.pageCount ?? 0
        
        if (data != nil) {
            connect()
        }
        else {
            loading = -1
            pages = [0]
        }
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        query = try decoder.decodeIfPresent("query") ?? query
        data = try decoder.decodeIfPresent("data") ?? data
        sortProperty = try decoder.decodeIfPresent("sortProperty") ?? sortProperty
        sortAscending = try decoder.decodeIfPresent("sortAscending") ?? sortAscending
        loading = try decoder.decodeIfPresent("loading") ?? loading
        pageCount = try decoder.decodeIfPresent("pageCount") ?? pageCount
        pages = try decoder.decodeIfPresent("pageCount") ?? pages
        
        if (data.isEmpty && loading == 0) {
            connect()
        }
        else {
            // If the searchResult is initiatlized with data we set the state to loading done
            loading = -1
        }
    }
    
    private func connect() -> Bool {
        if (loading > 0 || query == "") { return false }
        
        // Set state to loading
        loading = 1
        
        let options = QueryOptions(sortProperty: self.sortProperty ?? "",
                                   sortAscending: self.sortAscending,
                                   pageIndex: 0, pageCount: self.pageCount);
        
        podApi.query(self.query, options, { (error, items) -> Void in
            if (error != nil) {
                /* TODO: trigger event or so */
                
                // Loading error
                loading = -2
                
                return
            }
            
            self.data = items
            
            // We've successfully loaded page 0
            pages.append(0);
            
            // First time loading is done
            loading = -1
        })
    }
    
    /**
     * Client side filter //, with a fallback to the server
     */
    public func filter(_ query:String) -> SearchResult {
        let searchResult = SearchResult(self.query, nil, self.data);
        
        searchResult.sortProperty = self.sortProperty
        searchResult.sortAscending = self.sortAscending
        searchResult.loading = self.loading
        searchResult.pageCount = self.pageCount
        searchResult.pages = self.pages
        
        for i in 0...searchResult.data.count {
            if (!searchResult.data[i].match(query)) {
                searchResult.data.remove(at: i)
            }
        }
        
        return searchResult
    }
        
    /**
     * Executes the query again
     */
    public func reload() -> Bool {
        loading = 0
        return connect()
    }
    /**
     *
     */
    public func resort(_ options:QueryOptions) {
        
    }
    /**
     *
     */
    public func loadPage(_ pageNr:Int) {
        
    }
    
    // TODO: change this to use observable
    func fire(event: String) -> Void{}
    
    /**
     *
     */
    public static func fromDataItems(_ data: [DataItem]) -> SearchResult {
        let obj = SearchResult()
        obj.data = data
        return obj
    }
}
