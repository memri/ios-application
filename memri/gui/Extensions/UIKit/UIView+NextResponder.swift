//
//  UIView+NextResponder.swift
//  MemriPlayground
//
//  Created by Toby Brennan

import Foundation
import UIKit

extension UIView {
	func findAllResponderViews(maxLevels: Int = 3) -> [UIView] {
		let responders: [UIView] = subviews.flatMap { view -> [UIView] in
			guard view.isUserInteractionEnabled, !view.isHidden, view.alpha > 0 else { return [] }
			if view.canBecomeFirstResponder {
				return [view]
			} else {
				guard maxLevels > 0 else { return [] }
				return view.findAllResponderViews(maxLevels: maxLevels - 1)
			}
		}

		// subviews are returning in opposite order. Sorting according the frames 'y'.
		return responders.sorted(by: { (view1: UIView, view2: UIView) -> Bool in

			let frame1 = view1.convert(view1.bounds, to: self)
			let frame2 = view2.convert(view2.bounds, to: self)

			if frame1.minY != frame2.minY {
				return frame1.minY < frame2.minY
			} else {
				return frame1.minX < frame2.minX
			}
        })
	}

	func nextSuperviewOfType() -> UIView? {
		guard let superview = superview else { return nil }
		switch superview {
		case is UICollectionView:
			return superview
		case is UITableView:
			return superview
		case is UIScrollView:
			return superview
		default:
			return superview.nextSuperviewOfType()
		}
	}

	func moveToNextResponder(forward: Bool = true) {
		let allFields = nextSuperviewOfType()?.findAllResponderViews(maxLevels: 10) ?? []
		let currentIndex = allFields.firstIndex(of: self)
		let nextIndex = currentIndex.map { $0 + (forward ? 1 : -1) }
		guard let index = nextIndex, allFields.indices.contains(index) else {
			resignFirstResponder()
			return
		}
		allFields[index].becomeFirstResponder()
	}
}
