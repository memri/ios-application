//
//  cache.swift
//  memri
//
//  Created by Ruben Daniels on 3/12/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import RealmSwift

var config = Realm.Configuration(
//    fileURL: URL(string: "file:///Users/rubendaniels/Development/realm/memri.realm"),
    
    // Set the new schema version. This must be greater than the previously used
    // version (if you've never set a schema version before, the version is 0).
    schemaVersion: 32,

    // Set the block which will be called automatically when opening a Realm with
    // a schema version lower than the one set above
    migrationBlock: { migration, oldSchemaVersion in
        // We haven’t migrated anything yet, so oldSchemaVersion == 0
        if (oldSchemaVersion < 2) {
            // Nothing to do!
            // Realm will automatically detect new properties and removed properties
            // And will update the schema on disk automatically
        }
    })

func getRealmPath() -> String{
    let homeDir = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]!
    let realmDir = homeDir + "/realm.memri"
    
    do {
        try FileManager.default.createDirectory(atPath: realmDir, withIntermediateDirectories: true, attributes: nil)
    }
    catch {
        print(error)
    }
    
    return realmDir
}

public class Cache {
    var podApi: PodAPI
    var sync: Sync
    var realm: Realm
    
    private var rlmTokens: [NotificationToken] = []
    private var cancellables: [AnyCancellable] = []
    private var queryIndex: [String:ResultSet] = [:]
    
    /**
     * @private
     */
    public var scheduleUIUpdate: (() -> Void)? = nil
    
    public init(_ api: PodAPI){
                
        // Tell Realm to use this new configuration object for the default Realm
        #if targetEnvironment(simulator)
            config.fileURL = URL(string: "file://\(getRealmPath())/memri.realm")
        #endif
        
        Realm.Configuration.defaultConfiguration = config

        realm = try! Realm()
        
        print("Starting realm at \(Realm.Configuration.defaultConfiguration.fileURL!)")
        
        podApi = api
        
        // Create scheduler objects
        sync = Sync(podApi, realm)
        sync.cache = self
    }
    
    /**
     *
     */
    public func query(_ queryOptions:QueryOptions, _ callback: (_ error: Error?, _ items: [DataItem]?) -> Void) -> Void {

        // Do nothing when the query is empty. Should not happen.
        let q = queryOptions.query ?? ""
        if (q == "") {
            callback("Empty Query", nil)
        }
        else {
            // Schedule the query to sync from the pod
            sync.syncQuery(queryOptions)
            
            // Detect querying for a single item based on uid (hack!)
            if (q.starts(with: "0x")) {
                let result = realm.objects(Note.self).filter("uid = '\(q)'") // HACK
                
                callback(nil, [result[0]])
            }
            // Query based on a simple format:
            // Query format: <type><space><filter-text>
            else {
                // Parse query
                let (typeName, filter) = parseQuery(q)
                
                // Look up type and filter results
                let type = DataItemFamily(rawValue: typeName)
                if let type = type {
                    let queryType = DataItemFamily.getType(type)
                    let result = realm.objects(queryType())
                        .filter("deleted = false " + (filter ?? ""))
                    
                    // Construct return array
                    var returnValue:[DataItem] = []
                    for item in result { returnValue.append(item) }
                    
                    // Done
                    callback(nil, returnValue)
                }
                else {
                    // Done
                    callback("Unknown type send by server: \(q)", nil)
                }
            }
        }
    }
    
    private func parseQuery(_ query: String) -> (type:String, filter:String?) {
        if let _ = query.firstIndex(of: " ") {
            let splits = query.split(separator: " ")
            let type = String(splits[0])
            return (type, String(splits.dropFirst().joined(separator: " ")))
        }
        else {
            return (query, nil)
        }
    }

