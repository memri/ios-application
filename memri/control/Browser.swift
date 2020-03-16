//
//  ContentView.swift
//  memri
//
//  Created by Koen van der Veen on 11/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine

extension View {
    func fullHeight() -> some View {
        self.frame(minWidth: 0,
                   maxWidth: .infinity,
                   minHeight: 0, maxHeight: .infinity,
                   alignment: Alignment.topLeading)
    }
}

struct Browser: View {
    @EnvironmentObject var sessions: Sessions
    var renderers: [String: AnyView] = ["list": AnyView(ListRenderer()),
                                        "richTextEditor": AnyView(RichTextRenderer()),
                                        "thumbnail": AnyView(ThumbnailRenderer())]
    
    var currentRenderer: AnyView { renderers[sessions.currentSession.currentSessionView.rendererName,
                  default: AnyView(ThumbnailRenderer())]
    }
    
    var body: some View {
        return
            VStack() {
                TopNavigation()
                renderers[sessions.currentSession.currentSessionView.rendererName,
                          default: AnyView(ListRenderer())].fullHeight()
                Search()
                }.fullHeight()
    }
}

struct Browser_Previews: PreviewProvider {
    static var previews: some View {
        Browser().environmentObject(try! Sessions.from_json("empty_sessions"))
    }
}
