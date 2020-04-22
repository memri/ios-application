//
//  util.swift
//  memri
//
//  Created by Koen van der Veen on 09/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift
import CryptoKit
import SwiftUI

//func decodeFromTuples(_ decoder: Decoder, _ tuples: inout [(Any, String)]) throws{
//    for var (prop, name) in tuples.map({(AnyCodable($0), $1)}){
//        prop = try decoder.decodeIfPresent(name) ?? prop
//    }
//}

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
}

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Date {
    
    
    var timeDelta: String? {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]

        guard let deltaString = formatter.string(from: self, to: Date()) else {
             return nil
        }
        return deltaString
    }
    
   var timestampString: String? {
        guard let timeString = timeDelta else {
             return nil
        }
            let formatString = NSLocalizedString("%@ ago", comment: "")
            return String(format: formatString, timeString)
       }
}

let (MemriJSONEncoder, MemriJSONDecoder) = { () -> (x:JSONEncoder, y:JSONDecoder) in
    var encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    var decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    return (encoder, decoder)
}()

func unserialize<T:Decodable>(_ s:String) -> T {
    let data = s.data(using: .utf8)!
    let output:T = try! MemriJSONDecoder.decode(T.self, from: data)
    return output as T
}

func serialize(_ a:AnyCodable) -> String {
    let data = try! MemriJSONEncoder.encode(a)
    let string = String(data: data, encoding: .utf8)!
    return string
}

func stringFromFile(_ file: String, _ ext:String = "json") throws -> String{
    print("Reading from file \(file).\(ext)")
    let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
    let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
    return jsonString
}

func jsonDataFromFile(_ file: String, _ ext:String = "json") throws -> Data{
    let jsonString = try stringFromFile(file, ext)
    let jsonData = jsonString.data(using: .utf8)!
    return jsonData
}

func jsonErrorHandling(_ decoder: JSONDecoder, _ convert: () throws -> Void) {
    do {
        try convert()
    } catch {
        print("\nJSON Parse Error: \(error.localizedDescription)\n")
    }
}

func getCodingPathString(_ codingPath:[CodingKey]) -> String {
    var path:String = "[Unknown]"
    
    if codingPath.count > 0 {
        path = ""
        for i in 0...codingPath.count - 1 {
            if codingPath[i].intValue == nil {
                if i > 0 { path += "." }
                path += "\(codingPath[i].stringValue)"
            }
            else {
                path += "[\(Int(codingPath[i].intValue ?? -1))]"
            }
        }
    }
    
    return path
}

//extension Error {
//    var debugDescription: String {
//        return "\(String(describing: type(of: self))).\(String(describing: self)) (code \((self as NSError).code))"
//    }
//}

func jsonErrorHandling(_ decoder: Decoder, _ convert: () throws -> Void) {
    let path = getCodingPathString(decoder.codingPath)
    print("Decoding: \(path)")
    
    do {
        try convert()
    }
    catch DecodingError.dataCorrupted(let context) {
        let path = getCodingPathString(context.codingPath)
        print("\nJSON Parse Error at \(path)\nError: \(context.debugDescription)\n")
        raise(SIGINT)
    }
    catch Swift.DecodingError.keyNotFound(_, let context) {
        let path = getCodingPathString(context.codingPath)
        print("\nJSON Parse Error at \(path)\nError: \(context.debugDescription)\n")
        raise(SIGINT)
    }
    catch Swift.DecodingError.typeMismatch(_, let context) {
        let path = getCodingPathString(context.codingPath)
        print("\nJSON Parse Error at \(path)\nError: \(context.debugDescription)\n")
        raise(SIGINT)
    }
    catch {
        dump(error)
        print("\nJSON Parse Error at \(path)\nError: \(error)\n")
        raise(SIGINT)
    }
}

func serializeJSON(_ encode:(_ encoder:JSONEncoder) throws -> Data) -> String? {
    let encoder = MemriJSONEncoder
    encoder.outputFormatting = .prettyPrinted // for debugging purpose

    var json:String? = nil
    do {
        let data = try encode(encoder)
        json = String(data: data, encoding: .utf8) ?? ""
    }
    catch {
        print("\nUnexpected error: \(error.localizedDescription)\n")
    }
    
    return json
}

func decodeIntoList<T:Decodable>(_ decoder:Decoder, _ key:String, _ list:RealmSwift.List<T>) {
    let parsed:[T]? = try! decoder.decodeIfPresent(key)
    if let parsed = parsed {
        for item in parsed {
            list.append(item)
        }
    }
}

func negateAny(_ value:Any) -> Bool {
    if let value = value as? Bool { return !value}
    if let value = value as? Int { return value == 0 }
    if let value = value as? Double { return value == 0 }
    if let value = value as? String { return value == "" }
    
    return false
}
