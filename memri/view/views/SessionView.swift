//
//  SessionView.swift
//  memri
//
//  Created by Koen van der Veen on 29/04/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

// TODO generalize using Any and one dict for cache (add namespace support)
// TODO wrap all items in a class, so that they are stored by copy i.e. class CacheItem
public class GlobalCache {
    private var stringCache:[String:String] = [:]
    private var uiImageCache:[String:UIImage] = [:]
    private var dataCache:[String:Data] = [:]
    private var guiElementCache:[String:[String:GUIElementDescription]] = [:]
    private var dictStringArrayCache:[String:[String:[String]]] = [:]
    private var dictAnyCache:[String:[String:Any]] = [:]
    
    public func set<T>(_ key:String, _ value:T) throws {
        if T.self == UIImage.self {
            uiImageCache[key] = (value as! UIImage)
        }
        else if T.self == String.self {
            stringCache[key] = (value as! String)
        }
        else if T.self == Data.self {
            dataCache[key] = (value as! Data)
        }
        else if T.self == [String:[String]].self {
            dictStringArrayCache[key] = (value as! [String:[String]])
        }
        else if T.self == [String:Any].self {
            dictAnyCache[key] = (value as! [String:Any])
        }
        else if T.self == [String:GUIElementDescription].self {
            guiElementCache[key] = (value as! [String:GUIElementDescription])
        }
        else {
            throw "Exception: Could not parse the type to write to \(key)"
        }
    }
    
    public func get<T>(_ key:String) throws -> T? {
        if T.self == UIImage.self {
            return uiImageCache[key] as? T
        }
        else if T.self == String.self {
            return stringCache[key] as? T
        }
        else if T.self == Data.self {
            return dataCache[key] as? T
        }
        else if T.self == [String:[String]].self {
            return dictStringArrayCache[key] as? T
        }
        else if T.self == [String:Any].self {
            return dictAnyCache[key] as? T
        }
        else if T.self == [String:GUIElementDescription].self {
            return guiElementCache[key] as? T
        }
        else {
            throw "Exception: Could not parse the type to read from \(key)"
        }
    }
}
var globalCache = GlobalCache()

//public struct DataItemReference {
//    let type: DataItemFamily
//    let uid: String
//
//    init(type:DataItemFamily, uid:String) {
//        self.type = type
//        self.uid = uid
//    }
//
//    init(dataItem:DataItem) {
//        type = DataItemFamily(rawValue: dataItem.genericType)! // TODO refactor: error handling
//        uid = dataItem.uid
//    }
//}

public class UserState: Object {
    @objc dynamic var uid: String = DataItem.generateUUID()
    
    let state:String = ""
    
    subscript<T>(propName:String) -> T? {
        get {
            var x:[String:Any]? = try? globalCache.get(uid)
            if x == nil { x = try? transformToDict() }
            
            if T.self == DataItem.self {
                if let lookup = x?[propName] as? [String:Any] {
                    if let type = DataItemFamily(rawValue: lookup["type"] as! String) {
                        let x:DataItem? = realm?.object(
                            ofType: DataItemFamily.getType(type)() as! DataItem.Type,
                            forPrimaryKey: lookup["uid"] as! String)
                        return x as? T
                    }
                }
                
                return nil
            }
            
            return x?[propName] as? T
        }
        set(newValue) {
            var x:[String:Any]? = try? globalCache.get(uid)
            if (x == nil) { x = try? transformToDict() }
            
            if let newValue = newValue as? DataItem {
                x?[propName] = ["type": newValue.genericType, "uid": newValue.uid]
            }
            else {
                x?[propName] = newValue
            }
            
            try? globalCache.set(uid, x)
            
            scheduleWrite()
        }
    }
    
    private func transformToDict() throws -> [String:Any]{
        let dict:[String:AnyDecodable] = unserialize(state)
        try globalCache.set(self.uid, dict as [String:Any])
        return dict
    }
    
    var scheduled = false
    private func scheduleWrite(){
        // Don't schedule when we are already scheduled
        if !scheduled {
            
            // Prevent multiple calls to the dispatch queue
            scheduled = true
            
            // Schedule update
            DispatchQueue.main.async {
                
                // Reset scheduled
                self.scheduled = false
                
                // Update UI
                self.persist()
            }
        }
    }
    
    private func persist(){
        if let x:[String:Any] = try? globalCache.get(uid) {
            realmWriteIfAvailable(self.realm) {
                self["state"] = serialize(AnyCodable(x))
            }
        }
    }
    
    // Requires support for dataItem lookup.
    
    public func toggleState(_ stateName:String) {
        let x:Bool = self[stateName] as? Bool ?? true
        self[stateName] = !x
    }

    public func hasState(_ stateName:String) -> Bool {
        let x:Bool = self[stateName] ?? false
        return x
    }
}
typealias ViewArguments = UserState
    
public class SessionView: DataItem {
 
    override var genericType:String { "sessionview" }
 
    @objc dynamic var name: String? = nil
    @objc dynamic var viewDefinition: SessionViewDefinition? = nil
    @objc dynamic var userState: UserState? = nil
    @objc dynamic var viewArguments: ViewArguments? = nil
    @objc dynamic var queryOptions: QueryOptions? = nil
    
    override var computedTitle:String {
//        if let value = self.name ?? self.title { return value }
//        else if let rendererName = self.rendererName {
//            return "A \(rendererName) showing: \(self.queryOptions?.query ?? "")"
//        }
//        else if let query = self.queryOptions?.query {
//            return "Showing: \(query)"
//        }
        return "[No Name]"
    }
    
    required init(){
        super.init()
        
        self.functions["computedDescription"] = {_ in
            print("MAKE THIS DISSAPEAR")
            return self.computedTitle
        }
    }
}
