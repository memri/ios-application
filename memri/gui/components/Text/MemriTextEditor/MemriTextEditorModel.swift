//
//  MemriTextEditorModel.swift
//  RichTextEditor
//
//  Created by Toby Brennan on 5/10/20.
//  Copyright © 2020 ApptekStudios. All rights reserved.
//

import Foundation
import SwiftSoup

struct MemriTextEditorModel {
    
    var title: String?
    var body: String
    
    init(title: String? = nil, body: String) {
        self.title = title
        self.body = body
    }
    
    init(html: String) {
        (self.title, self.body) = MemriTextEditorModel.splitHTML(string: html)
    }
    
    var html: String {
        MemriTextEditorModel.combineHTML(title: title, body: body)
    }
    
    static func splitHTML(string: String) -> (title: String?, body: String) {
        do {
            let doc = try SwiftSoup.parseBodyFragment(string)
            let titleElement = doc.body()?.children().first(where: { $0.tag().getName() == "h1" })
            let title = try titleElement?.html()
            try titleElement?.remove()
            let body = try doc.body()?.html() ?? ""
            return (title, body)
        }
        catch {
            return (title: nil, body: string)
        }
    }
    
    static func combineHTML(title: String?, body: String) -> String {
        do {
            let doc = try SwiftSoup.parseBodyFragment(body)
            let titleElement = try doc.body()?.prependElement("h1")
            try titleElement?.html(title ?? "")
            return try doc.body()?.html() ?? ""
        }
        catch {
            return body
        }
    }
}
