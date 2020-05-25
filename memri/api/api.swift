import Foundation
import Combine
import RealmSwift

public class QueryOptions: Object, Codable {
    /// Retrieves the query which is used to load data from the pod
    @objc dynamic var query: String? = nil
    
    /// Retrieves the property that is used to sort on
    @objc dynamic var sortProperty: String? = nil
    
    /// Retrieves whether the sort direction
    /// false sort descending
    /// true sort ascending
    let sortAscending = RealmOptional<Bool>()
    /// Retrieves the number of items per page
    let pageCount = RealmOptional<Int>() // Todo move to ResultSet
 
    let pageIndex = RealmOptional<Int>() // Todo move to ResultSet
     /// Returns a string representation of the data in QueryOptions that is unique for that data
     /// Each QueryOptions object with the same data will return the same uniqueString
    var uniqueString:String {
        var result:[String] = []
        
        result.append((self.query ?? "").sha256())
        result.append(self.sortProperty ?? "")
        
        let sortAsc = self.sortAscending.value ?? true
        result.append(String(sortAsc))
            
        return result.joined(separator: ":")
    }
    
    init(query:String) {
        super.init()
        self.query = query
    }
    
    required init() {
        super.init()
    }
}

public class CascadingQueryOptions: Object, Codable {
    /// Retrieves the query which is used to load data from the pod
    @objc dynamic var query: String? = nil
    
    /// Retrieves the property that is used to sort on
    @objc dynamic var sortProperty: String? = nil
    
    /// Retrieves whether the sort direction
    /// false sort descending
    /// true sort ascending
    let sortAscending = RealmOptional<Bool>()
    /// Retrieves the number of items per page
    let pageCount = RealmOptional<Int>() // Todo move to ResultSet
 
    let pageIndex = RealmOptional<Int>() // Todo move to ResultSet
     /// Returns a string representation of the data in QueryOptions that is unique for that data
     /// Each QueryOptions object with the same data will return the same uniqueString
    var uniqueString:String {
        var result:[String] = []
        
        result.append((self.query ?? "").sha256())
        result.append(self.sortProperty ?? "")
        
        let sortAsc = self.sortAscending.value ?? true
        result.append(String(sortAsc))
            
        return result.joined(separator: ":")
    }
    
    init(query:String) {
        super.init()
        self.query = query
    }
    
    required init() {
        super.init()
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
    public func create(_ item:DataItem, _ callback: (_ error:Error?, _ id:String) -> Void) -> Void {
        print("created \(item)")
        callback(nil, "0x" + UUID().uuidString);
    }
 
    public func get(_ id:String, _ callback: (_ error:Error?, _ item:DataItem) -> Void) -> Void {
        callback(nil, Note(value: ["id": id]))
    }
    
 
    public func update(_ item:DataItem, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {
        print("updated \(item.id)")
        callback(nil, true);
    }
 
    public func remove(_ id:String, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {
        print("removed \(id)")
        callback(nil, true);
    }
    
 
    public func link(_ subjectId:String, _ entityId:String, _ predicate:String, _ callback: (_ error:Error?, _ created:Bool) -> Void) -> Void {
        print("linked \(subjectId) - \(predicate) > \(entityId)")
        callback(nil, true);
    }
    public func link(_ item:DataItem, _ item2:DataItem, _ predicate:String, _ callback: (_ error:Error?, _ created:Bool) -> Void) -> Void {}
    
 
    public func unlink(_ subjectId:String, _ entityId:String, _ predicate:String, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {
        print("unlinked \(subjectId) - \(predicate) > \(entityId)")
        callback(nil, true);
    }
    public func unlink(_ fromItem:DataItem, _ toItem:DataItem, _ predicate:String, _ callback: (_ error:Error?, _ success:Bool) -> Void) -> Void {}

 
    public func query(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]?) -> Void) -> Void {
        
        //        // this simulates async call
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        //            // get result
        //            // parse json
        //            searchResult.data = [DataItem("0x0"), DataItem("0x1")]
        //            searchResult.fire(event: "onload")
        //        }
        
        if let query_ = query.query{
            if query_.contains("0xNEW") {
                callback("nothing to do", nil)
                return
            }
            else {
                let matches = query_.match(#"^(\w+) AND uid = '(.*)'$"#)
                if matches.count == 3 {
                    callback(nil, itemsFromFile("\(matches[1]).\(matches[2])"))
                    return
                }
                if query_.prefix(6) == "person" {
                    callback(nil, itemsFromFile("persons_from_server"))
                    return
                }
                
                if query_.prefix(4) == "note" {
                    callback(nil, itemsFromFile("notes_from_server"))
                    return
                }
                
                
            }
        }
        else {
            // TODO: Error handling
            print("Tried to execute query with queryOptions \(query), but it did not contain a query")
        }
        

        

        
        // TODO do nothing
//        let items:[DataItem] = try! DataItem.fromJSONFile("test_dataItems")
//        callback(nil, items);
    }
    
    private func itemsFromFile(_ file: String) -> [DataItem]{
        do{
            return try DataItem.fromJSONFile("notes_from_server")
        }
        catch{
            print("Could note read DataItems from file: \(file)")
            return [DataItem]()
        }
    }
 
    public func queryNLP(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
 
    public func queryDSL(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
 
    public func queryRAW(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}

    /// Returns a read-only SettingsData object.
    public func getDefaultSettings(_ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
    /// Returns a read-write SettingsData object.
    public func getDeviceSettings(_ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
    /// Returns a read-write SettingsData object when admin, otherwise read-only.
    public func getGroupSettings(_ groupId:String, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
    /// Returns a read-write SettingsData object.
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
