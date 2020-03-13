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
public class RemoteStorage {
    
    private var podApi: PodAPI
    
    init(_ api:PodAPI) {
        podApi = api
    }
    
    /**
     *
     */
    public func set(_ key:String, _ value:String) {
        
    }
    
    /**
     *
     */
    public func get(_ key:String) -> String {
        
    }
}

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
    public func processQueue(){
        // Already working
        if busy { return }
        
        // Nothing to do
        if queue.count == 0 { return }
        
        let task = queue[0]
        busy = true;

        // TODO catch
        try cache.execute(task) { (error, success) -> Void in
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
    var id: String = UUID().uuidString
    
    public static func == (lt: Task, rt: Task) -> Bool {
        return lt.id == rt.id
    }
}

public class Cache {
    var podAPI: PodAPI
    var queryCache: [String: SearchResult]
    var typeCache: [String: SearchResult]
    var idCache: [String: SearchResult]
    
    private var localStorage: LocalStorage
    private var scheduler: Scheduler
    
    enum CacheError: Error {
        case UnknownTaskJob(job: String)
    }
    
    public init(_ podAPI: PodAPI, queryCache: [String: SearchResult] = [:],
                typeCache: [String: SearchResult] = [:], idCache: [String: SearchResult] = [:]){
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
    public func query(_ query:QueryOptions, _ callback: ((_ error: Error?, _ result: SearchResult?) -> Void)?) -> SearchResult {
        let results = SearchResult(query, nil)
        
        podAPI.query(query, { (error, items) -> Void in
            if (error != nil) {
                callback?(error, nil)
                return
            }
            
            results.data = items
            
            callback?(nil, results)
        })
        
        return results
    }

    public func findQueryResult(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: SearchResult) -> Void) -> Void {}
    public func queryLocal(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: SearchResult) -> Void) -> Void {}
    public func getItemById(_ id: String) -> DataItem {}
    public func fromJSON(_ file: String, _ ext: String = "json") throws -> [DataItem]{ [DataItem()]}
    
    public func getByType(type: String) -> SearchResult? {
        let cacheValue = self.typeCache[type]
        
        if cacheValue != nil {
            print("using cached result for \(type)")
            return cacheValue!
        } else{
            if type != "note" {
                return nil
            }
            else{
                // TODO refactor this
                let result =  self.podAPI.query("notes", nil) { (error, items) -> Void in
                    self.typeCache[type].data = items
//                    return result
                }
            }
        }
    }
    
    func findCachedResult(query: String) -> SearchResult? {
        return self.queryCache[query]
    }
    
    /**
     *
     */
    public func execute(_ task:Task, callback: (_ error:Error?, _ success:Bool) -> Void) throws {
        
        switch task.job {
        case "create":
            let item = self.getItemById(task.data["id"]!)
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
            let item = self.getItemById(id)
            podAPI.update(item, callback)
        default:
            throw CacheError.UnknownTaskJob(job: task.job)
        }
    }
}
