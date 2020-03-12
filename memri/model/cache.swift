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
    
}

// Stores data locally
public class LocalStorage {
    
}

// Schedules long term tasks like syncing with remote
public class Scheduler {
    
}

// Represents a task such as syncing with remote
public struct Task {
    
}

public class Cache {
    var podAPI: PodAPI
    var queryCache: [String: SearchResult]
    var typeCache: [String: SearchResult]
    var idCache: [String: SearchResult]
    
    public init(_ podAPI: PodAPI, queryCache: [String: SearchResult] = [:], typeCache: [String: SearchResult] = [:],
         idCache: [String: SearchResult] = [:]){
        self.podAPI=podAPI
        self.queryCache = queryCache
        self.typeCache = typeCache
        self.idCache = idCache
    }
    
    /**
     * Loads data from the pod. Returns SearchResult.
     * -> Calls callback twice, once for cache, once for real data [??]
     */
    public func query(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: SearchResult) -> Void) -> Void {
        
    }

    public func findQueryResult(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: SearchResult) -> Void) -> Void {}
    public func queryLocal(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: SearchResult) -> Void) -> Void {}
    public func getById(_ query:QueryOptions, _ callback: (_ error: Error?, _ result: SearchResult) -> Void) -> Void {}
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
    
}
