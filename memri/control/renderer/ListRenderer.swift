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
    var cascadeOrder: [String] = []
    var slideLeftActions: [ActionDescription] = []
    var slideRightActions: [ActionDescription] = []
    var press: ActionDescription? = nil
    var type: String = "list"
    var browse: String = ""
    var sortProperty: String = ""
    var sortAscending: Int = 0
    var itemRenderer: String = ""
    var longPress: ActionDescription? = nil
    

    init(name: String?=nil, icon: String?=nil, category: String?=nil, items: [ActionDescription]?=nil, options1: [ActionDescription]?=nil,
         options2: [ActionDescription]?=nil, cascadeOrder: [String]?=nil, slideLeftActions: [ActionDescription]?=nil,
         slideRightActions: [ActionDescription]?=nil, type: String?=nil, browse: String?=nil, sortProperty: String?=nil,
         sortAscending: Int?=nil, itemRenderer: String?=nil, longPress: ActionDescription?=nil, press: ActionDescription? = nil){
        super.init()
        self.cascadeOrder=cascadeOrder ?? self.cascadeOrder
        self.slideLeftActions=slideLeftActions ?? self.slideLeftActions
        self.slideRightActions=slideRightActions ?? self.slideRightActions
        self.type=type ?? self.type
        self.browse=browse ?? self.browse
        self.sortProperty=sortProperty ?? self.sortProperty
        self.sortAscending=sortAscending ?? self.sortAscending
        self.itemRenderer=itemRenderer ?? self.itemRenderer
        self.longPress=longPress ?? self.longPress
        self.press = press ?? self.press
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
    
//    var renderConfig: RenderConfig = RenderConfig()
    var renderConfig: RenderConfig = ListConfig(press: ActionDescription(icon: nil, title: nil, actionName: "openView", actionArgs: [])
    )

    func setState(_ state:RenderState) -> Bool {return false}
    
    func getState() -> RenderState {RenderState()}
    func setCurrentView(_ session:Session, _ callback:(_ error:Error, _ success:Bool) -> Void) {}
    
    @EnvironmentObject var main: Main
    
    var body: some View {
        return VStack {
            ForEach(main.currentView.searchResult.data) { dataItem in
                VStack{
                    Text(dataItem.properties["title"]!.value as! String)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(dataItem.properties["content"]!.value as! String)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.onTapGesture {
                    self.onTap(actionDescription: (self.renderConfig as! ListConfig).press!, dataItem: dataItem)
                    
                }.padding(.horizontal, 10)
                 .padding(.vertical, 7)
            }
        }
    }
    
    func onTap(actionDescription: ActionDescription, dataItem: DataItem){
        main.currentSession.executeAction(action: actionDescription, dataItem: dataItem)
        
    }
}

struct ListRenderer_Previews: PreviewProvider {
    static var previews: some View {
        ListRenderer().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
