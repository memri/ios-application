import Foundation

public class DataItem: Decodable, Equatable, Identifiable, ObservableObject {
    public var uid: String = ""
    public var type: String = ""
    
    @Published public var predicates: [String: [DataItem]] = [:]
    @Published public var properties: [String: AnyDecodable] = [:]
    @Published private var deleted: Bool = false;
    
    public var isDeleted:Bool {
        return deleted;
    }
    
    public var id: String {
        return self.uid
    }
    
    public convenience init(uid:String? = nil, type: String, predicates: [String: [DataItem]]? = [:],
                            properties:[String: AnyDecodable]? = [:]){
        self.init()
        self.uid = uid ?? self.uid
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
    
    public static func fromUid(uid:String)-> DataItem{
        var di = DataItem()
        di.uid = uid
        return di
    }
    
    public static func == (lhs: DataItem, rhs: DataItem) -> Bool {
        lhs.uid == rhs.uid
    }
    
    public class func from_json(file: String, ext: String = "json") throws -> [DataItem] {
        var data = try jsonDataFromFile(file, ext)
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
        return DataItem(uid:nil, type:self.type, predicates:self.predicates, properties:self.properties)
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
        var list:[DataItem] = self.predicates[name] ?? nil
        if (list != nil) { self.predicates[name] = []; list = self.predicates[name]!}
        list.append(item)
    }
    
    /**
     *
     */
    public func removePredicate(_ name:String, _ item:DataItem) {
        let index = self.predicates[name]?.firstIndex(of: item) ?? -1
        if (index > 0) { self.predicates[name]?.remove(at: index) }
    }
    
    /**
     *
     */
    public func merge(_ item:DataItem) {
        
    }
}


public class SearchResult: ObservableObject, Decodable {
    var query: String=""
    @Published public var data: [DataItem] = []
    
    public var sortProperty: String?=""
    public var sortAscending: Int=0
    public var loading: Int=0
    public var pageCount: Int=0
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        query = try decoder.decodeIfPresent("query") ?? query
        data = try decoder.decodeIfPresent("data") ?? data
        sortProperty = try decoder.decodeIfPresent("sortProperty") ?? sortProperty
        sortAscending = try decoder.decodeIfPresent("sortAscending") ?? sortAscending
        loading = try decoder.decodeIfPresent("loading") ?? loading
        pageCount = try decoder.decodeIfPresent("pageCount") ?? pageCount
    }
    
    public static func fromDataItems(_ data: [DataItem]) -> SearchResult {
        let obj = SearchResult()
        obj.data=data
        return obj
    }
    
    func fire(event: String) -> Void{}
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
