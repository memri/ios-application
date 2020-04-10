import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport

var collection: [String:Any] = [:]

//public func get3<T:Decodable>(_ path:String) -> T? {
//    return get2(path) as! T?
//}

public func get2<T:Decodable>(_ path:String) -> T {
    return get1(path)! as T
//    return x
}

public func get1<T:Decodable>(_ path:String) -> T? {
    return collection[path] as! T?
}

public func set(_ path:String, _ value:Any) -> Void {
    collection[path] = value
}

set("test", true)
var x:Bool = get1("test")!
print(x)
var y:Bool = get2("test")!
print(y)


// PROBLEM STATE
//
//public func get3<T:Decodable>(_ path:String) -> T? {
//    return get2(path) as! T?
//}
//
//public func get2<T:Decodable>(_ path:String) -> T? {
//    return get1(path) as! T?
//}
//
//public func get1<T:Decodable>(_ path:String) -> T? {
//    return collection[path] as! T?
//}
//
//public func set(_ path:String, _ value:Any) -> Void {
//    collection[path] = value
//}
//
//set("test", true)
//var x:Bool = get1("test")!
//print(x)
//var y:Bool = get3("test")!
//print(y)

