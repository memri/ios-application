import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport


//let expression = "Hello {test.prop} alsdja ld {try.title}"
let expression = "Hello {test.prop}{try.title} asldaldjs"

// We'll use this regular expression to match the name of the object and property
let pattern = #"(?:([^\{]+)?(?:\{([^\.]+).([^\{]*)\})?)"#
let regex = try! NSRegularExpression(pattern: pattern, options: [])

// Weird complex way to execute a regex
let nsrange = NSRange(expression.startIndex..<expression.endIndex, in: expression)
regex.enumerateMatches(in: expression, options: [], range: nsrange) { (match, _, stop) in
    guard let match = match else { return }
    
    print("found \(match.numberOfRanges - 1) matches")
    
    for i in 0...match.numberOfRanges - 2 {
        if let rangeObject = Range(match.range(at: i + 1), in: expression) {
            print("\(i+1): \(String(expression[rangeObject]))")
        }
    }
//
//    if match.numberOfRanges == 3,
//      let rangeObject = Range(match.range(at: 1), in: expression),
//      let rangeProp = Range(match.range(at: 2), in: expression)
//    {
//        objectToUpdate = String(expression[rangeObject])
//        propToUpdate = String(expression[rangeProp])
//    }
}

//let (obje



