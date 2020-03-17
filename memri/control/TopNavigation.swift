//
//  TopNavigation.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct TopNavigation: View {
    
    @EnvironmentObject var sessions: Sessions
    @State private var show_contextpage: Bool = false
    @Binding var isEditMode:EditMode
    
    var title: String = ""
//    var action: ()->Void = {sessions.currentSession.back()}
//    var action: [String: ()->Void] = [:]

    var hideBack:Bool = false
    
    var body: some View {
        HStack {
            
            Button(action: {}) {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.gray)
                    .font(Font.system(size: 20, weight: .medium))
            }
            .padding(.horizontal , 5)
            
            if sessions.currentView.backButton != nil {
                Button(action: backButtonAction ) {
                    Image(systemName: sessions.currentView.backButton!.icon)
                    .foregroundColor(.gray)
                }
            }

            Spacer()
            Text(sessions.currentView.title).font(.headline)
            Spacer()
            
            if self.sessions.currentView.editActionButton != nil {
                Button(action: editAction) {
                    Image(systemName: sessions.currentView.editActionButton!.icon)
                }
                .padding(.horizontal , 5)
                .foregroundColor(.gray)
            }
            
            if sessions.currentView.actionButton != nil {
                Button(action: actionButtonAction) {
                    Image(systemName:
                        sessions.currentView.actionButton!.icon)
                }
                .padding(.horizontal , 5)
                .foregroundColor(.green)
            }
            

            Button(action: {
                print("render contextpane")
                self.show_contextpage = true
            }) {
                Image(systemName: "ellipsis")
            }.sheet(isPresented: self.$show_contextpage) {
                ContextPane(sessions: self.sessions)
            }
            .padding(.horizontal , 5)
            .foregroundColor(.gray)
        }.padding(.all, 30)
    }
    func actionButtonAction(){
        sessions.currentSession.executeAction(action: sessions.currentView.actionButton)
    }
    
    func backButtonAction(){
        sessions.currentSession.executeAction(action: sessions.currentView.backButton)
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
        TopNavigation(isEditMode: .constant(.inactive)).environmentObject(try! Sessions.from_json("empty_sessions"))
    }
}
