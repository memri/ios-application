//
//  TopNavigation.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct TopNavigation: View {
    var title: String = ""
    var action: ()->Void = {}
    var hideBack:Bool = false
    
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.gray)
                    .font(Font.system(size: 20, weight: .medium))
            }.padding(.horizontal , 5)

            Button(action: self.action) {
                Image(systemName: "chevron.left")
                .foregroundColor(.gray)

            }.padding(.horizontal , 5)

            Spacer()

            Text(title).font(.headline)

            Spacer()

            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                Image(systemName: "plus")
            }.padding(.horizontal , 5)
             .foregroundColor(.green)


            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                Image(systemName: "ellipsis")
            }.padding(.horizontal , 5)
            .foregroundColor(.gray)


        }.padding(.all, 30)
    }
}
