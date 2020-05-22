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
        switch self.action?.renderAs {
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
        ActionView(action: Action(icon: "chevron.left", title: "back", actionType: .button))
            .environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}

struct ActionButtonView: View {
    @EnvironmentObject var main: Main
    
    var action: Action
    var execute: (() -> Void)? = nil
    
    var isActive: Bool {
        return action.hasState.value == true && action.actionStateName != nil &&
            main.hasState(action.actionStateName!)
    }
    
    var body: some View {
        Button(action: {
            withAnimation {
                self.execute?()
            }
        }) {
            if action.icon != "" {
                Image(systemName: action.icon)
                    .fixedSize()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 5)
                    .foregroundColor(Color(action.computeColor(state: isActive)))
//                    .background(Color(action.computeBackgroundColor(state: isActive)))
            }
            if action.title != nil && action.showTitle {
                Text(action.title!)
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
        return ActionButton(action: self.action, execute: {
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
        
        var variables = action.actionArgs[1].value as? [String:Any] ?? [:]
        variables["showCloseButton"] = true
        
        // TODO this is now set back on variables["."] there is something wrong in the architecture
        //      that is causing this
        let context = variables["."] as? DataItem ?? DataItem() // TODO Refactor: Error handling
        
        // TODO scroll selected into view? https://stackoverflow.com/questions/57121782/scroll-swiftui-list-to-new-selection
        if action.actionName == .openView {
            return SubView(
                main: self.main,
                view: action.actionArgs[0].value as! SessionView, // TODO refactor: consider adding .closePopup to all press actions
                context: context,
                variables: variables
            )
        }
        else  if action.actionName == .openViewByName {
            return SubView(
                main: self.main,
                viewName: action.actionArgs[0].value as! String,
                context: context,
                variables: variables
            )
        }
        else {
            // We should never get here. This is just to ease the compiler
            return SubView(
                main: self.main,
                viewName: "catch-all-view",
                context: context,
                variables: variables
            )
        }
    }
}
