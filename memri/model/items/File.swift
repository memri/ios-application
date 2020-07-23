//
//  File.swift
//  memri
//
//  Created by Ruben Daniels on 4/11/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftUI

extension File {
	public var url: URL? {
		uri.flatMap { uuid in
			// Normally we just want the URL
			return FileStorageController.getURLForFile(withUUID: uuid)
		}
	}
	
	public var asUIImage: UIImage? {
		do { if let x: UIImage = try read() { return x } }
		catch {
			// TODO: User error handling
			// TODO: Refactor: error handling
			if let uri = uri, let fileName = uri.components(separatedBy: "/").last {
				// Note that this is a temporary solution. Using UIImage(named:) will only work for files in the app bundle
				return UIImage(named: "DemoAssets/\(fileName)")
			}
			debugHistory.error("Could not read image in path: \(uri ?? "")")
		}
		return nil
	}

	public var asString: String? {
		do { if let x: String = try read() { return x } }
		catch {
			// TODO: User error handling
			// TODO: Refactor: error handling
		}
		return nil
	}

	public var asData: Data? {
		do { if let x: Data = try read() { return x } }
		catch {
			// TODO: User error handling
			// TODO: Refactor: error handling
		}
		return nil
	}

	public func read<T>() throws -> T? {
		guard let uri = uri else { throw "URI Not set" }

		let cachedData: T? = InMemoryObjectCache.global.get(uri) as? T
		if cachedData != nil { return cachedData }

		guard let data = FileStorageController.getData(fromFileForUUID: uri) else { throw "Couldn't read file" }

		let result: T?
		if T.self == UIImage.self {
			result = UIImage(data: data) as? T
		} else if T.self == String.self {
			result = String(data: data, encoding: .utf8) as? T
		} else if T.self == Data.self {
			result = data as? T
		} else {
			throw "Could not parse \(uri)"
		}
		try result.map { try InMemoryObjectCache.global.set(uri, $0) }
		return result
	}
	
	public func read<T: Decodable>() throws -> T? {
		guard let uri = uri else { throw "URI Not set" }
		
		let cachedData: T? = InMemoryObjectCache.global.get(uri) as? T
		if cachedData != nil { return cachedData }
		
		guard let data = FileStorageController.getData(fromFileForUUID: uri) else { throw "Couldn't read file" }
		
		let decoded = try JSONDecoder().decode(T.self, from: data)
		return decoded
	}

	public func write<T>(_ value: T) throws {
		guard let uri = uri else { throw "URI Not set" }

		do {
			var data: Data

			if T.self == UIImage.self {
				guard let pngData = (value as? UIImage)?.pngData() else { throw "Exception: Could not get data for \(uri) as PNG" }
				data = pngData
			} else if T.self == String.self {
				guard let stringData = (value as? String)?.data(using: .utf8) else { throw "Exception: Could not get data for \(uri) as UTF8 String" }
				data = stringData
			} else if T.self == Data.self {
				guard let binaryData = (value as? Data) else { throw "Exception: Could not get data for \(uri) of type \(T.self)" }
				data = binaryData
			} else {
				throw "Exception: Could not parse the type to write to \(uri)"
			}
			
			try FileStorageController.writeData(data, toFileForUUID: uri)
			try InMemoryObjectCache.global.set(uri, value)
		} catch {
			throw "\(error)"
		}
	}
	
	public func write<T: Encodable>(_ value: T) throws {
		guard let uri = uri else { throw "URI Not set" }
		
		do {
			let jsonData = try JSONEncoder().encode(value)
			
			try FileStorageController.writeData(jsonData, toFileForUUID: uri)
			try InMemoryObjectCache.global.set(uri, value)
		} catch {
			throw "\(error)"
		}
	}

	private func getPath() -> String {
		uri ?? ""
	}
}
