//
// File.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift
import SwiftUI
import CryptoKit

class LocalFileSyncQueue : Object {
    @objc var sha256: String? = nil
    @objc var task: String? = nil
    
    /// Primary key used in the realm database of this Item
    override public static func primaryKey() -> String? {
        "sha256"
    }
    
    public class func add(_ sha256:String, task:String) {
        DatabaseController.current(write:true) { realm in
            if let _ = realm.object(ofType: LocalFileSyncQueue.self, forPrimaryKey: sha256) {
                return
            }
            else {
                realm.create(LocalFileSyncQueue.self, value: ["sha256": sha256, "task": task])
            }
        }
    }
    
    public class func remove(_ sha256:String) {
        DatabaseController.current(write:true) { realm in
            if let fileToUpload = realm.object(ofType: LocalFileSyncQueue.self, forPrimaryKey: sha256) {
                realm.delete(fileToUpload)
            }
        }
    }
}

extension File {
    public var url: URL? {
        guard sha256 != nil else {
            return filename.flatMap { uuid in
                // Normally we just want the URL
                FileStorageController.getURLForFile(withUUID: uuid)
            }
        }
        
        return sha256.flatMap { uuid in
            // Normally we just want the URL
            FileStorageController.getURLForFile(withUUID: uuid)
        }
    }

    public var asUIImage: UIImage? {
        do { if let x: UIImage = try read() { return x } }
        catch {
            // TODO: User error handling
            // TODO: Refactor: error handling
            if sha256 == nil, let fileName = filename {
                // Note that this is a temporary solution. Using UIImage(named:) will only work for files in the app bundle
                return UIImage(named: "DemoAssets/\(fileName)")
            }
            debugHistory.error("Could not read image")
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
    
    private func createSHA256() throws -> String {
        guard let url = url else { throw "SHA256 Not set" }
        
        let bufferSize = 1024 * 1024
        let file = try FileHandle(forReadingFrom: url)
        defer {
            file.closeFile()
        }

        var sha256er = SHA512()
        
        while autoreleasepool(invoking: {
            let data = file.readData(ofLength: bufferSize)
            if data.count > 0 {
                sha256er.update(data: data)
                return true
            } else {
                return false
            }
        }) { }

        let digest = sha256er.finalize()
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func createSHA256(_ data:Data) throws -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    public func queueForDownload() {
        if let sha256 = sha256, !FileStorageController.exists(withUUID: sha256) {
            LocalFileSyncQueue.add(sha256, task: "download")
        }
    }

    public func clearCache() throws {
        guard let sha256 = sha256 else { return }
        
        try FileStorageController.deleteFile(withUUID: sha256)
        InMemoryObjectCache.global.clear(sha256)
        LocalFileSyncQueue.remove(sha256)
    }

    public func read<T>() throws -> T? {
        guard let sha256 = sha256 else { throw "SHA256 Not set" }

        let cachedData: T? = InMemoryObjectCache.global.get(sha256) as? T
        if cachedData != nil { return cachedData }

        guard let data = FileStorageController.getData(fromFileForUUID: sha256)
        else { throw "Couldn't read file" }

        let result: T?
        if T.self == UIImage.self {
            result = UIImage(data: data) as? T
        }
        else if T.self == String.self {
            result = String(data: data, encoding: .utf8) as? T
        }
        else if T.self == Data.self {
            result = data as? T
        }
        else {
            throw "Could not parse \(sha256)"
        }
        try result.map { try InMemoryObjectCache.global.set(sha256, $0) }
        return result
    }

    public func read<T: Decodable>() throws -> T? {
        guard let sha256 = sha256 else { throw "SHA256 Not set" }

        let cachedData: T? = InMemoryObjectCache.global.get(sha256) as? T
        if cachedData != nil { return cachedData }

        guard let data = FileStorageController.getData(fromFileForUUID: sha256)
        else { throw "Couldn't read file" }

        let decoded = try JSONDecoder().decode(T.self, from: data)
        try InMemoryObjectCache.global.set(sha256, decoded)
        return decoded
    }

    public func write<T>(_ value: T) throws {
        do {
            var data: Data

            if T.self == UIImage.self {
                guard let pngData = (value as? UIImage)?.pngData()
                else { throw "Exception: Could not get data as PNG" }
                data = pngData
            }
            else if T.self == String.self {
                guard let stringData = (value as? String)?.data(using: .utf8)
                else { throw "Exception: Could not get data as UTF8 String" }
                data = stringData
            }
            else if T.self == Data.self {
                guard let binaryData = (value as? Data)
                else { throw "Exception: Could not get data of type \(T.self)" }
                data = binaryData
            }
            else {
                throw "Exception: Could not parse data to write"
            }
            
            let lastSHA256 = self["sha256"] as? String
            
            let sha256 = try createSHA256(data)
            self.set("sha256", sha256)

            try FileStorageController.writeData(data, toFileForUUID: sha256)
            try InMemoryObjectCache.global.set(sha256, value)
            LocalFileSyncQueue.add(sha256, task:"upload")
            
            // Cleanup
            if let lastSHA256 = lastSHA256, lastSHA256 != sha256 {
                try FileStorageController.deleteFile(withUUID: lastSHA256)
                InMemoryObjectCache.global.clear(lastSHA256)
                LocalFileSyncQueue.remove(lastSHA256)
            }
        }
        catch {
            throw "\(error)"
        }
    }

    public func write<T: Encodable>(_ value: T) throws {
        do {
            let jsonData = try JSONEncoder().encode(value)
            let lastSHA256 = self["sha256"] as? String
            
            let sha256 = try createSHA256(jsonData)
            self.set("sha256", sha256)

            try FileStorageController.writeData(jsonData, toFileForUUID: sha256)
            try InMemoryObjectCache.global.set(sha256, value)
            LocalFileSyncQueue.add(sha256, task:"upload")
            
            // Cleanup
            if let lastSHA256 = lastSHA256, lastSHA256 != sha256 {
                try FileStorageController.deleteFile(withUUID: lastSHA256)
                InMemoryObjectCache.global.clear(lastSHA256)
                LocalFileSyncQueue.remove(lastSHA256)
            }
        }
        catch {
            throw "\(error)"
        }
    }
}
