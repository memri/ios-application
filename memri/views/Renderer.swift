//
//  Renderer.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

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
    var backGroundColor: Color { self.selected ? Color(white: 0.95) : Color(white: 1.0)}
    var foreGroundColor: Color { self.selected ? Color.green : Color.gray}
}



struct Renderer: View {
    
    @ObservedObject var dataStore: DataStore
    @EnvironmentObject var sessionViewStack: SessionViewStack
    
    var body: some View {
        return Group{
            if self.sessionViewStack.currentSessionView.rendererName == "List" {
                List{
                    ForEach(dataStore.data) { note in
                        VStack{
                            Text(note.title)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(note.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.onTapGesture {
                            self.sessionViewStack.openView(sessionView(rendererName: "RichTextEditor", data: note))
                        }
                    }
                }
            } else {
                TextView(note: self.sessionViewStack.currentSessionView.data!)
            }
        }
    }
}

struct Renderer_Previews: PreviewProvider {
    static var previews: some View {
        return Renderer(dataStore: DataStore()).environmentObject(SessionViewStack( sessionView(rendererName: "List", data: nil)))
    }
}
