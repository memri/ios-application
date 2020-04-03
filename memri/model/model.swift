import Foundation
import Combine
import RealmSwift

public class DataItem: Object, Codable, Identifiable, ObservableObject {
    public var id:String = UUID().uuidString
    var type:String { "unknown" }
    
    @objc dynamic var uid:String? = nil
    @objc dynamic var deleted:Bool = false
    @objc dynamic var starred:Bool = false
    
    let changelog = List<LogItem>()
    @objc dynamic var syncState:SyncState? = SyncState()
        
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
            syncState = try decoder.decodeIfPresent("syncState") ?? syncState
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
    
    private func isEqualProperty(_ fieldName:String, _ item:DataItem) {
        let prop = self.objectSchema.properties[fieldName]!
        
        // Optional
        if prop.isOptional {
            return self[fieldName].value == item[fieldName].value
        }
        // List
        else if prop.objectClassName != nil {
            return false // TODO implement a list compare and a way to add to updatedFields
        }
        else {
            return self[fieldName] == item[fieldName]
        }
        
        return true
    }
    
    public func safeMerge(_ item:DataItem) -> Bool {
        
        // Ignore when marked for deletion
        if self.syncState!.actionNeeded == "delete" { return true }
        
        // Do not update when the version is not higher then what we already have
        if item.syncState!.version =< self.syncState!.version { return true }
        
        // Make sure to not overwrite properties that have been changed
        let updatedFields = self.syncState!.updatedFields
        
        // Compare all properties and make sure they are the same
        for fieldName in updatedFields {
            if !isEqualProperty(fieldName, item) { return false }
        }
        
        // Merge with item
        merge(item)
        
        return true
    }
    
    public func merge(_ item:DataItem) throws {
        // TODO needs to detect lists which will always be set
        // TODO needs to detect optionals which will always be set
        
        // Store these changes in realm
        if let realm = self.realm {
            try self.realm.write {
                doMerge(item)
            }
        }
        else {
            doMerge(item)
        }
    }
    
    private func doMerge(_ item:DataItem) {
        let properties = self.objectSchema.properties
        for prop in properties {
            
            // Optional
            if prop.isOptional {
                if item[prop.name].value != nil {
                    self[prop.name].value = item[prop.name].value
                }
            }
            // List
            else if prop.objectClassName != nil {
                if item[prop.name].count > 0 {
                    self[prop.name].removeAll()
                    self[prop.name].append(contentsOf: item[prop.name])
                }
            }
            else {
                if item[prop.name].value != nil {
                    self[prop.name] = item[prop.name]
                }
            }
        }
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

public class ResultSet: ObservableObject {
//    let uid = UUID().uuidString
//
//    public static func == (lt: SearchResult, rt: SearchResult) -> Bool {
//        return lt.uid == rt.uid
//    }
    
    /**
     *
     */
    var queryOptions: QueryOptions = QueryOptions(query: "")
    /**
     * Retrieves the data loaded from the pod
     */
    var items: [DataItem] = []
    /**
     *
     */
    var count: Int = 0
    /**
     *
     */
    var determinedType: String? {
        if (self.queryOptions.query != nil) {
            return "note" // TODO implement (more) proper query language
        }
        else {
            return nil
        }
    }
    /**
     *
     */
    var isList: Bool {
        // TODO change this to be a proper query parser
        return !(self.queryOptions.query ?? "").starts(with: "0x")
    }
    /**
     *
     */
    var item: DataItem? {
        if isList && count > 0 { return items[0] }
        else { return nil }
    }
    
    private var loading: Bool = false
    private var pages: [Int] = []
    private let cache: Cache
    
    required init(_ ch:Cache) {
        cache = ch
    }
    
    func load(_ callback:(_ error:Error?) -> Void) throws {
        
        // Only execute one loading process at the time
        if !loading {
        
            // Validate queryOptions
            if queryOptions.query == "" {
                throw "Exception: No query specified when loading result set"
            }
            
            // Set state to loading
            loading = true
            
            // Execute the query
            cache.query(queryOptions) { (error, result) -> Void in
                if let result = result {
                    
                    // Set data and count
                    items = result
                    count = items.count

                    // We've successfully loaded page 0
                    setPagesLoaded(0) // TODO This is not used at the moment

                    // First time loading is done
                    loading = false

                    // Done
                    callback(nil)
                }
                else if (error != nil) {
                    // Set loading state to error
                    loading = false

                    // Done with errors
                    callback(error)
                }
            }
        }
    }
    
    func forceItemsUpdate(_ result:[DataItem]) {
        items = result
        count = items.count
        
        self.objectWillChange.send() // TODO create our own publishers
    }

    /**
     * Client side filter //, with a fallback to the server
     */
    public func filter(_ searchResult:ResultSet, _ query:String) -> ResultSet {
        let options = searchResult.queryOptions
        options.query = query
        
        let filterResult = ResultSet(cache)
        filterResult.queryOptions = options
        filterResult.items = searchResult.items
        filterResult.loading = searchResult.loading
        filterResult.pages.removeAll()
        filterResult.pages.append(contentsOf: searchResult.pages)
        
        for i in stride(from: filterResult.items.count - 1, through: 0, by: -1) {
            if (!filterResult.items[i].match(query)) {
                filterResult.items.remove(at: i)
            }
        }

        return filterResult
    }
        
    /**
     * Executes the query again
     */
    public func reload(_ searchResult:ResultSet) -> Void {
        // Reload all pages
//        for (page, _) in searchResult.pages {
//            let _ = self.loadPage(searchResult, page, { (error) in })
//        }
    }
    
    /**
     *
     */
    public func resort(_ options:QueryOptions) {
        
    }
    
    func setPagesLoaded(_ pageIndex:Int) {
        if !pages.contains(pageIndex) {
            pages.append(pageIndex)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case query, pages, data
    }
}
