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
    
    var title: String?
    var subtitle: String?
    var buttons: [ActionDescription] = []
    var actions: [ActionDescription] = []
    var navigate: [ActionDescription] = []
    
    let actionLabel = NSLocalizedString("actionLabel", comment: "")
    let navigateLabel = NSLocalizedString("navigateLabel", comment: "")
    let labelsLabel = NSLocalizedString("labelsLabel", comment: "")
    
    var body: some View {
        VStack (/*alignment: .leading*/){
            VStack {
                Text("\(main.currentView.title)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("\(main.currentView.subtitle)")
                    .font(.body)
                HorizontalLine().styleHorizontalLine()
            }
            VStack {
                Text("some stuff to add later ...")
                HorizontalLine().styleHorizontalLine()
            }
            VStack {
                HStack {
                    Text("\(actionLabel)")
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                HorizontalLine().styleHorizontalLine()
            }
            VStack {
                HStack {
                    Text("\(navigateLabel)")
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                HorizontalLine().styleHorizontalLine()
            }
            VStack {
                HStack {
                    Text("\(labelsLabel)")
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
