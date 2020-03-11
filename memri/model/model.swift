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
    
    public convenience init(id:String? = nil, type: String, predicates: [String: [DataItem]]? = [:],
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
    public func findPredicateByType(_ type:String) -> [DataItem] {
        return self.predicates[type]!
    }
    
    /**
     *
     */
    public func findPredicateByTarget(_ item:DataItem) -> [String] {
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
    public func addPredicate(_ name:String, _ item:DataItem) {
        let list:[DataItem] = self.predicates[name] ?? []
        self.predicates[name] = list
        self.predicates[name]?.append(item)
    }
    
    /**
     *
     */
    public func removePredicate(_ name:String, _ item:DataItem) {
        let index = self.predicates[name]?.firstIndex(of: item) ?? -1
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
     *  0 loading complete
     *  1 loading data from server
     */
    public var loading: Int = 0
    /**
     * Retrieves the number of items per page
     */
    public var pageCount: Int = 0
    
    /**
     * Sets the constants above
     */
//    public convenience required init(_ options:QueryOptions) {
//
//    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        query = try decoder.decodeIfPresent("query") ?? query
        data = try decoder.decodeIfPresent("data") ?? data
        sortProperty = try decoder.decodeIfPresent("sortProperty") ?? sortProperty
        sortAscending = try decoder.decodeIfPresent("sortAscending") ?? sortAscending
        loading = try decoder.decodeIfPresent("loading") ?? loading
        pageCount = try decoder.decodeIfPresent("pageCount") ?? pageCount
    }
    
    private func connect() -> Bool {
        if (loading > 0 || query == "") { return false }
        podApi.query(
    }
    
    /**
     * Client side filter, with a fallback to the server
     */
    public func filter(_ query:String) {
        
    }
    /**
     * Executes the query again
     */
    public func reload() {
        
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
    
    public func findQueryResult(_ query:String, _ options:QueryOptions, _ callback: (_ error:Error, _ result:SearchResult) -> Void) -> Void {}
    public func queryLocal(_ query:String, _ options:QueryOptions, _ callback: (_ error:Error, _ result:SearchResult) -> Void) -> Void {}
    public func getById(_ query:String, _ options:QueryOptions, _ callback: (_ error:Error, _ result:SearchResult) -> Void) -> Void {}
    public func fromJSON(_ file: String, _ ext: String = "json") throws -> [DataItem]{ [DataItem()]}
    
    public func getByType(type: String) -> SearchResult? {
        let cacheValue = self.typeCache[type]
        
        if cacheValue != nil {
            print("using cached result for \(type)")
            return cacheValue!
        } else{
            if type != "note" {
                return nil
            }else{
                let result =  self.podAPI.query("notes")
                self.typeCache[type] = result
                return result
            }
        }
    }
    
    func findCachedResult(query: String) -> SearchResult? {
        return self.queryCache[query]
    }
    
}
