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
    
    @State private var showingBackActions = false
    @State private var showingTitleActions = false
    
    @State private var isPressing = false // HACK because long-press isnt working why?
    
    private func forward(){
        self.main.executeAction(ActionDescription(actionName:.forward))
    }
    private func toFront(){
        self.main.executeAction(ActionDescription(actionName:.forwardToFront))
    }
    private func backAsSession(){
        self.main.executeAction(ActionDescription(actionName:.backAsSession))
    }
    
    private func createTitleActionSheet() -> ActionSheet {
        return ActionSheet(title: Text("Do something with the current view"),
                buttons: [
                    .default(Text("Save view")) { self.toFront() },
//                    .default(Text("Update view")) { self.toFront() }, // Only when its a saved view
                    .default(Text("Duplicate view")) { self.toFront() },
//                    .default(Text("Reset to saved view")) { self.backAsSession() }, // Only when its a saved view
                    .default(Text("Copy a link to this view")) { self.toFront() },
                    .cancel()
        ])
    }
    
    private func createBackActionSheet() -> ActionSheet {
        return ActionSheet(title: Text("Navigate to a view in this session"),
                buttons: [
                    .default(Text("Forward")) { self.forward() },
                    .default(Text("To the front")) { self.toFront() },
                    .default(Text("Back as a new session")) { self.backAsSession() },
                    .default(Text("Show all views")) { /* TODO */ },
                    .cancel()
        ])
    }
        
    public var body: some View {
        ZStack{
            // we place the title *over* the rest of the topnav, to center it horizontally
            HStack{
                Button(action: { self.showingTitleActions = true }) {
                    Text(main.computedView.title)
                        .font(.headline)
                        .foregroundColor(Color(hex: "#434343"))
                }
                .actionSheet(isPresented: $showingTitleActions) {
                    return createTitleActionSheet()
                }
            }
            VStack {
                HStack(spacing: 10){
                    
                    Action(action: ActionDescription(actionName: .showNavigation))
                        .font(Font.system(size: 20, weight: .semibold))
                    
    //                Action(action: main.currentSession.backButton)
                    
                        
                    if main.currentSession.backButton != nil{
                        Button(action: {
                            if !self.showingBackActions {
                                self.main.executeAction(self.main.currentSession.backButton!)
                            }
                        }) {
                            Image(systemName: main.currentSession.backButton!.icon)
                                .fixedSize()
                                .padding(.horizontal, 5)
                                .padding(.vertical, 5)
                                .foregroundColor(Color(main.currentSession.backButton!.computeColor(state: false)))
                        }
                        .font(Font.system(size: 19, weight: .semibold))
                        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 10, pressing: {
                            (someBool) in
                            if self.isPressing || someBool {
                                self.isPressing = someBool
                                
                                if someBool {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        if self.isPressing {
                                            self.showingBackActions = true
                                        }
                                    }
                                }
                            }
                        }, perform: {})
                        .actionSheet(isPresented: $showingBackActions) {
                            return createBackActionSheet()
                        }
                    }
                    else {
                        Button(action: { self.showingBackActions = true }) {
                            Image(systemName: "smallcircle.fill.circle")
                                .fixedSize()
                                .font(.system(size: 10, weight: .bold, design: .default))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 5)
                                .foregroundColor(Color(hex: "#434343"))
                        }
                        .font(Font.system(size: 19, weight: .semibold))
                        .actionSheet(isPresented: $showingBackActions) {
                            return createBackActionSheet()
                        }
                    }
                    
                    Spacer()
                    
                    // TODO this should not be a setting but a user defined view that works on all
                    if self.main.settings.getBool("user/general/gui/showEditButton") != false {
                        Action(action: main.computedView.editActionButton)
                            .font(Font.system(size: 19, weight: .semibold))
                    }
                    
                    Action(action: main.computedView.actionButton)
                        .font(Font.system(size: 22, weight: .semibold))
                    
                    Action(action: ActionDescription(actionName: .showSessionSwitcher))
                        .font(Font.system(size: 20, weight: .medium))
                        .rotationEffect(.degrees(90))
                        
                }
                .padding(.top, 15)
                .padding(.bottom, 5)
                .padding(.leading, 15)
                .padding(.trailing, 15)
                
                Divider().background(Color(hex: "#efefef"))
            }
            .padding(.bottom, 0)
        }
    }
}

struct Topnavigation_Previews: PreviewProvider {
    static var previews: some View {
        TopNavigation().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
