//
//  ForgroundContextPane.swift
//  memri
//
//  Created by Jess Taylor on 3/21/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct ContextPaneForground: View {
    
    @EnvironmentObject var main: Main
    
    var addLabelAction = Action(icon: nil, title: nil, actionName: .showAddLabel, actionArgs: [], actionType: .none)
    var openLabelViewAction = Action(icon: nil, title: nil, actionName: .openLabelView, actionArgs: [], actionType: .none)
    var paddingLeft:CGFloat = 25

    var body: some View {
        VStack(alignment: .leading) {
            VStack (alignment: .leading) {
                Text(main.cascadingView.title) // TODO make this generic
                    .font(.system(size: 23, weight: .regular, design: .default))
                    .fontWeight(.bold)
                    .opacity(0.75)
                    .padding(.horizontal, paddingLeft)
                    .padding(.vertical, 5)
                Text(main.cascadingView.subtitle)
                    .font(.body)
                    .opacity(0.75)
                    .padding(.horizontal, paddingLeft)
                
                HStack {
                    ForEach (self.main.cascadingView.contextButtons) { actionItem in
                        Action(action: actionItem)
                    }
                }
                .padding(.horizontal, paddingLeft)
                .padding(.bottom, 15)
                
                Divider()
                Text("You created this note in August 2017 and viewed it 12 times and edited it 3 times over the past 1.5 years.")
                    .padding(.horizontal, paddingLeft)
                    .padding(.vertical, 10)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .opacity(0.6)
                Divider()
            }
            HStack {
                Text(NSLocalizedString("actionLabel", comment: ""))
                    .fontWeight(.bold)
                    .opacity(0.4)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .padding(.horizontal, paddingLeft)
                Spacer()
            }
            .padding(.top, 15)
            .padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 0){
                ForEach (self.main.cascadingView.actionItems) { actionItem in
                    Button(action:{
                        self.main.executeAction(actionItem)
                    }) {
                        Text(actionItem.title ?? "")
                            .foregroundColor(.black)
                            .opacity(0.6)
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .padding(.vertical, 10)
                    }
                    .padding(.horizontal, self.paddingLeft)
                }
            }
            Divider()
            HStack {
                Text(NSLocalizedString("navigateLabel", comment: ""))
                    .fontWeight(.bold)
                    .opacity(0.4)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .padding(.horizontal, paddingLeft)
                Spacer()
            }
            .padding(.top, 15)
            .padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 0){
                ForEach (self.main.cascadingView.navigateItems) { navigateItem in
                    Button(action:{
                        self.main.executeAction(navigateItem)
                    }) {
                        Text(navigateItem.title ?? "")
                            .foregroundColor(.black)
                            .opacity(0.6)
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .padding(.vertical, 10)
                    }
                    .padding(.horizontal, self.paddingLeft)
                }
            }
            Divider()
            HStack {
                Text(NSLocalizedString("labelsLabel", comment: ""))
                    .fontWeight(.bold)
                    .opacity(0.4)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .padding(.horizontal, paddingLeft)
                Spacer()
            }
            .padding(.top, 15)
            .padding(.bottom, 15)
            VStack(alignment: .leading, spacing: 10){
                ForEach (self.main.cascadingView.resultSet.singletonItem!.labels) { labelItem in
                    Button(action:{
                        self.main.executeAction(self.openLabelViewAction, labelItem)
                    }) {
                        Text(labelItem.name)
                            .foregroundColor(.black)
                            .opacity(0.6)
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .padding(.vertical, 5)
                            .padding(.horizontal, 15)
                            .frame(minWidth: 150, alignment: .leading)
                    }
                    .background(Color(hex: labelItem.color ?? "#ffd966ff"))
                    .cornerRadius(5)
                    .padding(.horizontal, self.paddingLeft)
                }
                Button(action:{
                    self.main.executeAction(self.addLabelAction)
                }) {
                    Text(self.addLabelAction.title!)
                        .foregroundColor(.black)
                        .opacity(0.6)
                        .font(.system(size: 20, weight: .regular, design: .default))
                        .padding(.vertical, 10)
                }
                .padding(.horizontal, self.paddingLeft)
            }
            Spacer()
        }
        .padding(.top, 60)
//            .padding(.leading, 16)
        .background(Color.white)
    }
}

struct ForgroundContextPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPaneForground().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
