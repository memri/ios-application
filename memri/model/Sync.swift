//
//  Sync.swift
//  memri
//
//  Created by Ruben Daniels on 4/3/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

/// This class represent the state of syncing for a DataItem, it keeps tracks of the multiple versions of a DataItem on the server and
/// what actions are needed to sync the DataItem with the latest version on the pod
class SyncState: Object, Codable {
    // Whether the data item is loaded partially and requires a full load
    @objc dynamic var isPartiallyLoaded:Bool = false
    
    // What action is needed on this data item to sync with the pod
    // Enum: "create", "delete", "update"
    @objc dynamic var actionNeeded:String = ""
    
    // The last version loaded from the server
    @objc dynamic var version:Int = 0
    
    // Which fields to update
    let updatedFields = List<String>()
    
    //
    @objc dynamic var changedInThisSession = false
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            isPartiallyLoaded = try decoder.decodeIfPresent("isPartiallyLoaded") ?? isPartiallyLoaded
            version = try decoder.decodeIfPresent("version") ?? version
        }
    }
    
    required init() {
        super.init()
    }
}
/*
 Sync notes:
    - It probably needs a hook for Main to update the view when data that is being displayed is updated
        - How does Main know which data is displayed?
        - Because the cascadingView.resultSet would be updated
        - Perhaps it's best to put an event on the resultSet??
    - It should also ask the server if there are any changes since the last check time
    - It should also periodically look at the updated sync states and update the related objects
        - This could be optimized by storing the type and uid of the data item in the syncstate
 */


/// Based on a query, Sync checks whether it still has the latest version of the resulting DataItems. It does this asynchronous and in the
/// background, items are updated automatically.
class Sync {
    
    /// PodAPI Object to use for executing queries
    private var podAPI: PodAPI
    /// The local realm database
    private var realm: Realm
    /// Cache Object used to fetch resultsets
    public var cache: Cache? = nil
    
    private var scheduled: Bool = false
    private var syncing: Bool = false
    private var backgroundSyncing: Bool = false
    
    /// Initialization of the cache
    /// - Parameters:
    ///   - api: api Object
    ///   - rlm: local Realm database object
    init(_ api:PodAPI, _ rlm:Realm) {
        podAPI = api
        realm = rlm
        
        // Periodically sync data from the pod
        //TODO
        
        // Schedule syncing to the pod to see if there are any jobs that remain
        schedule()
        
        // Run any priority syncs in the background
        prioritySyncAll()
    }
    
    /// Schedule a query to sync the resulting DataItems from the pod
    /// - Parameter datasource: QueryOptions used to perform the query
    public func syncQuery(_ datasource:Datasource) {
        // TODO if this query was executed recently, considering postponing action
        do {
            // Store query in a log item
            let audititem = AuditItem()
            let data = try MemriJSONEncoder.encode([ // TODO move this to Datasource
                "query": datasource.query,
                "sortProperty": datasource.sortProperty,
                "sortAscending": datasource.sortAscending.value ?? false ? "true" : "false"
            ] as? [String:String])
            
            audititem.contents = String(data: data, encoding: .utf8) ?? ""
            audititem.action = "query"
            audititem.date = Date()
            
            // Set syncstate to "fetch" in order to get priority treatment for querying
            audititem.syncState?.actionNeeded = "fetch"
            
            // Add to realm
            realmWriteIfAvailable(realm) { realm.add(audititem) }
            
            // Execute query with priority
            prioritySync(datasource, audititem)
        }
        catch{
            print("syncQuery failed: \(error)")
        }
    }
    
    private func prioritySyncAll() {
        //
        if !backgroundSyncing {
            
            //
            backgroundSyncing = true
            
            // TODO make async in order to not hurt init when cache is not set
            
            // Execute query objects
//            prioritySync()
            
            //
            backgroundSyncing = false
        }
    }
    
    private func prioritySync(_ datasource:Datasource, _ audititem:AuditItem) {
        
        print("Syncing from pod with query: \(datasource.query ?? "")")
        
        // Call out to the pod with the query
        podAPI.query(datasource) { (error, items) in
            if let items = items {
                
                if let cache = cache{
                    
                    // Find resultset that belongs to this query
                    let resultSet = cache.getResultSet(datasource)
                    
                    // The result that we'll add to resultset
                    var result:[DataItem] = []
                    
                    for item in items {
                        // TODO handle sync errors
                        do{
                            let cachedItem = try cache.addToCache(item)
                            if cachedItem.syncState?.actionNeeded != "deleted" {
                                // Add item to result
                                result.append(cachedItem)
                            }
                            // Ignore items marked for deletion
                        }
                        catch {
                            print("\(error)")
                        }
                    }
                    
                    // Find added items
                    // TODO this could be skipped by re-executing resultSet.load()
                    for item in resultSet.items {
                        if item.syncState?.actionNeeded == "created" {
                            result.append(item)
                        }
                    }
                    
                    // Update resultset with the new results
                    resultSet.forceItemsUpdate(items)
                    
                    // We no longer need to process this log item
                    realmWriteIfAvailable(realm){
                        audititem.setSyncStateActionNeeded("")
                    }
                    // TODO consider deleting the log item
                }

            }
            else {
                // Ignore errors (we'll retry next time)
                // TODO consider resorting so that it is not retried too often
            }
        }
    }
    
    /// Schedule a syncing round
    /// - Remark: currently calls mock code
    /// - TODO: implement syncToPod()
    public func schedule(){
        // Don't schedule when we are already scheduled
        if !scheduled {
            
            // Prevent multiple calls to the dispatch queue
            scheduled = true
            
            // Wait 100ms before syncing (should this be longer?)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                
                // Reset scheduled
                self.scheduled = false
                
                // Start syncing local data to the pod
                self.syncToPod()
            }
        }
    }
    
    private func syncToPod(){
        syncing = true
        
        // TODO how to get the right info in SyncState (perhaps in the change binder)
        
        // Loop through syncstate objects (ignore "fetch" and "")
        
        // Fetch the data item
        
        // call execute
        
        // call next
        
        syncing = false
    }
    
    private func syncFromPod() {
        // TODO
    }
    
    
    /// - Remark: Currently unused
    /// - TODO: Implement and document
    /// - Parameters:
    ///   - item:
    ///   - callback:
    /// - Throws:
    public func execute(_ item:DataItem, callback: (_ error:Error?, _ success:Bool) -> Void) throws {
        if let syncState = item.syncState {
            switch syncState.actionNeeded {
            case "create":
                podAPI.create(item) { (error, id) -> Void in
                    if error != nil { return callback(error, false) }
                    
                    // Set the new id from the server
                    item.uid = id
                    
                    callback(nil, true)
                }
            case "delete":
                podAPI.remove(item.getString("uid")) { (error, success) -> Void in
                    if (error == nil) {
                        // Remove from local storage
                        realmWriteIfAvailable(realm){
                            realm.add(item) // , update: .modified
                        }
                    callback(error, success)
                    }
                }
            case "update":
                podAPI.update(item, callback)
            case "fetch":
                // TODO
                break
            default:
                // Ignore unknown tasks
                print("Unknown sync state action: \(item.syncState!.actionNeeded)")
            }
        }
        else {
            throw "No syncState deifned"
        }
    }
}
