//
//  Action.swift
//  memri
//
//  Created by Koen van der Veen on 30/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct ActionButton: View {
    @EnvironmentObject var main: Main
    
    var action: Action?

    // TODO Refactor: can this be created more efficiently?
    var body: some View {
        VStack{
            if action != nil {
                getAction()
            }
            else {
                EmptyView()
            }
        }
    }
    
    func getAction() -> AnyView{
        // NOTE: Allowed force unwrappings (logic)
        switch self.action?.getRenderAs(main.cascadingView.viewArguments) {
        case .popup:
            return AnyView(ActionPopupButton(action: self.action!))
        case .button:
            return AnyView(ActionButtonView(action: self.action!) {
                self.main.executeAction(self.action!)
            })
        default:
            return AnyView(ActionButtonView(action: self.action!))
        }
    }
}

struct ActionView_Previews: PreviewProvider {
    static var previews: some View {
        let main = RootMain(name: "", key: "").mockBoot()
        return ActionButton(action: ActionBack(main))
            .environmentObject(main)
    }
}

struct ActionButtonView: View {
    @EnvironmentObject var main: Main
    
    var action: Action
    var execute: (() -> Void)? = nil
    
    var body: some View {
        let icon = action.getString("icon")
        let title:String? = action.get("title")
        
        return Button(action: {
            withAnimation {
                self.execute?()
            }
        }) {
            if icon != "" {
                Image(systemName: icon)
                    .fixedSize()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 5)
                    .foregroundColor(action.color)
                    .background(action.backgroundColor)
//                    .border(Color.red, width: 1)
            }
            
            if title != nil && action.getBool("showTitle") {
                // NOTE: Allowed force unwrapping (logic)
                Text(title!)
                    .font(.subheadline)
                    .foregroundColor(.black)
             }
        }
    }
}

struct ActionPopupButton: View {
    @EnvironmentObject var main: Main
    
    var action: Action
    
    @State var isShowing = false
    
    var body: some View {
        return ActionButtonView(action: self.action, execute: {
            self.isShowing = true
        })
        .sheet(isPresented: $isShowing) {
            ActionPopup(action: self.action).environmentObject(self.main)
        }
    }
}

struct ActionPopup: View {
    @EnvironmentObject var main: Main
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var action: Action
    
    var body: some View {
        // TODO refactor: this list item needs to be removed when we close the popup in any way
        self.main.closeStack.append {
            self.presentationMode.wrappedValue.dismiss()
        }
        
        let args = action.arguments["viewArguments"] as? ViewArguments ?? ViewArguments()
        args["showCloseButton"] = true
        
        // TODO is this still needed? Need test cases
        // TODO this is now set back on variables["."] there is something wrong in the architecture
        //      that is causing this
        let dataItem = args["."] as? DataItem ?? DataItem() // TODO Refactor: Error handling
        
        // TODO scroll selected into view? https://stackoverflow.com/questions/57121782/scroll-swiftui-list-to-new-selection
        if action.name == .openView {
            if let view = action.arguments["view"] as? SessionView {
                return SubView(
                    main: self.main,
                    view: view, // TODO refactor: consider adding .closePopup to all press actions
                    dataItem: dataItem,
                    args: args
                )
            }
            else {
                // TODO ERror logging
            }
        }
        else  if action.name == .openViewByName {
            if let viewName = action.arguments["name"] as? String {
                return SubView(
                    main: self.main,
                    viewName: viewName,
                    dataItem: dataItem,
                    args: args
                )
            }
            else {
                // TODO Error logging
            }
        }
        
        // We should never get here. This is just to ease the compiler
        return SubView(
            main: self.main,
            viewName: "catch-all-view",
            dataItem: dataItem,
            args: args
        )
    }
}
