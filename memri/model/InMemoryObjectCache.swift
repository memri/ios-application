//
//  ObjectCache.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

// TODO using NSCache for OS level purging of cache when memory is needed
public class InMemoryObjectCache {
    private var cache = [String:CacheItem]()
    
    public func set<T>(_ key:String, _ value:T) throws {
        if cache[key] == nil {
            cache[key] = CacheItem(value)
        }
        else if let _ = cache[key]?.value as? T {
            cache[key]?.value = value
        }
        else {
            throw "Exception: Can not set cache value to differen type: \(key)"
        }
    }
    
    public func get(_ key:String) -> Any {
        if cache[key] == nil {
            return cache[key] as Any
        }
        return cache[key]?.value as Any
    }
    
    class func set<T>(_ key:String, _ value:T) throws {
        try globalInMemoryObjectCache.set(key, value)
    }
    class func get(_ key:String) -> Any {
        try globalInMemoryObjectCache.get(key)
    }
}
public class CacheItem {
    var value: Any
    init(_ value:Any) { self.value = value }
}

var globalInMemoryObjectCache = InMemoryObjectCache()
