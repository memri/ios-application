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
    
    private var _cachedData:Data? = nil
    
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
        if let x:UIImage = read() {
            return x
        }
        return nil
    }

    public var asString:String? {
        if let x:String = read() {
            return x
        }
        return nil
    }
    
    public func read<T>() -> T? {
        if _cachedData == nil, let data = self.readData() {
            _cachedData = data
        }
        else {
            print("Warn: Could not read data from \(self.uri)")
            return nil
        }
        
        if T.self == UIImage.self {
            return (UIImage(data: _cachedData!) as! T)
        }
        else if T.self == String.self {
            return (String(data: _cachedData!, encoding: .utf8) as! T)
        }
        else if T.self == Data.self {
            return (_cachedData! as! T)
        }
        else {
            print("Warn: Could not parse \(self.uri)")
            return nil
        }
    }
    
    public func store<T>(_ value: T) throws {
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
            _cachedData = data
        }
        catch let error {

            throw "\(error)"
        }
    }
    
//    public func store(uiImage: UIImage) throws {
//        do {
//            if let data = uiImage.pngData() {
//                try self.writeData(data)
//
//                _cachedData = data
//            }
//            else {
//                throw "Exception: Could not write \(self.uri) as PNG"
//            }
//        }
//        catch let error {
//            print(error)
//        }
//    }
//    public func store(str: String) throws {
//        do {
//            if let data = str.data(using: .utf8) {
//                try self.writeData(data)
//
//                _cachedData = data
//            }
//            else {
//                throw "Exception: Could not write \(self.uri) as UTF8 String"
//            }
//        }
//        catch let error {
//            print(error)
//        }
//    }
//    public func store(data: Data) throws {
//        do {
//            try self.writeData(data)
//            _cachedData = data
//        }
//        catch let error {
//            print(error)
//        }
//    }
        
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
