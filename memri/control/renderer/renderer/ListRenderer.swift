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


struct ListRenderer: Renderer {
    @EnvironmentObject var main: Main
    
    let name = "list"
    var renderConfig: ListConfig {
        return self.main.getRenderConfig(name: self.name) as! ListConfig
    }
    var deleteAction = ActionDescription(icon: "", title: "", actionName: .delete, actionArgs: [], actionType: .none)
    
//    @Binding var isEditMode: EditMode

    func generatePreview(_ item:DataItem) -> String {
        let content = item.getString("content")
        return content
    }
    
    var body: some View {
        return VStack {
            NavigationView {
                List{
                    ForEach(main.computedView.resultSet.items) { dataItem in
                        VStack{
                            Text(dataItem.getString("title"))
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(self.generatePreview(dataItem))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.onTapGesture {
                            self.onTap(actionDescription: self.renderConfig.press!,
                                       dataItem: dataItem)
                        }
                    }.onDelete{ indexSet in
                        
                        // TODO this should happen automatically in ResultSet
                        self.main.computedView.resultSet.items.remove(atOffsets: indexSet)
                        
                        // I'm sure there is a better way of doing this...
                        var items:[DataItem] = []
                        for i in indexSet {
                            let item = self.main.computedView.resultSet.items[i]
                            items.append(item)
                        }
                        
                        // Execute Action
                        self.main.executeAction(self.deleteAction, nil, items)

                    }
                }
                .environment(\.editMode, $main.sessions.isEditMode)
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
        ListRenderer().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
