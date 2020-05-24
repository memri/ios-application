//
//  Languages.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

public class Languages {
    var currentLanguage: String = "English"
    var keywords: [String:String] = [:]
    
    public func load(_ definitions:[CVUParsedDefinition]) {
        for def in definitions {
            for (keyword, naturalLanguageString) in def.parsed {
                if keywords[keyword] != nil {
                    // TODO warn developers
                    print("Keyword already exists \(keyword) for language \(self.currentLanguage)")
                }
                else {
                    keywords[keyword] = naturalLanguageString as? String
                }
            }
        }
    }
}
