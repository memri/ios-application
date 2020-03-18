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

func jsonDataFromFile(_ file: String, _ ext:String = "json") throws -> Data{
    let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
    let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
    let jsonData = jsonString.data(using: .utf8)!
    return jsonData
}

func jsonErrorHandling(_ decoder: Decoder, _ convert: () throws -> Void) {
    var path:String = "[Unknown]"
    
    if decoder.codingPath.count > 0 {
        path = "\(decoder.codingPath[0].stringValue)"
        for i in 1...decoder.codingPath.count - 1 {
            if decoder.codingPath[i].intValue == nil {
                path += ".\(decoder.codingPath[i].stringValue)"
            }
            else {
                path += "[\(Int(decoder.codingPath[i].intValue ?? -1))]"
            }
        }
    }
    
    print("Decoding: \(path)")
    
    do {
        try convert()
    } catch {
        dump(decoder)
        print("JSON Parse Error at \(path)\n\nError: \(error)")
    }
}
