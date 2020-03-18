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
            
            if main.currentView.backButton != nil {
                Button(action: backButtonAction ) {
                    Image(systemName: main.currentView.backButton!.icon)
                    .foregroundColor(.gray)
                }
            }

            Spacer()
            Text(main.currentView.title).font(.headline)
            Spacer()
            
            if main.currentView.actionButton != nil {
                Button(action: actionButtonAction) {
                    Image(systemName: main.currentView.actionButton!.icon)
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
                ContextPane()
            }
            .padding(.horizontal , 5)
            .foregroundColor(.gray)
        }.padding(.all, 30)
    }
    func actionButtonAction(){
        main.executeAction(main.currentView.actionButton!)
    }
    
    func backButtonAction(){
        main.executeAction(main.currentView.backButton!)
    }
}


struct Topnavigation_Previews: PreviewProvider {
    static var previews: some View {
        TopNavigation().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
