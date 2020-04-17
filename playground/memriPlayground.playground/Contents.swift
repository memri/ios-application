import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport

var expr = ". is atest"

print (expr
    .split(separator: ".", omittingEmptySubsequences: false) )
//    .map{ String($0) })
