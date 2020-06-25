import Foundation
import Combine
import RealmSwift

public class Item : SchemaItem {
    
    /// Title computed by implementations of the Item class
    @objc dynamic var computedTitle:String {
        return "\(genericType) [\(memriID)]"
    }
    
    var functions:[String: (_ args:[Any?]?) -> Any] = [:]
    
    /// Primary key used in the realm database of this Item
    public override static func primaryKey() -> String? {
        return "memriID"
    }
    
    private enum CodingKeys: String, CodingKey {
        case uid, memriID, deleted, starred, dateCreated, dateModified, dateAccessed, changelog,
             labels, syncState
    }
        
    enum ItemError: Error {
        case cannotMergeItemWithDifferentId
    }
    
    required init(){
        super.init()

        self.functions["describeChangelog"] = {_ in
            let dateCreated = Views.formatDate(self.dateCreated)
            let views =  self.changelog.filter{ $0.action == "read" }.count
            let edits = self.changelog.filter{ $0.action == "update" }.count
            let timeSinceCreated = Views.formatDateSinceCreated(self.dateCreated)
            return "You created this \(self.genericType) \(dateCreated) and viewed it \(views) times and edited it \(edits) times over the past \(timeSinceCreated)"
        }
        self.functions["computedTitle"] = {_ in
            return self.computedTitle
        }
    }
    
    /// Deserializes Item from json decoder
    /// - Parameter decoder: Decoder object
    /// - Throws: Decoding error
    required public convenience init(from decoder: Decoder) throws{
        self.init()
        try superDecode(from: decoder)
    }
    
    /// @private
    public func superDecode(from decoder: Decoder) throws {
        uid = try decoder.decodeIfPresent("uid") ?? uid
        memriID = try decoder.decodeIfPresent("memriID") ?? memriID
        starred = try decoder.decodeIfPresent("starred") ?? starred
        deleted = try decoder.decodeIfPresent("deleted") ?? deleted
        version = try decoder.decodeIfPresent("version") ?? version
        syncState = try decoder.decodeIfPresent("syncState") ?? syncState
        
        dateCreated = try decoder.decodeIfPresent("dateCreated") ?? dateCreated
        dateModified = try decoder.decodeIfPresent("dateModified") ?? dateModified
        dateAccessed = try decoder.decodeIfPresent("dateAccessed") ?? dateAccessed
        
        decodeIntoList(decoder, "changelog", self.changelog)
        decodeIntoList(decoder, "labels", self.labels)
    }
    
    public func cast() -> Self {
        return self
    }
    
    /// Get string, or string representation (e.g. "true) from property name
    /// - Parameter name: property name
    /// - Returns: string representation
    public func getString(_ name:String) -> String {
        if self.objectSchema[name] == nil {
            
            #if DEBUG
            print("Warning: getting property that this dataitem doesnt have: \(name) for \(self.genericType):\(self.memriID)")
            #endif
            
            return ""
        }
        else {
            let val = self[name]
            
            if let str = val as? String {
                return str
            }
            else if let val = val as? Bool {
                return String(val)
            }
            else if let val = val as? Int {
                return String(val)
            }
            else if let val = val as? Double {
                return String(val)
            }
            else if let val = val as? Date {
                let formatter = DateFormatter()
                formatter.dateFormat = Settings.get("user/formatting/date") // "HH:mm    dd/MM/yyyy"
                return formatter.string(from: val)
            }
            else {
                return ""
            }
        }
    }
    
    ///Get the type of Item
    /// - Returns: type of the Item
    public func getType() -> Item.Type? {
        if let type = ItemFamily(rawValue: self.genericType){
            let T = ItemFamily.getType(type)
            // NOTE: allowed forced downcast
            return (T() as! Item.Type)
        }
        else {
            print("Cannot find type \(self.genericType) in ItemFamily")
            return nil
        }
    }
    