    public func findQueryResult(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: [DataItem]) -> Void) -> Void {}
    
    public func getResultSet(_ queryOptions:QueryOptions) -> ResultSet {
        // Create a unique key from query options
        let key = queryOptions.uniqueString
        
        // Look for a resultset based on the key
        if let resultSet = queryIndex[key] {
            
            // Return found resultset
            return resultSet
        }
        else {
            // Create new result set
            let resultSet = ResultSet(self)
            
            // Store resultset in the lookup table
            queryIndex[key] = resultSet
            
            // Make sure the new resultset has the right query properties
            resultSet.queryOptions.merge(queryOptions)
            
            // Make sure the UI updates when the resultset updates
            self.cancellables.append(resultSet.objectWillChange.sink { (_) in
                self.scheduleUIUpdate!()
            })
            
            return resultSet
        }
    }
    
    /**
     *
     */
    public func getItemById<T:DataItem>(_ type:String, _ uid: String) -> T? {
        let type = DataItemFamily(rawValue: type)
        if let type = type {
            let item = DataItemFamily.getType(type)
            return realm.objects(item()).filter("uid = '\(uid)'").first as! T?
        }
        return nil
    }

    /**
     *
     */
    public func addToCache(_ item:DataItem) throws -> DataItem {
        // Check if this is a new item or an existing one
        if let uid = item.uid {
            
            // Fetch item from the cache to double check
            if let cachedItem:DataItem = self.getItemById(item.type, uid) {
                
                // Do nothing when the version is not higher then what we already have
                if !cachedItem.syncState!.isPartiallyLoaded && item.syncState!.version <= cachedItem.syncState!.version {
                    return cachedItem
                }
                
                // Check if there are local changes
                if cachedItem.syncState!.actionNeeded != "" {
                    
                    // Try to merge without overwriting local changes
                    if !item.safeMerge(cachedItem) {
                        
                        // Merging failed
                        throw "Exception: Sync conflict with item.uid \(cachedItem.uid!)"
                    }
                }
                
                // If the item is partially loaded, then lets not overwrite the database
                if item.syncState!.isPartiallyLoaded {
                    
                    // Merge in the properties from cachedItem that are not already set
                    item.merge(cachedItem, true)
                }
            }
        }
        else {
            // Create a new ID
            item.uid = DataItem.generateUID()
            
            // Schedule to be created on the pod
            try realm.write() { item.syncState!.actionNeeded = "create" }
        }
        
        // Add item to realm
        try realm.write() { realm.add(item, update: .modified) }
        
        // Update the sync state when the item changes
        rlmTokens.append(item.observe { (objectChange) in
            if case let .change(propChanges) = objectChange {
                if item.syncState!.actionNeeded == "" {
                    try! self.realm.write {
                        let syncState = item.syncState!
                        
                        // Update state in realm
                        try self.realm.write() {
                        
                            // Mark item for updating
                            syncState.actionNeeded = "update"
                            
                            // Record which field was updated
                            for prop in propChanges {
                                if !syncState.updatedFields.contains(prop.name) {
                                    syncState.updatedFields.append(prop.name)
                                }
                            }
                        }
                    }
                }
            }
        })
        
        // Trigger sync.schedule() when the SyncState changes
        rlmTokens.append(item.syncState!.observe { (objectChange) in
            if case .change = objectChange {
                if item.syncState!.actionNeeded != "" {
                    self.sync.schedule()
                }
            }
        })
        
        return item
    }
    
    /**
     * Sets deleted to true
     * All methods and properties must throw when deleted = true;
     */
    public func delete(_ item:DataItem) {
        if (!item.deleted) {
            try! self.realm.write {
                item.deleted = true;
                item.syncState!.actionNeeded = "delete"
            }
        }
    }
    
    public func delete(_ items:[DataItem]) {
        try! self.realm.write {
            for item in items {
                if (!item.deleted) {
                    item.deleted = true
                    item.syncState!.actionNeeded = "delete"
                }
            }
        }
    }
    
    /**
     * Does not copy the id property
     */
    public func duplicate(_ item:DataItem) -> DataItem {
        let type = DataItemFamily(rawValue: item.type)!
        let T = DataItemFamily.getType(type)
        let copy = T().init()
        let properties = item.objectSchema.properties
        for prop in properties {
            if prop.name == "uid" { continue }
            copy[prop.name] = item[prop.name]
        }
        return copy
    }
}
