import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport



extension String {
    mutating func replace(_ pattern: String, with: String = "") {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: with)
        } catch {
            return
        }
    }
}

var x = "a b 9 d 1"
x.replace(#"(\d)"#, with: "-$1")
