//
//  ContentView.swift
//  memri
//
//  Created by Koen van der Veen on 11/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

struct Browser: View {
    @EnvironmentObject var main: Main
    
    var renderers: [String: AnyView] = ["list": AnyView(ListRenderer()),
                                        "richTextEditor": AnyView(RichTextRenderer()),
                                        "thumbnail": AnyView(ThumbnailRenderer())]
    
    var currentRenderer: AnyView { renderers[main.currentView.rendererName!,
                  default: AnyView(ThumbnailRenderer())]
    }
    
    var body: some View {
        return
            VStack() {
                TopNavigation()
                renderers[main.currentView.rendererName!,
                          default: AnyView(ListRenderer())].fullHeight()
                Search()
                }
    }

    /**
     * Toggle the UI into edit mode
     */
    @State public var editMode: Bool = false
}

struct Browser_Previews: PreviewProvider {
    static var previews: some View {
        Browser().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
