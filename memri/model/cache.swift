//
//  cache.swift
//  memri
//
//  Created by Ruben Daniels on 3/12/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine

// Stores data remote
//public class RemoteStorage {
//
//    private var podApi: PodAPI
//
//    init(_ api:PodAPI) {
//        podApi = api
//    }
//
//    /**
//     *
//     */
//    public func set(_ key:String, _ value:String) {
//
//    }
//
//    /**
//     *
//     */
//    public func get(_ key:String) -> String {
//
//    }
//}

// Stores data locally
public class LocalStorage {
    /**
     *
     */
    public func set(_ key:String, _ value:String) { // TODO Should throw or callback for out of disk and other failures
        
    }
    
    /**
     *
     */
    public func get(_ key:String) -> String {
        
    }
}

// Schedules long term tasks like syncing with remote
public class Scheduler {
    private var queue: [Task] = []
    private var localStorage: LocalStorage
    private var cache: Cache
    private var busy: Bool = false
    
    init(_ local:LocalStorage, _ c:Cache) {
        localStorage = local
        cache = c
        
        // For a future solution: https://stackoverflow.com/questions/46344963/swift-jsondecode-decoding-arrays-fails-if-single-element-decoding-fails
        let decoder = JSONDecoder()
        do {
            let json = localStorage.get("scheduler").data(using: .utf8)!
            queue = try decoder.decode([Task].self, from: json)
            processQueue()
        } catch {
            print("Unexpected init error: \(error)")
            
            queue = []
            persist()
            
            // TODO fullSync()
        }
    }
    
    /**
     *
     */
    public func add(_ task:Task) {
        // Don't add the same update to the queue more than once
        if queue.firstIndex(of: task) ?? -1 > -1 { return }
        
        queue.append(task)
        persist()
        processQueue()
    }
    
    /**
     *
     */
    public func remove(_ task:Task) {
        queue.remove(at: queue.firstIndex(of: task) ?? -1)
        persist()
    }
    
    /**
     *
     */
    public func persist(){
        localStorage.set("scheduler", serialize()) // TODO this may be increasingly slow and should then be refactored
    }
    
    /**
     *
     */
    public func serialize() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // for debugging purpose

        var json:String
        do {
            let data = try encoder.encode(queue)
            json = String(data: data, encoding: .utf8) ?? ""
        } catch {
            print("Unexpected error: \(error)")
        }
        
        return json
    }
    
    /**
     *
     */
    // TODO add concurrency
    // TODO time-delay
    public func processQueue(){
        // Already working
        if busy { return }
        
        // Nothing to do
        if queue.count == 0 { return }
        
        let task = queue[0]
        busy = true;

        // TODO catch
        try? cache.execute(task) { (error, success) -> Void in
            queue.remove(at: 0)
            if !success { queue.append(task) } // TODO keep a retry counter to not have stuck jobs ??
            busy = false
            processQueue()
        }
    }
}

// Represents a task such as syncing with remote
public struct Task: Equatable, Codable {
    var job: String
    var data: [String:String]
//    var id: String = UUID().uuidString
//
//    public static func == (lt: Task, rt: Task) -> Bool {
//        return lt.id == rt.id
//    }
}

public class Cache {
    var podAPI: PodAPI
    var queryCache: [String: SearchResult]
    var typeCache: [String: SearchResult]
    var idCache: [String: DataItem]
    
    private var localStorage: LocalStorage
    private var scheduler: Scheduler
    
    enum CacheError: Error {
        case UnknownTaskJob(job: String)
    }
    
    public init(_ podAPI: PodAPI, queryCache: [String: SearchResult] = [:],
                typeCache: [String: SearchResult] = [:], idCache: [String: DataItem] = [:]){
        self.podAPI = podAPI
        self.queryCache = queryCache
        self.typeCache = typeCache
        self.idCache = idCache
        
        // Create storage and scheduler objects
        localStorage = LocalStorage()
        scheduler = Scheduler(localStorage, self)
    }
    
