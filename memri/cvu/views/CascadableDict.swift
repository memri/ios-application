//
//  CascadableDict.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift

public class CascadableDict: Cascadable, CustomStringConvertible, Subscriptable {
    class ItemReference {
        let uid:Int
        let type:Item.Type
        
        init (to: Item) {
            uid = to.uid.value ?? -1
            type = to.getType() ?? Item.self
        }
        
        func resolve() -> Item? {
            DatabaseController.read { $0.object(ofType: type, forPrimaryKey: uid) }
        }
    }
    
    func get<T>(_ name:String, type:T.Type = T.self) -> T? {
        let value = cascadeProperty(name, type: Any.self)
        
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
    
    public var description: String {
        head.parsed?.keys.description ?? ""
    }
    
    public init(_ head: [String:Any?]? = nil, _ tail: [CVUParsedDefinition]? = nil, host:Cascadable? = nil) {
        super.init(CVUParsedObjectDefinition(head), tail, host)
    }
    
    public init(_ head: CascadableDict?, _ tail: CascadableDict? = nil) {
        var combinedTail = head?.tail
        combinedTail?.append(contentsOf: tail?.cascadeStack ?? [])
        super.init(CVUParsedObjectDefinition(head?.head.parsed), combinedTail)
    }
    
    required init(_ head: CVUParsedDefinition? = nil, _ tail: [CVUParsedDefinition]? = nil, _ host: Cascadable? = nil) {
        super.init(head, tail, host)
    }
    
    func resolve(_ item: Item?) throws {
        // TODO: Only doing this for head, let's see if that is enough
        for (key, value) in head.parsed ?? [:] {
            if let expr = value as? Expression {
                head.parsed?[key] = try expr.execute(viewArguments)
            }
        }
    }
}
public typealias UserState = CascadableDict
public typealias ViewArguments = CascadableDict
