//
//  ObjectCache.swift
//  memri
//
//  Created by Ruben Daniels on 5/18/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import RealmSwift

// TODO generalize using Any and one dict for cache (add namespace support)
// TODO wrap all items in a class, so that they are stored by copy i.e. class CacheItem
public class InMemoryObjectCache {
    private var stringCache:[String:String] = [:]
    private var uiImageCache:[String:UIImage] = [:]
    private var dataCache:[String:Data] = [:]
    private var guiElementCache:[String:[String:UIElement]] = [:]
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
        else if T.self == [String:UIElement].self {
            guiElementCache[key] = (value as! [String:UIElement])
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
        else if T.self == [String:UIElement].self {
            return guiElementCache[key] as? T
        }
        else {
            throw "Exception: Could not parse the type to read from \(key)"
        }
    }
}
var globalInMemoryObjectCache = InMemoryObjectCache()
