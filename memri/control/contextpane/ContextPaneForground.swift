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
    
    var paddingLeft:CGFloat = 25

    var body: some View {
        VStack(alignment: .leading) {
            VStack (alignment: .leading) {
                Text(main.computedView.resultSet.item?.getString("title") ?? "") // TODO make this generic
                    .font(.system(size: 23, weight: .regular, design: .default))
                    .fontWeight(.bold)
                    .opacity(0.75)
                    .padding(.horizontal, paddingLeft)
                    .padding(.vertical, 5)
                Text(main.computedView.subtitle)
                    .font(.body)
                    .opacity(0.75)
                    .padding(.horizontal, paddingLeft)
                
                HStack {
                    ForEach (self.main.computedView.contextButtons) { actionItem in
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
                    .opacity(0.5)
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
            .padding(.top, 20)
            .padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 0){
                ForEach (self.main.computedView.actionItems) { actionItem in
                    Button(action:{
                        self.main.executeAction(actionItem)
                    }) {
                        Text(actionItem.title ?? "")
                            .foregroundColor(.black)
                            .opacity(0.8)
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
            .padding(.top, 20)
            .padding(.bottom, 10)
//                List {
            VStack(alignment: .leading, spacing: 0){

                ForEach (self.main.computedView.navigateItems) { navigateItem in
                    Button(action:{
                        self.main.executeAction(navigateItem)
                    }) {
                        Text(navigateItem.title ?? "")
                            .foregroundColor(.black)
                            .opacity(0.8)
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .padding(.vertical, 10)
                    }
                    .padding(.horizontal, self.paddingLeft)
                }
            }
//                }
            Divider()
            HStack {
                Text(NSLocalizedString("labelsLabel", comment: ""))
                    .fontWeight(.bold)
                    .opacity(0.4)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .padding(.horizontal, paddingLeft)
                Spacer()
            }
            .padding(.top, 20)
            .padding(.bottom, 10)
            Spacer()
        }
        .padding(.top, 60)
//            .padding(.leading, 16)
        .background(Color.white)
    }
}

struct ForgroundContextPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPaneForground().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
