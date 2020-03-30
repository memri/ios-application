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
    case back, add, openView, toggleEdit, toggleFilterPanel, star, showStarred, showContextPane, showOverlay, openContextView, share,
    addToPanel, duplicate, schedule, addToList, duplicateNote, noteTimeline, starredNotes, allNotes, exampleUnpack, noop
}

public class ActionDescription: Decodable, Identifiable {
    
    
    public var id = UUID()
    var color: UIColor = .gray
    var icon: String = ""
    var title: String = ""
    var actionName: ActionName = .noop
    var actionArgs: [AnyCodable] = []
    
    public convenience required init(from decoder: Decoder) throws{
        self.init()
        
        jsonErrorHandling(decoder) {
            self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
            self.title = try decoder.decodeIfPresent("title") ?? self.title
            self.actionName = try decoder.decodeIfPresent("actionName") ?? self.actionName
            self.actionArgs = try decoder.decodeIfPresent("actionArgs") ?? self.actionArgs
        
            let colorString = try decoder.decodeIfPresent("color") ?? ""
            
            switch colorString{
                case "gray": self.color = .gray
                case "yellow","systemYellow": self.color = .systemYellow
                default: self.color = .gray
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
    
    public convenience init(icon: String?=nil, title: String?=nil, actionName: ActionName?=nil, actionArgs: [AnyCodable]?=nil){
        self.init()
        self.icon = icon ?? self.icon
        self.title = title ?? self.title
        self.actionName = actionName ?? self.actionName
        self.actionArgs = actionArgs ?? self.actionArgs
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> ActionDescription {
        let jsonData = try jsonDataFromFile(file, ext)
        let description: ActionDescription = try! JSONDecoder().decode(ActionDescription.self, from: jsonData)
        return description
    }
}
