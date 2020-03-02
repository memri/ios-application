//
//  TopNavigation.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct TopNavigation: View {
    @EnvironmentObject var sessions: Sessions

    var title: String = ""
//    var action: ()->Void = {sessions.currentSession.back()}
//    var action: [String: ()->Void] = [:]


    var hideBack:Bool = false
    
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.gray)
                    .font(Font.system(size: 20, weight: .medium))
            }.padding(.horizontal , 5)

            Button(action: sessions.currentSession.back ) {
                Image(systemName: "chevron.left")
                .foregroundColor(.gray)

            }.padding(.horizontal , 5)

            Spacer()

            Text(sessions.currentSession.currentSessionView.title).font(.headline)

            Spacer()

            Button(action: newDataItem) {
                Image(systemName: "plus")
            }.padding(.horizontal , 5)
             .foregroundColor(.green)


            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                Image(systemName: "ellipsis")
            }.padding(.horizontal , 5)
            .foregroundColor(.gray)


        }.padding(.all, 30)
    }
    
    func newDataItem(){
        let n = self.sessions.currentSession.currentSessionView.searchResult.data.count + 100
        let dataItem = DataItem(uid: "0x0\(n)", properties: ["title": "new note", "content": ""])
        self.sessions.currentSession.currentSessionView.searchResult.data.append(dataItem)
        self.sessions.currentSession.openView(SessionView(rendererName: "RichTextEditor",
                              searchResult: SearchResult(query: "", data: [dataItem]),
                              title: "new note"))
    }
}


struct Topnavigation_Previews: PreviewProvider {
    static var previews: some View {
        TopNavigation().environmentObject(try! Sessions.from_json("empty_sessions"))
    }
}
