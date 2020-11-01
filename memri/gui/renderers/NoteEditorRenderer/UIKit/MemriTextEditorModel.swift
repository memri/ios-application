//
// MemriTextEditorModel.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftSoup

struct MemriTextEditorModel {
    var title: String?
    var body: String

    init(title: String? = nil, body: String = "") {
        self.title = title
        self.body = body
    }

    init(html: String) {
        (title, body) = MemriTextEditorModel.splitHTML(string: html)
    }

    var html: String {
        MemriTextEditorModel.combineHTML(title: title, body: body)
    }

    static func splitHTML(string: String) -> (title: String?, body: String) {
        do {
            let doc = try SwiftSoup.parseBodyFragment(string)
            let titleElement = doc.body()?.children()
                .first(where: { $0.tag().getName() == "h1" && $0.id() == "title" })
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
            try titleElement?.attr("id", "title")
            try titleElement?.html(title ?? "")
            return try doc.body()?.html() ?? ""
        }
        catch {
            return body
        }
    }
}

import SwiftUI
enum MemriTextEditorColor: String, CaseIterable {
    case `default` = "--text-color"
    case red = "--text-color-red"
    case orange = "--text-color-orange"
    case yellow = "--text-color-yellow"
    case green = "--text-color-green"
    case blue = "--text-color-blue"
    case purple = "--text-color-purple"
    case pink = "--text-color-pink"

    var cssVar: String {
        "var(\(rawValue))"
    }

    var swiftColor: Color? {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .pink: return .pink
        case .purple: return .purple
        case .red: return .red
        case .yellow: return .yellow
        default: return nil
        }
    }
}
