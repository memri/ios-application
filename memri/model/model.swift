import Foundation
import Combine

protocol PropertyReflectable { }

extension PropertyReflectable {
    subscript(key: String) -> Any? {
        let m = Mirror(reflecting: self)
        for child in m.children {
            if child.label == key { return child.value }
        }
        return nil
    }
}

public class DataItem: Codable, Equatable, Identifiable, ObservableObject, PropertyReflectable {
    private var uuid:String = UUID().uuidString
    public var uid:String? = nil // 0x" + UUID().uuidString
    public var type:String = ""
    
    @Published public var predicates:[String: [DataItem]] = [:]
    @Published public var properties:[String: AnyCodable] = [:]
    @Published private var deleted: Bool = false;
    
    public var isDeleted:Bool {
        return deleted;
    }
    
    public var id: String {
        return self.uid ?? self.uuid
    }
    
    enum DataItemError: Error {
        case cannotMergeItemWithDifferentId
    }
    
    public convenience required init(id:String=UUID().uuidString, type:String) {
        self.init()
        self.uid = id
        self.type = type
    }
    
    public convenience required init(id:String? = nil, type: String, predicates: [String: [DataItem]]? = [:],
                            properties:[String: AnyCodable]? = [:]){
        self.init()
        self.uid = id ?? self.uid
        self.type = type
        self.predicates = predicates ?? self.predicates
        self.properties = properties ?? self.properties
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            uid = try decoder.decodeIfPresent("uid") ?? uid
            type = try decoder.decodeIfPresent("type") ?? type
            predicates = try decoder.decodeIfPresent("predicates") ?? predicates
            properties = try decoder.decodeIfPresent("properties") ?? properties
        }
    }
    
    public static func fromUid(uid:String)-> DataItem {
        let di = DataItem()
        di.uid = uid
        return di
    }
    
    public static func == (lhs: DataItem, rhs: DataItem) -> Bool {
        lhs.uid == rhs.uid
    }
    
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> [DataItem] {
        let jsonData = try jsonDataFromFile(file, ext)
        let items: [DataItem] = try JSONDecoder().decode([DataItem].self, from: jsonData)
        return items
    }
    
    public class func fromJSONString(_ json: String) throws -> [DataItem] {
        let items: [DataItem] = try JSONDecoder().decode([DataItem].self, from: Data(json.utf8))
        return items
    }
    
    /**
     *
     */
    public func findProperty(name: String) -> AnyCodable {
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
    public func setProperty(_ name:String, _ value:AnyCodable) {
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
    
    /**
     *
     */
    public func merge(_ source:DataItem) throws {
        // Items that do not have the same id should never merge
        if (source.uid != nil && self.uid != nil && source.uid != self.uid) {
            throw DataItemError.cannotMergeItemWithDifferentId
        }
        
        if self.type == "" { self.type = source.type }
        
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
        let properties: [String:AnyCodable] = self.properties
        for (name, _) in properties {
            if properties[name]!.value is String {
                let haystack = (properties[name]!.value as! String)

                if haystack.lowercased().range(of: query.lowercased()) != nil {
                    return true
                }
            }
        }
        
        return false
    }
}

public class SearchResult: ObservableObject, Codable {
    /**
     *
     */
    public var query: QueryOptions = QueryOptions(query: "")
    /**
     * Retrieves the data loaded from the pod
     */
    @Published public var data: [DataItem] = []
    /**
     *
     */
    public var pages: [Int:Bool] = [:]
    /**
     * Returns the loading state
     *  -2 loading data failed
     *  -1 data is loaded from the server
     *  0 loading idle
     *  1 loading data from server
     */
    public var loading: Int = 0
    
    public convenience required init(_ query: QueryOptions? = nil, _ data:[DataItem]?) {
        self.init()
        
        self.query = query ?? self.query
        self.data = data ?? []
        
        if (data != nil) {
            loading = -1
            pages[query?.pageIndex ?? 0] = true
        }
    }
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            data = try decoder.decodeIfPresent("data") ?? data
            query = try decoder.decodeIfPresent("query") ?? query
            loading = try decoder.decodeIfPresent("loading") ?? loading
            pages = try decoder.decodeIfPresent("pageCount") ?? pages

            // If the searchResult is initiatlized with data we set the state to loading done
            if (!(data.isEmpty && loading == 0)) {
                loading = -1
            }
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
