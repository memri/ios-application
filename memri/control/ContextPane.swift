//
//  ContentPane.swift
//  memri
//
//  Created by Jess Taylor on 3/10/20.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct ContextPane: View {
    
    @EnvironmentObject var main: Main
        
    var body: some View {
        VStack {
            VStack {
                Text("\(main.currentView.title)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(main.currentView.subtitle)
                    .font(.body)
                HorizontalLine().styleHorizontalLine()
            }
            VStack {
                Text("some stuff to add later ...")
                HorizontalLine().styleHorizontalLine()
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
                HorizontalLine().styleHorizontalLine()
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
                HorizontalLine().styleHorizontalLine()
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
    }
}

struct ContentPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPane().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
