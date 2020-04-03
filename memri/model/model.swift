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

/*
    * resultSet.type should return the type of the result or "_mixed_"
    * resultSet.isList should return true if the query could return more than 1 item
        * Based on the query if there is no data yet
    * computeView and setCurrentView should not be called until there is data
    - resultSet should contain all the logic to load its data (??)
    * setCurrentView should be called directly instead of through bindings, and should trigger the bindings update itself
 */
public class SearchResult: ObservableObject {
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
    var data: [DataItem] = []
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
     * Returns the loading state
     *  -2 loading data failed
     *  -1 data is loaded from the server
     *  0 loading idle
     *  1 loading data from server
     */
    private var loading: Int = 0
    private var pages: [Int] = []
    private let cache: Cache
    
    required init(_ ch:Cache) {
        cache = ch
    }
//
//    public convenience required init(_ queryOptions: QueryOptions? = nil, _ data:[DataItem]?) {
//        self.init()
//
//        self.data = data ?? []
//
//        if let queryOptions = queryOptions {
//            self.queryOptions = queryOptions
//
//            if (data != nil) {
//                loading = -1
//                if !pages.contains(queryOptions.pageIndex.value ?? 0) {
//                    pages.append(queryOptions.pageIndex.value ?? 0)
//                }
//            }
//        }
//    }
    
    func load(_ callback:(_ error:Error?) -> Void) throws {
        // Set state to loading
        loading = 1
        
        if queryOptions.query == "" {
            throw "Exception: No query specified when loading result set"
        }
        
        cache.query(queryOptions) { (error, result, success) -> Void in
            if (error != nil) {
                // Set loading state to error
                loading = -2

                callback(error)
                return
            }

            // TODO this only works when retrieving 1 page. It will break for pagination
            if let result = result { data = result }

            // We've successfully loaded page 0
            setPagesLoaded(0)

            // First time loading is done
            loading = -1

            callback(nil)
        }
    }
    
//    let resultSet = cache.getResultSet(queryOptions)
//
//    // TODO: This is still a hack. ResultSet should fetch the data based on the query
//    resultSet.data = [item]
//
//    // TODO move this to resultSet
//    // Only load the item if it is partially loaded
//    if item.syncState!.isPartiallyLoaded {
//        resultSet.loading = 0
//    }
//    else {
//        resultSet.loading = -1
//    }
    
    
//    // Load data
//    let resultSet = self.computedView.resultSet
//
//    // TODO: create enum for loading
//    if resultSet.loading == 0 && resultSet.queryOptions.query != "" {
//        cache.loadPage(resultSet, 0, { (error) in
//            if error == nil {
//                // call again when data is loaded, so the view can adapt to the data
//                self.setCurrentView()
//            }
//        })
//    }

    /**
     * Client side filter //, with a fallback to the server
     */
    public func filter(_ searchResult:SearchResult, _ query:String) -> SearchResult {
        let options = searchResult.queryOptions
        options.query = query
        
        let filterResult = SearchResult(cache)
        filterResult.queryOptions = options
        filterResult.data = searchResult.data
        filterResult.loading = searchResult.loading
        filterResult.pages.removeAll()
        filterResult.pages.append(contentsOf: searchResult.pages)
        
        for i in stride(from: filterResult.data.count - 1, through: 0, by: -1) {
            if (!filterResult.data[i].match(query)) {
                filterResult.data.remove(at: i)
            }
        }

        return filterResult
    }
        
    /**
     * Executes the query again
     */
    public func reload(_ searchResult:SearchResult) -> Void {
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