    /// Determines whether item has property
    /// - Parameter propName: name of the property
    /// - Returns: boolean indicating whether Item has the property
    public func hasProperty(_ propName: String) -> Bool {
        if propName == "self" {
            return true
        }
        for prop in self.objectSchema.properties {
            if prop.name == propName { return true }
            if let haystack = self[prop.name] as? String {
                if haystack.lowercased().contains(propName.lowercased()) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Get property value
    /// - Parameters:
    ///   - name: property name
    public func get<T>(_ name: String, type: T.Type = T.self) -> T? {
        if name == "self" {
            return self as? T
        }
        return self[name] as? T
    }
    
    /// Set property to value, which will be persisted in the local database
    /// - Parameters:
    ///   - name: property name
    ///   - value: value
    public func set(_ name:String, _ value:Any?) {
        realmWriteIfAvailable(realm, {
            self[name] = value
        })
    }
    
    /// Toggle boolean property
    /// - Parameter name: property name
    public func toggle(_ name:String) {
        if let val = self[name] as? Bool{
            val ? self.set(name, false) : self.set(name, true)
        }
        else{
            print("tried to toggle property \(name), but \(name) is not a boolean")
        }

    }
    
    /// Compares value of this Items property with the corresponding property of the passed items property
    /// - Parameters:
    ///   - propName: name of the compared property
    ///   - item: item to compare against
    /// - Returns: boolean indicating whether the property values are the same
    public func isEqualProperty(_ propName:String, _ item:Item) -> Bool {
        if let prop = self.objectSchema[propName]{
            // List
            if prop.objectClassName != nil {
                return false // TODO implement a list compare and a way to add to updatedFields
            }
            else {
                let value1 = self[propName];
                let value2 = item[propName]
                
                if let item1 = value1 as? String, let value2 = value2 as? String {
                    return item1 == value2
                }
                if let item1 = value1 as? Int, let value2 = value2 as? Int {
                    return item1 == value2
                }
                if let item1 = value1 as? Double, let value2 = value2 as? Double {
                    return item1 == value2
                }
                if let item1 = value1 as? Object, let value2 = value2 as? Object {
                    return item1 == value2
                }
                else {
                    // TODO: Error handling
                    print("Trying to compare property \(propName) of item \(item) and \(self) " +
                          "but types do not mach")
                }
            }
            
            return true
        }
        else{
            // TODO: Error handling
            print("Tried to compare property \(propName), but \(self) does not have that property")
            return false
        }
    }
    
    /// Safely merges the passed item with the current Item. When there are merge conflicts, meaning that some other process
    /// requested changes for the same properties with different values, merging is not performed.
    /// - Parameter item: item to be merged with the current Item
    /// - Returns: boolean indicating the succes of the merge
    public func safeMerge(_ item:Item) -> Bool {
        if let syncState = self.syncState{
            // Ignore when marked for deletion
            if syncState.actionNeeded == "delete" { return true }
            
            // Do not update when the version is not higher then what we already have
            if item.version <= self.version { return true }
            
            // Make sure to not overwrite properties that have been changed
            let updatedFields = syncState.updatedFields
            
            // Compare all updated properties and make sure they are the same
            for fieldName in updatedFields {
                if !isEqualProperty(fieldName, item) { return false }
            }
            
            // Merge with item
            merge(item)
            
            return true
        }
        else {
            // TODO: Error handling
            print("trying to merge, but syncState is nil")
            return false
        }
    }
    
    /// merges the the passed Item in the current item
    /// - Parameters:
    ///   - item: passed Item
    ///   - mergeDefaults: boolean describing how to merge. If mergeDefault == true: Overwrite only the property values have
    ///    not already been set (nil). else: Overwrite all property values with the values from the passed item, with the exception
    ///    that values cannot be set from a non-nil value to nil.
    public func merge(_ item:Item, _ mergeDefaults:Bool=false) {
        // Store these changes in realm
        if let realm = self.realm {
            do {
                try realm.write { doMerge(item, mergeDefaults) }
            }
            catch{
                print("Could not write merge of \(item) and \(self) to realm")
            }
        }
        else {
            doMerge(item, mergeDefaults)
        }
    }
    
    private func doMerge(_ item:Item, _ mergeDefaults:Bool=false) {
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
        realmWriteIfAvailable(realm) {
            self.dateAccessed = Date()
        }
    }
    
    /// compare two dataItems
    /// - Parameters:
    ///   - lhs: Item 1
    ///   - rhs: Item 2
    /// - Returns: boolean indicating equality
    public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.memriID == rhs.memriID
    }
    
    /// Generate a new UUID, which are used by swift to identify objects
    /// - Returns: UUID string with "0xNEW" prepended
    public class func generateUUID() -> String {
        return "Memri\(UUID().uuidString)"
    }
    
    /// Reads Items from file
    /// - Parameters:
    ///   - file: filename (without extension)
    ///   - ext: extension
    /// - Throws: Decoding error
    /// - Returns: Array of deserialized Items
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> [Item] {
        let jsonData = try jsonDataFromFile(file, ext)
        
        let items:[Item] = try MemriJSONDecoder.decode(family:ItemFamily.self, from:jsonData)
        return items
    }
    
    /// Sets syncState .actionNeeded property
    /// - Parameters:
    ///   - action: action name
    public func setSyncStateActionNeeded(_ action: String){
        if let syncState = self.syncState {
            syncState.actionNeeded = action
        }
        else{
            print("No syncState available for item \(self)")
        }
    }
    
    /// Read Item from string
    /// - Parameter json: string to parse
    /// - Throws: Decoding error
    /// - Returns: Array of deserialized Items
    public class func fromJSONString(_ json: String) throws -> [Item] {
        let items:[Item] = try MemriJSONDecoder
            .decode(family:ItemFamily.self, from:Data(json.utf8))
        return items
    }
    
}

class Relationship: Object {
    @objc dynamic var objectMemriID:String = Item.generateUUID()
    @objc dynamic var subjectMemriID:String = Item.generateUUID()
    
    @objc dynamic var objectType:String = "unknown"
    @objc dynamic var subjectType:String = "unknown"
    
    required init() {}
    
    init(_ subjectMemriID: String = Item.generateUUID(),
         _ objectMemriID: String = Item.generateUUID(),
         _ subjectType: String = "unknown", _ objectType: String = "unknown") {
        self.objectMemriID = objectMemriID
        self.subjectMemriID = subjectMemriID
        self.objectType = objectType
        self.subjectType = subjectType
    }
    
    // maybe we dont need this
//    @objc dynamic var objectType:String = Item.generateUUID()
//    @objc dynamic var subectType:String = Item.generateUUID()
    
    /// Deserializes Item from json decoder
    /// - Parameter decoder: Decoder object
    /// - Throws: Decoding error
//    required public convenience init(from decoder: Decoder) throws{
//        self.init()
//        objectUid = try decoder.decodeIfPresent("objectUid") ?? objectUid
//        subjectUid = try decoder.decodeIfPresent("subjectUid") ?? subjectUid
//    }
}

