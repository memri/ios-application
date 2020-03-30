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
    @EnvironmentObject var main: Main
    
    var name: String="list"
    var icon: String=""
    var category: String=""
    var renderModes: [ActionDescription]=[]
    var options1: [ActionDescription]=[]
    var options2: [ActionDescription]=[]
    var editMode: Bool=false
    @Binding var isEditMode: EditMode
    @State var abc: Bool=false

//    var renderConfig: RenderConfig = RenderConfig()
    var renderConfig: RenderConfig = ListConfig(press:
        ActionDescription(icon: nil, title: nil, actionName: "openView", actionArgs: []))

    func setState(_ state:RenderState) -> Bool { return false }
    
    func getState() -> RenderState { RenderState() }
    func setCurrentView(_ session:Session, _ callback:(_ error:Error, _ success:Bool) -> Void) {}
    
    func generatePreview(_ item:DataItem) -> String {
        let content = item.getString("content")
        return content
    }
    
    var body: some View {
        return VStack {
            NavigationView {
                List{
                    ForEach(main.currentView.searchResult.data) { dataItem in
                        VStack{
                            Text(dataItem.getString("title"))
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(self.generatePreview(dataItem))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.onTapGesture {
                            self.onTap(actionDescription: (self.renderConfig as! ListConfig).press!, dataItem: dataItem)
                        }
//                        .padding(.horizontal, 10)
//                         .padding(.vertical, 7)
                    }.onDelete{ indexSet in
                        for i in indexSet {
                            let item = self.main.currentView.searchResult.data[i]
                            item.delete()
                        }
                        self.main.currentView.searchResult.data.remove(atOffsets: indexSet)
                        self.main.objectWillChange.send()
                    }
                }
                .environment(\.editMode, $isEditMode)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            }

        }
    }
    
    func onTap(actionDescription: ActionDescription, dataItem: DataItem){
        main.executeAction(actionDescription, dataItem)
    }
}

struct ListRenderer_Previews: PreviewProvider {
    static var previews: some View {
        ListRenderer(isEditMode: .constant(.inactive)).environmentObject(Main(name: "", key: "").mockBoot())
    }
}
