//
//  File.swift
//
//

import Foundation
import UIKit

extension UIFont {
	func helper_hasTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
		fontDescriptor.symbolicTraits.contains(trait)
	}

	func helper_toggleTrait(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
		var traits = fontDescriptor.symbolicTraits
		traits.formSymmetricDifference([trait])
		guard let newDescriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
		return UIFont(descriptor: newDescriptor, size: 0)
	}
}
