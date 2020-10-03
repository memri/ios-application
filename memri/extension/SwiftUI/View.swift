//
// view.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

extension View {
    @inlinable
    func ignoreSafeAreaOnMac() -> some View {
        #if targetEnvironment(macCatalyst)
            return edgesIgnoringSafeArea(.all)
        #else
            return self
        #endif
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        }
        else {
            self
        }
    }
    
    @ViewBuilder
    func `ifLet`<T, Content: View>(_ optional: T?, content: (Self, T) -> Content) -> some View {
        if optional != nil {
            optional.map { content(self, $0) }
        }
        else {
            self
        }
    }
}

extension Text {
    func `if`(_ conditional: Bool, content: (Self) -> Text) -> Text {
        if conditional { return content(self) }
        else { return self }
    }
}

extension Image {
    func `if`(_ conditional: Bool, content: (Self) -> Image) -> Image {
        if conditional { return content(self) }
        else { return self }
    }
}

//extension View {
//    func setProperties(
//        _ properties: [String: Any?],
//        _: Item,
//        _: MemriContext,
//        _ viewArguments: ViewArguments
//    ) -> AnyView {
//        var view: AnyView = AnyView(self)
//
//        if properties.count == 0 {
//            return view
//        }
//
//        for name in ViewPropertyOrder {
//            if var value = properties[name] {
//                if let expr = value as? Expression {
//                    do {
//                        value = try expr.execute(viewArguments) as Any?
//                    }
//                    catch {
//                        // TODO: refactor: Error handling
//                        print("Could not set property. Executing expression \(expr) failed")
//                        continue
//                    }
//                }
//                else if var list = value as? [Any?] {
//                    for i in 0..<list.count {
//                        if let expr = list[i] as? Expression {
//                            do {
//                                list[i] = try expr.execute(viewArguments) as Any?
//                            }
//                            catch {
//                                // TODO: refactor: Error handling
//                                print("Could not set property. Executing expression \(expr) failed")
//                                continue
//                            }
//                        }
//                    }
//                    value = list
//                }
//
//                view = view.setProperty(name, value)
//            }
//        }
//
//        return view
//    }
//
//    // TODO: investigate using ViewModifiers
//    func setProperty(_ name: String, _ value: Any?) -> AnyView {
//        switch name {
//        case "style":
//            // TODO: Refactor: Implement style sheets
//            break
//        case "shadow":
//            if let value = value as? [Any] {
//                if let c = value[0] as? CVUColor, let r = value[1] as? CGFloat,
//                    let x = value[2] as? CGFloat, let y = value[3] as? CGFloat {
//                    return AnyView(shadow(color: c.color, radius: r, x: x, y: y))
//                }
//                else {
//                    print("Exception: Invalid values for shadow")
//                    return AnyView(shadow(radius: 0))
//                }
//            }
//        case "margin":
//            fallthrough
//        case "padding":
//            if let value = value as? [CGFloat] {
//                #warning("This errored while editing CVU. Why did the validator not catch this?")
//                return AnyView(padding(EdgeInsets(
//                    top: value[safe: 0] ?? 0,
//                    leading: value[safe: 3] ?? 0,
//                    bottom: value[safe: 2] ?? 0,
//                    trailing: value[safe: 1] ?? 0
//                )))
//            }
//            else if let value = value as? CGFloat {
//                return AnyView(padding(value))
//            }
//            else if let value = (value as? String)?
//                .split(separator: " ")
//                .compactMap({ CGFloat(Int(String($0)) ?? 0) })
//            {
//                return AnyView(padding(EdgeInsets(
//                    top: value[safe: 0] ?? 0,
//                    leading: value[safe: 3] ?? 0,
//                    bottom: value[safe: 2] ?? 0,
//                    trailing: value[safe: 1] ?? 0
//                )))
//            }
//        case "blur":
//            if let value = value as? CGFloat {
//                return AnyView(blur(radius: value))
//            }
//        case "opacity":
//            if let value = value as? CGFloat {
//                return AnyView(opacity(Double(value)))
//            }
//        case "color":
//            if let color = value as? CVUColor {
//                return AnyView(foregroundColor(color.color)) // TODO: named colors do not work
//            }
//            if let color = value as? String {
//                return AnyView(foregroundColor(Color(hex: color)))
//            }
//        case "lineLimit":
//            if let lineLimit = value as? Int {
//                return AnyView(self.lineLimit(lineLimit))
//            }
//        case "background":
//            if let color = value as? CVUColor {
//                return AnyView(background(color.color)) // TODO: named colors do not work
//            }
//            else if let color = value as? String {
//                return AnyView(background(Color(hex: color))) // TODO: named colors do not work
//            }
//        case "rowbackground":
//            if let color = value as? CVUColor {
//                return AnyView(listRowBackground(color.color)) // TODO: named colors do not work
//            }
//            else if let color = value as? String {
//                return AnyView(listRowBackground(Color(hex: color))) // TODO: named colors do not work
//            }
//        case "border":
//            if let value = value as? [Any?] {
//                if let color = value[0] as? CVUColor {
//                    return AnyView(border(color.color, width: value[1] as? CGFloat ?? 1.0))
//                }
//                else {
//                    print("FIX BORDER HANDLING2")
//                }
//            }
//            else {
//                print("FIX BORDER HANDLING")
//            }
//        case "offset":
//            if let value = value as? [CGFloat] {
//                return AnyView(offset(x: value[0], y: value[1]))
//            }
//        case "zindex":
//            if let value = value as? CGFloat {
//                return AnyView(zIndex(Double(value)))
//            }
//        case "cornerRadius":
//            if let value = value as? CGFloat {
//                return AnyView(cornerRadius(value))
//            }
//            else {}
//        case "cornerborder":
//            if let value = value as? [Any?] {
//                if let color = value[0] as? CVUColor {
//                    return AnyView(overlay(
//                        RoundedRectangle(cornerRadius: value[2] as? CGFloat ?? 1.0)
//                            .stroke(color.color, lineWidth: value[1] as? CGFloat ?? 1.0)
//                            .padding(1)
//                    ))
//                }
//            }
//        case "frame":
//            if var value = value as? [Any?] {
//
//                return AnyView(frame(
//                    minWidth: value[0] as? CGFloat,
//                    maxWidth: value[1] as? CGFloat,
//                    minHeight: value[2] as? CGFloat,
//                    maxHeight: value[3] as? CGFloat,
//                    alignment: value[4] as? Alignment ?? .top
//                ))
//            }
//        case "font":
//            var font: Font
//
//            if let value = value as? [Any] {
//                if let name = value[0] as? String {
//                    font = .custom(name, size: value[1] as? CGFloat ?? 12.0)
//                }
//                else {
//                    font = .system(size: value[0] as? CGFloat ?? 12.0,
//                                   weight: value[1] as? Font.Weight ?? Font.Weight.regular,
//                                   design: .default)
//                }
//            }
//            else if let value = value as? CGFloat {
//                font = .system(size: value)
//            }
//            else if let value = value as? Font.Weight {
//                font = .system(size: 12, weight: value)
//            }
//            else {
//                return AnyView(self)
//            }
//
//            return AnyView(self.font(font))
//        case "textAlign":
//            if let value = value as? TextAlignment {
//                return AnyView(multilineTextAlignment(value))
//            }
//        //        case "minWidth", "minHeight", "align", "maxWidth", "maxHeight", "spacing", "alignment", "text", "maxchar", "removewhitespace", "bold":
//        //            break
//        default:
//            print("NOT IMPLEMENTED PROPERTY: \(name)")
//        }
//
//        return AnyView(self)
//    }
//  }


