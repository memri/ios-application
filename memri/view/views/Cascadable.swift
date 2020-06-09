//
//  Cascadable.swift
//  memri
//
//  Created by Ruben Daniels on 5/24/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

public class Cascadable {
    var viewArguments: ViewArguments
    var cascadeStack: [CVUParsedDefinition]
    var localCache = [String:Any?]()
    
    func cascadeProperty<T>(_ name:String) -> T? {
        if let expr = localCache[name] as? Expression {
            do { return try expr.execForReturnType(viewArguments) }
            catch let error {
                errorHistory.error("\(error)")
                return nil
            }
        }
        
        if let x = localCache[name] as? T { return x }
        
        for def in cascadeStack {
            if let expr = def[name] as? Expression {
                localCache[name] = expr
                return cascadeProperty(name)
            }
            if let x = def[name] as? T {
                localCache[name] = x
                return x
            }
        }
        
        return nil
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
    
    
    func cascadeDict<T>(_ name:String, _ defaultDict:[String:T] = [:],
                        forceArray:Bool = false) -> [String:T] {
        
        if let x = localCache[name] as? [String:T] { return x }
        
        var result = defaultDict
        
        if forceArray {
            for def in cascadeStack {
                if let x = def[name] as? [String:Any?] {
                    for (key, value) in x {
                        if let value = value as? T {
                            result[key] = value
                        }
                        else if let value = [value] as? T {
                            result[key] = value
                        }
                        else {
                            // TODO WARN
                        }
                    }
                }
                else {
                    // TODO WARN
                }
            }
        }
        else {
            for def in cascadeStack {
                if let x = def[name] as? [String:T] {
                    result.merge(x)
                }
                else {
                    // TODO WARN
                }
            }
        }
        
        localCache[name] = result
        return result
    }
    
    init(_ cascadeStack: [CVUParsedDefinition], _ viewArguments: ViewArguments) {
        self.viewArguments = viewArguments
        self.cascadeStack = cascadeStack
    }
}
