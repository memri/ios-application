import Foundation

public class DataItem: Decodable, Equatable, Identifiable, ObservableObject {
    
    public var uid: String = ""
    public var type: String = ""
    @Published public var predicates: [String: String] = [:]
    @Published public var properties: [String: String] = [:]
    
    public var id: String {
        return self.uid
    }
    
    public convenience init(uid:String? = nil, type: String? = nil, predicates: [String: String]? = nil,
                            properties:[String:String]? = nil){
        self.init()
        self.uid=uid ?? self.uid
        self.type=type ?? self.type
        self.predicates=predicates ?? self.predicates
        self.properties=properties ?? self.properties
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        self.uid = try decoder.decodeIfPresent("uid") ?? self.uid
        self.type = try decoder.decodeIfPresent("type") ?? self.type
        self.predicates = try decoder.decodeIfPresent("predicates") ?? self.predicates
        self.properties = try decoder.decodeIfPresent("properties") ?? self.properties
    }
    
    public static func fromUid(uid:String)-> DataItem{
        var di = DataItem()
        di.uid=uid
        return di
    }
    
    public static func == (lhs: DataItem, rhs: DataItem) -> Bool {
        lhs.uid == rhs.uid
    }
    
    func findProperty(name: String) -> String {
        return self.properties[name]!
    }
    
    public class func from_json(file: String, ext: String = "json") throws -> [DataItem] {
        var data = try jsonDataFromFile(file, ext)
        let items: [DataItem] = try! JSONDecoder().decode([DataItem].self, from: data)
        return items
    }
    
    //TODO: findRelationShipByType, findRelationshipByTarget, .onUpdate, .duplicate(), .delete()
    
}

extension DataItem{

}


public class SearchResult: ObservableObject, Decodable {
    var query: String=""
    @Published public var data: [DataItem] = []
    
    public var sortProperty: String?=""
    public var sortAscending: Int=0
    public var loading: Int=0
    public var pageCount: Int=0
    
    
    
//    public init(query: String, data: [DataItem] = [], sortProperty: String? = nil, sortAscending: Int = -1, loading: Int=0,
//         pageCount: Int=0){
//        self.query=query
//        self.data=data
//        self.sortProperty=sortProperty
//        self.sortAscending=sortAscending
//        self.loading=loading
//        self.pageCount=pageCount
//    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
//        try decodeFromTuples(decoder,
//                             [(searchResult, "searchResult"),(title, "title"),(test2, "test2")] as [(Any, String)])
    }
    
    public static func fromDataItems(_ data: [DataItem]) -> SearchResult{
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
