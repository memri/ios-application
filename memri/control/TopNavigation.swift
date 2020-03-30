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
    @Binding var isEditMode:EditMode
        
    public var body: some View {
        ZStack{
            // we place the title *over* the rest of the topnav, to center it horizontally
            HStack{
                if main.currentView.title != nil{
                    Text(main.currentView.title!).font(.headline)
                }
            }
            HStack(spacing: 20){
                
                Action(action: ActionDescription(icon: "line.horizontal.3", actionName: .showNavigation))
                    .font(Font.system(size: 20, weight: .medium))
                
                Action(action: main.currentSession.backButton)
                
                Spacer()
                if self.main.currentView.editActionButton != nil {
                    Button(action: editAction) {
                        Image(systemName: main.currentView.editActionButton!.icon)
                    }
                    .foregroundColor(.gray)
                }
                
                
                Action(action: main.currentView.actionButton)
                Action(action: ActionDescription(icon: "ellipsis", actionName: .noop))
                    
            }.padding(.all, 30)
        }
    }
    
    func backButtonAction(){
        main.executeAction(main.currentSession.backButton!)
    }
    
    func editAction(){
        switch self.isEditMode{
            case .active:
                self.isEditMode = .inactive
            case .inactive:
                self.isEditMode = .active
            default:
                break
        }
    }
}

struct Topnavigation_Previews: PreviewProvider {
    static var previews: some View {
        TopNavigation(isEditMode: .constant(.inactive)).environmentObject(Main(name: "", key: "").mockBoot())
    }
}
