//
//  ListRenderer.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class ListConfig: RenderConfig {
    var cascadeOrder: [String]
    var slideLeftActions: [ActionDescription]
    var slideRightActions: [ActionDescription]
    var type: String
    var browse: String
    var sortProperty: String
    var sortAscending: Int
    var itemRenderer: String
    var longPress: ActionDescription

    init(name: String, icon: String, category: String, items: [ActionDescription], options1: [ActionDescription],
         options2: [ActionDescription], cascadeOrder: [String], slideLeftActions: [ActionDescription],
         slideRightActions: [ActionDescription], type: String, browse: String, sortProperty: String,
         sortAscending: Int, itemRenderer: String, longPress: ActionDescription){
        self.cascadeOrder=cascadeOrder
        self.slideLeftActions=slideLeftActions
        self.slideRightActions=slideRightActions
        self.type=type
        self.browse=browse
        self.sortProperty=sortProperty
        self.sortAscending=sortAscending
        self.itemRenderer=itemRenderer
        self.longPress=longPress
        super.init(name: name, icon: icon, category: category, items: items, options1: options1, options2: options2)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

struct ListRenderer: Renderer {
    var name: String="list"
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
        return VStack {                     ForEach(self.sessions.currentSession.currentSessionView.searchResult.data) { dataItem in
                    VStack{
                        Text(dataItem.properties["title"] ?? "")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(dataItem.properties["content"] ?? "")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.onTapGesture {                    self.sessions.currentSession.openView(SessionView.fromSearchResult(searchResult: SearchResult.fromDataItems([dataItem]),
                            rendererName: "richTextEditor"))
                    }.padding(.horizontal, 10)
                     .padding(.vertical, 7)
            }
        }
    }
}

struct ListRenderer_Previews: PreviewProvider {
    static var previews: some View {
        ListRenderer().environmentObject(try! Sessions.from_json("empty_sessions"))
    }
}
