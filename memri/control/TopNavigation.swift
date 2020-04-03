//
//  TopNavigation.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

public struct TopNavigation: View {
    @EnvironmentObject var main: Main
        
    public var body: some View {
        ZStack{
            // we place the title *over* the rest of the topnav, to center it horizontally
            HStack{
                if main.computedView.title != nil{
                    Text(main.computedView.title!).font(.headline)
                }
            }
            HStack(spacing: 20){
                
                Action(action: ActionDescription(icon: "line.horizontal.3", actionName: .showNavigation))
                    .font(Font.system(size: 20, weight: .medium))
                
                Action(action: main.currentSession.backButton)
                
                Spacer()
                
                Action(action: main.computedView.editActionButton)
                
                Action(action: main.computedView.actionButton)
                Action(action: ActionDescription(icon: "ellipsis", actionName: .noop))
                    
            }.padding(.all, 30)
        }
    }
}

struct Topnavigation_Previews: PreviewProvider {
    static var previews: some View {
        TopNavigation().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
