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

func unserialize<T:Decodable>(_ s:String) -> T {
    let data = s.data(using: .utf8)!
    let output:T = try! JSONDecoder().decode(T.self, from: data)
    return output
}

func serialize(_ a:AnyCodable) -> String {
    let data = try! JSONEncoder().encode(a)
    let string = String(data: data, encoding: .utf8)!
    return string
}

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

func jsonErrorHandling(_ decoder: Decoder, _ convert: () throws -> Void) {
    let path = getCodingPathString(decoder.codingPath)
    print("Decoding: \(path)")
    
    do {
        try convert()
    } catch {
//        dump(decoder)
        print("\nJSON Parse Error at \(path)\nError: \(error.localizedDescription)\n")
        raise(SIGINT)
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
        print("\nUnexpected error: \(error.localizedDescription)\n")
    }
    
    return json
}
