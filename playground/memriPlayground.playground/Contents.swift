import Foundation
import PlaygroundSupport
import SwiftUI
import UIKit

let x = Date(timeIntervalSince1970: 10 * 365 * 24 * 60 * 60)

print(x.distance(to: Date()))
