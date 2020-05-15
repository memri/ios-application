import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport

var arr = ["aasdad","AsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsads","aasdad","AsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsads","aasdad","AsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsads","aasdad","AsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsads","aasdad","AsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsads","aasdad","AsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsads","aasdad","AsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsadsAsdadsasdasdasdadsads"]

let dt = Date()

var x = [String:String]()

for y in stride(from: 0, to: arr.count, by: 2) {
    x[arr[y]] = arr[y+1]
}

print (Date().timeIntervalSince(dt))
