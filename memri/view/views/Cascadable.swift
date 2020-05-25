//
//  Cascadable.swift
//  memri
//
//  Created by Ruben Daniels on 5/24/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

public class Cascadable {
    var cascadeStack = [CVUParsedDefinition]()
    var localCache = [String:Any]()
    
    // TODO execute x when Expression
    func cascadeProperty<T>(_ name:String, _ defaultValue:T) -> T {
        if let x = localCache[name] as? T { return x }
        
        for def in cascadeStack {
            if let x = def[name] as? T {
                localCache[name] = x
                return x
            }
        }
        
        return defaultValue
    }
    
    
    // TODO support deleting items
    func cascadeList<T>(_ name:String, _ merge:Bool = true) -> [T] {
        if let x = localCache[name] as? [T] { return x }
        
        var result = [T]()
        
        for def in cascadeStack {
            if let x = def[name] as? [T] {
                if !merge {
                    localCache[name] = x
                    return x
                }
                else {
                    result.append(contentsOf: x)
                }
            }
            else if let x = def[name] as? T {
                if !merge {
                    localCache[name] = [x]
                    return [x]
                }
                else {
                    result.append(x)
                }
            }
        }
        
        localCache[name] = result
        return result
    }
    
    
    func cascadeDict<T>(_ name:String, _ defaultDict:[String:T] = [:]) -> [String:T] {
        if let x = localCache[name] as? [String:T] { return x }
        
        var result = defaultDict
        
        for def in cascadeStack {
            if let x = def[name] as? [String:T] {
                result.merge(x)
            }
        }
        
        localCache[name] = result
        return result
    }
}
