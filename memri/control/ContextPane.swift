//
//  ContentPane.swift
//  memri
//
//  Created by Jess Taylor on 3/10/20.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct ContextPane: View {
    
    var currentSessionView: SessionView?

    init(sessions: Sessions) {
       self.currentSessionView = sessions.currentSession.currentSessionView
    }
    
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
                Text("\(self.currentSessionView?.title ?? "")")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("\(self.currentSessionView?.subtitle ?? "")")
                    .font(.body)
                HorizontalLine().adornedHorizontalLine()
            }
            VStack {
                Text("some stuff to add later ...")
                HorizontalLine().adornedHorizontalLine()
            }
            VStack {
                HStack {
                    Text("\(actionLabel)")
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                HorizontalLine().adornedHorizontalLine()
            }
            VStack {
                HStack {
                    Text("\(navigateLabel)")
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                HorizontalLine().adornedHorizontalLine()
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
        ContextPane(sessions: try! Sessions.from_json("empty_sessions"))
    }
}
