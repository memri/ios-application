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
        VStack {
            VStack {
                Text("\(main.currentView.title)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(main.currentView.subtitle)
                    .font(.body)
                Divider()
            }
            VStack {
                Text("some stuff to add later ...")
                Divider()
            }
            VStack {
                HStack {
                    Text(NSLocalizedString("actionLabel", comment: ""))
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                List {
                    ForEach (self.main.currentView.actionItems) { actionItem in
                        Button(action:{
                            self.main.executeAction(actionItem)
                        }) {
                            Text(actionItem.title)
                        }
                    }
                }
                Divider()
            }
            VStack {
                HStack {
                    Text(NSLocalizedString("navigateLabel", comment: ""))
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                List {
                    ForEach (self.main.currentView.navigateItems) { navigateItem in
                        Button(action:{
                            self.main.executeAction(navigateItem)
                        }) {
                            Text(navigateItem.title)
                        }
                    }
                }
                Divider()
            }
            VStack {
                HStack {
                    Text(NSLocalizedString("labelsLabel", comment: ""))
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
    }
}

struct ForgroundContextPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPaneForground().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
