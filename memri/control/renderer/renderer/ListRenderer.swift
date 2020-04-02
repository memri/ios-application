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
    var name="list"
    var renderConfig: ListConfig {
        return self.main.getRenderConfig(name: self.name) as! ListConfig
    }
    
    @Binding var isEditMode: EditMode

    func generatePreview(_ item:DataItem) -> String {
        let content = item.getString("content")
        return content
    }
    
    var body: some View {
        return VStack {
            NavigationView {
                List{
                    ForEach(main.computedView.searchResult.data) { dataItem in
                        VStack{
                            Text(dataItem.getString("title"))
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(self.generatePreview(dataItem))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.onTapGesture {
                            self.onTap(actionDescription: (self.renderConfig).press!,
                                       dataItem: dataItem)
                        }
                    }.onDelete{ indexSet in
                        for i in indexSet {
                            let item = self.main.computedView.searchResult.data[i]
                            let _ = item.delete()
                        }
                        self.main.computedView.searchResult.data.remove(atOffsets: indexSet)
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
