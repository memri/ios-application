import Foundation
import Combine
import RealmSwift

/// DataItem is the baseclass for all of the data clases, all functions
public class DataItem: Object, Codable, Identifiable, ObservableObject {
 
    /// name of the DataItem implementation class (E.g. "note" or "person")
    var genericType:String { "unknown" }
    
    /// Title computed by implementations of the DataItem class
    var computedTitle:String {
        return "\(genericType) [\(uid)]"
    }
    
    /// uid of the DataItem
    @objc dynamic var uid:String = DataItem.generateUUID()
    /// Boolean whether the DataItem has been deleted
    @objc dynamic var deleted:Bool = false
    /// Boolean whether the DataItem has been starred
    @objc dynamic var starred:Bool = false
    /// Creation date of the DataItem
    @objc dynamic var dateCreated:Date? = Date()
    /// Last modification date of the DataItem
    @objc dynamic var dateModified:Date? = Date()
    /// Last access date of the DataItem
    @objc dynamic var dateAccessed:Date? = nil
    /// Array LogItems describing the log history of the DataItem
    let changelog = List<LogItem>()
    /// Labels assigned to / associated with this DataItem
    let labels = List<memri.Label>()
    /// Object descirbing syncing information about this object like loading state, versioning, etc.
    @objc dynamic var syncState:SyncState? = SyncState()
    
 
    var functions:[String: (_ args:[Any]?) -> String] = [:]
    
    /// Primary key used in the realm database of this DataItem
    public override static func primaryKey() -> String? {
        return "uid"
    }
    
    public func cast() -> Self{
        return self
    }
    
    private enum CodingKeys: String, CodingKey {
        case uid, deleted, starred, dateCreated, dateModified, dateAccessed, changelog,
             labels, syncState
    }
        
    enum DataItemError: Error {
        case cannotMergeItemWithDifferentId
    }
    
    required init(){
        super.init()

        self.functions["describeChangelog"] = {_ in
            let dateCreated = GUIElementDescription.formatDate(self.dateCreated)
            let views =  self.changelog.filter{ $0.action == "read" }.count
            let edits = self.changelog.filter{ $0.action == "update" }.count
            let timeSinceCreated = GUIElementDescription.formatDateSinceCreated(self.dateCreated)
            return "You created this \(self.genericType) \(dateCreated) and viewed it \(views) times and edited it \(edits) times over the past \(timeSinceCreated)"
        }
        self.functions["computedTitle"] = {_ in
            return self.computedTitle
        }
    }
    
    /// Deserializes DataItem from json decoder
    /// - Parameter decoder: Decoder object
    /// - Throws: Decoding error
    required public convenience init(from decoder: Decoder) throws{
        self.init()
        try! superDecode(from: decoder)
    }
    
    /// @private
    public func superDecode(from decoder: Decoder) throws {
        uid = try decoder.decodeIfPresent("uid") ?? uid
        starred = try decoder.decodeIfPresent("starred") ?? starred
        deleted = try decoder.decodeIfPresent("deleted") ?? deleted
        syncState = try decoder.decodeIfPresent("syncState") ?? syncState
        
        dateCreated = try decoder.decodeIfPresent("dateCreated") ?? dateCreated
        dateModified = try decoder.decodeIfPresent("dateModified") ?? dateModified
        dateAccessed = try decoder.decodeIfPresent("dateAccessed") ?? dateAccessed
        
        decodeIntoList(decoder, "changelog", self.changelog)
        decodeIntoList(decoder, "labels", self.labels)
    }
    
    
    /// Get string, or string representation (e.g. "true) from property name
    /// - Parameter name: property name
    /// - Returns: string representation
    public func getString(_ name:String) -> String {
        if self.objectSchema[name] == nil {
            
            // TODO how to do this in swift?
            // #IFDEF DEBUG
            print("Warning: getting property that this dataitem doesnt have: \(name) for \(self.genericType):\(self.uid)")
            // #ENDIF
            
            return ""
        }
        else {
            let val = self[name]
            
            if let str = val as? String {
                return str
            }
            else if val is Bool {
                return String(val as! Bool)
            }
            else if val is Int {
                return String(val as! Int)
            }
            else if val is Double {
                return String(val as! Double)
            }
            else if val is Date {
                let formatter = DateFormatter()
                formatter.dateFormat = Settings.get("user/formatting/date") // "HH:mm    dd/MM/yyyy"
                return formatter.string(from: val as! Date)
            }
            else {
                return ""
            }
        }
    }
    
    ///Get the type of DataItem
    /// - Returns: type of the DataItem
    public func getType() -> DataItem.Type{
        let type = DataItemFamily(rawValue: self.genericType)!
        let T = DataItemFamily.getType(type)
        return T() as! DataItem.Type
    }
    
    
    /// Set property to value, which will be persisted in the local database
    /// - Parameters:
    ///   - name: property name
    ///   - value: value
    public func set(_ name:String, _ value:Any) {
        try! self.realm!.write() {
            self[name] = value
        }
    }
    
