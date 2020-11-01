//
// Cache.swift
// Copyright © 2020 memri. All rights reserved.

import AnyCodable
import Combine
import Foundation
import RealmSwift

public class Cache {
    /// PodAPI object
    var podAPI: PodAPI
    /// Object that schedules with the POD
    var sync: Sync

    private var rlmTokens: [NotificationToken] = []
    private var cancellables: [AnyCancellable] = []
    private var queryIndex: [String: ResultSet] = [:]

    // TODO: document
    public var scheduleUIUpdate: ((((_ context: MemriContext) -> Bool)?) -> Void)?

    /// Starts the local realm database, which is created if it does not exist, sets the api and initializes the sync from them.
    /// - Parameter api: api object
    public init(_ api: PodAPI) throws {
        podAPI = api

        // Create scheduler objects
        sync = Sync(podAPI)
        sync.cache = self
    }

    /// gets default item from database, and adds them to realm
    public func install(_ dbName: String, _ callback: @escaping (Error?) -> Void) throws {
        DatabaseController.asyncOnBackgroundThread(write: true, error: callback) { realm in
            try self._install(realm, dbName)
            callback(nil)
        }
    }

    private func _install(_ realm: Realm, _ dbName: String) throws {
        // Load default database from disk
        do {
            let jsonData = try jsonDataFromFile(dbName)
            let dicts: [AnyCodable] = try MemriJSONDecoder.decode([AnyCodable].self, from: jsonData)
            var items = [Item: [[String: Any]]]()
            var lut = [Int: Int]()

            func recur(_ dict: [String: Any]) throws -> Item? {
                var values = [String: Any?]()

                guard let type = dict["_type"] as? String,
                      let itemType = ItemFamily(rawValue: type)?.getType() as? Item.Type
                else {
                    print(
                        "DEMO DATABASE ERROR: Type does not exist: \(dict["_type"] ?? "No type")"
                    )
                    return nil
                }

                for (key, value) in dict {
                    if key == "uid" {
                        if let uid = value as? Int {
                            lut[uid] = try Cache.incrementUID()
                            values["uid"] = lut[uid]
                        }
                        else if dict["uid"] == nil { values["uid"] = try Cache.incrementUID() }
                    }
                    else if key != "allEdges", key != "_type" {
                        // Special case for installing default settings
                        if type == "Setting", key == "value" {
                            values["json"] = try serialize(AnyCodable(value))
                            continue
                        }

                        if realm.schema[type]?[key]?.type == .date {
                            values[key] = Date(
                                timeIntervalSince1970: Double((value as? Int ?? 0) / 1000)
                            )
                        }
                        else {
                            values[key] = value
                        }
                    }
                }

                let item = try Cache.createItem(itemType, values: values)
                if let allEdges = dict["allEdges"] as? [[String: Any]] {
                    items[item] = allEdges
                }

                return item
            }

            // First create all items
            for dict in dicts {
                if let dict = dict.value as? [String: Any] {
                    _ = try recur(dict)
                }
            }

            // Then create all edges
            for (item, allEdges) in items {
                for edgeDict in allEdges {
                    guard let edgeType = edgeDict["_type"] as? String else {
                        throw "Exception: Ill defined edge"
                    }

                    var edge: Edge
                    if let targetDict = edgeDict["_target"] as? [String: Any],
                       let target = try recur(targetDict)
                    {
                        edge = try Cache.createEdge(
                            source: item,
                            target: target,
                            type: edgeType,
                            label: edgeDict["edgeLabel"] as? String,
                            sequence: edgeDict["sequence"] as? Int
                        )
                    }
                    else {
                        guard
                            let targetType = edgeDict["targetType"] as? String,
                            let _itemUID = edgeDict["uid"] as? Int
                        else {
                            throw "Exception: Ill defined edge: \(edgeDict)"
                        }

                        guard let itemUID = lut[_itemUID] else {
                            print("DEMO DATABASE ERROR: Pointing to non-existing UID: \(_itemUID)")
                            return
                        }

                        edge = try Cache.createEdge(
                            source: item,
                            target: (targetType, itemUID),
                            type: edgeType,
                            label: edgeDict["edgeLabel"] as? String,
                            sequence: edgeDict["sequence"] as? Int
                        )
                    }

                    DatabaseController.asyncOnCurrentThread(write: true) { _ in
                        item.allEdges.append(edge)
                    }
                }
            }
        }
        catch {
            fatalError("Failed to Install: \(error)")
        }
    }

