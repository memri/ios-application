//
// InMemoryObjectCache.swift
// Copyright © 2020 memri. All rights reserved.

import Combine
import Foundation
import RealmSwift
import SwiftUI

public class InMemoryObjectCache {
    static var global = InMemoryObjectCache()

    private var cache = MemoryCache<String, Any>()

    public func set<T>(_ key: String, _ value: T) throws {
        if cache[key] == nil {
            cache[key] = value
        }
        else if (cache[key] as? T) != nil {
            cache[key] = value
        }
        else {
            throw "Exception: Can not set cache value to different type: \(key)"
        }
    }

    public func get(_ key: String) -> Any? {
        cache[key] as Any?
    }

    public func clear(_ key: String) {
        cache[key] = nil
    }
}

public final class MemoryCache<Key: Hashable, Value> {
    private let wrapped = NSCache<WrappedKey, Entry>()

    init() {
        wrapped.countLimit = 50
    }

    public func insert(_ value: Value, forKey key: Key) {
        let entry = Entry(value: value)
        wrapped.setObject(entry, forKey: WrappedKey(key))
    }

    public func value(forKey key: Key) -> Value? {
        let entry = wrapped.object(forKey: WrappedKey(key))
        return entry?.value
    }

    public func removeValue(forKey key: Key) {
        wrapped.removeObject(forKey: WrappedKey(key))
    }

    subscript(key: Key) -> Value? {
        get { value(forKey: key) }
        set {
            guard let value = newValue else {
                removeValue(forKey: key)
                return
            }
            insert(value, forKey: key)
        }
    }

    private final class WrappedKey: NSObject {
        let key: Key

        init(_ key: Key) { self.key = key }

        override var hash: Int { key.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }

            return value.key == key
        }
    }

    private final class Entry {
        let value: Value

        init(value: Value) {
            self.value = value
        }
    }
}
