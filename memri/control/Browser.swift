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
    @State var isEditMode: EditMode = .inactive
    
    var body: some View {
        return
            VStack() {
                TopNavigation(isEditMode: $isEditMode)
                getRenderer().fullHeight()
                Search()
            }.fullHeight()
    }
    
    
    func getRenderer() -> AnyView{
        switch self.sessions.currentSession.currentSessionView.rendererName{
        case "list":
            return AnyView(ListRenderer(isEditMode: $isEditMode))
        case "richTextEditor":
            return AnyView(RichTextRenderer())
        case "thumbnail":
            return AnyView(ThumbnailRenderer())
        default:
            return AnyView(ThumbnailRenderer())
        }
    }
    
}

struct Browser_Previews: PreviewProvider {
    static var previews: some View {
        Browser().environmentObject(try! Sessions.from_json("empty_sessions"))
    }
}
