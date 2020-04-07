//
//  Action.swift
//  memri
//
//  Created by Koen van der Veen on 30/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct Action: View {

    var action: ActionDescription?
    @EnvironmentObject var main: Main

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
        switch self.action!.actionType{
        case .button:
            return AnyView(ActionButton(action: self.action!))
        default:
            return AnyView(ActionButton(action: self.action!))
        }
    }


}

struct Action_Previews: PreviewProvider {
    static var previews: some View {
        Action(action: ActionDescription(icon: "chevron.left", title: "back", actionType: .button))
            .environmentObject(Main(name: "", key: "").mockBoot())
    }
}

struct ActionButton: View {
    @EnvironmentObject var main: Main
    
    var action: ActionDescription
    
    var isActive: Bool {
        return action.hasState.value == true && action.actionStateName != nil &&
            main.hasState(action.actionStateName!)
    }
    
    var body: some View {
        Button(action: {self.main.executeAction(self.action)} ) {
            if action.icon != "" {
                Image(systemName: action.icon)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 5)
                    .foregroundColor(Color(action.computeColor(state: isActive)))
                    .foregroundColor(Color(action.computeBackgroundColor(state: isActive)))
            }
            if action.title != nil && action.showTitle {
                Text(action.title!)
                 .font(.subheadline)
                 .foregroundColor(.black)
             }
        }
    }
}