//
//extension View {
//    func border(width: [CGFloat], color: Color) -> some View {
//        overlay(
//            GeometryReader { geom in
//                Path { path in
//                    if let topEdge = width[safe: 0], topEdge > 0 {
//                        path.addRect(CGRect(x: 0, y: 0, width: geom.size.width, height: topEdge))
//                    }
//                    if let bottomEdge = width[safe: 2], bottomEdge > 0 {
//                        path
//                            .addRect(CGRect(x: 0, y: geom.size.height - bottomEdge,
//                                            width: geom.size.width, height: bottomEdge))
//                    }
//                    if let leftEdge = width[safe: 3], leftEdge > 0 {
//                        path.addRect(CGRect(x: 0, y: 0, width: leftEdge, height: geom.size.height))
//                    }
//                    if let rightEdge = width[safe: 1], rightEdge > 0 {
//                        path
//                            .addRect(CGRect(x: geom.size.width - rightEdge, y: 0, width: rightEdge,
//                                            height: geom.size.height))
//                    }
//                }
//                .fill(color)
//            }
//        )
//    }
//
//    public func border(width: CGFloat, edge: SwiftUI.Edge, color: Color) -> some View {
//        overlay(
//            EdgeBorder(width: width, edge: edge).foregroundColor(color)
//        )
//    }
//}
