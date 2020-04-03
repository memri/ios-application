//
//  Sync.swift
//  memri
//
//  Created by Ruben Daniels on 4/3/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift

class SyncState: Object, Codable {
    // Whether the data item is loaded partially and requires a full load
    @objc dynamic var isPartiallyLoaded:Bool = false
    
    // What action is needed on this data item to sync with the pod
    @objc dynamic var actionNeeded:String = ""
    
    // The last version loaded from the server
    @objc dynamic var version:Int = 0 // TODO don't overwrite if the version is same or higher
    
    // Which fields to update
    let updatedFields = List<String>()
}

/*
    - Based on a query sync checks whether it still has the latest version of the results
    - It does this asynchronous and in the background, items should update automatically
    - It probably needs a hook for Main to update the view when data that is being displayed is updated
        - How does Main know which data is displayed?
        - Because the computedView.resultSet would be updated
        - Perhaps it's best to put an event on the resultSet??
    - It should also ask the server if there are any changes since the last check time
    - It should also periodically look at the updated sync states and update the related objects
        - This could be optimized by storing the type and uid of the data item in the syncstate
 */
class Sync {
    
    private var podApi: PodAPI
    private var realm: Realm
    
    private var scheduled: Bool = false
    private var syncing: Bool = false
    
    init(_ api:PodAPI, _ rlm:Realm) {
        podApi = api
        realm = rlm
        
        // Periodically sync data from the pod
        //TODO
        
        // Schedule syncing to the pod to see if there are any jobs that remain
        schedule()
    }
    
    /**
     *
     */
    public func syncQuery() {
        // Store query in a log item
        
        // Set syncstate to "fetch"
        
        // Execute query with priority

    }
    
    private func prioritySync(){
        // Execute query objects
    }
    
    /**
     * Schedule a syncing round
     */
    public func schedule(){
        // Don't schedule when we are already scheduled
        if !scheduled {
            
            // Prevent multiple calls to the dispatch queue
            scheduled = true
            
            // Wait 100ms before syncing (should this be longer?)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                
                // Reset scheduled
                scheduled = false
                
                // Start syncing local data to the pod
                syncToPod()
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
    
    /**
     *
     */
    public func execute(_ item:DataItem, callback: (_ error:Error?, _ success:Bool) -> Void) throws {
        switch item.syncState!.actionNeeded {
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
                    try! realm.write() {
                        realm.add(item) // , update: .modified
                    }
                }
                
                callback(error, success)
            }
        case "update":
            podAPI.update(item, callback)
        default:
            throw CacheError.UnknownTaskJob(job: item.syncState!.actionNeeded)
        }
    }
}
