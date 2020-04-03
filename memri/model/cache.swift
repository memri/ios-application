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

    schemaVersion: 31,

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

        let q = queryOptions.query ?? ""
        if (q == "") {
            callback("Empty Query", nil)
        }
        else {
            // Schedule the real query
            sync.syncQuery(queryOptions)
            
            if (q.starts(with: "0x")) {
                let result = realm.objects(Note.self).filter("uid = '\(q)'") // HACK
                
                callback(nil, [result[0]])
            }
            else {
                let type = DataItemFamily(rawValue: q)
                if let type = type {
                    let queryType = DataItemFamily.getType(type)
                    let result = realm.objects(queryType()).filter("deleted = false") // TODO filter
                    
                    var returnValue:[DataItem] = []
                    for item in result { returnValue.append(item) }
                    
                    callback(nil, returnValue)
                }
                else {
                    callback("Unknown type send by server: \(q)", nil)
                }
            }
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
    public func addToCache(_ item:DataItem) throws {
        // Check if this is a new item or an existing one
        if let uid = item.uid {
            
            // Fetch item from the cache to double check
            if let cachedItem:DataItem = self.getItemById(item.type, uid) {
                
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
            item.syncState!.actionNeeded = "create"
        }
        
        try realm.write() {
            realm.add(item, update: .modified)
        }
        
        // Update the sync state when the item changes
        let _ = item.observe { (objectChange) in
            if case let .change(propChanges) = objectChange {
                if item.syncState!.actionNeeded == "" {
                    try! self.realm.write {
                        let syncState = item.syncState!
                        
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
        
        // Trigger sync.schedule() when the SyncState changes
        let _ = item.syncState!.observe { (objectChange) in
            if case .change = objectChange {
                if item.syncState!.actionNeeded != "" {
                    self.sync.schedule()
                }
            }
        }
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