    /**
     * Loads data from the pod. Returns SearchResult.
     * -> Calls callback twice, once for cache, once for real data [??]
     */
    public func query(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: SearchResult?, _ cached:Bool?) -> Void) -> SearchResult {
        let results = SearchResult(query, nil)
        
        var receivedFromServer = false
        func handle (_ error:Error?, _ items:[DataItem], _ cached:Bool) -> Void {
            if receivedFromServer { return } 
            receivedFromServer = !cached
            
            if (error != nil) {
                callback(error, nil, nil)
                return
            }
            
            // Add all new data items to the cache
            try? items.forEach { (item) throws in
                self.addToCache(item)
            }
            
            // Add the searchresult to the cache
            self.queryCache[query.query] = results // Overwrite past results (even though sorting options etc, may differ ...
            
            results.data = items
            
            callback(nil, results, cached)
        }
        
        queryLocalItems(query) { (error, items) in handle(error, items, true) }
        podAPI.query(query) { (error, items) in handle(error, items, false) }
        
        return results
    }
    
    /**
     *
     */
    public func queryLocalItems(_ query:QueryOptions, _ callback: (_ error: Error?, _ items: [DataItem]) -> Void) -> Void {
        // Search in query cache
        if self.queryCache[query.query] != nil {
            callback(nil, self.queryCache[query.query]!.data)
            return
        }
        
        // Parse query -> query types
        if self.typeCache[query.query] != nil {
            callback(nil, self.typeCache[query.query]!.data)
            return
        }
        
        callback(nil, [])
    }

    public func findQueryResult(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: SearchResult) -> Void) -> Void {}
    public func queryLocal(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: SearchResult) -> Void) -> Void {}
    public func fromJSON(_ file: String, _ ext: String = "json") throws -> [DataItem]{ [DataItem()]}
    
    /**
     *
     */
    public func getItemById(_ id: String) -> DataItem? {
        return self.idCache[id]
    }
    
    /**
     *
     */
    public func getItemByType(type: String) -> SearchResult? {
        return self.typeCache[type]
    }
    
    /**
     *
     */
    func findCachedResult(query: String) -> SearchResult? {
        return self.queryCache[query]
    }
    
    /**
     *
     */
    public func addToCache(_ item:DataItem) {
        if self.idCache[item.id] == nil {
            self.idCache[item.id] = item
        }
        else { return }

        if item.type != "" && self.typeCache[item.type] == nil {
            self.typeCache[item.type] = SearchResult()
        }
        
        self.typeCache[item.type]!.data.append(item) // TODO sort??
        
        let _ = item.objectWillChange.sink {
            if (item.isDeleted) { self.onRemove(item) } // TODO how to prevent calling this more than once
            else { self.onUpdate(item) }
        }
    }
    
    /**
     *
     */
    public func addToCache(_ result:SearchResult) {
        
    }
    
    /**
     *
     */
    public func execute(_ task:Task, callback: (_ error:Error?, _ success:Bool) -> Void) throws {
        
        switch task.job {
        case "create":
            let item = self.getItemById(task.data["id"]!) ?? DataItem()
            podAPI.create(item) { (error, id) -> Void in
                if error != nil { return callback(error, false) }
                
                // Set the new id from the server
                item.setProperty("id", AnyDecodable(id))
                
                callback(nil, true)
            }
        case "delete":
            let id = task.data["id"]!
            podAPI.remove(id) { (error, success) -> Void in
                callback(error, success)
            }
        case "update-property":
            fallthrough
        case "update":
            let id = task.data["id"]!
            let item = self.getItemById(id) ?? DataItem()
            podAPI.update(item, callback)
        default:
            throw CacheError.UnknownTaskJob(job: task.job)
        }
    }
    
    private func onCreate(_ item:DataItem) {
        // Store in local storage
        
        // Create a task
        let task = Task(job: "create", data: ["id": item.id])
        
        // Add task to the scheduler
        scheduler.add(task)
    }
    private func onRemove(_ item:DataItem) {
        // Store in local storage
        
        // Create a task
        let task = Task(job: "delete", data: ["id": item.id])
        
        // Add task to the scheduler
        scheduler.add(task)
    }
    private func onUpdate(_ item:DataItem) {
        // Store in local storage
        
        // Create a task
        let task = Task(job: "update", data: ["id": item.id])
        
        // Add task to the scheduler
        scheduler.add(task)
    }
}
