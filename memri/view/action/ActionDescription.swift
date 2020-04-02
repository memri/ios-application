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


public class ActionDescription: Codable, Identifiable {
    
    public var id = UUID()
    
    var icon: String = ""
    var title: String? = nil
    var actionName: ActionName = .noop
    var actionArgs: [AnyCodable] = []
    var actionType: ActionType = .button
    var showTitle: Bool = false
    var hasState: Bool = false
    var state: Bool? = false
    
    var color: UIColor = .systemGray
    var activeColor: UIColor? = .systemGreen
    var inactiveColor: UIColor? = .systemGray
    
    private enum CodingKeys: String, CodingKey {
        case icon, title, actionName, actionArgs, actionType, showTitle, hasState, state
    }
    
    enum ActionDescriptionKeys: String, CodingKey {
      case actionArgs
    }
    
    public convenience required init(from decoder: Decoder) throws{
        self.init()
        
        jsonErrorHandling(decoder) {
            self.actionName = try decoder.decodeIfPresent("actionName") ?? self.actionName
            self.icon = try decoder.decodeIfPresent("icon") ?? self.actionName.defaultIcon
            self.title = try decoder.decodeIfPresent("title") ?? self.actionName.defaultTitle
            self.activeColor = self.actionName.defaultActiveColor
            self.inactiveColor = self.actionName.defaultInactiveColor
            self.actionArgs = try decoder.decodeIfPresent("actionArgs") ?? self.actionArgs
            self.actionType = try decoder.decodeIfPresent("actionType") ?? self.actionType
            self.showTitle = try decoder.decodeIfPresent("showTitle") ?? self.showTitle

        
            // TODO decode colorString for active/inactive in function
            let colorString = try decoder.decodeIfPresent("color") ?? ""
            
            switch colorString{
                case "gray", "systemGray": self.color = .systemGray
                case "yellow","systemYellow": self.color = .systemYellow
                case "green", "systemGreen": self.color = .systemGreen
                default: break
            }
            
            let container = try decoder.container(keyedBy:ActionDescriptionKeys.self)
            self.actionArgs = try self.decodeActionArgs(container)
        }
    }
    
    func decodeActionArgs(_ ctr:KeyedDecodingContainer<ActionDescriptionKeys>) throws -> [AnyCodable] {
        var container = try ctr.nestedUnkeyedContainer(forKey: ActionDescriptionKeys.actionArgs)
        var list = [AnyCodable]()
        var tmpContainer = container // Force a copy of the container
        let path = getCodingPathString(tmpContainer.codingPath)
        
        print("Decoding: \(path)")
        
        if let count = container.count {
            if (self.actionName.argumentTypes.count > 0) {
                for i in 0...count - 1 {
                    do {
                        let type = self.actionName.argumentTypes[i]
                        if let _ = type as? DataItemFamily.Type {
                            let typeContainer = try container.nestedContainer(keyedBy: Discriminator.self)
                            let family:DataItemFamily = try typeContainer.decode(DataItemFamily.self, forKey: DataItemFamily.discriminator)
                            list.append(AnyCodable(try tmpContainer.decode(family.getType())))
                        }
                        else if let type = type as? SessionView.Type {
                            list.append(AnyCodable(try tmpContainer.decode(type)))
                        }
                        else if let type = type as? String.Type {
                            list.append(AnyCodable(try tmpContainer.decode(type)))
                        }
                        else if let type = type as? Double.Type {
                            list.append(AnyCodable(try tmpContainer.decode(type)))
                        }
                        else if let type = type as? Int.Type {
                            list.append(AnyCodable(try tmpContainer.decode(type)))
                        }
                    } catch {
                        print("\nJSON Parse Error at \(path)\nError: \(error.localizedDescription)\n")
                        raise(SIGINT)
                    }
                }
            }
        }
        
        return list
    }
    
    public convenience init(icon: String?=nil, title: String?=nil, actionName: ActionName?=nil, actionArgs: [AnyCodable]?=nil, actionType: ActionType?=nil){
        self.init()
        self.actionName = actionName ?? self.actionName
        self.icon = icon ?? self.actionName.defaultIcon
        self.title = title ?? self.title
        self.actionArgs = actionArgs ?? self.actionArgs
        self.actionType = actionType ?? self.actionType
    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> ActionDescription {
        let jsonData = try jsonDataFromFile(file, ext)
        let description: ActionDescription = try! JSONDecoder().decode(ActionDescription.self, from: jsonData)
        return description
    }
}
