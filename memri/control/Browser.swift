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
    @EnvironmentObject var application: Application
    
    @State var renderername: String = "list"
    var renderers: [String: AnyView] = ["list": AnyView(ListRenderer()),
                                        "richTextEditor": AnyView(RichTextRenderer())]
    var currentRenderer: AnyView {               renderers[sessions.currentSession.currentView.rendererName,
              default: AnyView(ListRenderer())]
    }
    
    var body: some View {
        return
            VStack {
                TopNavigation()
                currentRenderer
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
        Browser().environmentObject(try! Sessions.from_json("empty_sessions"))
    }
}


