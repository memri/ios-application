//
//  NSAttributedString+SafeReplace.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import Foundation

extension NSMutableAttributedString {
    // MARK: - Safe methods

    func safeReplaceCharactersInRange(_ range: NSRange, withString str: String) {
        if isSafeRange(range) {
            replaceCharacters(in: range, with: str)
        }
    }

    func safeReplaceCharactersInRange(_ range: NSRange, withAttributedString attrStr: NSAttributedString) {
        if isSafeRange(range) {
            replaceCharacters(in: range, with: attrStr)
        }
    }

    func safeAddAttributes(_ attrs: [NSAttributedString.Key : Any], range: NSRange) {
        if isSafeRange(range) {
            addAttributes(attrs, range: range)
        }
    }
}

extension NSAttributedString {
    func safeAttribute(_ attrName: String, atIndex location: Int, effectiveRange range: NSRangePointer?, defaultValue: AnyObject?) -> AnyObject? {
        var attributeValue: AnyObject? = nil

        if location >= 0 && location < string.length() {
            attributeValue = attribute(NSAttributedString.Key(rawValue: attrName), at: location, effectiveRange: range) as AnyObject?
        }

        return attributeValue == nil ? defaultValue : attributeValue
    }

    func isSafeRange(_ range: NSRange) -> Bool {
        if range.location < 0 {
            return false
        }

        let maxLength = range.location + range.length
        if maxLength <= string.length() {
            return true
        } else {
            return false
        }
    }
}

extension String {
    // Return real length of String. it's not absolute equal String.characters.count
    func length() -> Int {
        return NSString(string: self).length
    }
}
