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
    
    /**
     * @private
     */
    public func superDecode(from decoder: Decoder) throws {
        uid = try decoder.decodeIfPresent("uid") ?? uid
        starred = try decoder.decodeIfPresent("starred") ?? starred
        deleted = try decoder.decodeIfPresent("deleted") ?? deleted
        syncState = try decoder.decodeIfPresent("syncState") ?? syncState
        
        decodeIntoList(decoder, "changelog", self.changelog)
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
    
    private func isEqualProperty(_ fieldName:String, _ item:DataItem) -> Bool {
        for prop in self.objectSchema.properties { // Seems inefficient
            if prop.name == fieldName {
                // Optional
//                if prop.isOptional {
//                    return self[fieldName] == item[fieldName]
//                }
                // List
//                else
                if prop.objectClassName != nil {
                    return false // TODO implement a list compare and a way to add to updatedFields
                }
                else {
                    if prop.isOptional {
                        1+1
                    }
                    
                    let item1 = self[fieldName];
                    let item2 = item[fieldName]
                    
                    if let item1 = item1 as? String {
                        return item1 == item2 as! String
                    }
                    if let item1 = item1 as? Int {
                        return item1 == item2 as! Int
                    }
                    if let item1 = item1 as? Double {
                        return item1 == item2 as! Double
                    }
                    if let item1 = item1 as? Object {
                        return item1 == item2 as! Object
                    }
                }
                break
            }
        }
        
        return true
    }
    
    public func safeMerge(_ item:DataItem) -> Bool {
        
        // Ignore when marked for deletion
        if self.syncState!.actionNeeded == "delete" { return true }
        
        // Do not update when the version is not higher then what we already have
        if item.syncState!.version <= self.syncState!.version { return true }
        
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
    
    public func merge(_ item:DataItem, _ mergeDefaults:Bool=false) {
        // Store these changes in realm
        if let realm = self.realm {
            try! realm.write { doMerge(item, mergeDefaults) }
        }
        else {
            doMerge(item, mergeDefaults)
        }
    }
    
    private func doMerge(_ item:DataItem, _ mergeDefaults:Bool=false) {
        let properties = self.objectSchema.properties
        for prop in properties {
            
            // Exclude SyncState
            if prop.name == "SyncState" {
                continue
            }
            
            // Perhaps not needed:
            // - TODO needs to detect lists which will always be set
            // - TODO needs to detect optionals which will always be set
            
            // Merge only the ones that self doesnt already have
            if mergeDefaults {
                if self[prop.name] != nil {
                    self[prop.name] = item[prop.name]
                }
            }
            // Merge all that item doesnt already have
            else {
                if item[prop.name] != nil {
                    self[prop.name] = item[prop.name]
                }
            }
        }
    }
    
    public static func == (lhs: DataItem, rhs: DataItem) -> Bool {
        lhs.uid == rhs.uid
    }
    
    public class func generateUID() -> String {
        let counter = UUID().uuidString
        return "0xNEW\(counter)"
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
        if !isList && count > 0 { return items[0] }
        else { return nil }
    }
    /**
     *
     */
    var filterText: String {
        get {
            return _filterText
        }
        set (newFilter) {
            _filterText = newFilter
            filter()
        }
    }
    
    private var loading: Bool = false
    private var pages: [Int] = []
    private let cache: Cache
    private var _filterText: String = ""
    private var _unfilteredItems: [DataItem]? = nil
    
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
    public func filter() {
        // Cancel filtering
        if _filterText == "" {
            
            // If we filtered before...
            if let _unfilteredItems = _unfilteredItems{
                
                // Put back the items of this resultset
                items = _unfilteredItems
                count = _unfilteredItems.count
            }
        }
            
        // Filter using _filterText
        else {
            // Array to store filter results
            var filterResult:[DataItem] = []
            
            // Filter through items
            let searchSet = _unfilteredItems ?? items
            if searchSet.count >  0 {
                for i in 0...searchSet.count - 1 {
                    if searchSet[i].match(_filterText) {
                        filterResult.append(searchSet[i])
                    }
                }
            }
            
            // Store the items of this resultset
            if _unfilteredItems == nil { _unfilteredItems = items }
            
            // Set the filtered result
            items = filterResult
            count = filterResult.count
        }
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
