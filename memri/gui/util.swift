//
//  util.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftUI

// func decodeFromTuples(_ decoder: Decoder, _ tuples: inout [(Any, String)]) throws{
//    for var (prop, name) in tuples.map({(AnyCodable($0), $1)}){
//        prop = try decoder.decodeIfPresent(name) ?? prop
//    }
// }

// Run formatter: swift-format . --configuration .swift-format.json

let (MemriJSONEncoder, MemriJSONDecoder) = { () -> (x: JSONEncoder, y: JSONDecoder) in
	var encoder = JSONEncoder()
	encoder.dateEncodingStrategy = .millisecondsSince1970
	var decoder = JSONDecoder()
	decoder.dateDecodingStrategy = .millisecondsSince1970

	return (encoder, decoder)
}()

func unserialize<T: Decodable>(_ s: String) throws -> T? {
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
	} else {
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
	} catch {
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
			} else {
				path += "[\(Int(codingPath[i].intValue ?? -1))]"
			}
		}
	}

	return path
}

// extension Error {
//    var debugDescription: String {
//        return "\(String(describing: type(of: self))).\(String(describing: self)) (code \((self as NSError).code))"
//    }
// }

func JSONErrorReporter(_ convert: () throws -> Void) throws {
	do {
		try convert()
	} catch let DecodingError.dataCorrupted(context) {
		let path = getCodingPathString(context.codingPath)
		throw ("JSON Parse Error at \(path)\nError: \(context.debugDescription)")
	} catch let Swift.DecodingError.keyNotFound(_, context) {
		let path = getCodingPathString(context.codingPath)
		throw ("JSON Parse Error at \(path)\nError: \(context.debugDescription)")
	} catch let Swift.DecodingError.typeMismatch(_, context) {
		let path = getCodingPathString(context.codingPath)
		throw ("JSON Parse Error at \(path)\nError: \(context.debugDescription)")
	} catch {
		throw ("JSON Parse Error: \(error)")
	}
}

func jsonErrorHandling(_ decoder: Decoder, _ convert: () throws -> Void) {
	let path = getCodingPathString(decoder.codingPath)
	//    print("Decoding: \(path)")

	do {
		try convert()
	} catch let DecodingError.dataCorrupted(context) {
		let path = getCodingPathString(context.codingPath)
		print("\nJSON Parse Error at \(path)\nError: \(context.debugDescription)\n")
		raise(SIGINT)
	} catch let Swift.DecodingError.keyNotFound(_, context) {
		let path = getCodingPathString(context.codingPath)
		print("\nJSON Parse Error at \(path)\nError: \(context.debugDescription)\n")
		raise(SIGINT)
	} catch let Swift.DecodingError.typeMismatch(_, context) {
		let path = getCodingPathString(context.codingPath)
		print("\nJSON Parse Error at \(path)\nError: \(context.debugDescription)\n")
		raise(SIGINT)
	} catch {
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
	} catch {
		print("\nUnexpected error: \(error.localizedDescription)\n")
	}

	return json
}

// func decodeIntoList<T: Decodable>(_ decoder: Decoder, _ key: String, _ list: RealmSwift.List<T>) {
//	do {
//		if let parsed: [T] = try decoder.decodeIfPresent(key) {
//			for item in parsed {
//				list.append(item)
//			}
//		}
//	} catch {
//		print("Failed to decode into list \(error)")
//	}
// }

func decodeEdges(_ decoder: Decoder, _ key: String, _ source: Item) {
	do {
		if let edges: [Edge] = try decoder.decodeIfPresent(key) {
			for edge in edges {
				edge.sourceItemType = source.genericType
				edge.sourceItemID.value = source.uid.value
			}

			source[key] = edges
		}
	} catch {
		debugHistory.error("\(error)")
	}
}

func realmWriteIfAvailableThrows(_ realm: Realm?, _ doWrite: () throws -> Void) throws {
	if let realm = realm {
		if !realm.isInWriteTransaction {
			// TODO: Error handling (this can happen for instance if you pass a
			// non existing property string to dataItem.set())
			try realm.write { try doWrite() }
		} else {
			try doWrite()
		}
	} else {
		try doWrite()
	}
}

