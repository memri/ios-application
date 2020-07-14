//
//  NSAttributedString+SafeReplace.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import Foundation
import UIKit

extension NSAttributedString {
	func toHTML() -> String? {
		do {
			let htmlData = try data(from: NSRange(location: 0, length: length), documentAttributes: [.documentType: NSAttributedString.DocumentType.html])
			let string = String(data: htmlData, encoding: .utf8)
			guard let theString = string else {
				print("Could not convert NSAttributedString to html")
				return nil
			}
			return theString
		} catch {
			print("Error, could not convert NSAttributedString to html:", error)
			return nil
		}
	}

	static func fromHTML(_ string: String) -> NSAttributedString? {
		guard let data = string.data(using: .utf8) else { return nil }
		return try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
	}

	func withFontSize(_ size: CGFloat) -> NSAttributedString {
		let systemFontDescriptor = UIFont.systemFont(ofSize: size).fontDescriptor
		let mutableSelf = NSMutableAttributedString(attributedString: self)
		enumerateAttribute(.font, in: NSRange(location: 0, length: length), options: .longestEffectiveRangeNotRequired) { attribute, range, _ in
			guard let oldFont = attribute as? UIFont else { return }
			let traits = oldFont.fontDescriptor.symbolicTraits
			guard let descriptor = systemFontDescriptor.withSymbolicTraits(traits) else { return } // We're intentionally overriding with system font here. There is a NSAttributedString bug that means TimesNewRoman will be used when loading HTML (instead of system)
			let font = UIFont(descriptor: descriptor, size: size)
			mutableSelf.setAttributes([.font: font], range: range)
		}
		return mutableSelf
	}
}

extension String {
	func firstLineString() -> String? {
		guard !isEmpty else { return "" }
		let firstLineRange = lineRange(for: startIndex ... startIndex)
		let firstLineString: String = self[firstLineRange].trimmingCharacters(in: .newlines)

		guard firstLineString.contains(where: { !$0.isWhitespace }) else { return nil }
		return firstLineString
	}

	func withoutFirstLine() -> String {
		guard !isEmpty else { return "" }
		let firstLineRange = lineRange(for: startIndex ... startIndex)
		return String(self[firstLineRange.upperBound...])
	}
}
