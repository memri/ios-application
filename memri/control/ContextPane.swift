//
//  ContentPane.swift
//  memri
//
//  Created by Jess Taylor on 3/10/20.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct ContextPane: View {
    
    let horizontalLineWidth: CGFloat = 1.5
    var horizontalLine = HorizontalLine()
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
                horizontalLine
                    .stroke(Color.gray, lineWidth: horizontalLineWidth)
                    .frame(height: horizontalLineFrameHeight)
            }
            VStack {
                Text("some stuff to add later ...")
                horizontalLine
                    .stroke(Color.gray, lineWidth: horizontalLineWidth)
                    .frame(height: horizontalLineFrameHeight)
            }
            VStack {
                HStack {
                    Text("\(actionLabel)")
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                horizontalLine
                    .stroke(Color.gray, lineWidth: horizontalLineWidth)
                    .frame(height: horizontalLineFrameHeight)
            }
            VStack {
                HStack {
                    Text("\(navigateLabel)")
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                horizontalLine
                    .stroke(Color.gray, lineWidth: horizontalLineWidth)
                    .frame(height: horizontalLineFrameHeight)
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