    // TODO: Refactor: don't use async syntax when nothing is async
    public func query(_ datasource: Datasource) throws -> [Item] {
        var error: Error?
        var items: [Item]?

        try query(datasource) {
            error = $0
            items = $1
        }

        if let error = error { throw error }

        return items ?? []
    }

    ///  This function does two things 1) executes a query on the local realm database with given querOptions, and executes callback on the result.
    ///  2) calls the syncer with the same datasource to execute the query on the pod.
    /// - Parameters:
    ///   - datasource: datasource for the query, containing datatype(s), filters, sortInstructions etc.
    ///   - callback: action exectued on the result
    public func query(
        _ datasource: Datasource,
        syncWithRemote: Bool = true,
        _ callback: @escaping (_ error: Error?, _ items: [Item]?) throws -> Void
    ) throws {
        try DatabaseController.trySync { realm in
            // Do nothing when the query is empty. Should not happen.
            let q = datasource.query ?? ""

            // Log to a maker user
            debugHistory.info("Executing query \(q)")

            if q == "" {
                try callback("Empty Query", nil)
            }
            else {
                // Schedule the query to sync from the pod
                if syncWithRemote { self.sync.syncQuery(datasource) }

                // Parse query
                let (typeName, filter) = self.parseQuery(q)

                if typeName == "*" {
                    var returnValue: [Item] = []

                    for dtype in ItemFamily.allCases {
                        // NOTE: Allowed forced cast
                        guard let type = dtype.getType() as? Object.Type else { continue }
                        realm.objects(type).filter("deleted = false " + (filter ?? ""))
                            .forEach { item in
                                if let item = item as? Item {
                                    returnValue.append(item)
                                }
                            }
                    }

                    try callback(nil, returnValue)
                }
                // Fetch the type of the data item
                else if let type = ItemFamily(rawValue: typeName) {
                    // Get primary key of data item
                    // let primKey = type.getPrimaryKey()

                    // Query based on a simple format:
                    // Query format: <type><space><filter-text>
                    guard let queryType = ItemFamily.getType(type)() as? Object.Type else {
                        throw "Unknown type \(type)"
                    }
                    //                let t = queryType() as! Object.Type

                    var result = realm.objects(queryType)
                        .filter("deleted = false " + (filter ?? ""))

                    if let sortProperty = datasource.sortProperty, sortProperty != "" {
                        result = result.sorted(
                            byKeyPath: sortProperty,
                            ascending: datasource.sortAscending ?? true
                        )
                    }

                    // Construct return array
                    var returnValue: [Item] = []
                    for item in result {
                        if let item = item as? Item {
                            returnValue.append(item)
                        }
                    }

                    // Done
                    try callback(nil, returnValue)
                }
                else {
                    // Done
                    try callback("Unknown type send by server: \(q)", nil)
                }
            }
        }
    }

    /// Parses the query string, which whould be of format \<type\>\<space\>\<filter-text\>
    /// - Parameter query: query string
    /// - Returns: (type to query, filter to apply)
    public func parseQuery(_ query: String) -> (type: String, filter: String?) {
        if let _ = query.firstIndex(of: " ") {
            let splits = query.split(separator: " ")
            let type = String(splits[0])
            return (type, String(splits.dropFirst().joined(separator: " ")))
        }
        else {
            return (query, nil)
        }
    }

    public func getResultSet(_ datasource: Datasource) -> ResultSet {
        // Create a unique key from query options
        let key = datasource.uniqueString

        // Look for a resultset based on the key
        if let resultSet = queryIndex[key] {
            // Return found resultset
            return resultSet
        }
        else {
            // Create new result set
            let resultSet = ResultSet(self, datasource)

            // Store resultset in the lookup table
            queryIndex[key] = resultSet

            // Make sure the UI updates when the resultset updates
            cancellables.append(resultSet.objectWillChange.sink { _ in
                // TODO: Error handling
                self.scheduleUIUpdate? { context in
                    context.currentView?.resultSet.datasource == resultSet.datasource
                }
            })

            return resultSet
        }
    }

    /// Adds an item to the local database
    /// - Parameter item:Item to be added
    /// - Throws: Sync conflict exception
    /// - Returns: cached dataItem
    public class func addToCache(_ item: Item) throws -> Item {
        guard item.uid.value != nil else {
            throw "Cannot add an item without uid to the cache"
        }

        do {
            if let cachedItem = try mergeWithCache(item) {
                return cachedItem
            }

            // Add item to realm
            try DatabaseController.trySync(write: true) { $0.add(item, update: .modified) }
        }
        catch {
            throw "Could not add item to cache: \(error)"
        }

        //		bindChangeListeners(item)

        return item
    }

