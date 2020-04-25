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
                QGrid(main.items,
                      columns: renderConfig.columns.value ?? 3,
                      columnsInLandscape: renderConfig.columnsInLandscape.value ?? 5,
                      vSpacing: CGFloat(renderConfig.vSpacing.value ?? 10),
                      hSpacing: CGFloat(renderConfig.hSpacing.value ?? 10),
                      vPadding: CGFloat(renderConfig.vPadding.value ?? 20),
                      hPadding: CGFloat(renderConfig.hPadding.value ?? 20)
                ) { dataItem in
                    
                    self.renderConfig.render(item: dataItem)
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
        ThumbnailRendererView().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
