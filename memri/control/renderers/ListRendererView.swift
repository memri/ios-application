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
        canDisplayResults: { items -> Bool in true }
    )
    
    Renderers.register(
        name: "list.alphabet",
        title: "Alphabet",
        order: 1,
        view: AnyView(ListRendererView()),
        canDisplayResults: { items -> Bool in true }
    )
}()

class CascadingListConfig: CascadingRenderConfig {
    var type: String? = "list"
    
    var longPress: Action? { cascadeProperty("longPress", nil) }
    var press: Action? { cascadeProperty("press", nil) }
    
    var slideLeftActions:[Action] { cascadeList("slideLeftActions") }
    var slideRightActions:[Action] { cascadeList("slideRightActions") }
}

struct ListRendererView: View {
    @EnvironmentObject var main: Main
    
    let name = "list"
    let deleteAction = Action(icon: "", title: "", actionName: .delete, actionArgs: [], actionType: .none)
    
    var renderConfig: CascadingListConfig {
        return self.main.cascadingView.renderConfigs[name] as? CascadingListConfig ?? CascadingListConfig()
    }
    
    init() {
        UITableView.appearance().separatorColor = .clear
    }
    
    struct MyButtonStyle: ButtonStyle {

      func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
          .background(configuration.isPressed ? Color.red : Color.blue)
      }

    }
    
    var body: some View {
        let guiEl = renderConfig.renderDescription?["*"]
        if guiEl != nil {
            if guiEl!._properties["padding"] == nil {
                guiEl!._properties["padding"] = [CGFloat(10), CGFloat(10), CGFloat(10), CGFloat(20)]
            }
        }
        
        return VStack{
            if main.cascadingView.resultSet.count == 0 {
                HStack (alignment: .top)  {
                    Spacer()
                    Text(self.main.cascadingView.emptyResultText)
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
                                if let press = self.renderConfig.press {
                                    self.main.executeAction(press, dataItem)
                                }
                            }) {
                                self.renderConfig.render(item: dataItem)
                            }
                            .listRowInsets(EdgeInsets(top:0, leading:0, bottom:0, trailing:0))
                        }
                        .onDelete{ indexSet in
                            
                            // TODO this should happen automatically in ResultSet
                            self.main.items.remove(atOffsets: indexSet)
                            
                            // I'm sure there is a better way of doing this...
                            var items:[DataItem] = []
                            for i in indexSet {
                                let item = self.main.items[i]
                                items.append(item)
                            }
                            
                            // Execute Action
                            self.main.executeAction(self.deleteAction, nil, items)

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
