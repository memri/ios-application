//
//  CascadableDict.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift

public class CascadableDict: Cascadable, Subscriptable {
    func get<T>(_ name:String, type:T.Type = T.self) -> T? {
        guard let value = cascadeProperty(name, type: Any?.self) else {
            return nil
        }
        
        if let itemRef = value as? ItemReference {
            return itemRef.resolve() as? T
        }
        else if let list = value as? [ItemReference?] {
            return list.map { ref -> Item? in
                guard let ref = ref else { return nil }
                return ref.resolve()
            } as? T
        }
        // Dicts are not support atm
        
        return value as? T
    }
    
    func set(_ name:String, _ value:Any?) {
        if let item = value as? Item {
            setState(name, ItemReference(to: item))
        }
        else if let list = value as? [Item?] {
            setState(name, list.map { item -> ItemReference? in
                guard let item = item else { return nil }
                return ItemReference(to: item)
            })
        }
        else {
            setState(name, value)
        }
    }
    
    subscript(name: String) -> Any? {
        get { get(name) }
        set (value) { set(name, value) }
    }
    
    public init(_ dict: [String:Any?]? = nil, _ tail: [CVUParsedDefinition]? = nil, host:Cascadable? = nil) {
        var result = [String:Any?]()
        
        if let dict = dict {
            for (key, value) in dict {
                if let item = value as? Item {
                    result[key] = ItemReference(to: item)
                }
                else if let list = value as? [Item?] {
                    result[key] = list.map { item -> ItemReference? in
                        guard let item = item else { return nil }
                        return ItemReference(to: item)
                    }
                }
                else {
                    result[key] = value
                }
            }
        }
        
        super.init(CVUParsedObjectDefinition(result.isEmpty ? nil : result), tail, host)
    }
    
    public init(_ other: CascadableDict? = nil, _ item: Item? = nil) {
        super.init(CVUParsedObjectDefinition(), other?.cascadeStack)
        if let item = item { self.set(".", item) }
    }
    
    required init(_ head: CVUParsedDefinition? = nil, _ tail: [CVUParsedDefinition]? = nil, _ host: Cascadable? = nil) {
        super.init(head, tail, host)
    }
    
    func merge(_ other: CascadableDict?) -> CascadableDict {
        guard let other = other else { return self }
        
        if let parsed = other.head.parsed {
            for (key, value) in parsed {
                self.head[key] = value
            }
        }
        
        if !other.tail.isEmpty {
            self.tail.append(contentsOf: other.tail)
            self.cascadeStack.append(contentsOf: other.tail)
        }
        
        return self
    }
    
    func deepMerge(_ other: CascadableDict?) -> CascadableDict {
        guard let other = other else { return self }
        
        func merge(_ parsed:[String:Any?]?) {
            guard let parsed = parsed else { return }
            for (key, value) in parsed {
                self.head[key] = value
            }
        }
        
        merge(other.head.parsed)
        for item in other.tail {
            merge(item.parsed)
        }
        
        return self
    }
    
    func resolve(_ item: Item?) throws -> CascadableDict {
        // TODO: Only doing this for head, let's see if that is enough
        //       Currently the assumption is that tails never change.
        //       If they do, a copy is required
        
        #warning("This will resolve items which is not good")
        for (key, value) in head.parsed ?? [:] {
            if let expr = value as? Expression {
                let value = try expr.execute(viewArguments)
                if let _ = value as? Item { /* ignore */ }
                else { head.parsed?[key] = value }
            }
        }
        
        set(".", item)
        
        return self
    }
    
    func copy(_ item: Item? = nil) -> CascadableDict {
        let dict = CascadableDict(CVUParsedObjectDefinition(), self.cascadeStack)
        if let item = item { dict.set(".", item) }
        return dict
    }
}
public typealias UserState = CascadableDict
public typealias ViewArguments = CascadableDict
