//
// MemriButton.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

public struct MemriButton: View {
    @EnvironmentObject var context: MemriContext

    let item: Item?
    let edge: Edge?
    
    init(item:Item? = nil, edge:Edge? = nil) {
        self.item = item
        self.edge = edge
    }

    public var body: some View {
        var inputItem:Item? = item
        if edge != nil {
            inputItem = edge?.target()
        }
        
        let family = ItemFamily(rawValue: inputItem?.genericType ?? "Note")
        var type = edge?.type?.capitalizingFirst() ?? (inputItem?.objectSchema["itemType"] == nil
            ? inputItem?.genericType
            : inputItem?.getString("itemType"))
        if type == "" { type = inputItem?.genericType }
        
        var title = inputItem?.computedTitle ?? ""
        var bgColor = family?.backgroundColor ?? Color.white
        if inputItem?.genericType == "Person" && inputItem == me() {
            title = "Me"
            bgColor = Color(hex:"#e8ba32")
        }
        
        return Group {
            if inputItem == nil {
                EmptyView()
            }
//            else if isMe {
//                HStack(spacing: 0) {
//                    Text("Me")
//                        .padding(.leading, 6)
//                        .padding(.trailing, 6)
//                        .padding(.vertical, 3)
//                        .foregroundColor(Color.white)
//                        .font(.system(size: 14, weight: .semibold))
//                        .zIndex(10)
//                }
//                .background(Color(hex:"#b3b3b3"))
//                .cornerRadius(20)
//                .compositingGroup()
//                //        .fixedSize(horizontal: false, vertical: true)
//            }
            else {
                HStack(spacing: 0) {
                    Text(type ?? "")
                        .padding(.trailing, 8)
                        .padding(.leading, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#afafaf"))
                        .foregroundColor(Color(hex: "#fff"))
                        .font(.system(size: 14, weight: .semibold))
                        .cornerRadius(20)
                        .compositingGroup()

                    Text(title)
                        .padding(.leading, 5)
                        .padding(.trailing, 9)
                        .padding(.vertical, 3)
                        .foregroundColor(family?.foregroundColor ?? Color.white)
                        .font(.system(size: 14, weight: .semibold))
                        .zIndex(10)
                }
                .background(bgColor)
                .cornerRadius(20)
                .compositingGroup()
                //        .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct memriButton_Previews: PreviewProvider {
    static var previews: some View {
        MemriButton(item: Note(value: ["title": "Untitled Note"]))
    }
}
