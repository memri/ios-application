import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport


enum MemriError: Error {
    case basic
}

func wPrint( _ object: @escaping () -> Any){
    let when = DispatchTime.now() + 0.1
    DispatchQueue.main.asyncAfter(deadline: when) {
        print(object())
    }
}
/*
MODEL
*/


public protocol Renderer: View {
    var name: String {get set}
    var icon: String {get set}
    var category: String {get set}
}













