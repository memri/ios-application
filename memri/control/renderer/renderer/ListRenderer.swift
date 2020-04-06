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
    var deleteAction = ActionDescription(icon: "", title: "", actionName: .delete, actionArgs: [], actionType: .none)

    func generatePreview(_ item:DataItem) -> String {
        let content = String(item.getString("content")
            .replacingOccurrences(of: "[\\r\\n]", with: " ", options: .regularExpression)
            .prefix(100))
        return content
    }
    
    var renderConfig: ListConfig {
        return self.main.computedView.renderConfigs.list!
    }
    
    var body: some View {
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
                    List{
                    
                        ForEach(main.computedView.resultSet.items) { dataItem in
                            VStack{
                                Text(dataItem.getString("title"))
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(self.generatePreview(dataItem))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }.onTapGesture {
                                if let press = self.renderConfig.press {
                                    self.main.executeAction(press, dataItem)
                                }
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
    }
}

struct ListRenderer_Previews: PreviewProvider {
    static var previews: some View {
        ListRenderer().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