    private class func mergeWithCache(_ item: Item) throws -> Item? {
        guard let uid = item.uid.value else {
            throw "Cannot add an item without uid to the cache"
        }

        // Fetch item from the cache to double check
        if let cachedItem: Item = getItem(item.genericType, uid) {
            // Do nothing when the version is not higher then what we already have
            if item.version <= cachedItem.version && !cachedItem._partial {
                return cachedItem
            }

            // Check if there are local changes
            if cachedItem._action != nil {
                // Try to merge without overwriting local changes
                if !cachedItem.safeMerge(item) {
                    // Merging failed
                    throw "Exception: Sync conflict with item \(item.genericType):\(cachedItem.uid.value ?? 0)"
                }
                return cachedItem
            }
            // Merge in the properties from cachedItem that are not already set
            cachedItem.merge(item)
        }
        return nil
    }

    //	// TODO: does this work for subobjects?
    //	private func bindChangeListeners(_ item: Item) {
//        // Update the sync state when the item changes
//        rlmTokens.append(item.observe { objectChange in
//            if case let .change(propChanges) = objectChange {
//                if item._action == nil {
//                    func doAction() {
//                        // Mark item for updating
//                        item._action = "update"
//                        item._changedInSession = true
//
//                        // Record which field was updated
//                        for prop in propChanges {
//                            if !item._updated.contains(prop.name) {
//                                item._updated.append(prop.name)
//                            }
//                        }
//                    }
//
//                    self.sync.schedule()
//
    //					DatabaseController.writeSync { _ in doAction() }
//                }
//                self.scheduleUIUpdate?(nil)
//            }
//        })
    //	}

    /// marks an item to be deleted
    /// - Parameter item: item to be deleted
    /// - Remark: All methods and properties must throw when deleted = true;
    public func delete(_ item: Item) throws {
        if !item.deleted {
            try DatabaseController.trySync(write: true) { _ in
                item.deleted = true
                item._action = "delete"
                item.allEdges.forEach {
                    $0.deleted = true
                    $0._action = "delete"
                }
                let auditItem = try Cache.createItem(AuditItem.self, values: ["action": "delete"])
                _ = try item.link(auditItem, type: "changelog")

                self.sync.schedule()
            }
        }
    }

    /// marks a set of items to be deleted
    /// - Parameter items: items to be deleted
    public func delete(_ items: [Item]) throws {
        try DatabaseController.trySync(write: true) { _ in
            for item in items {
                if !item.deleted {
                    item.deleted = true
                    item._action = "delete"
                    item.allEdges.forEach {
                        $0.deleted = true
                        $0._action = "delete"
                    }
                    let auditItem = try Cache.createItem(
                        AuditItem.self,
                        values: ["action": "delete"]
                    )
                    _ = try item.link(auditItem, type: "changelog")
                }
            }

            self.sync.schedule()
        }
    }

    /// - Parameter item: item to be duplicated
    /// - Remark:Does not copy the id property
    /// - Returns: copied item
    public func duplicate(_ item: Item) throws -> Item {
        let excludes = [
            "uid",
            "dateCreated",
            "dateAccessed",
            "dateModified",
            "starred",
            "deleted",
            "_updated",
            "_action",
            "_partial",
            "_changedInSession",
        ]

        // TODO: Does not duplicate all edges

        if let itemType = item.getType() {
            var dict = [String: Any?]()

            for prop in item.objectSchema.properties {
                if !excludes.contains(prop.name) {
                    dict[prop.name] = item[prop.name]
                }
            }

            return try Cache.createItem(itemType, values: dict)
        }

        throw "Exception: Could not copy \(item.genericType)"
    }

    public class func getDeviceID() throws -> Int {
        1_000_000_000
    }

    static var cacheUIDCounter: Int = -1

    public class func incrementUID() throws -> Int {
        try DatabaseController.trySync(write: true) { realm in
            if cacheUIDCounter == -1 {
                if
                    let setting = realm.objects(Setting.self)
                    .filter("key = '\(try getDeviceID())/uid-counter'")
                    .first,
                    let str = setting.json,
                    let counter = Int(str)
                {
                    cacheUIDCounter = counter
                }
                else {
                    cacheUIDCounter = try getDeviceID() + 1

                    // As an exception we are not using Cache.createItem here because it should
                    // not be synced to the backend
                    realm.create(Setting.self, value: [
                        "uid": cacheUIDCounter - 1,
                        "key": "\(try getDeviceID())/uid-counter",
                        "_action": "create",
                        "json": String(cacheUIDCounter),
                    ])
                    return
                }
            }

            cacheUIDCounter += 1

            if let setting = realm.objects(Setting.self)
                .filter("key = '\(try getDeviceID())/uid-counter'")
                .first
            {
                setting.json = String(cacheUIDCounter)
                if setting._action == nil {
                    setting._action = "update"
                    setting["_updated"] = ["json"]
                }
            }
        }
        return cacheUIDCounter
    }

