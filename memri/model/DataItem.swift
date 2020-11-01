//
// DataItem.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift

/// DataItem is the baseclass for all of the data clases, all functions
public class DataItem: Object, Codable, Identifiable, ObservableObject {
    /// name of the DataItem implementation class (E.g. "note" or "person")
    var genericType: String { "unknown" }

    /// Title computed by implementations of the DataItem class
    @objc dynamic var computedTitle: String {
        "\(genericType) [\(memriID)]"
    }

    var test: String = DataItem.generateUUID()
    /// Boolean whether the DataItem has been deleted

    /// uid of the DataItem set by the pod
    @objc dynamic var uid: Int = 0
    /// memriID of the DataItem
    @objc dynamic var memriID: String = DataItem.generateUUID()
    /// Boolean whether the DataItem has been deleted
    @objc dynamic var deleted: Bool = false
    /// The last version loaded from the server
    @objc dynamic var version: Int = 0
    /// Boolean whether the DataItem has been starred
    @objc dynamic var starred: Bool = false
    /// Creation date of the DataItem
    @objc dynamic var dateCreated: Date? = Date()
    /// Last modification date of the DataItem
    @objc dynamic var dateModified: Date? = Date()
    /// Last access date of the DataItem
    @objc dynamic var dateAccessed: Date? = nil
    /// Array AuditItems describing the log history of the DataItem
    let changelog = List<AuditItem>()
    /// Labels assigned to / associated with this DataItem
    let labels = List<memri.Label>()
    /// Object descirbing syncing information about this object like loading state, versioning, etc.
    @objc dynamic var syncState: SyncState? = SyncState()

    var functions: [String: (_ args: [Any?]?) -> Any] = [:]

    /// Primary key used in the realm database of this DataItem
    override public static func primaryKey() -> String? {
        "memriID"
    }

    public func cast() -> Self {
        self
    }

    private enum CodingKeys: String, CodingKey {
        case uid, memriID, deleted, starred, dateCreated, dateModified, dateAccessed, changelog,
             labels, syncState
    }

    enum DataItemError: Error {
        case cannotMergeItemWithDifferentId
    }

    required init() {
        super.init()

        functions["describeChangelog"] = { _ in
            let dateCreated = Views.formatDate(self.dateCreated)
            let views = self.changelog.filter { $0.action == "read" }.count
            let edits = self.changelog.filter { $0.action == "update" }.count
            let timeSinceCreated = Views.formatDateSinceCreated(self.dateCreated)
            return "You created this \(self.genericType) \(dateCreated) and viewed it \(views) times and edited it \(edits) times over the past \(timeSinceCreated)"
        }
        functions["computedTitle"] = { _ in
            self.computedTitle
        }
    }

    /// Deserializes DataItem from json decoder
    /// - Parameter decoder: Decoder object
    /// - Throws: Decoding error
    public required convenience init(from decoder: Decoder) throws {
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

        decodeIntoList(decoder, "changelog", changelog)
        decodeIntoList(decoder, "labels", labels)
    }

