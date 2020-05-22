//
//  string.swift
//  memri
//
//  Created by Ruben Daniels on 5/18/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import CryptoKit

extension String: Error {
    func sha256() -> String {
        // Convert the string to data
        let data = self.data(using: .utf8)!

        // Hash the data
        let digest = SHA256.hash(data: data)

        // Return the hash string
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func test(_ pattern:String, _ options:String = "i") -> Bool {
        return match(pattern, options).count > 0
    }
    
    // TODO Refactor: optimize regex match
//    var expressions = [String: NSRegularExpression]()
//    public extension String {
//        func match(_ regex: String) -> String? {
//            let expression: NSRegularExpression
//            if let exists = expressions[regex] {
//                expression = exists
//            } else {
//                expression = try! NSRegularExpression(pattern: "^\(regex)", options: [])
//                expressions[regex] = expression
//            }
//
//            let range = expression.rangeOfFirstMatch(in: self, options: [], range: NSMakeRange(0, self.utf16.count))
//            if range.location != NSNotFound {
//                return (self as NSString).substring(with: range)
//            }
//            return nil
//        }
//    }
    
    // let pattern = #"\{([^\.]+).(.*)\}"#
    func match(_ pattern:String, _ options:String = "i") -> [String] {
        var nsOptions:NSRegularExpression.Options = NSRegularExpression.Options()
        for chr in options {
            if chr == "i" { nsOptions.update(with: .caseInsensitive) }
        }
        
        let regex = try! NSRegularExpression(pattern: pattern, options: nsOptions)
        var matches:[String] = []
        
        // Weird complex way to execute a regex
        let nsrange = NSRange(self.startIndex..<self.endIndex, in: self)
        regex.enumerateMatches(in: self, options: [], range: nsrange) { (match, _, stop) in
            guard let match = match else { return }

            for i in 0..<match.numberOfRanges {
                let rangeObject = Range(match.range(at: i), in: self)!
                matches.append(String(self[rangeObject]))
            }
        }
        
        return matches
    }
    
    func substr(_ startIndex:Int, _ length:Int? = nil) -> String {
        let start = startIndex < 0
            ? self.index(self.endIndex, offsetBy: startIndex)
            : self.index(self.startIndex, offsetBy: startIndex)
        
        let end = length == nil
            ? self.endIndex
            : length! < 0
                ? self.index(self.startIndex, offsetBy: startIndex + length!)
                : self.index(self.endIndex, offsetBy: length!)
        
        let range = start..<end

        return String(self[range])
    }
    
    func replace(_ target: String, _ withString: String) -> String
    {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.regularExpression, range: nil)
    }
    
    func camelCaseToWords() -> String {
        return unicodeScalars.reduce("") {
            if CharacterSet.uppercaseLetters.contains($1) {
                return ($0 + " " + String($1))
            }
            else {
                return $0 + String($1)
            }
        }
    }
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

