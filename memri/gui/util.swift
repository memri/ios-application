//
// util.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift
import SwiftUI

// Run formatter: swift-format . --configuration .swift-format.json

let (MemriJSONEncoder, MemriJSONDecoder) = { () -> (x: JSONEncoder, y: JSONDecoder) in
    var encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    var decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970

    return (encoder, decoder)
}()

func unserialize<T: Decodable>(_ s: String, type: T.Type = T.self) throws -> T? {
    let data = s.data(using: .utf8) ?? Data()
    let output: T = try MemriJSONDecoder.decode(T.self, from: data)
    return output as T
}

func serialize(_ a: AnyCodable) throws -> String {
    let data = try MemriJSONEncoder.encode(a)
    let string = String(data: data, encoding: .utf8) ?? ""
    return string
}

func stringFromFile(_ file: String, _ ext: String = "json") throws -> String {
    debugHistory.info("Reading from file \(file).\(ext)")
    let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
    if let fileURL = fileURL {
        let jsonString = try String(contentsOf: fileURL, encoding: String.Encoding.utf8)
        return jsonString
    }
    else {
        throw "Cannot read from \(file) with ext \(ext), path does not result in valid url"
    }
}

func jsonDataFromFile(_ file: String, _ ext: String = "json") throws -> Data {
    let jsonString = try stringFromFile(file, ext)
    let jsonData = jsonString.data(using: .utf8) ?? Data()
    return jsonData
}

func jsonErrorHandling(_: JSONDecoder, _ convert: () throws -> Void) {
    do {
        try convert()
    }
    catch {
        print("\nJSON Parse Error: \(error.localizedDescription)\n")
    }
}

func getCodingPathString(_ codingPath: [CodingKey]) -> String {
    var path: String = "[Unknown]"

    if codingPath.count > 0 {
        path = ""
        for i in 0 ... codingPath.count - 1 {
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

func JSONErrorReporter(_ convert: () throws -> Void) throws {
    do {
        try convert()
    }
    catch let DecodingError.dataCorrupted(context) {
        let path = getCodingPathString(context.codingPath)
        throw ("JSON Parse Error at \(path)\nError: \(context.debugDescription)")
    }
    catch let Swift.DecodingError.keyNotFound(_, context) {
        let path = getCodingPathString(context.codingPath)
        throw ("JSON Parse Error at \(path)\nError: \(context.debugDescription)")
    }
    catch let Swift.DecodingError.typeMismatch(_, context) {
        let path = getCodingPathString(context.codingPath)
        throw ("JSON Parse Error at \(path)\nError: \(context.debugDescription)")
    }
    catch {
        throw ("JSON Parse Error: \(error)")
    }
}

func jsonErrorHandling(_ decoder: Decoder, _ convert: () throws -> Void) {
    let path = getCodingPathString(decoder.codingPath)
    //    print("Decoding: \(path)")

    do {
        try convert()
    }
    catch let DecodingError.dataCorrupted(context) {
        let path = getCodingPathString(context.codingPath)
        print("\nJSON Parse Error at \(path)\nError: \(context.debugDescription)\n")
        raise(SIGINT)
    }
    catch let Swift.DecodingError.keyNotFound(_, context) {
        let path = getCodingPathString(context.codingPath)
        print("\nJSON Parse Error at \(path)\nError: \(context.debugDescription)\n")
        raise(SIGINT)
    }
    catch let Swift.DecodingError.typeMismatch(_, context) {
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

func serializeJSON(_ encode: (_ encoder: JSONEncoder) throws -> Data) -> String? {
    let encoder = MemriJSONEncoder
    encoder.outputFormatting = .prettyPrinted // for debugging purpose

    var json: String?
    do {
        let data = try encode(encoder)
        json = String(data: data, encoding: .utf8) ?? ""
    }
    catch {
        print("\nUnexpected error: \(error.localizedDescription)\n")
    }

    return json
}

func decodeEdges(_ decoder: Decoder, _ key: String, _ source: Item) {
    do {
        if let edges: [Edge] = try decoder.decodeIfPresent(key) {
            for edge in edges {
                edge.sourceItemType = source.genericType
                edge.sourceItemID.value = source.uid.value
            }

            source[key] = edges
        }
    }
    catch {
        debugHistory.error("\(error)")
    }
}

/// retrieves item from realm by type and uid.
/// - Parameters:
///   - type: realm type
///   - memriID: item memriID
/// - Returns: retrieved item. If the item does not exist, returns nil.
func getItem(_ type: String, _ uid: Int) -> Item? {
    let type = ItemFamily(rawValue: type)
    if let type = type {
        let item = ItemFamily.getType(type)
        return DatabaseController.current {
            $0.object(ofType: item() as! Object.Type, forPrimaryKey: uid) as? Item
        }
    }
    return nil
}

func me() -> Person {
    do {
        let realm = try DatabaseController.getRealmSync()
        guard let myself = realm.objects(Person.self).filter("ANY allEdges.type = 'me'").first else {
            throw "Unexpected error. Cannot find 'me' in the database"
        }
        return myself
    }
    catch {
        return Person()
    }
}
