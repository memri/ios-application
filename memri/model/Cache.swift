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
    // Set the new schema version. This must be greater than the previously used
    // version (if you've never set a schema version before, the version is 0).
    schemaVersion: 51,

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

/// Computes the Realm path /home/<user>/realm.memri and creates the directory if it does not exist.
/// - Returns: the computed directory
func getRealmPath() throws -> String{
    if  let homeDir = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] {
        let realmDir = homeDir + "/realm.memri"
        
        do {
            try FileManager.default.createDirectory(atPath:
                realmDir, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print(error)
        }
        
        return realmDir
        }
    else {
        throw "Could not get realm path"
    }
}

public class Cache {
    
    /// PodAPI object
    var podAPI: PodAPI
    /// Object that schedules with the POD
    var sync: Sync
    /// Realm Database object
    var realm: Realm
    
    private var rlmTokens: [NotificationToken] = []
    private var cancellables: [AnyCancellable] = []
    private var queryIndex: [String:ResultSet] = [:]
    
    
     //TODO: document
    public var scheduleUIUpdate: ((_ check:(_ context:MemriContext) -> Bool) -> Void)? = nil
    
    
    /// Starts the local realm database, which is created if it does not exist, sets the api and initializes the sync from them.
    /// - Parameter api: api object
    public init(_ api: PodAPI){

        // Tell Realm to use this new configuration object for the default Realm
        #if targetEnvironment(simulator)
            do {
                config.fileURL = URL(string: "file://\(try getRealmPath())/memri.realm")
            }
            catch {
                // TODO: Error handling
                print("\(error)")
            }
        #endif

        Realm.Configuration.defaultConfiguration = config

        // TODO: Error handling
        realm = try! Realm()
        
        print("Starting realm at \(String(describing: Realm.Configuration.defaultConfiguration.fileURL))")
        
        podAPI = api
        
        // Create scheduler objects
        sync = Sync(podAPI, realm)
        sync.cache = self
    }
    
    
    /// gets default item from database, and adds them to realm
    public func install() {
        // Load default database from disk
        do{
            let jsonData = try jsonDataFromFile("default_database")
            let items:[DataItem] = try MemriJSONDecoder.decode(family:DataItemFamily.self, from:jsonData)
            realmWriteIfAvailable(realm, {
                for item in items {
                    realm.add(item, update: .modified)
                }
            })
        }
        catch {
            print("Failed to Install: \(error)")
        }
    }
    
