//
//  memriButton.swift
//  memri
//
//  Created by Ruben Daniels on 4/24/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public struct memriButton : View {
    @EnvironmentObject var main: Main
    
    let item: DataItem
    
    public var body: some View {
        var type = item.objectSchema["type"] == nil ? item.genericType : item.getString("type")
        if type == "" { type = item.genericType }
        
        return HStack (spacing:0) {
            Text(type.camelCaseToWords().capitalizingFirstLetter())
                .padding(.trailing, 8)
                .padding(.leading, 8)
                .padding(.vertical, 3)
                .background(Color(hex: "#d9d9d9"))
                .foregroundColor(Color(hex: "#666"))
                .font(.system(size: 14, weight: .regular))
                .cornerRadius(20)
                .compositingGroup()
                
            Text(item.computeTitle)
                .padding(.leading, 5)
                .padding(.trailing, 9)
                .padding(.vertical, 3)
                .foregroundColor(Color.white)
                .font(.system(size: 14, weight: .semibold))
                .zIndex(10)
        }
        .background(Color(hex: "#93c47d"))
        .cornerRadius(20)
//        .fixedSize(horizontal: false, vertical: true)
    }
}

struct memriButton_Previews: PreviewProvider {
    static var previews: some View {
        memriButton(item: Note(value: ["title": "Untitled Note"]))
    }
}
