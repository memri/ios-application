//
//  TumbnailRenderer.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import QGrid

extension Text {
    func asThumbnail(withMaxWidth maxWidth: CGFloat = 120) -> some View {
        self.bold()
            .frame(minWidth: maxWidth, maxWidth: maxWidth, minHeight: maxWidth, maxHeight: maxWidth)
            .background(Color(red: 250 / 255, green: 252 / 255, blue: 252 / 255))
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
    
    var cols: Int = 3

    func setState(_ state:RenderState) -> Bool {return false}
    func getState() -> RenderState {RenderState()}
    func setCurrentView(_ session:Session, _ callback:(_ error:Error, _ success:Bool) -> Void) {}
    
    @EnvironmentObject var sessions: Sessions
    var body: some View {
        
        QGrid(self.sessions.currentSession.currentSessionView.searchResult.data, columns: 3) { dataItem in
                Text(dataItem.properties["title"] ?? "default title").asThumbnail()
                    .onTapGesture {
                        self.sessions.currentSession.openView(
                            SessionView.fromSearchResult(searchResult: SearchResult.fromDataItems([dataItem]),
                                                         rendererName: "richTextEditor")
                        )
                }
        }
    }
    
}

struct ThumbnailRenderer_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailRenderer().environmentObject(try! Sessions.from_json("empty_sessions"))
    }
}
