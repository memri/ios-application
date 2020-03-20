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
    var actionItems: Array<ActionDescription>? = nil
    typealias actionMethod = () -> ()
    var actionMethods = Dictionary<String, actionMethod>()
    let noAction: actionMethod = actionNotFound
    let shareAction: actionMethod = share
    let addToListAction: actionMethod = addToList
    let duplicateAction: actionMethod = duplicateNote

    let navigateLabel = NSLocalizedString("navigateLabel", comment: "")
    var navigationItems: Array<ActionDescription>? = nil
    typealias navigationMethod = () -> ()
    var navigationMethods = Dictionary<String, navigationMethod>()
    let noteTimelineNavigation: navigationMethod = noteTimeline
    let starredNotesNavigation: navigationMethod = starredNotes
    let allNotesNavigation: navigationMethod = allNotes

    let labelsLabel = NSLocalizedString("labelsLabel", comment: "")

    init() {
//        self.currentView = main.currentView
//        self.actionItems = self.currentView.actionItems
//        self.navigationItems = self.currentView.navigateItems
        
        self.actionMethods.updateValue(shareAction, forKey: "share")
        self.actionMethods.updateValue(addToListAction, forKey: "addToList")
        self.actionMethods.updateValue(duplicateAction, forKey: "duplicateNote")

        self.navigationMethods.updateValue(noteTimelineNavigation, forKey: "noteTimeline")
        self.navigationMethods.updateValue(starredNotesNavigation, forKey: "starredNotes")
        self.navigationMethods.updateValue(allNotesNavigation, forKey: "allNotes")
    }
    
    
    var body: some View {
        VStack {
            VStack {
                Text("\(main.currentView.title ?? "")")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("\(main.currentView.subtitle ?? "")")
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
                List {
                    ForEach (0 ..< (self.main.currentView.actionItems?.count ?? 0)) { i in
                        Button(action:{
                            (self.actionMethods[self.main.currentView.actionItems![i].actionName] ?? self.noAction)()
                        }) {
                            Text(self.main.currentView.actionItems![i].title)
                        }
                    }
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
                List {
                    ForEach (0 ..< (main.currentView.navigateItems?.count ?? 0)) { i in
                        Button(action:{
                            (self.navigationMethods[self.main.currentView.navigateItems![i].actionName] ?? self.noAction)()
                        }) {
                            Text(self.main.currentView.navigateItems![i].title)
                        }
                    }
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

func share() {
    print("share function called!")
}

func addToList() {
    print("addToList function called!")
}

func duplicateNote() {
    print("duplicateNote function called!")
}

func noteTimeline() {
    print("noteTimeline function called!")
}

func starredNotes() {
    print("starredNotes function called!")
}

func allNotes() {
    print("allNotes function called!")
}

func actionNotFound() {
    print("actionNotFound!")
}

struct ContentPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPane().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
