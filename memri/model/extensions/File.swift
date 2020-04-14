//
//  File.swift
//  memri
//
//  Created by Ruben Daniels on 4/11/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift

class File:DataItem {
    @objc dynamic var uri:String = ""
    override var type:String { "file" }
    
    public override static func primaryKey() -> String? {
        return "uri"
    }
    
    let usedBy = RealmSwift.List<DataItem>() // TODO make two-way binding in realm
    
    required init () {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        
        jsonErrorHandling(decoder) {
            uri = try decoder.decodeIfPresent("uri") ?? uri
            
            decodeIntoList(decoder, "usedBy", self.usedBy)
            
            try! self.superDecode(from: decoder)
        }
    }
    
    public var asUIImage:UIImage? {
        if let x:UIImage = read() { return x }
        return nil
    }

    public var asString:String? {
        if let x:String = read() { return x }
        return nil
    }
    
    public var asData:Data? {
        if let x:Data = read() { return x }
        return nil
    }
    
    public func read<T>() -> T? {
        var cachedData:T? = try! fileCache.read(self.uri)
        if cachedData != nil { return cachedData }
        
        let data = self.readData()
        if data != nil {
            if T.self == UIImage.self {
                cachedData = (UIImage(data: data!) as! T)
            }
            else if T.self == String.self {
                cachedData = (String(data: data!, encoding: .utf8) as! T)
            }
            else if T.self == Data.self {
                cachedData = (data! as! T)
            }
            else {
                print("Warn: Could not parse \(self.uri)")
                return nil
            }
            
            try! fileCache.add(self.uri, cachedData!)
            return cachedData
        }
        else {
            print("Warn: Could not read data from \(self.uri)")
            return nil
        }
    }
    
    public func write<T>(_ value: T) throws {
        do {
            var data:Data?
            
            if T.self == UIImage.self {
                data = (value as! UIImage).pngData()
                if data == nil { throw "Exception: Could not write \(self.uri) as PNG" }
            }
            else if T.self == String.self {
                data = (value as! String).data(using: .utf8)
                if data == nil { throw "Exception: Could not write \(self.uri) as UTF8 String" }
            }
            else if T.self == Data.self {
                data = (value as! Data)
            }
            else {
                throw "Exception: Could not parse the type to write to \(self.uri)"
            }
            
            try self.writeData(data!)
            try! fileCache.add(self.uri, value)
        }
        catch let error {

            throw "\(error)"
        }
    }
        
    private func getPath() -> String {
        return self.uri
    }
    
    private func writeData(_ data:Data)  throws {
        let path = getPath()

        FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
//        }
//        catch let error {
//            throw "Exception: Could not write to \(path) with Error:\(error)"
//        }
        
//        if let file = FileHandle(forWritingAtPath: path) {
//            file.write(data)
//
//            // Close the file
//            file.closeFile()
//        }
//        else {
//
//        }
    }
    
    private func readData() -> Data? {
        let path = getPath()

//        let databuffer = FileManager.default.contents(atPath: path)
        
        if let file = FileHandle(forReadingAtPath: path) {
            // Read all the data
            let data = file.readDataToEndOfFile()

            // Close the file
            file.closeFile()

            // Return data
            return data
        }
        else {
            print("Warning: Could not read file \(path)")
        }
        
        return nil
    }
    
    // TODO where to save these files properly?
    public class func generateFilePath() -> String {
        let homeDir = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]!
        let url = URL(fileURLWithPath: homeDir)
                    .appendingPathComponent(".memri.cache/File", isDirectory:true)
        
        do {
            try FileManager.default.createDirectory(atPath: url.relativePath,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }
        catch {
            print(error)
        }
        
        let fileName = UUID().uuidString
        return url.appendingPathComponent(fileName).relativePath
    }
}

public class FileCache {
    private var stringCache:[String:String] = [:]
    private var uiImageCache:[String:UIImage] = [:]
    private var dataCache:[String:Data] = [:]
    
    public func add<T>(_ key:String, _ value:T) throws {
        if T.self == UIImage.self {
            uiImageCache[key] = (value as! UIImage)
        }
        else if T.self == String.self {
            stringCache[key] = (value as! String)
        }
        else if T.self == Data.self {
            dataCache[key] = (value as! Data)
        }
        else {
            throw "Exception: Could not parse the type to write to \(key)"
        }
    }
    
    public func read<T>(_ key:String) throws -> T? {
        if T.self == UIImage.self {
            return uiImageCache[key] as? T
        }
        else if T.self == String.self {
            return stringCache[key] as? T
        }
        else if T.self == Data.self {
            return dataCache[key] as? T
        }
        else {
            throw "Exception: Could not parse the type to read from \(key)"
        }
    }
}

var fileCache = FileCache()
