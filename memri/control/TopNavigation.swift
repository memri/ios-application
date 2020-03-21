//
//  TopNavigation.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct TopNavigation: View {
    @EnvironmentObject var main: Main
    
    @State private var show_contextpage: Bool = false
    @Binding var isEditMode:EditMode
    
    var title: String = ""
//    var action: ()->Void = {sessions.currentSession.back()}
//    var action: [String: ()->Void] = [:]

    var hideBack:Bool = false
    
    var body: some View {
        
        ZStack{
            // we place the title *over* the rest of the topnav, to center it horizontally
            HStack{
                Text(main.currentView.title).font(.headline)
            }
            HStack{
                Button(action: {}) {
                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(.gray)
                        .font(Font.system(size: 20, weight: .medium))
                }.padding(.horizontal, 5)

                if main.currentView.backButton != nil {
                    Button(action: backButtonAction ) {
                        Image(systemName: main.currentView.backButton!.icon)
                        .foregroundColor(.gray)
                        if main.currentView.backTitle != nil{
                            Text(main.currentView.backTitle!)
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }

                    }
                }
                Spacer()
                if self.main.currentView.editActionButton != nil {
                    Button(action: editAction) {
                        Image(systemName: main.currentView.editActionButton!.icon)
                    }
                    .padding(.horizontal , 5)
                    .foregroundColor(.gray)
                }
            
                
                if main.currentView.actionButton != nil {
                    Button(action: actionButtonAction) {
                        Image(systemName:
                            main.currentView.actionButton!.icon)
                    }
                    .padding(.horizontal , 5)
                    .foregroundColor(.green)
                }
                
                Button(action: {
                    print("render contextpane")
                    self.show_contextpage = true
                }) {
                    Image(systemName: "ellipsis")
                }
                .sheet(isPresented: self.$show_contextpage) {
                    ContextPane().environmentObject(self.main)
                }
                .padding(.horizontal , 5)
                .foregroundColor(.gray)
                
            }.padding(.all, 30)
        }

    }
    func actionButtonAction(){
        main.executeAction(main.currentView.actionButton!)
    }
    
    func backButtonAction(){
        main.executeAction(main.currentView.backButton!)
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
