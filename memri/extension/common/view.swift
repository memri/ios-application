//
//  view.swift
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

private let ViewPropertyOrder = ["style", "frame", "color", "font", "padding", "background",
    "textAlign", "rowbackground", "cornerRadius", "cornerborder", "border", "margin", "shadow",
    "offset", "blur", "opacity", "zindex"]

extension View {
    func setProperties(_ properties:[String:Any?], _ item:DataItem, _ main:Main) -> AnyView {
        var view:AnyView = AnyView(self)
        
        for name in ViewPropertyOrder {
            if var value = properties[name] {
                
                if let expr = value as? Expression {
                    do { value = try expr.execute(main.cascadingView.viewArguments) as Any? }
                    catch {
                        // TODO refactor: Error handling
                        print("Could not set property. Executing expression \(expr) failed")
                        continue
                    }
                }
                
                view = view.setProperty(name, value)
            }
        }
        
        return view
    }
    
    // TODO investigate using ViewModifiers
    func setProperty(_ name:String, _ value:Any?) -> AnyView {
        switch name {
        case "style":
            // TODO Refactor: Implement style sheets
            break
        case "shadow":
            if let value = value as? [Any] {
                if let c = value[0] as? Color, let r = value[1] as? CGFloat,
                    let x = value[2] as? CGFloat, let y = value[3] as? CGFloat{
                    return AnyView(self.shadow(color: c, radius: r, x: x, y: y))
                }
                else {
                    print("Exception: Invalid values for shadow")
                    return AnyView(self.shadow(radius: 0))
                }
            }
        case "margin":
            fallthrough
        case "padding":
            if let value = value as? [CGFloat] {
                return AnyView(self.padding(EdgeInsets(
                    top: value[0],
                    leading: value[3],
                    bottom: value[2],
                    trailing: value[1]))
                )
            }
            else if let value = value as? CGFloat {
                return AnyView(self.padding(value))
            }
        case "blur":
            if let value = value as? CGFloat {
                return AnyView(self.blur(radius: value))
            }
        case "opacity":
            if let value = value as? CGFloat {
                return AnyView(self.opacity(Double(value)))
            }
        case "color":
            if let color = value as? Color {
                return AnyView(self.foregroundColor(color)) //TODO named colors do not work
            }
        case "background":
            if let color = value as? Color {
                return AnyView(self.background(color)) //TODO named colors do not work
            }
        case "rowbackground":
            if let color = value as? Color {
                return AnyView(self.listRowBackground(color)) //TODO named colors do not work
            }
        case "border":
            if let value = value as? [Any?] {
                if let color = value[0] as? Color {
                    return AnyView(self.border(color, width: value[1] as? CGFloat ?? 1.0))
                }
                else {
                    print("FIX BORDER HANDLING2")
                }
            }
            else {
                print("FIX BORDER HANDLING")
            }
        case "offset":
            if let value = value as? [CGFloat] {
                return AnyView(self.offset(x: value[0], y: value[1]))
            }
        case "zindex":
            if let value = value as? CGFloat {
                return AnyView(self.zIndex(Double(value)))
            }
        case "cornerRadius":
            if let value = value as? CGFloat {
                return AnyView(self.cornerRadius(value))
            }
            else {
                
            }
        case "cornerborder":
            if let value = value as? [Any?] {
                if let color = value[0] as? Color {
                    return AnyView(self.overlay(
                        RoundedRectangle(cornerRadius: value[2] as? CGFloat ?? 1.0)
                            .stroke(color, lineWidth: value[1] as? CGFloat ?? 1.0)
                            .padding(1)
                    ))
                }
            }
        case "frame":
            if let value = value as? [Any?] {
                return AnyView(self.frame(
                    minWidth: value[0] as? CGFloat ?? .none,
                    maxWidth: value[1] as? CGFloat ?? .greatestFiniteMagnitude,
                    minHeight: value[2] as? CGFloat ?? .none,
                    maxHeight: value[3] as? CGFloat ?? .greatestFiniteMagnitude,
                    alignment: value[4] as? Alignment ?? .top))
            }
        case "font":
            var font:Font
            
            if let value = value as? [Any] {
                if let name = value[0] as? String {
                    font = .custom(name, size: value[1] as? CGFloat ?? 12.0)
                }
                else {
                    font = .system(size: value[0] as? CGFloat ?? 12.0,
                                   weight: value[1] as? Font.Weight ?? Font.Weight.regular,
                                   design: .default)
                }
                
            }
            else if let value = value as? CGFloat {
                font = .system(size: value)
            }
            else if let value = value as? Font.Weight {
                font = .system(size: 12, weight: value)
            }
            else {
                return AnyView(self)
            }
            
            return AnyView(self.font(font))
        case "textAlign":
            if let value = value as? TextAlignment {
                return AnyView(self.multilineTextAlignment(value))
            }
        case "minwidth", "minheight", "align", "maxwidth", "maxheight", "spacing", "alignment", "text", "maxchar", "removewhitespace", "bold":
            break
        default:
            print("NOT IMPLEMENTED PROPERTY: \(name)")
        }
        
        return AnyView(self)
    }
    
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional { return AnyView(content(self)) }
        else { return AnyView(self) }
    }
    
    // TODO Refactor: use only one path to draw this (is that possible?)
    func border(width: [CGFloat], color: Color) -> some View {
        var x:AnyView = AnyView(self)
        if width[0] > 0 {
            x = AnyView(x.overlay(EdgeBorder(width: width[0], edge: .top).foregroundColor(color)))
        }
        if width[1] > 0 {
            x = AnyView(x.overlay(EdgeBorder(width: width[1], edge: .trailing).foregroundColor(color)))
        }
        if width[2] > 0 {
            x = AnyView(x.overlay(EdgeBorder(width: width[2], edge: .bottom).foregroundColor(color)))
        }
        if width[3] > 0 {
            x = AnyView(x.overlay(EdgeBorder(width: width[3], edge: .leading).foregroundColor(color)))
        }
        
        return x
    }
    func border(width: CGFloat, edge: SwiftUI.Edge, color: Color) -> some View {
        self.overlay(
            EdgeBorder(width: width, edge: edge).foregroundColor(color)
        )
    }
}

extension Text {
    func `if`(_ conditional: Bool, content: (Self) -> Text) -> Text {
        if conditional { return content(self) }
        else { return self }
    }
}

//extension Image {
//    func `if`(_ conditional: Bool, content: (Self) -> Image) -> Image {
//        if conditional { return content(self) }
//        else { return self }
//    }
//}

struct EdgeBorder: Shape {

    var width: CGFloat
    var edge: SwiftUI.Edge

    func path(in rect: CGRect) -> Path {
        var x: CGFloat {
            switch edge {
            case .top, .bottom, .leading: return rect.minX
            case .trailing: return rect.maxX - width
            }
        }

        var y: CGFloat {
            switch edge {
            case .top, .leading, .trailing: return rect.minY
            case .bottom: return rect.maxY - width
            }
        }

        var w: CGFloat {
            switch edge {
            case .top, .bottom: return rect.width
            case .leading, .trailing: return self.width
            }
        }

        var h: CGFloat {
            switch edge {
            case .top, .bottom: return self.width
            case .leading, .trailing: return rect.height
            }
        }

        return Path( CGRect(x: x, y: y, width: w, height: h) )
    }
}
