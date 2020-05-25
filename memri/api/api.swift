import Foundation
import Combine
import RealmSwift

protocol UniqueString {
    var uniqueString:String { get }
}

public class Datasource: Object, UniqueString {
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
    
    public class func fromCVUDefinition(_ def:CVUParsedDatasourceDefinition) -> Datasource {
        return Datasource(value: [
            "selector": def.selector ?? "[datasource]",
            "query": def["query"] as? String ?? "" as Any,
            "sortProperty": def["sortProperty"] as? String ?? "",
            "sortAscending": def["sortAscending"] as? Bool ?? true
        ])
    }
}

public class CascadingDatasource: Cascadable, UniqueString {
    /// Retrieves the query which is used to load data from the pod
    var query: String? {
        datasource.query ?? cascadeProperty("query")
    }
    
    /// Retrieves the property that is used to sort on
    var sortProperty: String? {
        datasource.sortProperty ?? cascadeProperty("sortProperty")
    }
    
    /// Retrieves whether the sort direction
    /// false sort descending
    /// true sort ascending
    var sortAscending:Bool? {
        datasource.sortAscending.value ?? cascadeProperty("sortAscending")
    }
    
    let datasource:Datasource
 
     /// Returns a string representation of the data in QueryOptions that is unique for that data
     /// Each QueryOptions object with the same data will return the same uniqueString
    var uniqueString:String {
        var result:[String] = []
        
        result.append((self.query ?? "").sha256())
        result.append(self.sortProperty ?? "")
        
        let sortAsc = self.sortAscending ?? true
        result.append(String(sortAsc))
            
        return result.joined(separator: ":")
    }
    
    func flattened() -> Datasource {
        return Datasource(value: [
            "query": self.query as Any,
            "sortProperty": self.sortProperty as Any,
            "sortAscending": self.sortAscending as Any
        ])
    }
    
    required init(_ cascadeStack: [CVUParsedDefinition], _ datasource:Datasource) {
        self.datasource = datasource
        super.init()
        self.cascadeStack = cascadeStack
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

 
    public func query(_ query:Datasource, _ callback: (_ error:Error?, _ result:[DataItem]?) -> Void) -> Void {
        
        //        // this simulates async call
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        //            // get result
        //            // parse json
        //            searchResult.data = [DataItem("0x0"), DataItem("0x1")]
        //            searchResult.fire(event: "onload")
        //        }
        
        if query.query!.contains("0xNEW") {
            callback("nothing to do", nil)
            return
        }
        
        let matches = query.query!.match(#"^(\w+) AND uid = '(.*)'$"#)
        if matches.count == 3 {
            callback(nil, try! DataItem.fromJSONFile("\(matches[1]).\(matches[2])"))
            return
        }
        
        if query.query!.prefix(6) == "Person" {
            callback(nil, try! DataItem.fromJSONFile("persons_from_server"))
            return
        }
        
        if query.query!.prefix(4) == "Note" {
            callback(nil, try! DataItem.fromJSONFile("notes_from_server"))
            return
        }
        

        
        // TODO do nothing
//        let items:[DataItem] = try! DataItem.fromJSONFile("test_dataItems")
//        callback(nil, items);
    }
 
    public func queryNLP(_ query:Datasource, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
 
    public func queryDSL(_ query:Datasource, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}
 
    public func queryRAW(_ query:Datasource, _ callback: (_ error:Error?, _ result:[DataItem]) -> Void) -> Void {}

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
