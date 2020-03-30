//
//  ActionDescription.swift
//  memri
//
//  Created by Koen van der Veen on 30/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

public enum ActionName: String, Codable {
    case back, add, openView, toggleEdit, toggleFilterPanel, star, showStarred, showContextPane, showOverlay, openContextView, share, showNavigation, addToPanel, duplicate, schedule, addToList, duplicateNote, noteTimeline, starredNotes, allNotes, exampleUnpack, noop
}


public enum ActionType: String, Codable{
    case button, emptytype
}

public class ActionDescription: Decodable, Identifiable {
    
    
    public var id = UUID()
    var color: UIColor = .systemGray
    var icon: String = ""
    var title: String? = nil
    var actionName: ActionName = .noop
    var actionArgs: [AnyCodable] = []
    var actionType: ActionType = .button
    var showTitle: Bool = false
    
    public convenience required init(from decoder: Decoder) throws{
        self.init()
        
        jsonErrorHandling(decoder) {
            self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
            self.title = try decoder.decodeIfPresent("title") ?? self.title
            self.actionName = try decoder.decodeIfPresent("actionName") ?? self.actionName
            self.actionArgs = try decoder.decodeIfPresent("actionArgs") ?? self.actionArgs
            self.actionType = try decoder.decodeIfPresent("actionType") ?? self.actionType
            self.showTitle = try decoder.decodeIfPresent("showTitle") ?? self.showTitle

        
            let colorString = try decoder.decodeIfPresent("color") ?? ""
            
            switch colorString{
            case "gray", "systemGray": self.color = .systemGray
            case "yellow","systemYellow": self.color = .systemYellow
            case "green", "systemGreen": self.color = .systemGreen
            default: break
            }
                    
            // we manually set the objects for the actionArgs key, since it has a somewhat dynamic value
            switch self.actionName{
            case .add:
                break
//                    self.actionArgs[0] = AnyCodable(try DataItem(from: self.actionArgs[0].value))
            case .openView:
                break
                // TODO make this work
//                    self.actionArgs[0] = AnyCodable(try! SessionView(from: self.actionArgs[0].value))
            default:
                break
            }
        }
    }
    
    public convenience init(icon: String?=nil, title: String?=nil, actionName: ActionName?=nil, actionArgs: [AnyCodable]?=nil, actionType: ActionType?=nil){
        self.init()
        self.icon = icon ?? self.icon
        self.title = title ?? self.title
        self.actionName = actionName ?? self.actionName
        self.actionArgs = actionArgs ?? self.actionArgs
        self.actionType = actionType ?? self.actionType
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> ActionDescription {
        let jsonData = try jsonDataFromFile(file, ext)
        let description: ActionDescription = try! JSONDecoder().decode(ActionDescription.self, from: jsonData)
        return description
    }
}
