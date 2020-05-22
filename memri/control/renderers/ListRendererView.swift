//
//  ListRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

private var register:Void = {
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
        order: 1,
        view: AnyView(ListRendererView()),
        renderConfigType: CascadingListConfig.self,
        canDisplayResults: { items -> Bool in true }
    )
}()

class CascadingListConfig: CascadingRenderConfig, CascadingRendererDefaults {
    var type: String? = "list"
    
    var longPress: Action? { cascadeProperty("longPress", nil) }
    var press: Action? { cascadeProperty("press", nil) }
    
    var slideLeftActions:[Action] { cascadeList("slideLeftActions") }
    var slideRightActions:[Action] { cascadeList("slideRightActions") }
    
    public func setDefaultValues(_ element:UIElement) {
        if element.properties["padding"] == nil {
            element.properties["padding"] = [CGFloat(10), CGFloat(10), CGFloat(10), CGFloat(20)]
        }
    }
}

struct ListRendererView: View {
    @EnvironmentObject var main: Main
    
    let name = "list"
    
    var renderConfig: CascadingListConfig? {
        self.main.cascadingView.renderConfig as? CascadingListConfig
    }
    
    init() {
        UITableView.appearance().separatorColor = .clear
    }
    
    var body: some View {
        let renderConfig = self.renderConfig
        let main = self.main
        
        return VStack{
            if renderConfig == nil {
                Text("Unable to render this view")
            }
            else if main.cascadingView.resultSet.count == 0 {
                HStack (alignment: .top)  {
                    Spacer()
                    Text(main.cascadingView.emptyResultText)
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
                NavigationView{
                    // TODO REfactor: why are there 2px between each list row?
                    SwiftUI.List {
                        ForEach(main.items) { dataItem in
                            Button (action:{
                                if let press = renderConfig!.press {
                                    main.executeAction(press, with: dataItem)
                                }
                            }) {
                                renderConfig!.render(item: dataItem)
                            }
                            .listRowInsets(EdgeInsets(top:0, leading:0, bottom:0, trailing:0))
                        }
                        .onDelete{ indexSet in
                            main.executeAction(Action("delete"))
                        }
                    }
                    .environment(\.editMode, $main.currentSession.isEditMode)
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                }
            }
        }
    }
}

struct ListRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ListRendererView().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
