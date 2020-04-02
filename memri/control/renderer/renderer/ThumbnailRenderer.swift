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


struct ThumbnailRenderer: View {
    @EnvironmentObject var main: Main
    var name: String="thumbnail"
    var renderConfig: ThumbnailConfig {
        return self.main.getRenderConfig(name: self.name) as! ThumbnailConfig
    }
    
    var body: some View {
        QGrid(main.computedView.searchResult.data, columns: renderConfig.cols) { dataItem in

            Text(dataItem.getString("title")).asThumbnail()
                .onTapGesture {
                    self.onTap(actionDescription: (self.renderConfig as! ListConfig).press!, dataItem: dataItem)
                }
        }
    }
    
    func onTap(actionDescription: ActionDescription, dataItem: DataItem){
        main.executeAction(actionDescription, dataItem)
        
    }
}

struct ThumbnailRenderer_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailRenderer().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
