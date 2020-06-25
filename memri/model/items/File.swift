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

extension File {
    
    public var asUIImage: UIImage? {
        do { if let x:UIImage = try read() { return x } }
        catch {
            // TODO: User error handling
            // TODO Refactor: error handling
            if let fileName = uri.components(separatedBy: "/").last {
                return UIImage(named: fileName)
            }
            debugHistory.error("Could not read image in path: \(uri)")
        }
        return nil
    }

    public var asString:String? {
        do { if let x:String = try read() { return x } }
        catch {
            // TODO: User error handling
            // TODO Refactor: error handling
        }
        return nil
    }
    
    public var asData:Data? {
        do { if let x:Data = try read() { return x } }
        catch {
            // TODO: User error handling
            // TODO Refactor: error handling
        }
        return nil
    }
    
    public func read<T>() throws -> T? {
        var cachedData:T? = InMemoryObjectCache.get(self.uri) as? T
        if cachedData != nil { return cachedData }
        
        let data = try self.readData()
        
        // NOTE: Allowed forced casting, because we check for types
        if T.self == UIImage.self {
            cachedData = UIImage(data: data) as? T
        }
        else if T.self == String.self {
            cachedData = String(data: data, encoding: .utf8) as? T
        }
        else if T.self == Data.self {
            cachedData = data as? T
        }
        else {
            throw "Could not parse \(self.uri)"
        }
        // NOTE: Allowed forced unwrapping, because variable must have value by now
        try InMemoryObjectCache.set(self.uri, cachedData!)
        return cachedData
    }
    
    public func write<T>(_ value: T) throws {
        do {
            var data:Data?
            
            // NOTE: allowed forced casting, because type has been checked
            if T.self == UIImage.self {
                data = (value as? UIImage)?.pngData()
                if data == nil { throw "Exception: Could not write \(self.uri) as PNG" }
            }
            else if T.self == String.self {
                data = (value as? String)?.data(using: .utf8)
                if data == nil { throw "Exception: Could not write \(self.uri) as UTF8 String" }
            }
            else if T.self == Data.self {
                data = (value as? Data)
            }
            else {
                throw "Exception: Could not parse the type to write to \(self.uri)"
            }
            // NOTE: Allowed forced unwrapping, should have value here
            try self.writeData(data!)
            try InMemoryObjectCache.set(self.uri, value)
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
    
    private func readData() throws -> Data  {
        let path = getPath()
        if path == "" { throw "Path is empty" } // TODO reporting??

//        let databuffer = FileManager.default.contents(atPath: path)
        
        func readFromPath(_ path: String) -> Data? {
            if let file = FileHandle(forReadingAtPath: path) {
                // Read all the data
                let data = file.readDataToEndOfFile()

                // Close the file
                file.closeFile()

                // Return data
                return data
            }
            else {
                return nil
            }
        }
        
        if let data = readFromPath(path) {
            return data
        }
        else {
            let splitted = path.split(separator: ".")
            let file = String(splitted[0])
            let ext = String(splitted[1])
            if let file = Bundle.main.path(forResource: file, ofType: ext){
                if let data = readFromPath(file){
                    return data
                }else{
                    throw "Warning: Could not read file at \(path)"
                }
            }
            else {
                throw "Warning: Could not find file in bundle at \(path)"
            }
        }
        
    }
    
    // TODO where to save these files properly?
    public class func generateFilePath() -> String {
        let homeDir = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]
        if let homeDir = homeDir {
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
        else {
            // TODO: Error handling
            print("Cannot generate filePath")
            return ""
        }
    }
}
