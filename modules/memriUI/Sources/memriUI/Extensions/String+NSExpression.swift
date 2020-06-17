//
//  File.swift
//  
//

import Foundation

extension String {
    var isOnlyWhitespace: Bool {
        !contains { !$0.isWhitespace }
    }
    
    func replacePartsMatchingExpression(_ exp: NSRegularExpression, with string: String) -> String {
        let mutable = NSMutableString(string: self)
        let range = NSMakeRange(0, mutable.length)
        exp.replaceMatches(in: mutable, options: [], range: range, withTemplate: string)
        return mutable as String
    }
    
    func removePartsMatchingExpression(_ exp: NSRegularExpression) -> String {
        replacePartsMatchingExpression(exp, with: "")
    }
}