    /// Toggle boolean property
    /// - Parameter name: property name
    public func toggle(_ name:String) {
        if self[name] as! Bool == false {
            self.set(name, true)
        }
        else {
            self.set(name, false)
        }
    }
    
    
    /// Determines whether item has property
    /// - Parameter propName: name of the property
    /// - Returns: boolean indicating whether DataItem has the property
    public func hasProperty(_ propName:String) -> Bool{
        for prop in self.objectSchema.properties {
            if let haystack = self[prop.name] as? String {
                if haystack.lowercased().contains(propName.lowercased()) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Compares value of this DataItems property with the corresponding property of the passed items property
    /// - Parameters:
    ///   - propName: name of the compared property
    ///   - item: item to compare against
    /// - Returns: boolean indicating whether the property values are the same
    public func isEqualProperty(_ propName:String, _ item:DataItem) -> Bool {
        let prop = self.objectSchema[propName]!

        // List
        if prop.objectClassName != nil {
            return false // TODO implement a list compare and a way to add to updatedFields
        }
        else {
            let value1 = self[propName];
            let value2 = item[propName]
            
            if let item1 = value1 as? String {
                return item1 == value2 as! String
            }
            if let item1 = value1 as? Int {
                return item1 == value2 as! Int
            }
            if let item1 = value1 as? Double {
                return item1 == value2 as! Double
            }
            if let item1 = value1 as? Object {
                return item1 == value2 as! Object
            }
        }
        
        return true
    }
    
    /// Safely merges the passed item with the current DataItem. When there are merge conflicts, meaning that some other process
    /// requested changes for the same properties with different values, merging is not performed.
    /// - Parameter item: item to be merged with the current DataItem
    /// - Returns: boolean indicating the succes of the merge
    public func safeMerge(_ item:DataItem) -> Bool {
        
        // Ignore when marked for deletion
        if self.syncState!.actionNeeded == "delete" { return true }
        
        // Do not update when the version is not higher then what we already have
        if item.syncState!.version <= self.syncState!.version { return true }
        
        // Make sure to not overwrite properties that have been changed
        let updatedFields = self.syncState!.updatedFields
        
        // Compare all updated properties and make sure they are the same
        for fieldName in updatedFields {
            if !isEqualProperty(fieldName, item) { return false }
        }
        
        // Merge with item
        merge(item)
        
        return true
    }
    
    /// merges the the passed DataItem in the current item
    /// - Parameters:
    ///   - item: passed DataItem
    ///   - mergeDefaults: boolean describing how to merge. If mergeDefault == true: Overwrite only the property values have
    ///    not already been set (nil). else: Overwrite all property values with the values from the passed item, with the exception
    ///    that values cannot be set from a non-nil value to nil.
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
            
            // Overwrite only the property values that are not already set
            if mergeDefaults {
                if self[prop.name] == nil {
                    self[prop.name] = item[prop.name]
                }
            }
            // Overwrite all property values with the values from the passed item, with the
            // exception, that values cannot be set ot nil
            else {
                if item[prop.name] != nil {
                    self[prop.name] = item[prop.name]
                }
            }
        }
    }
    
    /// update the dateAccessed property to the current date
    public func access() {
        if let realm = realm, !realm.isInWriteTransaction {
            try! realm.write { self.dateAccessed = Date() }
        }
        else {
            self.dateAccessed = Date()
        }
    }
    
    /// compare two dataItems
    /// - Parameters:
    ///   - lhs: DataItem 1
    ///   - rhs: DataItem 2
    /// - Returns: boolean indicating equality
    public static func == (lhs: DataItem, rhs: DataItem) -> Bool {
        lhs.uid == rhs.uid
    }
    
    /// Generate a new UUID, which are used by swift to identify objects
    /// - Returns: UUID string with "0xNEW" prepended
    public class func generateUUID() -> String {
        let counter = UUID().uuidString
        return "0xNEW\(counter)"
    }
    
    /// Reads DataItems from file
    /// - Parameters:
    ///   - file: filename (without extension)
    ///   - ext: extension
    /// - Throws: Decoding error
    /// - Returns: Array of deserialized DataItems
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> [DataItem] {
        let jsonData = try jsonDataFromFile(file, ext)
        
        let items:[DataItem] = try MemriJSONDecoder.decode(family:DataItemFamily.self, from:jsonData)
        return items
    }
    
    /// Read DataItem from string
    /// - Parameter json: string to parse
    /// - Throws: Decoding error
    /// - Returns: Array of deserialized DataItems
    public class func fromJSONString(_ json: String) throws -> [DataItem] {
        let items:[DataItem] = try MemriJSONDecoder
            .decode(family:DataItemFamily.self, from:Data(json.utf8))
        return items
    }
    
}

/// This class wraps a query and its results, and is responsible for loading a the result and possibly applying clienside filtering
public class ResultSet: ObservableObject {
 
