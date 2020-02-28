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
    var body: some View {
        return
            VStack {
                TopNavigation(action:{self.sessions.currentSession.back()})
                Renderer()
                Search()
            }
    }
}

struct Browser_Previews: PreviewProvider {
    static var previews: some View {
//        Browser().environmentObject(Session(SessionView(rendererName: "List",
//                        searchResult: SearchResult(query: "",data: [DataItem(uid: "0x0"), DataItem(uid: "0x1")])))
//        )
        Browser().environmentObject(        Sessions([Session(SessionView(rendererName: "List",
                searchResult: SearchResult(query: "",
                                           data: [DataItem(uid: "0x0"), DataItem(uid: "0x1")]))
                                    )            ,
                                                                              Session(SessionView(rendererName: "List",
                                                                              searchResult: SearchResult(query: "",
                                                                                                         data: [DataItem(uid: "0x0"), DataItem(uid: "0x1")]))
                                                                                                  )

                            ]
            )
        )
        

    }
}


