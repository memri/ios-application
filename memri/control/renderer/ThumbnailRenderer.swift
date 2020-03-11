//
//  TumbnailRenderer.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

extension Text {
    func asThumbnail(withMaxWidth maxWidth: CGFloat = 120) -> some View {
        self.bold()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: maxWidth,
                   maxHeight: maxWidth)
            .background(Color(red: 252 / 255, green: 252 / 255, blue: 252 / 255))
    }
}

struct ThumbnailRenderer: View {
    var name: String="thumbnail"
    var icon: String=""
    var category: String=""
    var renderModes: [ActionDescription]=[]
    var options1: [ActionDescription]=[]
    var options2: [ActionDescription]=[]
    var editMode: Bool=false
    var renderConfig: RenderConfig=RenderConfig(name: "", icon: "", category: "", items: [], options1: [], options2: [])

    func setState(_ state:RenderState) -> Bool {return false}
    func getState() -> RenderState {RenderState()}
    func setCurrentView(_ session:Session, _ callback:(_ error:Error, _ success:Bool) -> Void) {}
    
    @EnvironmentObject var sessions: Sessions
    var body: some View {
        VStack{
            ForEach(0..<chunked(items: self.sessions.currentSession.currentSessionView.searchResult.data, into: 3).count) { index in
                    HStack {
                        ForEach(self.chunked(items: self.sessions.currentSession.currentSessionView.searchResult.data, into: 3)[index]) { dataItem in
                            Text(dataItem.properties["title"] ?? "default title").asThumbnail().onTapGesture {                    self.sessions.currentSession.openView(SessionView.fromSearchResult(searchResult: SearchResult.fromDataItems([dataItem]),
                                    rendererName: "richTextEditor"))
                            }
                        }
                    }
                }
        }
    }
    
    func chunked(items: [DataItem], into size:Int) -> [[DataItem]] {
        var chunkedArray = [[DataItem]]()
        for index in 0...items.count {
            if index % size == 0 && index != 0 {
                chunkedArray.append(Array(items[(index - size)..<index]))
            } else if(index == items.count) {
                chunkedArray.append(Array(items[index - (index % size)..<index]))
            }
        }
        return chunkedArray
    }
}

struct ThumbnailRenderer_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailRenderer().environmentObject(try! Sessions.from_json("empty_sessions"))
    }
}
