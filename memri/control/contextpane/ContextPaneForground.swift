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

    var body: some View {
        VStack(alignment: .leading) {
                VStack {
                    Text(main.computedView.title ?? "No Title")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(main.computedView.subtitle ?? "No Subtitle")
                        .font(.body)
                    Divider()
                    Text("some stuff to add later ...")
                    Divider()
                }
                HStack {
                    Text(NSLocalizedString("actionLabel", comment: ""))
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                        .font(.headline)
                    Spacer()
                }.padding(.vertical, 20)
                VStack(alignment: .leading, spacing: 20){
                    ForEach (self.main.computedView.actionItems) { actionItem in
                        Button(action:{
                            self.main.executeAction(actionItem)
                        }) {
                            Text(actionItem.title ?? "")
                                .foregroundColor(.black)
                        }
                    }
                }
                Divider()
                HStack {
                    Text(NSLocalizedString("navigateLabel", comment: ""))
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }.padding(.vertical, 20)
//                List {
                VStack(alignment: .leading, spacing: 20){

                    ForEach (self.main.computedView.navigateItems) { navigateItem in
                        Button(action:{
                            self.main.executeAction(navigateItem)
                        }) {
                            Text(navigateItem.title ?? "")
                                .foregroundColor(.black)
                        }
                    }
                }
//                }
                Divider()
                HStack {
                    Text(NSLocalizedString("labelsLabel", comment: ""))
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }.padding(.vertical, 20)
                Spacer()
            }
            .padding(.vertical, 60)
            .padding(.leading, 16)
            .background(Color.white)
    }
}

struct ForgroundContextPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPaneForground().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
