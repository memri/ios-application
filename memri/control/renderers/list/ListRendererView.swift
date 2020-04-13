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


struct ListRendererView: View {
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
        return self.main.computedView.renderConfigs[name] as? ListConfig ?? ListConfig()
    }
    
    struct MyButtonStyle: ButtonStyle {

      func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
          .background(configuration.isPressed ? Color.red : Color.blue)
      }

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
                    
                        ForEach(main.items) { dataItem in
                            VStack (alignment: .leading, spacing: 0){
                                Text(dataItem.getString("title"))
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(Color(hex: "#333"))
                                    .padding(.bottom, 3)
                                Text(self.generatePreview(dataItem))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(Color(hex: "#666"))
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                Rectangle()
                                    .size(width: 373, height: 1)
                                    .foregroundColor(Color(hex: "#efefef"))
                                    .padding(.top, 10)
                                    .padding(.bottom, -15)
//                                Divider()
//                                    .background(Color(hex: "#efefef"))
//                                    .padding(.top, 10)
//                                    .padding(.bottom, -5)
                            }
                            .padding(.top, 5)
//                            .listRowBackground(Color.red)
                            .onTapGesture {
                                if let press = self.renderConfig.press {
                                    self.main.executeAction(press, dataItem)
                                }
                            }
                        }.onDelete{ indexSet in
                            
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
                    .padding(.top, 5)
                }
            }
        }
    }
}

struct ListRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ListRendererView().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
