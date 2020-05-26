//
//  ListRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI


struct ListRendererView: View {
    @EnvironmentObject var main: Main
    
//    let name = "list"
//    let deleteAction = ActionDescription(icon: "", title: "", actionName: .delete, actionArgs: [], actionType: .none)
    
//    var renderConfig: ListConfig {
//        return self.main.computedView.renderConfigs[name] as? ListConfig ?? ListConfig()
//    }
//
//    init() {
//        UITableView.appearance().separatorColor = .clear
//    }
    
    struct MyButtonStyle: ButtonStyle {

      func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
          .background(configuration.isPressed ? Color.red : Color.blue)
      }

    }
    
    var body: some View {
//        let guiEl = renderConfig.renderDescription?["*"]
//        if guiEl != nil {
//            if guiEl!._properties["padding"] == nil {
//                guiEl!._properties["padding"] = [CGFloat(10), CGFloat(10), CGFloat(10), CGFloat(20)]
//            }
//        }
        
        return VStack{
            if main.computedView.resultSet.count == 0 {
                HStack (alignment: .top)  {
                    Spacer()
                    Text(self.main.computedView.emptyResultText)
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
                NavigationView {
//                    SwiftUI.List {
//                        ForEach(main.items) { dataItem in
//                            Button (action:{
//                                if let press = self.renderConfig.press {
//                                    self.main.executeAction(press, dataItem)
//                                }
//                            }) {
//                                self.renderConfig.render(item: dataItem)
//                            }
//                            .listRowInsets(EdgeInsets(top:0, leading:0, bottom:0, trailing:0))
//                        }
//                        .onDelete{ indexSet in
//                            
//                            // TODO this should happen automatically in ResultSet
//                            self.main.items.remove(atOffsets: indexSet)
//                            
//                            // I'm sure there is a better way of doing this...
//                            var items:[DataItem] = []
//                            for i in indexSet {
//                                let item = self.main.items[i]
//                                items.append(item)
//                            }
//                            
//                            // Execute Action
//                            self.main.executeAction(self.deleteAction, nil, items)
//
//                        }
//                    }
                    TableView<DataItem,GUIElementInstance>(main: self.main, canReorder: false)
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
