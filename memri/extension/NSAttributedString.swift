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
