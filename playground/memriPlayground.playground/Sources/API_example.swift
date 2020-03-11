import Foundation
import UIKit


public class PodAPI {
    var key: String
    
    public init(_ podkey: String){
        self.key = podkey
    }
    
    func remove(uid: String) -> Void {
        print("removed \(uid)")
    }

    func get(uid: String) -> DataItem {
        return DataItem(uid)
    }
    
    func update(uid: String, dataItem: DataItem) -> Void {
        print("updated \(uid)")
    }
    
    func create(dataItem: DataItem) -> Void {
        print("created \(dataItem)")
    }
    
    func link(uid1: String, uid2: String, predicate: String) -> Void {
        // TODO: arguments can either be uids or DataItems
        print("linked \(uid1) - \(predicate) > \(uid2)")
    }
    
    func unlink(uid1: String, uid2: String, predicate: String) -> Void {
        // TODO: arguments can either be uids or DataItems
        print("unlinked \(uid1) - \(predicate) > \(uid2)")
    }
    
    public func query(_ query: String) -> SearchResult {
        var searchResult = SearchResult(query: query)
        // this simulates async call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // get result
            // parse json
            searchResult.data = [DataItem("0x0"), DataItem("0x1")]
            searchResult.fire(event: "onload")
        }
        return searchResult
    }
    
}
