//
//  DefaultCodingKeys.swift
//  memri
//
//  Created by Koen van der Veen on 06/03/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

//import Foundation

//protocol DefaultingCodingKey: CodingKey, Hashable {
//    static var defaults: [Self: Any] { get }
//}
//
//extension KeyedDecodingContainer where Key: DefaultingCodingKey {
//
//    func decode(_ type: String.Type, forKey key: Key) throws -> String {
//        if let t = try self.decodeIfPresent(type, forKey: key) {
//            return t
//        } else {
//            return Swift.type(of: key).defaults[key] as! String
//        }
//    }
//
//    func decode<T: Codable>(_ type: T.Type, forKey key: Key) throws -> T {
//        if let t = try self.decodeIfPresent(type, forKey: key) {
//            return t
//        } else {
//            return Swift.type(of: key).defaults[key] as! T
//        }
//    }
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
