import Foundation

public class SearchResult {
    var query: String
    public var data: [DataItem]?
    
    var sortProperty: String?
    var sortAscending: Int
    var loading: Int
    var pageCount: Int
    
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
