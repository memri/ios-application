//
//  UIView+FirstResponder.swift
//  memri
//
//  Created by Toby Brennan on 21/6/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import UIKit

public func dismissCurrentResponder() {
	UIApplication.shared.windows.first?.findFirstResponder()?.resignFirstResponder()
}

extension UIViewController {
	public func findFirstResponder() -> UIView? {
		view.findFirstResponder()
	}
}

extension UIView {
	public func findFirstResponder() -> UIView? {
		if isFirstResponder {
			return self
		} else {
			for subview in subviews {
				if let found = subview.findFirstResponder() {
					return found
				}
			}
		}
		return nil
	}
}