func realmWriteIfAvailable(_ realm: Realm?, _ doWrite: () throws -> Void) {
	// TODO: Refactor, Error Handling , _ error:(error) -> Void  ??
	do {
		try realmWriteIfAvailableThrows(realm, doWrite)
	} catch {
		debugHistory.error("Realm Error: \(error)")
	}
}

func withReadRealm(_ doThis: (_ realm: Realm) -> Any?) -> Any? {
    do { return try withReadRealmThrowsReturn(doThis) }
    catch let error {
        debugHistory.error("Could not read from realm: \(error)")
        return nil
    }
}
func withReadRealmThrows(_ doThis: (_ realm: Realm) throws -> Void) throws {
    let realm = try Realm()
    try doThis(realm)
}
func withReadRealmThrowsReturn(_ doThis: (_ realm: Realm) throws -> Any?) throws -> Any? {
    let realm = try Realm()
    return try doThis(realm)
}
func withWriteRealm(_ doThis: (_ realm: Realm) throws -> Void) {
    do { try withWriteRealmThrows(doThis) }
    catch let error {
        debugHistory.error("Could not read from realm: \(error)")
    }
}
func withWriteRealmThrows(_ doThis: (_ realm: Realm) throws -> Void) throws {
    let realm = try Realm()
    if !realm.isInWriteTransaction {
        try realm.write { try doThis(realm) }
    } else {
        try doThis(realm)
    }
}

let realmWriteQueue = DispatchQueue(label: "memri.sync.realm.write", qos: .utility)

func realmWriteAsync<T: ThreadConfined>(_ object: T, _ doWrite: @escaping (Realm, T) throws -> Void) {
    if object.realm != nil {
        // Handle managed object
        let wrappedObject = ThreadSafeReference(to: object) // Managed instance, needs to be passed safely
        realmWriteAsync(wrappedObject, doWrite)
        return
    } else {
        // Handle unmanaged object
        realmWriteQueue.async {
            autoreleasepool {
                do {
                    let realmInstance = try Realm()
                    try realmInstance.write {
                        try doWrite(realmInstance, object)
                    }
                } catch {
                    // Implement me
                }
            }
        }
    }
}

func realmWriteAsync<T>(_ objectReference: ThreadSafeReference<T>, _ doWrite: @escaping (Realm, T) throws -> Void) {
    realmWriteQueue.async {
        autoreleasepool {
            do {
                let realmInstance = try Realm()
                guard let threadSafeObject = realmInstance.resolve(objectReference) else { return }
                try realmInstance.write {
                    try doWrite(realmInstance, threadSafeObject)
                }
            } catch {
                // Implement me
            }
        }
    }
}

func realmWriteAsync(_ doWrite: @escaping (Realm) throws -> Void) {
    realmWriteQueue.async {
        autoreleasepool {
            do {
                let realmInstance = try Realm()
                try realmInstance.write {
                    try doWrite(realmInstance)
                }
            } catch {
                // Implement me
            }
        }
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
		return withReadRealm { realm in
			realm.object(ofType: item() as! Object.Type, forPrimaryKey: uid)
		} as? Item
	}
	return nil
}

//
// func getItem(_ edge: Edge) -> Item? {
//	if let family = ItemFamily(rawValue: edge.targetType) {
//		return withRealm { realm in
//			realm.object(ofType: family.getType() as! Object.Type,
//						 forPrimaryKey: edge.objectMemriID)
//		} as? Item
//	}
//	return nil
// }

// func dataItemListToArray(_ object: Any) -> [Item] {
//	var collection: [Item] = []
//
//	if let list = object as? Results<Note> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Label> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Photo> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Video> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Audio> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<File> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Person> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<AuditItem> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Sessions> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<PhoneNumber> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Website> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Location> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Address> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Country> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Company> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<PublicKey> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<OnlineProfile> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Diet> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<MedicalCondition> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Session> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<SessionView> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<CVUStoredDefinition> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Importer> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<Indexer> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<ImporterRun> { list.forEach { collection.append($0) } }
//	else if let list = object as? Results<IndexerRun> { list.forEach { collection.append($0) } }
//    else if let list = object as? Results<Edge> { return list.itemsArray() }
//
//	return collection
// }