    private class func mergeFromCache(_ cachedItem: Item, newerItem: Item) throws -> Item? {
        // Do nothing when the version is not higher then what we already have
        if !newerItem._partial && newerItem.version <= cachedItem.version {
            return cachedItem
        }

        // Check if there are local changes
        if newerItem._action != nil {
            // Try to merge without overwriting local changes
            if !newerItem.safeMerge(cachedItem) {
                // Merging failed
                throw "Exception: Sync conflict with item.uid \(cachedItem.uid)"
            }
        }

        // If the item is partially loaded, then lets not overwrite the database
        if newerItem._partial {
            // Merge in the properties from cachedItem that are not already set
            newerItem.merge(cachedItem, true)
        }

        return newerItem
    }

    // TODO: This doesnt trigger syncToPod()
    public class func createItem<T: Item>(
        _ type: T.Type,
        values: [String: Any?] = [:],
        unique: String? = nil
    ) throws -> T {
        var item: T?
        try DatabaseController.trySync(write: true) { realm in
            var dict = values

            // TODO:
            // Always merge
            var fromCache: T?
            if let unique = unique {
                // TODO: find item in DB & merge
                // Uniqueness based on also not primary key
                fromCache = realm.objects(type).filter(unique).first
            }
            else if let uid = dict["uid"] {
                // TODO: find item in DB & merge
                fromCache = realm.object(ofType: type, forPrimaryKey: uid)
            }

            if let fromCache = fromCache {
                // mergeFromCache(fromCache, ....)
                let properties = fromCache.objectSchema.properties
                let excluded = ["uid", "dateCreated", "dateAccessed", "dateModified"]

                var fields = [String]()

                func setWhenChanged(_ name: String, _ value: Any?) {
                    guard !fromCache.isEqualValue(fromCache[name], value) else { return }
                    fromCache[name] = value
                    fields.append(name)
                }

                for prop in properties {
                    if !excluded.contains(prop.name), dict[prop.name] != nil {
                        setWhenChanged(prop.name, dict[prop.name] as Any?)
                    }
                }
                if !fields.isEmpty {
                    fromCache.modified(fields)
                }

                if let item = item, type != AuditItem.self {
                    let auditItem = try Cache.createItem(
                        AuditItem.self,
                        values: ["action": "update"]
                    )
                    _ = try item.link(auditItem, type: "changelog")
                }

                item = fromCache
                return
            }

            if dict["dateCreated"] == nil { dict["dateCreated"] = Date() }
            if dict["uid"] == nil {
                dict["uid"] = try Cache.incrementUID()
            }

            #if DEBUG
                print("\(type) - \(String(describing: dict["uid"]))")
            #endif

            item = realm.create(type, value: dict)

            if let item = item {
                item["_action"] = "create"
            }

            if let item = item, type != AuditItem.self {
                let auditItem = try Cache.createItem(AuditItem.self, values: ["action": "create"])
                _ = try item.link(auditItem, type: "changelog")
            }
        }

        return item ?? Item() as! T
    }

    public class func createEdge(
        source: Item,
        target: Object,
        type edgeType: String,
        label: String? = nil,
        sequence: Int? = nil
    ) throws -> Edge {
        guard target.objectSchema["uid"] != nil, let targetUID = target["uid"] as? Int else {
            throw "Cannot link target, no .uid set"
        }

        return try createEdge(source: source, target: (target.genericType, targetUID),
                              type: edgeType, label: label, sequence: sequence)
    }

    public class func createEdge(
        source: Item,
        target: (String, Int),
        type edgeType: String,
        label: String? = nil,
        sequence: Int? = nil
    ) throws -> Edge {
        var edge: Edge?
        try DatabaseController.trySync(write: true) { realm in
            // TODO:
            // Always overwrite (see also link())

            // TODO: find item in DB & merge
            // Uniqueness based on also not primary key

            let values: [String: Any?] = [
                "targetItemType": target.0,
                "targetItemID": target.1,
                "sourceItemType": source.genericType,
                "sourceItemID": source.uid.value,
                "type": edgeType,
                "edgeLabel": label,
                "sequence": sequence,
                "dateCreated": Date(),
                "_action": "create",
            ]

            edge = realm.create(Edge.self, value: values)
        }

        return edge ?? Edge()
    }
}
