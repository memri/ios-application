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
    
    @EnvironmentObject var sessions: Sessions
    
    var body: some View {
        return Group{
            if self.sessions.currentSession.currentSessionView.rendererName == "List" {
                List{
                    ForEach(self.sessions.currentSession.currentSessionView.searchResult.data) { dataItem in
                        VStack{
                            Text(dataItem.properties["title"]!)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(dataItem.properties["content"]!)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.onTapGesture {
                            // TODO: HOW TO MAKE THIS UPDATE AFTER CLICK IN THIS VIEW
                            self.sessions.currentSession.openView(SessionView(rendererName: "RichTextEditor",
                                                  searchResult: SearchResult(query: "", data: [dataItem])))
                        }
                    }
                }
            } else {
                TextView(dataItem: self.sessions.currentSession.currentSessionView.searchResult.data[0])
            }
        }
    }
}

struct Renderer_Previews: PreviewProvider {
    static var previews: some View {
        return Renderer().environmentObject(
            Sessions([Session(SessionView(rendererName: "List",
                    searchResult: SearchResult(query: "",
                                               data: [DataItem(uid: "0x0"), DataItem(uid: "0x1")]))
                                        )
                                ]
            )
        )
    }
}
