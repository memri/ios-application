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
    @Binding var showNavigation: Bool
    @Binding var isEditMode:EditMode

    
    var title: String = ""
//    var action: ()->Void = {sessions.currentSession.back()}
//    var action: [String: ()->Void] = [:]

    var hideBack:Bool = false
    
    public var body: some View {
        ZStack{
            // we place the title *over* the rest of the topnav, to center it horizontally
            HStack{
                if main.currentView.title != nil{
                    Text(main.currentView.title!).font(.headline)
                }
            }
            HStack{
                Button(action: {
                    self.showNavigation = true
                }) {
                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(.gray)
                        .font(Font.system(size: 20, weight: .medium))
                }
                .padding(.horizontal, 5)

                if main.currentSession.backButton != nil {
                    Button(action: backButtonAction ) {
                        Image(systemName: main.currentSession.backButton!.icon)
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
//                    self.showContextPane.toggle()
                }) {
                    Image(systemName: "ellipsis")
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
        TopNavigation(showNavigation: .constant(false),
                      isEditMode: .constant(.inactive)).environmentObject(Main(name: "", key: "").boot())
    }
}
