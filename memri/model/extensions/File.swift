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
        return "url"
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
    
//    private var _cachedUIImage:UIImage? = nil
//    public var asUIImage:UIImage? {
//        if _cachedUIImage == nil, let data = readData() {
//            _cachedUIImage = UIImage(data: data)
//        }
//        if let c = _cachedUIImage {
//            return c
//        }
//
//        print("Warn: Could not read \(self.uri) as UIImage")
//        return nil
//    }
//
//    private var _cachedString:String? = nil
//    public var asString:String? {
//        if _cachedString == nil, let data = readData() {
//            _cachedString = String(data: data, encoding: .utf8)
//        }
//        if let c = _cachedString {
//            return c
//        }
//
//        print("Warn: Could not read \(self.uri) as UTF8 String")
//        return nil
//    }
    
    public func read<T>() -> T? {
        if _cachedData == nil, let data = readData() {
            _cachedData = data
        }
        else {
            print("Warn: Could not read \(self.uri) as UTF8 String")
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
    
    public func store<T>(value: T) throws {
        do {
            var data:Data
            
            if T.self == UIImage.self {
                let v = value as! UIImage
                data = v.pngData()!
                
                if data == nil {
                    throw "Exception: Could not write \(self.uri) as PNG"
                }
            }
            else if T.self == String.self {
                data = value.data(using: .utf8) {
                    
                if data == nil {
                    throw "Exception: Could not write \(self.uri) as UTF8 String"
                }
            }
            else if T.self == Data.self {
                data = value
            }
            else {
                throw "Exception: Could not parse the type to write to \(self.uri)"
                return nil
            }
            
            try self.writeData(data)

            _cachedData = data
        }
        catch let error {

            throw "Exception: Could not write \(self.uri): \(error)"
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
        let file: FileHandle? = FileHandle(forWritingAtPath: path)

        if file != nil {
            file?.write(data)
            
            // Close the file
            file?.closeFile()
        }
        else {
            throw "Exception: Could not write to \(path)"
        }
    }
    
    private func readData() -> Data? {
        let path = getPath()
        let file: FileHandle? = FileHandle(forReadingAtPath: path)

        if file != nil {
            // Read all the data
            let data = file?.readDataToEndOfFile()

            // Close the file
            file?.closeFile()

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
        let url = URL(fileURLWithPath: homeDir).appendingPathExtension(".memri.cache/File")
        
        do {
            try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print(error)
        }
        
        let fileName = UUID().uuidString
        
        return url.appendingPathExtension(fileName).absoluteString

    }
}