    // TODO Refactor: don't use async syntax when nothing is async
    public func query(_ datasource:Datasource) throws -> [DataItem] {
        var error:Error?
        var items:[DataItem]?
        
        query(datasource) {
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
    public func query(_ datasource:Datasource,
                      _ callback: (_ error: Error?, _ items: [DataItem]?) -> Void) -> Void {

        // Do nothing when the query is empty. Should not happen.
        let q = datasource.query ?? ""
        
        // Log to a maker user
        errorHistory.info("Executing query \(q)")
        
        if (q == "") {
            callback("Empty Query", nil)
        }
        else {
            // Schedule the query to sync from the pod
            sync.syncQuery(datasource)
            
            // Parse query
            let (typeName, filter) = parseQuery(q)
            
            if typeName == "*" {
                
                var returnValue:[DataItem] = []

                for dtype in DataItemFamily.allCases{
                    // NOTE: Allowed forced cast
                    let objects = realm.objects(dtype.getType() as! Object.Type)
                                        .filter("deleted = false " + (filter ?? ""))
                    for item in objects { returnValue.append(item as! DataItem) }
                }
                
                callback(nil, returnValue)
            }
            // Fetch the type of the data item
            else if let type = DataItemFamily(rawValue: typeName) {
                // Get primary key of data item
                // let primKey = type.getPrimaryKey()
                
                // Query based on a simple format:
                // Query format: <type><space><filter-text>
                let queryType = DataItemFamily.getType(type)
//                let t = queryType() as! Object.Type
                
                var result = realm.objects(queryType() as! Object.Type)
                    .filter("deleted = false " + (filter ?? ""))
                
                if let sortProperty = datasource.sortProperty, sortProperty != "" {
                    result = result.sorted(
                        byKeyPath: sortProperty,
                        ascending: datasource.sortAscending.value ?? true)
                }
                
                // Construct return array
                var returnValue:[DataItem] = []
                for item in result {
                    if let item = item as? DataItem{
                        returnValue.append(item)
                    }
                }
                
                // Done
                callback(nil, returnValue)
            }
            else {
                // Done
                callback("Unknown type send by server: \(q)", nil)
            }
        }
    }
    
    /// Parses the query string, which whould be of format \<type\>\<space\>\<filter-text\>
    /// - Parameter query: query string
    /// - Returns: (type to query, filter to apply)
    public func parseQuery(_ query: String) -> (type:String, filter:String?) {
        if let _ = query.firstIndex(of: " ") {
            let splits = query.split(separator: " ")
            let type = String(splits[0])
            return (type, String(splits.dropFirst().joined(separator: " ")))
        }
        else {
            return (query, nil)
        }
    }

    public func getResultSet(_ datasource:Datasource) -> ResultSet {
        // Create a unique key from query options
        let key = datasource.uniqueString
        
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
            resultSet.datasource.query = datasource.query
            resultSet.datasource.sortProperty = datasource.sortProperty
            resultSet.datasource.sortAscending.value = datasource.sortAscending.value
            
            // Make sure the UI updates when the resultset updates
            self.cancellables.append(resultSet.objectWillChange.sink { (_) in
                // TODO: Error handling
                self.scheduleUIUpdate!() { context in
                    return context.cascadingView.resultSet.datasource == resultSet.datasource
                }
            })
            
            return resultSet
        }
    }
    
    
     /// retrieves item from realm by type and uid.
     /// - Parameters:
     ///   - type: realm type
     ///   - memriID: item memriID
     /// - Returns: retrieved item. If the item does not exist, returns nil.
    public func getItemById<T:DataItem>(_ type:String, _ memriID: String) -> T? {
        let type = DataItemFamily(rawValue: type)
        if let type = type {
            let item = DataItemFamily.getType(type)
            // NOTE: Allowed force unwrapping
            return realm.object(ofType: item() as! Object.Type, forPrimaryKey: memriID) as! T?
        }
        return nil
    }
    
    /// Adding an item to cache consist of 3 phases. 1) When the passed item already exists, it is merged with the existing item in the cache.
    /// If it does not exist, this method passes a new "create" action to the SyncState, which will generate a uid for this item. 2) the merged
    /// objects ia added to realm 3) We create bindings from the item with the syncstate which will trigger the syncstate to update when
    /// the the item changes
    /// - Parameter item:DataItem to be added
    /// - Throws: Sync conflict exception
    /// - Returns: cached dataItem
    public func addToCache(_ item:DataItem) throws -> DataItem {
        
        do {
            if let newerItem = try mergeWithCache(item){
                return newerItem
            }
            
            // Add item to realm
            try realm.write() { realm.add(item, update: .modified) }
        }
        catch{
            print("Could not add to cache: \(error)")
        }
        
        bindChangeListeners(item)
        
        return item
    }
    
    private func mergeWithCache(_ item: DataItem) throws -> DataItem?  {
        // Check if this is a new item or an existing one
        if let syncState = item.syncState{

            if item.uid == 0 {
                // Schedule to be created on the pod
                try realm.write() {
                    syncState.actionNeeded = "create"
                    realm.add(AuditItem(action: "create", appliesTo: [item]))
                }
            }
            else {
                // Fetch item from the cache to double check
                if let cachedItem:DataItem = self.getItemById(item.genericType, item.memriID) {
                    
                    // Do nothing when the version is not higher then what we already have
                    if !syncState.isPartiallyLoaded
                        && item.version <= cachedItem.version {
                        return cachedItem
                    }
                    
                    // Check if there are local changes
                    if syncState.actionNeeded != "" {
                        
                        // Try to merge without overwriting local changes
                        if !item.safeMerge(cachedItem) {
                            
                            // Merging failed
                            throw "Exception: Sync conflict with item.memriID \(cachedItem.memriID)"
                        }
                    }
                    
                    // If the item is partially loaded, then lets not overwrite the database
                    if syncState.isPartiallyLoaded {
                        
                        // Merge in the properties from cachedItem that are not already set
                        item.merge(cachedItem, true)
                    }
                }
            }
            return nil
        }
        else{
            print("Error: no syncstate available during merge")
            return nil
        }
    }
    
    // TODO does this work for subobjects?
    private func bindChangeListeners(_ item: DataItem) {
        if let syncState = item.syncState {
            // Update the sync state when the item changes
            rlmTokens.append(item.observe { (objectChange) in
                if case let .change(propChanges) = objectChange {
                    if syncState.actionNeeded == "" {
                                                
                        func doAction(){
                            
                            // Mark item for updating
                            syncState.actionNeeded = "update"
                            syncState.changedInThisSession = true
                            
                            // Record which field was updated
                            for prop in propChanges {
                                if !syncState.updatedFields.contains(prop.name) {
                                    syncState.updatedFields.append(prop.name)
                                }
                            }
                        }
                        
                        realmWriteIfAvailable(self.realm, { doAction() } )
                    }
                    if let scheduleUIUpdate = self.scheduleUIUpdate{
                        scheduleUIUpdate{_ in true}
                    }
                    else {
                        print("No scheduleUIUpdate available in bindChangeListeners()")
                    }
                }
            })
            
            // Trigger sync.schedule() when the SyncState changes
            rlmTokens.append(syncState.observe { (objectChange) in
                if case .change = objectChange {
                    if syncState.actionNeeded != "" {
                        self.sync.schedule()
                    }
                }
            })
        }
        else {
            print("Error, no syncState available for item")
        }
    }
    
    /// sets delete to true in the syncstate, for an array of items
    /// - Parameter item: item to be deleted
    /// - Remark: All methods and properties must throw when deleted = true;
    public func delete(_ item:DataItem) {
        if (!item.deleted) {
            realmWriteIfAvailable(self.realm) {
                item.deleted = true;
                item.syncState!.actionNeeded = "delete"
                realm.add(AuditItem(action: "delete", appliesTo: [item]))
            }
        }
    }
    
    
     /// sets delete to true in the syncstate, for an array of items
     /// - Parameter items: items to be deleted
    public func delete(_ items:[DataItem]) {
        realmWriteIfAvailable(self.realm) {
            for item in items {
                if (!item.deleted) {
                    item.deleted = true
                    item.setSyncStateActionNeeded("delete")
                    realm.add(AuditItem(action: "delete", appliesTo: [item]))
                }
            }
        }
    }
    
     /// - Parameter item: item to be duplicated
     /// - Remark:Does not copy the id property
     /// - Returns: copied item
    public func duplicate(_ item:DataItem) -> DataItem {
        if let cls = item.getType() {
            let copy = item.getType()!.init()
            let primaryKey = cls.primaryKey()
            for prop in item.objectSchema.properties {
                // TODO allow generation of uid based on number replaces {uid}
                // if (item[prop.name] as! String).includes("{uid}")
                
                if prop.name != primaryKey{
                    copy[prop.name] = item[prop.name]

                }
            }
            return copy
        }
        else {
            print("Failled to copy DataItem")
            return DataItem()
        }
    }
    
}
