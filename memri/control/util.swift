//
//  util.swift
//  memri
//
//  Created by Koen van der Veen on 09/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

func jsonDataFromFile(_ file: String, _ ext:String = "json") throws -> Data{
    let fileURL = Bundle.main.url(forResource: file, withExtension: ext)
    let jsonString = try String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
    let jsonData = jsonString.data(using: .utf8)!
    return jsonData
}
