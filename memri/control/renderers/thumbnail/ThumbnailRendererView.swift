//
//  TumbnailRenderer.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import QGrid

extension Text {
    func asThumbnail(withMaxWidth maxWidth: CGFloat = 120) -> some View {
        self.bold()
            .frame(minWidth: maxWidth, maxWidth: maxWidth, minHeight: maxWidth, maxHeight: maxWidth)
            .background(Color(red: 250 / 255, green: 252 / 255, blue: 252 / 255))
    }
}


struct ThumbnailRendererView: View {
    @EnvironmentObject var main: Main
    
    var name: String="thumbnail"
    
    var renderConfig: ThumbnailConfig {
        if self.main.computedView.renderConfigs[name] == nil {
            print ("Warning: Using default render config for thumbnail")
        }
        
        return self.main.computedView.renderConfigs[name] as? ThumbnailConfig ?? ThumbnailConfig()
    }
    
    var body: some View {
        VStack {
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
                // TODO: vPadding, hPadding, vSpacing, hSpacing, columnsInLandscape
                QGrid(main.items, columns: renderConfig.cols.value!, vPadding: 20, hPadding: 20) { dataItem in
//                    VStack (alignment: .center) {
////                        HStack {
//                            Text(dataItem.getString("content"))
//                                .frame(minWidth: 0, maxWidth: .greatestFiniteMagnitude, minHeight: 100, maxHeight: .greatestFiniteMagnitude, alignment: Alignment.topLeading)
//                                .foregroundColor(Color(hex:"#555"))
//                                .font(.system(size: 9, weight: .regular, design: .default))
//                                .border(Color(hex: "#00ff00"), width: 1)
////                        }
//                        .padding(4)
//
//                        .border(Color(hex: "#ff0000"), width: 1)
//                        .background(Color(hex:"#efefef"))
//
//                        Text (dataItem.getString("title"))
//                            .padding(2) // [2, 0, 5, 0],
//                            .font(.system(size: 10, weight: .regular, design: .default))
//                    }
//                    .padding(0) // = [0, 0, 5, 0],
                    
                    
                    self.renderConfig.render(dataItem)
                        .onTapGesture {
                            if let press = self.renderConfig.press {
                                self.main.executeAction(press, dataItem)
                            }
                        }
                }
            }
        }
    }
    
    func onTap(actionDescription: ActionDescription, dataItem: DataItem){
        main.executeAction(actionDescription, dataItem)
    }
}

struct ThumbnailRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailRendererView().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
