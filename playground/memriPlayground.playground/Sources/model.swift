import Foundation

public class DataItem: Codable {
    public var uid: String
    public var type: String
    public var predicates: [String: String]
    public var properties: [String: String]
    
    
    public init(_ uid: String){
        self.uid = uid
        self.type = "note"
        self.predicates = ["owner": "0x0"]
        self.properties = ["title": "example note",
                           "content": "This is an example note"]
    }
    func findProperty(name: String) -> String {
        return self.properties[name]!
    }
    
    public class func from_json(file: String, ext: String = "json") throws -> [DataItem] {
        let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
        let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
        let jsonData = jsonString.data(using: .utf8)!
        let items: [DataItem] = try! JSONDecoder().decode([DataItem].self, from: jsonData)
        return items
    }
    
    //TODO: findRelationShipByType, findRelationshipByTarget, .onUpdate, .duplicate(), .delete()
    
}


public class SearchResult: Codable {
    var query: String
    public var data: [DataItem]?
    
    public var sortProperty: String?
    public var sortAscending: Int
    public var loading: Int
    public var pageCount: Int
    
    public init(query: String, data: [DataItem]? = nil, sortProperty: String? = nil, sortAscending: Int = -1, loading: Int=0,
         pageCount: Int=0){
        self.query=query
        self.data=data
        self.sortProperty=sortProperty
        self.sortAscending=sortAscending
        self.loading=loading
        self.pageCount=pageCount
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
    
    public func findCachedResult(query: String) -> SearchResult? {
        return self.queryCache[query]
    }
    
//    func queryLocal(query: String) -> [SearchResult]?{}
//    this will be a more complex function
    
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
    
}
