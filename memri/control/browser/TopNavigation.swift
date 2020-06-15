//
//  TopNavigation.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

public struct TopNavigation: View {
    @EnvironmentObject var context: MemriContext
    
    @State private var showingBackActions = false
    @State private var showingTitleActions = false
    
    @State private var isPressing = false // HACK because long-press isnt working why?
    
    private let inSubView:Bool
    private let showCloseButton:Bool
    
    init() {
        self.inSubView = false
        self.showCloseButton = false
    }
    
    init(inSubView:Bool, showCloseButton:Bool) {
        self.inSubView = inSubView
        self.showCloseButton = showCloseButton
    }
    
    private func forward(){
        self.context.executeAction(ActionForward(context))
    }
    private func toFront(){
        self.context.executeAction(ActionForwardToFront(context))
    }
    private func backAsSession(){
        self.context.executeAction(ActionBackAsSession(context))
    }
    private func openAllViewsOfSession(){
        let memriID = self.context.currentSession.memriID
        let view = """
        {
            "title": "Views in current session",
            "datasource": {
                "query": "SessionView AND session.uid = '\(memriID)'",
            }
        }
        """
        
        // TODO 
        do { try ActionOpenView.exec(context, ["view": view]) }
        catch {}
    }
    
    private func createTitleActionSheet() -> ActionSheet {
        var buttons:[ActionSheet.Button] = []
        let isNamed = self.context.currentSession.currentView.name != nil
        
        // TODO or copyFromView
        buttons.append(isNamed
            ? .default(Text("Update view")) { self.toFront() }
            : .default(Text("Save view")) { self.toFront() }
        )
        
        buttons.append(.default(Text("Add to Navigation")) { self.toFront() })
        buttons.append(.default(Text("Duplicate view")) { self.toFront() })
        
        if isNamed {
            buttons.append(.default(Text("Reset to saved view")) { self.backAsSession() })
        }
        
        buttons.append(.default(Text("Copy a link to this view")) { self.toFront() })
        buttons.append(.cancel())
        
        return ActionSheet(title: Text("Do something with the current view"), buttons: buttons)
    }
    
    private func createBackActionSheet() -> ActionSheet {
        return ActionSheet(title: Text("Navigate to a view in this session"),
                buttons: [
                    .default(Text("Forward")) { self.forward() },
                    .default(Text("To the front")) { self.toFront() },
                    .default(Text("Back as a new session")) { self.backAsSession() },
                    .default(Text("Show all views")) { self.openAllViewsOfSession() },
                    .cancel()
        ])
    }
        
    public var body: some View {
        let backButton = context.currentSession.hasHistory ? ActionBack(context) : nil
        let context = self.context
        
        return ZStack {
            // we place the title *over* the rest of the topnav, to center it horizontally
            HStack {
                Button(action: { self.showingTitleActions = true }) {
                    Text(context.cascadingView.title)
                        .font(.headline)
                        .foregroundColor(Color(hex: "#333"))
                }
                .actionSheet(isPresented: $showingTitleActions) {
                    return createTitleActionSheet()
                }
            }
            VStack (alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 10) {
                    
                    if !inSubView {
                        ActionButton(action: ActionShowNavigation(context))
                            .font(Font.system(size: 20, weight: .semibold))
                    }
                    else if showCloseButton {
                        // TODO Refactor: Properly support text labels
//                        Action(action: Action(actionName: .closePopup))
//                            .font(Font.system(size: 20, weight: .semibold))
                        Button(action: {
                            context.executeAction(ActionClosePopup(context))
                        }) {
                            Text("Close")
                                .font(.system(size: 16, weight: .regular))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .foregroundColor(Color(hex: "#106b9f"))
                        }
                        .font(Font.system(size: 19, weight: .semibold))
                    }
                    
                    if backButton != nil{
                        Button(action: {
                            if !self.showingBackActions, let backButton = backButton {
                                context.executeAction(backButton)
                            }
                        }) {
                            Image(systemName: backButton?.getString("icon") ?? "")
                                .fixedSize()
                                .padding(.horizontal, 5)
                                .padding(.vertical, 5)
                                .foregroundColor(backButton?.color ?? Color.white)
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
                                .padding(.vertical, 8)
                                .foregroundColor(Color(hex: "#434343"))
                        }
                        .font(Font.system(size: 19, weight: .semibold))
                        .actionSheet(isPresented: $showingBackActions) {
                            return createBackActionSheet()
                        }
                    }
                    
                    Spacer()
                    
                    // TODO this should not be a setting but a user defined view that works on all
                    if context.item != nil || context.settings.getBool("user/general/gui/showEditButton") != false {
                        ActionButton(action: context.cascadingView.editActionButton)
                            .font(Font.system(size: 19, weight: .semibold))
                    }
                    
                    ActionButton(action: context.cascadingView.actionButton)
                        .font(Font.system(size: 22, weight: .semibold))
                    
                    if !inSubView {
                        ActionButton(action: ActionShowSessionSwitcher(context))
                            .font(Font.system(size: 20, weight: .medium))
                            .rotationEffect(.degrees(90))
                    }
                }
                .padding(.top, 15)
                .padding(.bottom, 10)
                .padding(.leading, 15)
                .padding(.trailing, 15)
                .frame(height: 50, alignment: .top)
                
                Divider()
                    .background(Color(hex: "#efefef"))
                    .padding(.top, 0)
            }
            .padding(.bottom, 0)
        }
    }
}

struct Topnavigation_Previews: PreviewProvider {
    static var previews: some View {
        TopNavigation().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
