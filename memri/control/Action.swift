//
//  Action.swift
//  memri
//
//  Created by Koen van der Veen on 30/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct Action: View {
    
    @EnvironmentObject var main: Main
    var action: ActionDescription?
    
    // type (button)
    // foregroundColor
    // text optional
    // actionName
    //
    
    var body: some View {
        VStack{
            if action != nil {
                Button(action: {self.main.executeAction(self.action!)} ) {
                    Image(systemName: main.currentSession.backButton!.icon)
                    .foregroundColor(.gray)
                    if main.currentView.backTitle != nil{
                        Text(main.currentView.backTitle!)
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                }.padding(.horizontal, 5)
            } else{
                EmptyView()
            }
            
        }
    }
        
}

struct Action_Previews: PreviewProvider {
    static var previews: some View {
        Action().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
