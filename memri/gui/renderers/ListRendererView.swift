//
//  ListRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import ASCollectionView

let registerListRenderer = {
    Renderers.register(
        name: "list",
        title: "Default",
        order: 0,
        icon: "line.horizontal.3",
        view: AnyView(ListRendererView()),
        renderConfigType: CascadingListConfig.self,
        canDisplayResults: { items -> Bool in true }
    )
        
    Renderers.register(
        name: "list.alphabet",
        title: "Alphabet",
        order: 10,
        view: AnyView(ListRendererView()),
        renderConfigType: CascadingListConfig.self,
        canDisplayResults: { items -> Bool in true }
    )
}

class CascadingListConfig: CascadingRenderConfig, CascadingRendererDefaults {
    var type: String? = "list"
    
    var longPress: Action? { cascadeProperty("longPress") }
    var press: Action? { cascadeProperty("press") }
    
    var slideLeftActions:[Action] { cascadeList("slideLeftActions") }
    var slideRightActions:[Action] { cascadeList("slideRightActions") }
    
    public func setDefaultValues(_ element:UIElement) {
        if element.properties["padding"] == nil {
            element.properties["padding"] = [CGFloat(10), CGFloat(10), CGFloat(10), CGFloat(20)]
        }
    }
}

struct ListRendererView: View {
    @EnvironmentObject var context: MemriContext
    var selectedIndices: Binding<Set<Int>> {
        Binding<Set<Int>>(
            get: { [] },
            set: { self.context.cascadingView.userState.set("selection", $0.compactMap { self.context.items[safe: $0] }) }
        )
    }
    
    let name = "list"
    
    var renderConfig: CascadingListConfig {
        self.context.cascadingView.renderConfig as? CascadingListConfig ?? CascadingListConfig()
    }
    
    var body: some View {
        let context = self.context
        
        return VStack {
            if context.cascadingView.resultSet.count == 0 {
                HStack (alignment: .top)  {
                    Spacer()
                    Text(context.cascadingView.emptyResultText)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .opacity(0.7)
                    Spacer()
                }
                .padding(.all, 30)
                .padding(.top, 40)
                Spacer()
            }
            else {
                ASTableView(section:
                        ASSection(id: 0,
                                  data: context.items,
                                  dataID: \.memriID,
                                  selectedItems: selectedIndices,
                                  onSwipeToDelete: { index, item, callback in
                                    context.executeAction(ActionDelete(context), with: item)
                                    callback(true)
                        }
                        ) { dataItem, cellContext in
                            self.renderConfig.render(item: dataItem)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .environmentObject(context)
                        }
                        .onSelectSingle({ (index) in
                            if let press = self.renderConfig.press {
                                context.executeAction(press, with: context.items[safe: index])
                            }
                        })
                )
                .alwaysBounce()
                
            }
        }
    }
}

struct ListRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ListRendererView().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
