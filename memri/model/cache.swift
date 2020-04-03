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
    
    private var cancellables:[AnyCancellable]? = nil
    private var queryIndex:[String:SearchResult] = [:]
    
    enum CacheError: Error {
        case UnknownTaskJob(job: String)
    }
    
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
        scheduler.cache = self
    }
    
    /**
     * Loads data from cache
     */
    public func query(_ query:QueryOptions, _ callback: (_ error:Error?, _ result:[DataItem]?, _ cached:Bool?) -> Void) {
        var receivedFromServer = false
        func handle (_ error:Error?, _ items:[DataItem]?, _ cached:Bool) -> Void {
            if receivedFromServer { return } 
            receivedFromServer = !cached
            
            if (error != nil) {
                callback(error, nil, nil)
                return
            }
            
            // Add all new data items to the cache
            var data:[DataItem] = []
            if let items = items {
                if items.count > 0 {
                    for i in 0...items.count - 1 {
                        data.append(self.addToCache(items[i]))
                    }
                }
            }
            
            callback(nil, data, cached)
        }
        
        queryLocal(query) { (error, items) in handle(error, items, true) }
        podApi.query(query) { (error, items) in handle(error, items, false) }
    }
    
    /**
     *
     */
    public func queryLocal(_ query:QueryOptions, _ callback: (_ error: Error?, _ items: [DataItem]?) -> Void) -> Void {
        let q = query.query ?? ""
        if (q != "") {
            callback("Empty Query", nil)
        }
        else if (q.starts(with: "0x")) {
            let result = realm.objects(Note.self).filter("id = '\(q)'") // HACK
            
            callback(nil, [result[0]])
        }
        else {
            let type = DataItemFamily(rawValue: q)
            if let type = type {
                let queryType = DataItemFamily.getType(type)
                let result = realm.objects(queryType()) // TODO filter
                
                var returnValue:[DataItem] = []
                for item in result { returnValue.append(item) }
                
                callback(nil, returnValue)
            }
            else {
                callback(nil, [])
            }
        }
    }

    public func findQueryResult(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: [DataItem]) -> Void) -> Void {}
    
    public func getResultSet(_ queryOptions:QueryOptions) -> SearchResult {
        let key = queryOptions.uniqueString
        if let resultset = queryIndex[key] {
            return resultset
        }
        else {
            let resultset = SearchResult(self)
            queryIndex[key] = resultset
            resultset.queryOptions.merge(queryOptions)
            return resultset
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
    
    private func generateUID() -> String {
        let counter = UUID().uuidString
        return "0xNEW\(counter)"
    }

    /**
     *
     */
    public func addToCache(_ item:DataItem) -> DataItem {
        // Fetch item from the cache
        var cachedItem:DataItem?
        if let uid = item.uid {
            cachedItem = self.getItemById(item.type, uid)
        }
        else {
            item.uid = generateUID()
            item.syncState!.actionNeeded = "create"
        }
        
        // Update properties to the cached item that are not nil
        if let cachedItem = cachedItem {
            let properties = cachedItem.objectSchema.properties
            var value:[String:Any] = [:]
            for prop in properties {
                if (item[prop.name] != nil) {
                    value[prop.name] = item[prop.name]
                }
            }
            
            let type = DataItemFamily(rawValue: item.type)
            if let type = type {
                let itemType = DataItemFamily.getType(type)
                try! realm.write() {
                    realm.create(itemType(), value: value, update: .modified) // Should update cachedItem
                }
            }
        }
        // Or, if its not in the cache, add to the cache
        else {
            try! realm.write() {
                realm.add(item) // , update: .modified
            }
            cachedItem = item
        }
        
        // Update the sync state when the item changes
        let _ = cachedItem!.observe { (change) in
            if change == .change {
                if !item.syncState!.actionNeeded {
                    try! realm.write {
                        item.syncState!.actionNeeded = "update"
                    }
                }
            }
        }
        // Trigger Sync.schedule() when the SyncState changes
        let _ = cachedItem!.syncState.observe { (change) in
            if change == .change && actionNeeded != "" {
                sync.schedule()
            }
        }

        // Return item from the cache
        return cachedItem ?? item
    }
    
    /**
     * Sets deleted to true
     * All methods and properties must throw when deleted = true;
     */
    public func delete(_ item:DataItem) {
        if (!item.deleted) {
            try! self.realm!.write {
                item.deleted = true;
                item.syncState!.actionNeeded = "delete"
            }
        }
    }
    
    public func delete(_ items:[DataItem]) {
        try! self.realm!.write {
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
