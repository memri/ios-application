//
//  util.swift
//  memri
//
//  Created by Koen van der Veen on 09/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

//func decodeFromTuples(_ decoder: Decoder, _ tuples: inout [(Any, String)]) throws{
//    for var (prop, name) in tuples.map({(AnyCodable($0), $1)}){
//        prop = try decoder.decodeIfPresent(name) ?? prop
//    }
//}

extension String: Error {}

func stringFromFile(_ file: String, _ ext:String = "json") throws -> String{
    print("Reading from file \(file).\(ext)")
    let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
    let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
    return jsonString
}

func jsonDataFromFile(_ file: String, _ ext:String = "json") throws -> Data{
    let jsonString = try stringFromFile(file, ext)
    let jsonData = jsonString.data(using: .utf8)!
    return jsonData
}

func jsonErrorHandling(_ decoder: JSONDecoder, _ convert: () throws -> Void) -> Bool {
    do {
        try convert()
        return true
    } catch {
        return false
    }
}

func jsonErrorHandling(_ decoder: Decoder, _ convert: () throws -> Void) -> Bool {
    var path:String = "[Unknown]"
    
    if decoder.codingPath.count > 0 {
        path = ""
        for i in 0...decoder.codingPath.count - 1 {
            if decoder.codingPath[i].intValue == nil {
                if i > 0 { path += "." }
                path += "\(decoder.codingPath[i].stringValue)"
            }
            else {
                path += "[\(Int(decoder.codingPath[i].intValue ?? -1))]"
            }
        }
    }
    
    print("Decoding: \(path)")
    
    do {
        try convert()
        return true
    } catch {
//        dump(decoder)
        print("JSON Parse Error at \(path)\n\nError: \(error)")
        raise(SIGINT)
        return false
    }
}

func serializeJSON(_ encode:(_ encoder:JSONEncoder) throws -> Data) -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted // for debugging purpose

    var json:String? = nil
    do {
        let data = try encode(encoder)
        json = String(data: data, encoding: .utf8) ?? ""
    } catch {
        print("Unexpected error: \(error)")
    }
    
    return json
}
