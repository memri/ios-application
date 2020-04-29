//
//  memriButton.swift
//  memri
//
//  Created by Ruben Daniels on 4/24/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public struct MemriButton : View {
    @EnvironmentObject var main: Main
    
    let item: DataItem
    
    public var body: some View {
        let family = DataItemFamily(rawValue: item.genericType)!
        var type = item.objectSchema["type"] == nil ? item.genericType : item.getString("type")
        if type == "" { type = item.genericType }
        
        return HStack (spacing:0) {
            Text(type.camelCaseToWords().capitalizingFirstLetter())
                .padding(.trailing, 8)
                .padding(.leading, 8)
                .padding(.vertical, 3)
                .background(Color(hex: "#afafaf"))
                .foregroundColor(Color(hex: "#fff"))
                .font(.system(size: 14, weight: .semibold))
                .cornerRadius(20)
                .compositingGroup()
                
            Text(item.computeTitle)
                .padding(.leading, 5)
                .padding(.trailing, 9)
                .padding(.vertical, 3)
                .foregroundColor(family.foregroundColor)
                .font(.system(size: 14, weight: .semibold))
                .zIndex(10)
        }
        .background(family.backgroundColor)
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