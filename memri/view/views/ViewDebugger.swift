//
//  ViewDebugger.swift
//  memri
//
//  Created by Ruben Daniels on 5/12/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation

// TODO file watcher
//let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//let watcher = DirectoryWatcher.watch(documentsUrl)
//
//watcher.onNewFiles = { newFiles in
//  // Files have been added
//}
//
//watcher.onDeletedFiles = { deletedFiles in
//  // Files have been deleted
//}
//Call watcher.stopWatching() and watcher.startWatching() to pause / resume.

/*
    Needs to know, which views are currently displayed (in the cascade)
    Then updates the view by recomputing the view with the new values
    Display any errors in the console
*/

import SwiftUI
import Combine

enum InfoType: String {
    case info, warn, error
    
    var icon: String {
        switch self{
        case .info: return "info.circle.fill"
        case .warn: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch self{
        case .info: return Color.gray
        case .warn: return Color.yellow
        case .error: return Color.red
        }
    }
}

class InfoState: Hashable {
    var id = UUID()
    
    static func == (lhs: InfoState, rhs: InfoState) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(displayMessage)
        hasher.combine(date)
    }
    
    var date: Date = Date()
    var displayMessage: String = ""
    var messageCount: Int = 1
    var type: InfoType = .info
//    var computedView: ComputedView
    
    init (displayMessage m:String) {
        displayMessage = m
    }
}

class ErrorState: InfoState {
    var error: Error? = nil
    
    override init (displayMessage m:String) {
        super.init(displayMessage: m)
        
        type = .error
    }
}

class WarnState: InfoState {
    override init (displayMessage m:String) {
        super.init(displayMessage: m)
        
        type = .warn
    }
}

class ErrorHistory: ObservableObject {
    @Published var showErrorConsole:Bool = false
    
    var log = [InfoState]()
    
    func info(_ message:String/*, _ computedView:ComputedView*/){
        // if same view
        if log.last?.displayMessage == message {
            log[log.count - 1].messageCount += 1
        }
        else {
            log.append(InfoState(
                displayMessage: message
    //            computedView: computedView
            ))
        }
        
        showErrorConsole = true
    }
    
    func warn(_ message:String/*, _ computedView:ComputedView*/){
        // if same view
        if log.last?.displayMessage == message {
            log[log.count - 1].messageCount += 1
        }
        else {
            log.append(WarnState(
                displayMessage: message
    //            computedView: computedView
            ))
        }
        
        showErrorConsole = true
    }
    
    func error(_ message:String/*, _ computedView:ComputedView*/){
        // if same view
        if log.last?.displayMessage == message {
            log[log.count - 1].messageCount += 1
        }
        else {
            log.append(ErrorState(
                displayMessage: message
    //            computedView: computedView
            ))
        }
        
        showErrorConsole = true
    }
    
    func clear(){
        log = []
    }
}

// Intentionally global
var errorHistory = ErrorHistory()

struct ErrorConsole: View {
    @EnvironmentObject var main: Main
    
    @ObservedObject var history = errorHistory
    
    var body: some View {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.locale = Locale(identifier: "en_US")
//        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return Group {
            if errorHistory.showErrorConsole {
                VStack (spacing:0) {
                    HStack {
                        Text("Error Console")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                            .foregroundColor(Color(hex:"555"))
                        Spacer()
                        Button(action: { self.history.showErrorConsole = false }) {
                            Image(systemName: "xmark")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#999"))
                        .padding(10)
                    }
                    .fullWidth()
                    .background(Color(hex:"#eee"))
                    
                    CustomScrollView(scrollToEnd: true) {
                        VStack (spacing:0) {
                            ForEach (errorHistory.log, id: \.self) { notice in
                                VStack (spacing: 0 ){
                                    HStack (alignment: .center, spacing: 4) {
                                        Image(systemName: notice.type.icon)
                                        .font(.system(size: 14))
                                            .foregroundColor(notice.type.color)
                                        
                                        Text(notice.displayMessage)
                                            .font(.system(size: 14))
                                            .padding(.top, 1)
                                            .foregroundColor(Color(hex: "#333"))
                                        
                                        if notice.messageCount > 1 {
                                            Text("\(notice.messageCount)x")
                                                .padding(3)
                                                .background(Color.yellow)
                                                .cornerRadius(20)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(Color.white)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(dateFormatter.string(from: notice.date))
                                            .font(.system(size: 12))
                                            .padding(.top, 1)
                                            .foregroundColor(Color(hex: "#999"))
                                    }
                                    .fullWidth()
                                    .padding(5)
                                    
                                    Divider()
                                }
                            }
                        }
                    }
                    .fullWidth()
                }
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200, alignment: .topLeading)
                .border(width: [1, 0, 0, 0], color: Color(hex: "ddd"))
            }
        }
    }
}

struct ErrorConsole_Previews: PreviewProvider {
    static var previews: some View {
        ErrorConsole().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
