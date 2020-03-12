import Foundation
import Combine

public class DataItem: Decodable, Equatable, Identifiable, ObservableObject {
    private var uid: String? = nil
    public var type: String = ""
    
    @Published public var predicates: [String: [DataItem]] = [:]
    @Published public var properties: [String: AnyDecodable] = [:]
    @Published private var deleted: Bool = false;
    
    public var isDeleted:Bool {
        return deleted;
    }
    
    public var id: String {
        return self.uid ?? ""
    }
    
    public convenience required init(id:String? = nil, type:String) {
        self.init()
        self.uid = id
        self.type = type
    }
    
    public convenience required init(id:String? = nil, type: String, predicates: [String: [DataItem]]? = [:],
                            properties:[String: AnyDecodable]? = [:]){
        self.init()
        self.uid = id ?? self.uid
        self.type = type
        self.predicates = predicates ?? self.predicates
        self.properties = properties ?? self.properties
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        uid = try decoder.decodeIfPresent("uid") ?? uid
        type = try decoder.decodeIfPresent("type") ?? type
        predicates = try decoder.decodeIfPresent("predicates") ?? predicates
        properties = try decoder.decodeIfPresent("properties") ?? properties
    }
    
    public static func fromUid(uid:String)-> DataItem {
        let di = DataItem()
        di.uid = uid
        return di
    }
    
    public static func == (lhs: DataItem, rhs: DataItem) -> Bool {
        lhs.uid == rhs.uid
    }
    
    public class func from_json(file: String, ext: String = "json") throws -> [DataItem] {
        let data = try jsonDataFromFile(file, ext)
        let items: [DataItem] = try! JSONDecoder().decode([DataItem].self, from: data)
        return items
    }
    
    /**
     *
     */
    public func findProperty(name: String) -> AnyDecodable {
        return self.properties[name]!
    }
    
    /**
     *
     */
    public func findEntityByPredicate(_ predicate:String) -> [DataItem] {
        return self.predicates[predicate]!
    }
    
    /**
     *
     */
    public func findPredicateByEntity(_ item:DataItem) -> [String] {
        var items:[String] = []
        for (name, list) in self.predicates {
            for index in 0...list.count {
                if (list[index] === item) {
                    items.append(name);
                    break;
                }
            }
        }
        return items
    }

    
    /**
     * Does not copy the id property
     */
    public func duplicate() -> DataItem {
        return DataItem(id:nil, type:self.type, predicates:self.predicates, properties:self.properties)
    }
    
    /**
     * Sets deleted to true
     * All methods and properties must throw when deleted = true;
     */
    public func delete() -> Bool {
        if (deleted) { return false; }
        deleted = true;
        return true;
    }
    
    /**
     *
     */
    public func setProperty(_ name:String, _ value:AnyDecodable) {
        self.properties[name] = value;
    }
    
    /**
     *
     */
    public func removeProperty(_ name:String) {
        self.properties.remove(at: self.properties.index(forKey: name)!)
    }
    
    /**
     *
     */
    public func addPredicate(_ name:String, _ entity:DataItem) {
        let list:[DataItem] = self.predicates[name] ?? []
        self.predicates[name] = list
        self.predicates[name]?.append(entity)
    }
    
    /**
     *
     */
    public func removePredicate(_ name:String, _ entity:DataItem) {
        let index = self.predicates[name]?.firstIndex(of: entity) ?? -1
        if (index > 0) { self.predicates[name]?.remove(at: index) }
    }
    
    enum DataItemError: Error {
        case cannotMergeItemWithDifferentId
    }
    
    /**
     *
     */
    public func merge(_ source:DataItem) throws {
        // Items that do not have the same id should never merge
        if (source.id != "" && self.uid != nil && source.id != self.uid) {
            throw DataItemError.cannotMergeItemWithDifferentId
        }
        
        // Copy properties
        for (name, value) in source.properties {
            self.properties[name] = value
        }
        
        // Copy predicates
        let sourcePredicates = source.predicates
        for (name, list) in self.predicates {
            let sourceList = sourcePredicates[name] ?? []
            outerLoop: for i in 0...list.count {
                for j in 0...sourceList.count {
                    if (list[i] === sourceList[j]) {
                        break outerLoop
                    }
                    self.predicates[name]?.append(sourceList[j])
                }
            }
        }
    }
    
    /**
     *
     */
    public func match(_ query:String) -> Bool{
        let properties: [String:AnyDecodable] = self.properties
        for (name, _) in properties {
            if properties[name]!.value is String {
                let haystack = (properties[name]!.value as! String)

                if haystack.lowercased().range(of: query) != nil {
                    return true
                }
            }
        }
        
        return false
    }
}

public class SearchResult: ObservableObject, Decodable {
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
    /**
     *
     */
    private var cache: Cache? = nil
    
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
        
        cache?.query(self.query, options, { (error, items) -> Void in
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

// Stores data remote
public class RemoteStorage {
    
}

// Stores data locally
public class LocalStorage {
    
}

// Schedules long term tasks like syncing with remote
public class Scheduler {
    
}

// Represents a task such as syncing with remote
public struct Task {
    
}

public class Cache {
    var podAPI: PodAPI
    var queryCache: [String: SearchResult]
    var typeCache: [String: SearchResult]
    var idCache: [String: SearchResult]
    
    public init(_ podAPI: PodAPI, queryCache: [String: SearchResult] = [:], typeCache: [String: SearchResult] = [:],
         idCache: [String: SearchResult] = [:]){
        self.podAPI=podAPI
        self.queryCache = queryCache
        self.typeCache = typeCache
        self.idCache = idCache
    }
    
    /**
     * Loads data from the pod. Returns SearchResult.
     * -> Calls callback twice, once for cache, once for real data [??]
     */
    public func query(_ query:String, _ options:QueryOptions, _ callback: (_ error:Error?, _ result:SearchResult) -> Void) -> Void {
        
    }

    public func findQueryResult(_ query:String, _ options:QueryOptions, _ callback: (_ error:Error?, _ result:SearchResult) -> Void) -> Void {}
    public func queryLocal(_ query:String, _ options:QueryOptions, _ callback: (_ error:Error?, _ result:SearchResult) -> Void) -> Void {}
    public func getById(_ query:String, _ options:QueryOptions, _ callback: (_ error:Error?, _ result:SearchResult) -> Void) -> Void {}
    public func fromJSON(_ file: String, _ ext: String = "json") throws -> [DataItem]{ [DataItem()]}
    
    public func getByType(type: String) -> SearchResult? {
        let cacheValue = self.typeCache[type]
        
        if cacheValue != nil {
            print("using cached result for \(type)")
            return cacheValue!
        } else{
            if type != "note" {
                return nil
            }
            else{
                // TODO refactor this
                let result =  self.podAPI.query("notes", nil) { (error, items) -> Void in
                    self.typeCache[type].data = items
//                    return result
                }
            }
        }
    }
    
    func findCachedResult(query: String) -> SearchResult? {
        return self.queryCache[query]
    }
    
}
