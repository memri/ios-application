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
    func toRTF() -> String? {
        do {
            let rtfData = try self.data(from: NSRange(location: 0, length: self.length), documentAttributes:[.documentType: NSAttributedString.DocumentType.rtf]);
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
    
    static func fromRTF(_ string: String) -> NSAttributedString? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
    }
    
    func firstLineString() -> String? {
        let theString = string as NSString
        let firstLineRange = theString.lineRange(for: NSRange(location: 0, length: 0))
        let firstLineString: String = theString.substring(with: firstLineRange).trimmingCharacters(in: .newlines)
        guard firstLineString.contains(where: { !$0.isWhitespace }) else { return nil }
        return firstLineString
    }
}

