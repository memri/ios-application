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
    @ObservedObject var dataStore: DataStore = DataStore()
    @EnvironmentObject var sessionViewStack: SessionViewStack

    
    var body: some View {
        return
            VStack {
                TopNavigation(action:{self.sessionViewStack.back()})
                Renderer(dataStore: self.dataStore)
                Search()
                }
            
    }
}

struct Browser_Previews: PreviewProvider {
    static var previews: some View {
        Browser().environmentObject(SessionViewStack( sessionView(rendererName: "List", data: nil)))
    }
}