    /// Object describing the query and postprocessing instructions
    var queryOptions: QueryOptions = QueryOptions(query: "")
    /// Resulting DataItems
    var items: [DataItem] = []
    /// Nr of items in the resultset
    var count: Int = 0
    /// Boolean indicating whether the DataItems in the result are currently being loaded
    var isLoading: Bool = false
    
    /// Unused, Experimental
    private var pages: [Int] = []
    private let cache: Cache
    private var _filterText: String = ""
    private var _unfilteredItems: [DataItem]? = nil
 
    /// Computes a string representation of the resultset
    var determinedType: String? {
        // TODO implement (more) proper query language (and parser)
        
        if let query = self.queryOptions.query, query != "" {
            if let typeName = query.split(separator: " ").first {
                return String(typeName == "*" ? "mixed" : typeName)
            }
        }
        return nil
    }

    /// Boolean indicating whether the resultset is a collection of items or a single item
    var isList: Bool {
        // TODO change this to be a proper query parser
        
        let (typeName, filter) = cache.parseQuery((self.queryOptions.query ?? ""))
        
        if let type = DataItemFamily(rawValue: typeName) {
            let primKey = type.getPrimaryKey()
            if (filter ?? "").match("^AND \(primKey) = '.*?'$").count > 0 {
                return false
            }
        }
        
        return true
    }
 
    /// Get the only item from the resultset if the set has size 1, else return nil. Note that
    ///  [singleton](https://en.wikipedia.org/wiki/Singleton_(mathematics)) is here in the mathematical sense.
    var singletonItem: DataItem? {
        get{
            if !isList && count > 0 { return items[0] }
            else { return nil }
        } set (newValue){
            
        }
    }
 
    /// Text used to filter queries
    var filterText: String {
        get {
            return _filterText
        }
        set (newFilter) {
            _filterText = newFilter
            filter()
        }
    }
    
    required init(_ ch:Cache) {
        cache = ch
    }
    
    /// Executes a query given the current QueryOptions, filters the result client side and executes the callback on the resulting
    ///  DataItems
    /// - Parameter callback: Callback with params (error: Error, result: [DataItem]) that is executed on the returned result
    /// - Throws: empty query error
    func load(_ callback:(_ error:Error?) -> Void) throws {
        
        // Only execute one loading process at the time
        if !isLoading {
        
            // Validate queryOptions
            if queryOptions.query == "" {
                throw "Exception: No query specified when loading result set"
            }
            
            // Set state to loading
            isLoading = true
            
            // Make sure the loading state is updated in the UI
            updateUI()
        
            // Execute the query
            cache.query(queryOptions) { (error, result) -> Void in
                if let result = result {
                    
                    // Set data and count
                    items = result
                    count = items.count
                    
                    // Resapply filter
                    if _unfilteredItems != nil {
                        _unfilteredItems = nil
                        filter()
                    }

                    // We've successfully loaded page 0
                    setPagesLoaded(0) // TODO This is not used at the moment

                    // First time loading is done
                    isLoading = false

                    // Done
                    callback(nil)
                }
                else if (error != nil) {
                    // Set loading state to error
                    isLoading = false

                    // Done with errors
                    callback(error)
                }
                
                // Make sure the loading state is updated in the UI
                updateUI()
            }
        }
    }
    
    /// Force update the items property, recompute the counts and reapply filters
    /// - Parameter result: the new items
    func forceItemsUpdate(_ result:[DataItem]) {
        
        // Set data and count
        items = result
        count = items.count

        // Resapply filter
        if _unfilteredItems != nil {
            _unfilteredItems = nil
            filter()
        }
        
        updateUI()
    }
    
    private func updateUI(){
        self.objectWillChange.send() // TODO create our own publishers
    }

    /// Apply client side filter using the FilterText , with a fallback to the server
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
                    if searchSet[i].hasProperty(_filterText) {
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
        
        self.objectWillChange.send() // TODO create our own publishers
    }
        
    /// Executes the query again
    public func reload(_ searchResult:ResultSet) -> Void {
        // Reload all pages
//        for (page, _) in searchResult.pages {
//            let _ = self.loadPage(searchResult, page, { (error) in })
//        }
    }
    
    
    /// - Remark: currently unused
    /// - Todo: Implement
    /// - Parameter options:
    public func resort(_ options:QueryOptions) {
        
    }
    
    /// Mark page with pageIndex as index as loaded
    /// - Parameter pageIndex: index of the page to mark as loaded
    func setPagesLoaded(_ pageIndex:Int) {
        if !pages.contains(pageIndex) {
            pages.append(pageIndex)
        }
    }
}
