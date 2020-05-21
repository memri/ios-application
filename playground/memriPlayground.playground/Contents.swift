import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport

class Action {
    var defaults:[String:Any] { return [:] }
    
    init() {
        print(defaults)
    }
}

class Foo : Action {
    override var defaults:[String:Any] {[
        "test": true
    ]}
}

let x = Foo()
