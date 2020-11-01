//
// UINode.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift
import SwiftUI

public struct UINode {
    var type: UIElementFamily
    var children: [UINode] = []
    var properties: [String: Any?] = [:]

    let id = UUID()
}

extension UINode: CVUToString {
    func toCVUString(_ depth: Int, _ tab: String) -> String {
        let tabs = Array(0 ..< depth + 1).map { _ in "" }.joined(separator: tab)
        let tabsPlus = Array(0 ..< depth + 2).map { _ in "" }.joined(separator: tab)

        return properties.count > 0 || children.count > 0
            ? "\(type) {\n"
            + (properties.count > 0
                ?
                "\(tabsPlus)\(CVUSerializer.dictToString(properties, depth + 1, tab, withDef: false))"
                : "")
            + (properties.count > 0 && children.count > 0
                ? "\n\n"
                : "")
            + (children.count > 0
                ?
                "\(tabsPlus)\(CVUSerializer.arrayToString(children, depth + 1, tab, withDef: false, extraNewLine: true))"
                : "")
            + "\n\(tabs)}"
            : "\(type)\n"
    }

    public var description: String {
        toCVUString(0, "    ")
    }
}
