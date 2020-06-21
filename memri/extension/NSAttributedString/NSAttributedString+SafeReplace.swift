//
//  NSAttributedString+SafeReplace.swift
//  LEOTextView
//
//  Created by Leonardo Hammer on 21/04/2017.
//
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    // MARK: - Safe methods

    func safeReplaceCharactersInRange(_ range: NSRange, withString str: String) {
        if isSafeRange(range) {
            replaceCharacters(in: range, with: str)
        }else{
            print("WARNING, CANNOT ADD ATTRIBUTES (NOT SAFE RANGE)")
        }
    }

    func safeReplaceCharactersInRange(_ range: NSRange, withAttributedString attrStr: NSAttributedString) {
        if isSafeRange(range) {
            replaceCharacters(in: range, with: attrStr)
        }else{
            print("WARNING, CANNOT ADD ATTRIBUTES (NOT SAFE RANGE)")
        }
    }

    func safeAddAttributes(_ attrs: [NSAttributedString.Key : Any], range: NSRange) {
        if isSafeRange(range) {
            addAttributes(attrs, range: range)
        }else{
            print("WARNING, CANNOT ADD ATTRIBUTES (NOT SAFE RANGE)")
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

extension NSAttributedString {
    func toHTML() -> String? {
        do {
            let rtfData = try self.data(from: NSRange(location: 0, length: self.length), documentAttributes:[.documentType: NSAttributedString.DocumentType.html]);
            let string = String(data: rtfData, encoding: .utf8)
            guard let theString = string else {
                print("Could not convert NSAttributedString to rtf")
                return nil
            }
            return theString
        } catch {
            print("Error, could not convert NSAttributedString to rtf:", error)
            return nil
        }
    }
    
    static func fromHTML(_ string: String) -> NSAttributedString? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
    }
    
}

extension String {
    func firstLineString() -> String? {
        guard !isEmpty else { return "" }
        let firstLineRange = lineRange(for: startIndex...startIndex)
        let firstLineString: String = self[firstLineRange].trimmingCharacters(in: .newlines)
        
        guard firstLineString.contains(where: { !$0.isWhitespace }) else { return nil }
        return firstLineString
    }
    
    
    func secondLineString() -> String? {
        withoutFirstLine().firstLineString()
    }
    
    func withoutFirstLine() -> String {
        guard !isEmpty else { return "" }
        let firstLineRange = lineRange(for: startIndex...startIndex)
        return String(self[firstLineRange.upperBound...])
    }
}
