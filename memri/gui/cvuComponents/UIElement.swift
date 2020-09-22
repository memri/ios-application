//
// UIElement.swift
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

public struct UINodeResolver: Identifiable {
    init(node: UINode, viewArguments: ViewArguments) {
        self.node = node
        self.viewArguments = viewArguments
    }
    
    public var id: UUID { node.id }
    var node: UINode
    var viewArguments: ViewArguments

    
    var item: Item? { viewArguments.get(".") }

    func resolve<T>(_ propertyName: String, type: T.Type = T.self) -> T? {
        guard let property = node.properties[propertyName] else {
            return nil
        }
        
        if let propertyExpression = property as? Expression {
            do {
                if T.self == [Item].self {
                    let x = try propertyExpression.execute(viewArguments)
                    
                    var result = [Item]()
                    if let list = x as? Results<Edge> {
                        for edge in list {
                            if let d = edge.target() {
                                result.append(d)
                            }
                        }
                    }
                    else {
                        result = dataItemListToArray(x as Any)
                    }
                    
                    return (result as! T)
                }
                else {
                    let x = try propertyExpression.execForReturnType(T.self, args: viewArguments)
                    return x
                }
            }
            catch {
                print("Expression could not be resolved: \(propertyExpression.code). \(error)")
                return nil
            }
        }
        else if type == CGFloat.self, let value = property as? Double {
            return CGFloat(value) as? T
        }
        else if type == Int.self, let value = property as? Double {
            return Int(value) as? T
        }
        else if let value = property as? T {
            return value
        } else {
            return nil
        }
        
    }
    
    var childrenInForEach: some View {
        let childNodeResolvers = node.children.map { UINodeResolver(node: $0, viewArguments: viewArguments) }
        return ForEach(childNodeResolvers) { childNodeResolver in
            UIElementView(nodeResolver: childNodeResolver)
        }
    }

    var childrenInArray: [UIElementView] {
        node.children.map { UINodeResolver(node: $0, viewArguments: viewArguments) }.map { UIElementView(nodeResolver: $0) }
    }
//
//
//    func processText(_ text: String?) -> String? {
//        guard var outText = text else { return nil }
//        outText = (get("removeWhiteSpace") ?? false) ? removeWhiteSpace(text: outText) : outText
//        outText = (get("maxChar") as CGFloat?).map { String(outText.prefix(Int($0))) } ?? outText
//        guard outText.contains(where: { !$0.isWhitespace })
//        else { return nil } // Return nil if blank
//        return outText
//    }
//
//    func removeWhiteSpace(text: String) -> String {
//        text
//            .trimmingCharacters(in: .whitespacesAndNewlines) // Remove whitespace/newLine from start/end of string
//            .split { $0.isNewline }.joined(separator: " ") // Replace new-lines with a space
//    }

    
    func fileURI(for propertyName: String) -> String? {
        if let file: File = resolve(propertyName) {
            return file.fileUID
        }
        else if let photo: Photo? = resolve(propertyName), let file = photo?.file {
            return file.fileUID
        }
        return nil
    }


    func color(for propertyName: String = "color") -> CVUColor? {
        if let colorDef = resolve(propertyName, type: CVUColor.self) {
            return colorDef
        }
        else if let colorHex = resolve(propertyName, type: String.self) {
            return CVUColor.hex(colorHex)
        }
        return nil
    }
    
    func font(for propertyName: String = "font", baseFont defaultValue: CVUFont = CVUFont()) -> CVUFont {
        if let value = resolve(propertyName, type: [Any].self) {
            if let name = value[safe: 0] as? String, let size = value[safe: 1] as? CGFloat {
                return CVUFont(
                    name: name,
                    size: size,
                    weight: value[safe: 2] as? Font.Weight ?? defaultValue.weight
                )
            }
            else if let size = value[safe: 0] as? CGFloat {
                return CVUFont(name: defaultValue.name, size: size, weight: value[safe: 1] as? Font.Weight ?? defaultValue.weight)
            }
        }
        else if let size = resolve(propertyName, type: CGFloat.self) {
            return CVUFont(name: defaultValue.name, size: size, weight: defaultValue.weight)
        }
        else if let weight = resolve(propertyName, type: Font.Weight.self) {
            return CVUFont(name: defaultValue.name, size: defaultValue.size, weight: weight)
        }
        return defaultValue
    }
    
    func alignment(for propertyName: String = "alignment") -> Alignment {
        switch resolve(propertyName, type: String.self) {
        case "left", "leading": return Alignment.leading
        case "top": return Alignment.top
        case "right", "trailing": return Alignment.trailing
        case "bottom": return Alignment.bottom
        case "center": return Alignment.center
        case "lefttop", "topleft": return Alignment.topLeading
        case "righttop", "topright": return Alignment.topTrailing
        case "leftbottom", "bottomleft": return Alignment.bottomLeading
        case "rightbottom", "bottomright": return Alignment.bottomTrailing
        default: return Alignment.center
        }
    }
    
    func textAlignment(for propertyName: String = "textAlign") -> TextAlignment {
        switch resolve(propertyName, type: String.self) {
        case "left", "leading": return .leading
        case "right", "trailing": return .trailing
        case "center", "middle": return .center
        default: return .leading
        }
    }
    
    func string(for propertyName: String) -> String? {
        resolve(propertyName, type: String.self)
    }
    