    /// Get string, or string representation (e.g. "true) from property name
    /// - Parameter name: property name
    /// - Returns: string representation
    public func getString(_ name: String) -> String {
        if objectSchema[name] == nil {
            #if DEBUG
                print(
                    "Warning: getting property that this dataitem doesnt have: \(name) for \(genericType):\(memriID)"
                )
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

    /// Get the type of DataItem
    /// - Returns: type of the DataItem
    public func getType() -> DataItem.Type? {
        if let type = DataItemFamily(rawValue: genericType) {
            let T = DataItemFamily.getType(type)
            // NOTE: allowed forced downcast
            return (T() as! DataItem.Type)
        }
        else {
            print("Cannot find type \(genericType) in DataItemFamily")
            return nil
        }
    }

    /// Determines whether item has property
    /// - Parameter propName: name of the property
    /// - Returns: boolean indicating whether DataItem has the property
    public func hasProperty(_ propName: String) -> Bool {
        if propName == "self" {
            return true
        }
        for prop in objectSchema.properties {
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
    public func get<T>(_ name: String, type _: T.Type = T.self) -> T? {
        if name == "self" {
            return self as? T
        }
        return self[name] as? T
    }

    /// Set property to value, which will be persisted in the local database
    /// - Parameters:
    ///   - name: property name
    ///   - value: value
    public func set(_ name: String, _ value: Any?) {
        realmWriteIfAvailable(realm) {
            self[name] = value
        }
    }

    public func addEdge(_ propertyName: String, _ item: DataItem) throws {
        guard let subjectID: String = get("memriID"),
              let objectID: String = item.get("memriID")
        else {
            return
        }

        let edges: [Edge] = get(propertyName) ?? []
        if !edges.map(\.objectMemriID).contains(objectID) {
            let newEdge = Edge(subjectID, objectID, "Label", "Note")
            let newEdges = edges + [newEdge]
            set("appliesTo", newEdges)
        }
        else {
            throw "Could note create Edge, already exists"
        }

        //        // Check that the property exists to avoid hard crash
        //        guard let schema = self.objectSchema[propertyName] else {
        //            throw "Exception: Invalid property access of \(item) for \(self)"
        //        }
        //        guard let objectID: String = item.get("memriID") else {
        //            throw "no memriID"
        //        }
//
        //        if schema.isArray {
        //            // Get list and append
        //            var list = dataItemListToArray(self[propertyName] as Any)
//
        //            if !list.map{$0.memriID}.contains(objectID){
        //                list.append(item)
        //                print(list)
        //                self.set(propertyName, list as Any)
        //            }
        //            else {
        //                print("Could not set edge, already exists")
        //            }
        //        }
        //        else {
        //            self.set(propertyName, item)
        //        }
    }

    /// Toggle boolean property
    /// - Parameter name: property name
    public func toggle(_ name: String) {
        if let val = self[name] as? Bool {
            val ? set(name, false) : set(name, true)
        }
        else {
            print("tried to toggle property \(name), but \(name) is not a boolean")
        }
    }

    /// Compares value of this DataItems property with the corresponding property of the passed items property
    /// - Parameters:
    ///   - propName: name of the compared property
    ///   - item: item to compare against
    /// - Returns: boolean indicating whether the property values are the same
    public func isEqualProperty(_ propName: String, _ item: DataItem) -> Bool {
        if let prop = objectSchema[propName] {
            // List
            if prop.objectClassName != nil {
                return false // TODO: implement a list compare and a way to add to updatedFields
            }
            else {
                let value1 = self[propName]
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
        else {
            // TODO: Error handling
            print("Tried to compare property \(propName), but \(self) does not have that property")
            return false
        }
    }

    /// Safely merges the passed item with the current DataItem. When there are merge conflicts, meaning that some other process
    /// requested changes for the same properties with different values, merging is not performed.
    /// - Parameter item: item to be merged with the current DataItem
    /// - Returns: boolean indicating the succes of the merge
    public func safeMerge(_ item: DataItem) -> Bool {
        if let syncState = self.syncState {
            // Ignore when marked for deletion
            if syncState.actionNeeded == "delete" { return true }

            // Do not update when the version is not higher then what we already have
            if item.version <= version { return true }

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

    /// merges the the passed DataItem in the current item
    /// - Parameters:
    ///   - item: passed DataItem
    ///   - mergeDefaults: boolean describing how to merge. If mergeDefault == true: Overwrite only the property values have
    ///    not already been set (nil). else: Overwrite all property values with the values from the passed item, with the exception
    ///    that values cannot be set from a non-nil value to nil.
    public func merge(_ item: DataItem, _ mergeDefaults: Bool = false) {
        // Store these changes in realm
        if let realm = self.realm {
            do {
                try realm.write { doMerge(item, mergeDefaults) }
            }
            catch {
                print("Could not write merge of \(item) and \(self) to realm")
            }
        }
        else {
            doMerge(item, mergeDefaults)
        }
    }

    private func doMerge(_ item: DataItem, _ mergeDefaults: Bool = false) {
        let properties = objectSchema.properties
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
    ///   - lhs: DataItem 1
    ///   - rhs: DataItem 2
    /// - Returns: boolean indicating equality
    public static func == (lhs: DataItem, rhs: DataItem) -> Bool {
        lhs.memriID == rhs.memriID
    }

    /// Generate a new UUID, which are used by swift to identify objects
    /// - Returns: UUID string with "0xNEW" prepended
    public class func generateUUID() -> String {
        "Memri\(UUID().uuidString)"
    }

    /// Reads DataItems from file
    /// - Parameters:
    ///   - file: filename (without extension)
    ///   - ext: extension
    /// - Throws: Decoding error
    /// - Returns: Array of deserialized DataItems
    public class func fromJSONFile(_ file: String, ext: String = "json") throws -> [DataItem] {
        let jsonData = try jsonDataFromFile(file, ext)

        let items: [DataItem] = try MemriJSONDecoder
            .decode(family: DataItemFamily.self, from: jsonData)
        return items
    }

    /// Sets syncState .actionNeeded property
    /// - Parameters:
    ///   - action: action name
    public func setSyncStateActionNeeded(_ action: String) {
        if let syncState = self.syncState {
            syncState.actionNeeded = action
        }
        else {
            print("No syncState available for item \(self)")
        }
    }

    /// Read DataItem from string
    /// - Parameter json: string to parse
    /// - Throws: Decoding error
    /// - Returns: Array of deserialized DataItems
    public class func fromJSONString(_ json: String) throws -> [DataItem] {
        let items: [DataItem] = try MemriJSONDecoder
            .decode(family: DataItemFamily.self, from: Data(json.utf8))
        return items
    }
}

class Edge: Object {
    @objc dynamic var objectMemriID: String = DataItem.generateUUID()
    @objc dynamic var subjectMemriID: String = DataItem.generateUUID()

    @objc dynamic var objectType: String = "unknown"
    @objc dynamic var subjectType: String = "unknown"

    required init() {}

    init(
        _ subjectMemriID: String = DataItem.generateUUID(),
        _ objectMemriID: String = DataItem.generateUUID(),
        _ subjectType: String = "unknown",
        _ objectType: String = "unknown"
    ) {
        self.objectMemriID = objectMemriID
        self.subjectMemriID = subjectMemriID
        self.objectType = objectType
        self.subjectType = subjectType
    }

    // maybe we dont need this
    //    @objc dynamic var objectType:String = DataItem.generateUUID()
    //    @objc dynamic var subectType:String = DataItem.generateUUID()

    /// Deserializes DataItem from json decoder
    /// - Parameter decoder: Decoder object
    /// - Throws: Decoding error
    //    required public convenience init(from decoder: Decoder) throws{
    //        self.init()
    //        objectUid = try decoder.decodeIfPresent("objectUid") ?? objectUid
    //        subjectUid = try decoder.decodeIfPresent("subjectUid") ?? subjectUid
    //    }
}
