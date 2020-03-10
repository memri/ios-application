//
//  util.swift
//  memri
//
//  Created by Koen van der Veen on 09/03/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import Foundation

//func decodeFromTuples(_ decoder: Decoder, _ tuples: inout [(Any, String)]) throws{
//    for var (prop, name) in tuples.map({(AnyCodable($0), $1)}){
//        prop = try decoder.decodeIfPresent(name) ?? prop
//    }
//}


func jsonDataFromFile(_ file: String, _ ext:String = "json") throws -> Data{
    let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
    let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
    let jsonData = jsonString.data(using: .utf8)!
    return jsonData
}
