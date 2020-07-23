//
// CodablePublishedExtension.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

extension Published: Decodable where Value: Decodable {
    public init(from decoder: Decoder) throws {
        let decoded = try Value(from: decoder)
        self = Published(initialValue: decoded)
    }
}

// AnyDecodable
// extension Published:Decodable where Value:AnyDecodable {
//    public init(from decoder: Decoder) throws {
//        let decoded = try Value(from:decoder)
//        self = Published(initialValue:decoded)
//    }
// }

extension Published: Encodable where Value: Decodable {
    public func encode(to encoder: Encoder) throws {
        let mirror = Mirror(reflecting: self)
        if let valueChild = mirror.children.first(where: { $0.label == "value"
        }) {
            if let value = valueChild.value as? Encodable {
                do {
                    try value.encode(to: encoder)
                    return
                }
                catch {
                    assertionFailure("Failed encoding: \(self) - \(error)")
                }
            }
            else {
                assertionFailure("Decodable Value not decodable. Odd \(self)")
            }
        }
        else {
            assertionFailure("There is no value! :\(self)")
        }
    }
}
