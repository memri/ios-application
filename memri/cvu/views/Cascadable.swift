//
// Cascadable.swift
// Copyright © 2020 memri. All rights reserved.

import CoreGraphics
import Foundation
import SwiftUI
import Realm

enum SelectorType {
    case singleItem
    case list
}

public class Cascadable: CustomStringConvertible {
    var host: Cascadable?
    var cascadeStack: [CVUParsedDefinition]
    var tail: [CVUParsedDefinition]
    var head: CVUParsedDefinition
    var localCache = [String: Any?]()

    var viewArguments: ViewArguments? {
        get { host?.viewArguments }
        set(value) { host?.viewArguments = value }
    }

    public var description: String {
        var merged = [String: Any?]()

        func recur(_ dict: [String: Any?]?) {
            guard let dict = dict else { return }
            for (key, value) in dict {
                merged[key] = value
            }
        }
        recur(head.parsed)
        for item in tail { recur(item.parsed) }

        return CVUSerializer.dictToString(merged, 0, "    ")
    }

    private func execExpression<T>(_ expr: Expression) -> T? {
        do {
            let x: Any? = try expr.execute(viewArguments)
            let value: T? = transformActionArray(x)
            if value == nil { return nil }
            else { return value }
        }
        catch {
            debugHistory.error("\(error)")
            return nil
        }
    }

    private func transformActionArray<T>(_ value: Any?) -> T? {
        var result: [Any?] = []
        if let inspect = value as? [Any?] {
            for v in inspect {
                if let expr = v as? Expression {
                    let x: Any? = execExpression(expr)
                    result.append(x)
                }
                else {
                    result.append(v)
                }
            }
        }

        if result.count > 0 {
            if let value = result as? [Action], T.self == Action.self {
                return (ActionMultiAction(value[0].context, values: ["actions": value]) as? T)
            }

            return result as? T
        }
        else { return value as? T }
    }

    func setState(_ propName: String, _ value: Any?) {
        head[propName] = value
        localCache.removeValue(forKey: propName)
    }

    func isSet() -> Bool {
        head.parsed?.count ?? 0 > 0 || tail.count > 0
    }

    func cascadePropertyAsCGFloat(_ name: String)
        -> CGFloat? { // Renamed to avoid mistaken calls when comparing to nil
        (cascadeProperty(name) as Double?).map { CGFloat($0) }
    }

    func cascadeProperty<T>(_ name: String, type _: T.Type = T.self) -> T? {
        #if DEBUG
            // These are temporary checks put in place to catch programmer errors. We should find a safer way that won't lose CVU properties. It is wrapped in DEBUG flag so will not crash in testflight.
            if T.self == CGFloat.self {
                fatalError("You need to use the `cascadePropertyAsCGFloat` function instead")
            }
            if T.self == Int.self {
                fatalError("You need to request a Double and then case to integer instead")
            }
        #endif
        if let expr = localCache[name] as? Expression {
            if T.self == Expression.self {
                return expr as? T // We're requesting the Expression (not just the resolved value)
            }
            else {
                return execExpression(expr)
            }
        }
        else if let local = localCache[name] {
            return transformActionArray(local)
        }

        for def in cascadeStack {
            if let expr = def[name] as? Expression {
                localCache[name] = expr
                if T.self == Expression.self {
                    return expr as? T // We're requesting the Expression (not just the resolved value)
                }
                else {
                    return cascadeProperty(name) as T?
                }
            }
            if def[name] != nil {
                localCache[name] = def[name]
                return transformActionArray(def[name])
            }
        }

        return nil
    }
    

    func cascadeList(
        _ name: String,
        uniqueKey: ([String: Any]) -> String?,
        merging: ([String: Any], [String: Any]) -> [String: Any]
    ) -> [[String: Any]] {
        if let x = localCache[name] as? [[String: Any]] { return x }

        var result = [Any]()
        var lut = [String: [String: Any]]()

        for def in cascadeStack {
            if let list = def[name] as? [[String: Any]] {
                for item in list {
                    if let key = uniqueKey(item) {
                        if let y = lut[key] {
                            lut[key] = merging(y, item)
                        }
                        else {
                            lut[key] = item
                            result.append(key)
                        }
                    }
                    else {
                        result.append(item)
                    }
                }
            }
        }

        let list = result.map {
            if let key = $0 as? String, let item = lut[key] {
                return item
            }
            else if let item = $0 as? [String: Any] {
                return item
            }
            return [:]
        } as [[String: Any]]

        localCache[name] = list

        return list
    }

    // TODO: support deleting items
    func cascadeList<T>(_ name: String, selectorType: SelectorType? = nil, merge: Bool = true) -> [T] {
        if let x = localCache[name] as? [T] { return x }

        var result = [T]()

        for def in cascadeStack {
            if let selectorType = selectorType {
                // Check if this matches the selector type, otherwise continue to next definition
                switch selectorType {
                case .list:
                    // Only include definitions for list selectors
                    guard def.selectorIsForList else {
                        continue
                    }
                case .singleItem:
                    // Only include definitions for single item selectors
                    guard !def.selectorIsForList else {
                        continue
                    }
                }
            }
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

    func cascadeDict<T>(
        _ name: String,
        _ defaultDict: [String: T] = [:],
        forceArray: Bool = false
    ) -> [String: T] {
        if let x = localCache[name] as? [String: T] { return x }

        var result = defaultDict

        if forceArray {
            for def in cascadeStack {
                if let x = def[name] as? [String: Any?] {
                    for (key, value) in x {
                        if let value = value as? T {
                            result[key] = value
                        }
                        else if let value = [value] as? T {
                            result[key] = value
                        }
                        else {
                            // TODO: WARN
                        }
                    }
                }
                else {
                    // TODO: WARN
                }
            }
        }
        else {
            for def in cascadeStack {
                if let x = def[name] as? [String: T] {
                    result.merge(x, uniquingKeysWith: { a, _ in a })
                }
                else {
                    // TODO: WARN
                }
            }
        }

        localCache[name] = result
        return result
    }

    func cascadeContext<T: Cascadable, P: CVUParsedDefinition>(
        _ propName: String,
        _ lookupName: String,
        _: P.Type,
        _: T.Type = T.self
    ) -> T {
        if let x = localCache[propName] as? T { return x }

        let head = self.head[lookupName] as? P ?? P()
        self.head[lookupName] = head

        let tail = self.tail.compactMap { $0[lookupName] as? P }

        let cascadable = T(head, tail, self)
        localCache[propName] = cascadable
        return cascadable
    }

    required init(
        _ head: CVUParsedDefinition? = nil,
        _ tail: [CVUParsedDefinition]? = nil,
        _ host: Cascadable? = nil
    ) {
        self.host = host
        self.tail = tail ?? []
        self.head = head ?? CVUParsedDefinition()

        cascadeStack = [self.head]
        cascadeStack.append(contentsOf: self.tail)
    }
}
