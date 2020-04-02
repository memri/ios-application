//
//  Search.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

struct SortButton: Identifiable {
    var id = UUID()
    var name: String
    var selected: Bool
    var color: Color {self.selected ? Color.green : Color.black}
    var fontWeight: Font.Weight? {self.selected ? .bold : .none}
}

struct BrowseSetting: Identifiable {
    var id = UUID()
    var name: String
    var selected: Bool
    var color: Color {self.selected ? Color.green : Color.black}
    var fontWeight: Font.Weight? {self.selected ? .bold : .none}
}

struct ViewTypeButton: Identifiable {
    var id = UUID()
    var imgName: String
    var selected: Bool
    var rendererName: String
    var backgroundColor: Color { self.selected ? Color(white: 0.95) : Color(white: 1.0)}
    var foreGroundColor: Color { self.selected ? Color.green : Color.gray}
}

struct Search: View {
    @EnvironmentObject var main: Main

    @State var searchText=""


    var body: some View {
        VStack{
            HStack{
                TextField("type your search query here", text: $searchText)
                    .onReceive(Just(searchText)) { (newValue: String) in
                        self.main.search(self.searchText)
                    }
                if self.main.computedView.filterButtons != nil{
                    ForEach(self.main.computedView.filterButtons!){ filterButton in
                        
                        // TODO: buttonview
                        
                        Action(action: filterButton)
                            .font(Font.system(size: 20, weight: .medium))

                        
//                        Button(action: {self.main.executeAction(filterButton)}) {
//                            Image(systemName: filterButton.icon)
//                        }.padding(.horizontal , 5)
//                         .font(Font.system(size: 20, weight: .medium))
//                            .foregroundColor(Color(filterButton.color))
                        
                    }
                }
            }.padding(.horizontal , 15)
            FilterPanel()
        }
    }
}

struct Search_Previews: PreviewProvider {
    static var previews: some View {
        Search().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
