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
    
    private func execExpression<T>(_ expr:Expression) -> T? {
        do {
            let x:Any? = try expr.execForReturnType(viewArguments)
            let value:T? = transformActionArray(x)
            if value == nil { return nil }
            else { return value }
        }
        catch let error {
            debugHistory.error("\(error)")
            return nil
        }
    }
    
    private func transformActionArray<T>(_ value:Any?) -> T? {
        var result:[Any?] = []
        if let inspect = value as? [Any?] {
            for v in inspect {
                if let expr = v as? Expression {
                    let x:Any? = execExpression(expr)
                    result.append(x)
                }
                else {
                    result.append(v)
                }
            }
        }
        
        if result.count > 0 {
            if let value = result as? [Action], T.self == Action.self {
                return (ActionMultiAction(value[0].context, arguments: ["actions": value]) as? T)
            }
            
            return result as? T
        }
        else { return value as? T }
    }
    
    func cascadeProperty<T>(_ name:String) -> T? {
        if let expr = localCache[name] as? Expression {
            return execExpression(expr)
        }
        
        if localCache[name] != nil {
            return transformActionArray(localCache[name])
        }

        for def in cascadeStack {
            if let expr = def[name] as? Expression {
                localCache[name] = expr
                return cascadeProperty(name) as T?
            }
            if def[name] != nil {
                localCache[name] = def[name]
                return transformActionArray(def[name])
            }
        }

        return nil
    }

    
    // TODO support deleting items
    func cascadeList<T>(_ name:String, merge:Bool = true) -> [T] {
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
