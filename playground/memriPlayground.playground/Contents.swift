import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport

//protocol DefaultingCodingKey: CodingKey, Hashable {
//    static var defaults: [Self: Any] { get }
//}
//
//extension KeyedDecodingContainer where Key: DefaultingCodingKey {
//
//    func decode(_ type: String.Type, forKey key: Key) throws -> String {
//        print("DEF")
//        if let t = try self.decodeIfPresent(type, forKey: key) {
//            return t
//        } else {
//            return Swift.type(of: key).defaults[key] as! String
//        }
//    }
//
//    func decode(_ type: String.Type, forKey key: Key) throws -> String? {
//        print("DEF")
//
//        if let t = try self.decodeIfPresent(type, forKey: key) {
//            return t
//        } else {
//            return Swift.type(of: key).defaults[key] as! String
//        }
//    }
//
//
//    func decode<T: Codable>(_ type: T.Type, forKey key: Key) throws -> T {
//        if let t = try self.decodeIfPresent(type, forKey: key) {
//            return t
//        } else {
//            print(type)
//            print(key)
//            print(Swift.type(of: key))
//            print(self.allKeys)
//            print
//            return Swift.type(of: key).defaults[key] as! T
//        }
//    }
//
//
//
//    func decode<T: Codable>(_ type: T.Type, forKey key: Key) throws -> T? {
//        if let t = try self.decodeIfPresent(type, forKey: key) {
//            return t
//        } else {
//            print(type)
//            print(key)
//            print(Swift.type(of: key))
//            print(self.allKeys)
//            print
//            return Swift.type(of: key).defaults[key] as! T
//        }
//    }
//
//}
//
//extension KeyedEncodingContainer where Key: DefaultingCodingKey {
//
//    mutating func encode(_ value: String, forKey key: Key) throws {
//        guard value != type(of: key).defaults[key] as! String else { return }
//        try self.encodeIfPresent(value, forKey: key)
//    }
//
//    mutating func encode<T: Encodable & Equatable>(_ value: [T], forKey key: Key) throws {
//        guard value != type(of: key).defaults[key] as! [T] else { return }
//        try self.encodeIfPresent(value, forKey: key)
//    }
//
//    mutating func encode<T: Encodable & Equatable>(_ value: T, forKey key: Key) throws {
//        guard value != type(of: key).defaults[key] as! T else { return }
//        try self.encodeIfPresent(value, forKey: key)
//    }
//
//}

class Test: Codable {

    public var name: String = "abc"
    public var styles: [String]? = ["default styles"]

//    enum CodingKeys: String, CodingKey {
//        case name, styles
//    }
    
    init(name: String = "", styles: [String]? = []){
        self.name=name
        self.styles=styles
    }

    required init (from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        var props: [AnyDecodable] = [self.name, self.styles]
        for var prop in props{
            print(CodingKeys.name)
            prop = try values.decodeIfPresent(Swift.type(of: self.name).self, forKey: CodingKeys.name) ?? prop
//            print(prop)
        }
        print(CodingKeys(stringValue: "name")!)
        
//        name = try values.decodeIfPresent(Swift.type(of: self.name).self, forKey: .name) ?? self.name
//
//        styles = try values.decodeIfPresent([String]?.self, forKey: .styles) ?? ["default styles"]
    }
}


//let x = Test()
//
//let encoder = JSONEncoder()
//
//let json = try! encoder.encode(x)
//print(String(data: json, encoding: .utf8)!)
//
let decoder = JSONDecoder()
//
//let a = try! decoder.decode(Test.self, from: json)
//print(a.name)
//print(a.styles)
//let decoder = JSONDecoder()

let refWithName = "{\"name\": \"Randy\"}"
let b = try! decoder.decode(Test.self, from: refWithName.data(using: .utf8)!)
print(b.name)
print(b.styles)

//print()
//
//let ref = "{\"name\": \"Randy\", \"styles\": [\"Swifty\"]}"
//let c = try! decoder.decode(Test.self, from: ref.data(using: .utf8)!)
//print(c.name)
//print(c.styles)












