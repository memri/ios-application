//
//  util.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftUI

//func decodeFromTuples(_ decoder: Decoder, _ tuples: inout [(Any, String)]) throws{
//    for var (prop, name) in tuples.map({(AnyCodable($0), $1)}){
//        prop = try decoder.decodeIfPresent(name) ?? prop
//    }
//}

// Run formatter: swift-format . --configuration .swift-format.json

let (MemriJSONEncoder, MemriJSONDecoder) = { () -> (x:JSONEncoder, y:JSONDecoder) in
    var encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    var decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    return (encoder, decoder)
}()

func unserialize<T:Decodable>(_ s:String) -> T? {
    do {
        // NOTE: Allowed forced unwrapping
        let data = s.data(using: .utf8)!
        let output:T = try MemriJSONDecoder.decode(T.self, from: data)
        return output as T
    }
    catch{
        return nil
    }
}

func serialize(_ a:AnyCodable) -> String {
    do {
        // NOTE: Allowed force unwrap
        let data = try MemriJSONEncoder.encode(a)
        let string = String(data: data, encoding: .utf8)!
        return string
    }
    catch {
        print("Failed to encode \(a)")
        return ""
    }
}

func stringFromFile(_ file: String, _ ext:String = "json") throws -> String{
    print("Reading from file \(file).\(ext)")
    let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
    if let fileURL = fileURL{
        let jsonString = try String(contentsOf: fileURL, encoding: String.Encoding.utf8)
        return jsonString
    }
    else {
        throw "Cannot read from \(file) with ext \(ext), path does not result in valid url"
    }
}

func jsonDataFromFile(_ file: String, _ ext:String = "json") throws -> Data{
    let jsonString = try stringFromFile(file, ext)
    // NOTE: Allowed force unwrap
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

func JSONErrorReporter(_ convert: () throws -> Void) throws {
    do {
        try convert()
    }
    catch DecodingError.dataCorrupted(let context) {
        let path = getCodingPathString(context.codingPath)
        throw ("JSON Parse Error at \(path)\nError: \(context.debugDescription)")
    }
    catch Swift.DecodingError.keyNotFound(_, let context) {
        let path = getCodingPathString(context.codingPath)
        throw ("JSON Parse Error at \(path)\nError: \(context.debugDescription)")
    }
    catch Swift.DecodingError.typeMismatch(_, let context) {
        let path = getCodingPathString(context.codingPath)
        throw ("JSON Parse Error at \(path)\nError: \(context.debugDescription)")
    }
    catch {
        throw ("JSON Parse Error: \(error)")
    }
}

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
    do {
        if let parsed:[T] = try decoder.decodeIfPresent(key) {
            for item in parsed {
                list.append(item)
            }
        }
    }
    catch {
        print("Failed to decode into list \(error)")
    }
}


func decodeEdges<T:DataItem>(_ decoder:Decoder, _ key:String, _ subjectType:T.Type,
                             _ edgeList:RealmSwift.List<Edge>, _ subject: DataItem) {
    let objects:[T]? = try! decoder.decodeIfPresent(key)
    if let objects = objects {
        for object in objects {
            do { _ = try globalCache?.addToCache(object) }
            catch {
                // TODO Error logging
            }
            let edge = Edge(subject.memriID, object.memriID, subject.genericType, object.genericType)
            edgeList.append(edge)
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

func realmWriteIfAvailable(_ realm:Realm?, _ doWrite:() -> Void) {
    // TODO Refactor, Error Handling , _ error:(error) -> Void  ??
    if let realm = realm {
        if !realm.isInWriteTransaction {
            try! realm.write { doWrite() }
        }
        else {
            doWrite()
        }
    }
    else {
        doWrite()
    }
}
