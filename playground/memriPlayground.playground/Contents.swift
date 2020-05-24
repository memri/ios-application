import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport


let x = [(1,1,"a"),(1,1,"b"),(0,0,"a"),(0,0,"b"),(0,1,"a"),(0,1,"b")]

print(x.sorted(by: { lhp, rhp in
    return lhp < rhp
}))
