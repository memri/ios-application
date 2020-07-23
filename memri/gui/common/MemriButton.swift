//
// MemriButton.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import SwiftUI

public struct MemriButton: View {
    @EnvironmentObject var context: MemriContext

    let item: Item

    public var body: some View {
        // NOTE: Allowed force unwrap
        let family = ItemFamily(rawValue: item.genericType)
        var type = item.objectSchema["type"] == nil ? item.genericType : item.getString("type")
        if type == "" { type = item.genericType }

        return HStack(spacing: 0) {
            Text(type.camelCaseToWords().capitalizingFirst())
                .padding(.trailing, 8)
                .padding(.leading, 8)
                .padding(.vertical, 3)
                .background(Color(hex: "#afafaf"))
                .foregroundColor(Color(hex: "#fff"))
                .font(.system(size: 14, weight: .semibold))
                .cornerRadius(20)
                .compositingGroup()

            Text(item.computedTitle)
                .padding(.leading, 5)
                .padding(.trailing, 9)
                .padding(.vertical, 3)
                .foregroundColor(family?.foregroundColor ?? Color.white)
                .font(.system(size: 14, weight: .semibold))
                .zIndex(10)
        }
        .background(family?.backgroundColor ?? Color.white)
        .cornerRadius(20)
        .compositingGroup()
        //        .fixedSize(horizontal: false, vertical: true)
    }
}

struct memriButton_Previews: PreviewProvider {
    static var previews: some View {
        MemriButton(item: Note(value: ["title": "Untitled Note"]))
    }
}
