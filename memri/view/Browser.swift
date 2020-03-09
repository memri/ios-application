//
//  ContentView.swift
//  memri
//
//  Created by Koen van der Veen on 11/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI
import Combine


struct Browser: View {
    @EnvironmentObject var sessions: Sessions
    @State var renderername: String = "list"
        
    var renderers: [String: AnyView] = ["list": AnyView(ListRenderer()),
                                        "richTextEditor": AnyView(RichTextEditor())]
    
    var body: some View {
        return
            VStack {
                TopNavigation()
                renderers[sessions.currentSession.currentSessionView.rendererName,
                          default: AnyView(ListRenderer())]
                Search()
            }
    }
}




struct Browser_Previews: PreviewProvider {
    static var previews: some View {
        Browser().environmentObject(try! Sessions.from_json("empty_sessions"))
    }
}


