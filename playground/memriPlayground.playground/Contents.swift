import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport

let x = Date()
let y = "\"2020-03-10T11:11:11Z\""

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601

let data = try! encoder.encode(x)
let string = String(data: data, encoding: .utf8)!

print(x.description)
print(string)

let d:Date = try! decoder.decode(Date.self, from: y.data(using: .utf8)!)
print(d.description)
