//
//  ContentView.swift
//  memri
//
//  Created by Koen van der Veen on 11/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI
import Combine


struct Browser<Content: Renderer>: View {
    @EnvironmentObject var sessions: Sessions
    
    var renderername: String
    var renderers: [String: Content]

    
    init(renderername: String, renderers: [String: Content]=[:]){
        self.renderername = renderername
        self.renderers = renderers
        
    }
    
    var body: some View {
        return
            VStack {
                TopNavigation()
                renderers[renderername]
//                renderer
                Search()
            }
    }
}

struct Browser_Previews: PreviewProvider {
    static var previews: some View {
        Browser(renderername: "list",
                renderers: ["list": ListRenderer(),
                            "single_item_view": SingleItemRenderer()]
        ).environmentObject(try! Sessions.from_json("empty_sessions"))
    }
}


