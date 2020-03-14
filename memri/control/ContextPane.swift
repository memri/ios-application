//
//  ContentPane.swift
//  memri
//
//  Created by Jess Taylor on 3/10/20.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct LineDivider: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0.0, y: 0.0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

let lineDividerLineWidth: CGFloat = 1.5
let lineDividerFrameHeight: CGFloat = 5.0

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
                LineDivider()
                    .stroke(Color.gray, lineWidth: lineDividerLineWidth)
                    .frame(height: lineDividerFrameHeight)
            }
            VStack {
                Text("some stuff to add later ...")
                LineDivider()
                    .stroke(Color.gray, lineWidth: lineDividerLineWidth)
                    .frame(height: lineDividerFrameHeight)
            }
            VStack {
                HStack {
                    Text("\(actionLabel)")
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                LineDivider()
                    .stroke(Color.gray, lineWidth: lineDividerLineWidth)
                    .frame(height: lineDividerFrameHeight)
            }
            VStack {
                HStack {
                    Text("\(navigateLabel)")
                        .fontWeight(.bold)
                        .foregroundColor(Color.gray)
                    Spacer()
                }
                LineDivider()
                    .stroke(Color.gray, lineWidth: lineDividerLineWidth)
                    .frame(height: lineDividerFrameHeight)
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
