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
        let data = s.data(using: .utf8) ?? Data()
        let output:T = try MemriJSONDecoder.decode(T.self, from: data)
        return output as T
    }
    catch{
        return nil
    }
}

func serialize(_ a:AnyCodable) -> String {
    do {
        let data = try MemriJSONEncoder.encode(a)
        let string = String(data: data, encoding: .utf8) ?? ""
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
    let jsonData = jsonString.data(using: .utf8) ?? Data()
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
//    print("Decoding: \(path)")
    
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
    do {
        let objects:[T]? = try decoder.decodeIfPresent(key)
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
    catch let error {
        debugHistory.error("\(error)")
    }
}

func realmWriteIfAvailable(_ realm:Realm?, _ doWrite:() throws -> Void) {
    // TODO Refactor, Error Handling , _ error:(error) -> Void  ??
    do {
        if let realm = realm {
            if !realm.isInWriteTransaction {
                // TODO: Error handling (this can happen for instance if you pass a
                // non existing property string to dataItem.set())
                try! realm.write { try doWrite() }
            }
            else {
                try doWrite()
            }
        }
        else {
            try doWrite()
        }
    }
    catch let error {
        debugHistory.error("Realm Error: \(error)")
    }
}

func withRealm(_ doThis:(_ realm:Realm) -> Void) {
    do {
        let realm = try Realm()
        doThis(realm)
    }
    catch let error {
        debugHistory.error("\(error)")
    }
}

func withRealm(_ doThis:(_ realm:Realm) -> Any?) -> Any? {
    do {
        let realm = try Realm()
        return doThis(realm)
    }
    catch let error {
        debugHistory.error("\(error)")
    }
    return nil
}

/// retrieves item from realm by type and uid.
/// - Parameters:
///   - type: realm type
///   - memriID: item memriID
/// - Returns: retrieved item. If the item does not exist, returns nil.
func getDataItem(_ type:String, _ memriID: String) -> DataItem? {
    let type = DataItemFamily(rawValue: type)
    if let type = type {
        let item = DataItemFamily.getType(type)
        return withRealm { realm in
            realm.object(ofType: item() as! Object.Type, forPrimaryKey: memriID)
        } as? DataItem
    }
    return nil
}

func getDataItem(_ edge:Edge) -> DataItem? {
    if let family = DataItemFamily(rawValue: edge.objectType) {
        return withRealm { realm in
            realm.object(ofType: family.getType() as! Object.Type,
                         forPrimaryKey: edge.objectMemriID)
        } as? DataItem
    }
    return nil
}

func dataItemListToArray(_ object:Any) -> [DataItem] {
    var collection:[DataItem] = []
    
    if let list = object as? List<Note> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Label> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Photo> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Video> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Audio> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<File> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Person> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<AuditItem> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Sessions> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<PhoneNumber> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Website> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Location> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Address> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Country> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Company> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<PublicKey> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<OnlineProfile> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Diet> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<MedicalCondition> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Session> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<SessionView> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<CVUStoredDefinition> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Importer> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Indexer> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<ImporterInstance> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<IndexerInstance> { list.forEach{ collection.append($0) } }
    else if let list = object as? List<Edge> {
        withRealm { realm -> Void in
            for edge in list {
                let objectType = edge.objectType
                let objectId = edge.objectMemriID
                
                if let family = DataItemFamily(rawValue: objectType),
                   let type = family.getType() as? Object.Type {
                    
                    if let item = realm.object(ofType: type, forPrimaryKey: objectId) as? DataItem {
                        collection.append(item)
                    }
                    else {
                        // TODO Error handling
                        debugHistory.error("Unknown type \(objectType) for dataItem \(objectId)")
                        print("Could not find object of type \(type) with memriID \(objectId)")
                    }
                }
                else {
                    // TODO user warning
                    debugHistory.error("Unknown type \(objectType) for dataItem \(objectId)")
                    print("Unknown type \(objectType) for dataItem \(objectId)")
                }
            }
        }
    }

    return collection
}
