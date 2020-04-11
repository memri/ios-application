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
                Text(main.computedView.title).font(.headline)
            }
            HStack(spacing: 10){
                
                Action(action: ActionDescription(actionName: .showNavigation))
                    .font(Font.system(size: 20, weight: .semibold))
                
                Action(action: main.currentSession.backButton)
                    .font(Font.system(size: 19, weight: .semibold))
                
                Spacer()
                
                // TODO setting to not display edit action button in multi-item views
                Action(action: main.computedView.editActionButton)
                    .font(Font.system(size: 19, weight: .semibold))
                
                Action(action: main.computedView.actionButton)
                    .font(Font.system(size: 22, weight: .semibold))
                
                Action(action: ActionDescription(actionName: .showSessionSwitcher))
                    .font(Font.system(size: 20, weight: .medium))
                    .rotationEffect(.degrees(90))
                    
            }
            .padding(.vertical, 30)
            .padding(.leading, 15)
            .padding(.trailing, 15)
        }
    }
}

struct Topnavigation_Previews: PreviewProvider {
    static var previews: some View {
        TopNavigation().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
