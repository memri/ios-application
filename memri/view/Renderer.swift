//
//  Renderer.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

public class RenderConfig: Codable {
    var name: String
    var icon: String
    var category: String
    var items: [ActionDescription]
    var options1: [ActionDescription]
    var options2: [ActionDescription]
    
    init(name: String, icon: String, category: String, items: [ActionDescription], options1: [ActionDescription],
         options2: [ActionDescription]){
        self.name=name
        self.icon=icon
        self.category=category
        self.items=items
        self.options1=options1
        self.options2=options2
    }
}


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

public class RenderState{}


public protocol Renderer: View {
    var name: String {get set}
    var icon: String {get set}
    var category: String {get set}
    
    
    var renderModes: [ActionDescription]  {get set}
    var options1: [ActionDescription] {get set}
    var options2: [ActionDescription] {get set}
    var editMode: Bool {get set}
    var renderConfig: RenderConfig {get set}

    func setState(_ state:RenderState) -> Bool
    func getState() -> RenderState
    func setCurrentView(_ session:Session, _ callback:(_ error:Error, _ success:Bool) -> Void)
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

    func setState(_ state:RenderState) -> Bool {false}
    func getState() -> RenderState {RenderState()}
    func setCurrentView(_ session:Session, _ callback:(_ error:Error, _ success:Bool) -> Void) {}
    
    @EnvironmentObject var sessions: Sessions
    
    var body: some View {
        return VStack{
            List{
                ForEach(self.sessions.currentSession.currentSessionView.searchResult.data) { dataItem in
                    VStack{
                        Text(dataItem.properties["title"]!)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(dataItem.properties["content"]!)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.onTapGesture {
                        self.sessions.currentSession.openView(SessionView.fromSearchResult(searchResult: SearchResult.fromDataItems([dataItem]),
                            rendererName: "richTextEditor"))
                    }
                }
            }
        }
    }
}

struct RichTextEditor: Renderer {
    var name: String="singleItem"
    var icon: String=""
    var category: String=""
    var renderModes: [ActionDescription]=[]
    var options1: [ActionDescription]=[]
    var options2: [ActionDescription]=[]
    var editMode: Bool=false
    var renderConfig: RenderConfig=RenderConfig(name: "", icon: "", category: "", items: [], options1: [], options2: [])

    func setState(_ state:RenderState) -> Bool {false}
    func getState() -> RenderState {RenderState()}
    func setCurrentView(_ session:Session, _ callback:(_ error:Error, _ success:Bool) -> Void) {}
    @EnvironmentObject var sessions: Sessions

    var body: some View {
        return VStack{
                TextView(dataItem: self.sessions.currentSession.currentSessionView.searchResult.data[0])
        }
    }
}

//struct Renderer_Previews: PreviewProvider {
//    static var previews: some View {
//        return Renderer().environmentObject(try! Sessions.from_json("empty_sessions"))
//    }
//}