    func int(for propertyName: String) -> Int? {
        resolve(propertyName, type: Int.self)
    }
    
    func double(for propertyName: String) -> Double? {
        resolve(propertyName, type: Double.self)
    }
    
    func cgFloat(for propertyName: String) -> CGFloat? {
        resolve(propertyName, type: CGFloat.self)
    }
    
    func cgPoint(for propertyName: String) -> CGPoint? {
        if let dimensions = resolve(propertyName, type: [Double].self), let x = dimensions[safe: 0], let y = dimensions[safe: 1] {
            return CGPoint(x: x, y: y)
        } else if let dimension = resolve(propertyName, type: CGFloat.self) {
            return CGPoint(x: dimension, y: dimension)
        } else {
            return nil
        }
    }
    
    func insets(for propertyName: String) -> UIEdgeInsets? {
        if let edgeInset = resolve(propertyName, type: CGFloat.self) {
            return UIEdgeInsets(
                top: edgeInset,
                left: edgeInset,
                bottom: edgeInset,
                right: edgeInset
            )
        } else if let insetArray = resolve(propertyName, type: [Double].self)?.map({ CGFloat($0) }) {
            switch insetArray.count {
            case 2: return UIEdgeInsets(
                top: insetArray[1],
                left: insetArray[0],
                bottom: insetArray[1],
                right: insetArray[0]
                )
            case 4: return UIEdgeInsets(
                top: insetArray[0],
                left: insetArray[3],
                bottom: insetArray[2],
                right: insetArray[1]
                )
            default: return .init()
            }
        } else {
            return nil
        }
    }
    
    func bool(for propertyName: String, defaultValue: Bool) -> Bool {
        resolve(propertyName, type: Bool.self) ?? defaultValue
    }
    
    func binding<T>(for propertyName: String, type: T.Type = T.self) -> Binding<T?>? {
        let (_, dataItemOptional, itemPropertyName) = getType(for: propertyName)
        guard let dataItem = dataItemOptional, dataItem.hasProperty(itemPropertyName)
        else { return nil }
        return Binding<T?>(
            get: { dataItem.get(itemPropertyName) },
            set: { dataItem.set(itemPropertyName, $0) }
        )
    }
    
    func binding<T>(for propertyName: String, defaultValue: T, type: T.Type = T.self) -> Binding<T> {
        let (_, dataItemOptional, itemPropertyName) = getType(for: propertyName)
        guard let dataItem = dataItemOptional, dataItem.hasProperty(itemPropertyName) else {
            return .constant(defaultValue)
        }
        return  Binding<T>(
            get: { dataItem.get(itemPropertyName) ?? defaultValue },
            set: { dataItem.set(itemPropertyName, $0) }
        )
    }
    
    private func getType(for propName: String) -> (PropertyType, Item?, String) {
        if let prop = node.properties[propName] {
            // Execute expression to get the right value
            if let expr = prop as? Expression {
                do {
                    return try expr.getTypeOfItem(viewArguments)
                }
                catch {
                    // TODO: Refactor: Error Handling
                    debugHistory.error("could not get type of \(String(describing: item))")
                }
            }
        }
        return (.any, item, "")
    }

}

extension UINodeResolver {
    var showNode: Bool {
        return bool(for: "show", defaultValue: true)
    }
    var opacity: Double {
        double(for: "opacity") ?? 1
    }
    
    var cornerRadius: CGFloat {
        cgFloat(for: "cornerRadius") ?? 0
    }
    
    var spacing: CGPoint {
        cgPoint(for: "spacing") ?? .zero
    }
    
    var backgroundColor: CVUColor? {
        color(for: "background")
    }
    
    var borderColor: CVUColor? {
        color(for: "border")
    }
    
    var minWidth: CGFloat? {
        cgFloat(for: "width") ?? cgFloat(for: "minWidth")
    }
    var minHeight: CGFloat? {
        cgFloat(for: "height") ?? cgFloat(for: "minHeight")
    }
    var maxWidth: CGFloat? {
        cgFloat(for: "width") ?? cgFloat(for: "maxWidth")
    }
    var maxHeight: CGFloat? {
        cgFloat(for: "height") ?? cgFloat(for: "maxHeight")
    }
    
    var offset: CGSize {
        guard let value = cgPoint(for: "offset") else { return .zero }
        return CGSize(width: value.x, height: value.y)
    }
    
    var shadow: CGFloat? {
        guard let value = cgFloat(for: "shadow"), value > 0 else { return nil }
        return value
    }
    
    var sizingMode: CVU_SizingMode {
        string(for: "sizingMode").flatMap { CVU_SizingMode(rawValue: $0) } ?? .fit
    }
    
    var zIndex: Double? {
        double(for: "zIndex")
    }
    
    var lineLimit: Int? {
        int(for: "lineLimit")
    }
    
    var forceAspect: Bool {
        bool(for: "forceAspect", defaultValue: false)
    }
    
    var padding: EdgeInsets {
        guard let uiInsets = insets(for: "padding") else { return .init() }
        return EdgeInsets(top: uiInsets.top, leading: uiInsets.left, bottom: uiInsets.bottom, trailing: uiInsets.right)
    }
    
    var margin: EdgeInsets {
        guard let uiInsets = insets(for: "margin") else { return .init() }
        return EdgeInsets(top: uiInsets.top, leading: uiInsets.left, bottom: uiInsets.bottom, trailing: uiInsets.right)
    }
}
