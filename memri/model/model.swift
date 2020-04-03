import Foundation
import Combine
import RealmSwift

class SyncState: Object, Codable {
    // Whether the data item is loaded partially and requires a full load
    @objc dynamic var isPartiallyLoaded:Bool = false
    
    // What action is needed on this data item to sync with the pod
    @objc dynamic var actionNeeded:String = ""
    
    // Which fields to update
    let updatedFields = List<String>()
}

public class DataItem: Object, Codable, Identifiable, ObservableObject {
    public var id:String = UUID().uuidString
    var type:String { "unknown" }
    
    @objc dynamic var uid:String? = nil
    @objc dynamic var deleted:Bool = false
    @objc dynamic var starred:Bool = false
    
    let changelog = List<LogItem>()
    @objc dynamic var loadState:SyncState? = SyncState()
        
    enum DataItemError: Error {
        case cannotMergeItemWithDifferentId
    }
    
    public override static func primaryKey() -> String? {
        return "uid"
    }
    
    public func initFomJSON(from decoder: Decoder) throws {
        jsonErrorHandling(decoder) {
            uid = try decoder.decodeIfPresent("uid") ?? uid
            starred = try decoder.decodeIfPresent("starred") ?? starred
            deleted = try decoder.decodeIfPresent("deleted") ?? deleted
            loadState = try decoder.decodeIfPresent("loadState") ?? loadState
            //TODO log
        }
    }
    
    /**
     *
     */
    public func getString(_ name:String) -> String {
        return self[name] as? String ?? ""
    }
    
    /**
     *
     */
    public func set(_ name:String, _ value:Any) {
        try! self.realm!.write() {
            self[name] = value
        }
    }
    
    /**
     * Sets deleted to true
     * All methods and properties must throw when deleted = true;
     */
    public func delete() -> Bool {
        if (self.deleted) { return false; }
        
        try! self.realm!.write() {
            self.deleted = true;
            self.realm!.delete(self)
        }
        
        return true;
    }
    
    /**
     *
     */
    public func match(_ needle:String) -> Bool{
        let properties = self.objectSchema.properties
        for prop in properties {
            if let haystack = self[prop.name] as? String {
                if haystack.lowercased().range(of: needle.lowercased()) != nil {
                    return true
                }
            }
        }
        
        return false
    }
    
    public static func == (lhs: DataItem, rhs: DataItem) -> Bool {
        lhs.uid == rhs.uid
    }
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> [DataItem] {
        let jsonData = try jsonDataFromFile(file, ext)
        
        let items:[DataItem] = try JSONDecoder().decode(family:DataItemFamily.self, from:jsonData)
        return items
    }
    
    public class func fromJSONString(_ json: String) throws -> [DataItem] {
        let items:[DataItem] = try JSONDecoder()
            .decode(family:DataItemFamily.self, from:Data(json.utf8))
        return items
    }
    
    public static func fromUid(uid:String)-> DataItem {
        let di = DataItem()
        di.uid = uid
        return di
    }
}

public class SearchResult: ObservableObject {
    let uid = UUID().uuidString

    public static func == (lt: SearchResult, rt: SearchResult) -> Bool {
        return lt.uid == rt.uid
    }
    
    /**
     *
     */
    var queryOptions: QueryOptions = QueryOptions(query: "")
    /**
     * Retrieves the data loaded from the pod
     */
    var data:[DataItem] = []
    /**
     *
     */
    var pages:[Int] = []
    /**
     * Returns the loading state
     *  -2 loading data failed
     *  -1 data is loaded from the server
     *  0 loading idle
     *  1 loading data from server
     */
    var loading: Int = 0
    
    public convenience required init(_ queryOptions: QueryOptions? = nil, _ data:[DataItem]?) {
        self.init()
        
        self.data = data ?? []
        
        if let queryOptions = queryOptions {
            self.queryOptions = queryOptions
            
            if (data != nil) {
                loading = -1
                if !pages.contains(queryOptions.pageIndex.value ?? 0) {
                    pages.append(queryOptions.pageIndex.value ?? 0)
                }
            }
        }
    }
    
    func setPagesLoaded(_ pageIndex:Int) {
        if !pages.contains(pageIndex) {
            pages.append(pageIndex)
        }
    }
    
    /**
     *
     */
    public static func fromDataItems(_ data: [DataItem]) -> SearchResult {
        let obj = SearchResult()
        obj.data = data
        return obj
    }
    
    private enum CodingKeys: String, CodingKey {
        case query, pages, data
    }
}
