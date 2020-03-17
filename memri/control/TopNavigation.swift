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
    @EnvironmentObject var application: Application
    
    @State private var show_contextpage: Bool = false
    
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
            
            if self.sessions.currentSession.currentView.backButton != nil {
                Button(action: backButtonAction ) {
                    Image(systemName: self.sessions.currentSession.currentView.backButton!.icon)
                    .foregroundColor(.gray)
                }
            }

            Spacer()
            Text(sessions.currentSession.currentView.title).font(.headline)
            Spacer()
            
            if self.sessions.currentSession.currentView.actionButton != nil {
                Button(action: actionButtonAction) {
                    Image(systemName: self.sessions.currentSession.currentView.actionButton!.icon)
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
        self.sessions.currentSession.executeAction(action: self.sessions.currentSession.currentView.actionButton)
    }
    
    func backButtonAction(){
        self.sessions.currentSession.executeAction(action: self.sessions.currentSession.currentView.backButton)
    }
}


struct Topnavigation_Previews: PreviewProvider {
    static var previews: some View {
        TopNavigation().environmentObject(try! Sessions.fromJSONFile("empty_sessions"))
    }
}
