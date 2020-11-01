//
// UIKit+FirstResponder.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import UIKit

public func dismissCurrentResponder() {
    UIApplication.shared.windows.first?.findFirstResponder()?.resignFirstResponder()
}

public extension UIViewController {
    func findFirstResponder() -> UIView? {
        view.findFirstResponder()
    }
}

public extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }
        else {
            for subview in subviews {
                if let found = subview.findFirstResponder() {
                    return found
                }
            }
        }
        return nil
    }
}
