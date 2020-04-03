//
//  ActionDescription.swift
//  memri
//
//  Created by Koen van der Veen on 30/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import RealmSwift

public class ActionDescription: Object, Codable, Identifiable {
    public var id = UUID() // TODO why is this here?
    
    var actionName: ActionName = .noop
    var actionArgs: [AnyCodable] = []
    var actionType: ActionType = .button
    
    @objc dynamic var icon: String = ""
    @objc dynamic var title: String? = nil
    
    @objc dynamic var showTitle: Bool = false // TODO Is there ever a place where the AD determines whether the title is shown?
    
    let hasState = RealmOptional<Bool>()
    let state = RealmOptional<Bool>() // TODO is state ever set on a default view?
    
    var color: UIColor = .systemGray
    var backgroundColor: UIColor = .white
    var activeColor: UIColor? = .systemGreen
    var inactiveColor: UIColor? = .systemGray
    var activeBackgroundColor: UIColor? = .white
    var inactiveBackGroundColor: UIColor? = .white
    
    var computedColor: UIColor{
        if self.hasState.value == true {
            if self.state.value == true {
                return self.activeColor!
            }else{
                return self.inactiveColor!
            }
        } else{
            return self.color
        }
    }
    
    var computedBackgroundColor: UIColor{
        if self.hasState.value == true {
            if self.state.value == true {
                return self.activeBackgroundColor!
            }
            else {
                return self.inactiveBackGroundColor!
            }
        }
        else {
            return self.backgroundColor
        }
    }
    
    // Helper properties
    let _actionArgs = List<String>() // Used to store actionArgs as JSON in realm
    @objc dynamic var _actionName: String = "noop" // Used to store actionName as string in realm
    @objc dynamic var _actionType: String = "button" // Used to store actionType as string in realm
    
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
            self.actionType = try decoder.decodeIfPresent("actionType") ?? self.actionType
            self.actionArgs = try decoder.decodeIfPresent("actionArgs") ?? self.actionArgs
            
            self.icon = try decoder.decodeIfPresent("icon") ?? self.actionName.defaultIcon
            self.title = try decoder.decodeIfPresent("title") ?? self.actionName.defaultTitle
            
            self.showTitle = try decoder.decodeIfPresent("showTitle") ?? self.showTitle
            self.hasState.value = try decoder.decodeIfPresent("hasState") ?? self.hasState.value
            self.state.value = try decoder.decodeIfPresent("state") ?? self.actionName.defaultState

            // TODO get default color from actionName
            let colorString = try decoder.decodeIfPresent("color") ?? ""
            self.color = UIColor.init(named: colorString) ?? self.actionName.defaultColor
            
            self.activeColor = self.actionName.defaultActiveColor
            self.inactiveColor = self.actionName.defaultInactiveColor
            self.inactiveBackGroundColor = self.actionName.defaultInactiveBackGroundColor
            self.activeBackgroundColor = self.actionName.defaultActiveBackGroundColor
            self.backgroundColor = self.actionName.defaultBackgroundColor

//            switch colorString{
//                case "gray", "systemGray": self.color = .systemGray
//                case "yellow","systemYellow": self.color = .systemYellow
//                case "green", "systemGreen": self.color = .systemGreen
//                default: self.color = self.actionName.defaultColor
//            }
            
            let container = try decoder.container(keyedBy:ActionDescriptionKeys.self)
            self.actionArgs = try self.decodeActionArgs(container)
            
            self._actionName = self.actionName.rawValue
            self._actionType = self.actionType.rawValue
            
//            for arg in self.actionArgs {
//                self._actionArgs.append(serialize(arg))
//            }
        }
    }
    
    public convenience init(icon: String?=nil, title: String?=nil,
                            actionName: ActionName?=nil, actionArgs: [AnyCodable]?=nil,
                            actionType: ActionType?=nil){
        self.init()
        
        self.actionName = actionName ?? self.actionName
        self.icon = icon ?? self.actionName.defaultIcon
        self.title = title ?? self.title
        self.actionArgs = actionArgs ?? self.actionArgs
        self.actionType = actionType ?? self.actionType
        
        print("create action description runtime: \(self.actionName)")
    }
    
    public required init() {
//        for arg in self._actionArgs {
//            self.actionArgs.append(unserialize(arg))
//        }
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
                            let typeContainer = try container
                                .nestedContainer(keyedBy: Discriminator.self)
                            let family:DataItemFamily = try typeContainer
                                .decode(DataItemFamily.self, forKey: DataItemFamily.discriminator)
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
    
//    public static func == (lhs: ActionDescription, rhs: ActionDescription) -> Bool {
//        return true
//    }

//    public convenience init(color: UIColor?=nil, icon: String?=nil, title: String?=nil, actionName: ActionName?=nil, actionArgs: [AnyCodable]?=nil, actionType: ActionType?=nil){
//        self.init()
//        self.actionName = actionName ?? self.actionName
//        self.color = color ?? self.actionName.defaultColor
//        self.icon = icon ?? self.actionName.defaultIcon
//        self.title = title ?? self.title
//        self.actionArgs = actionArgs ?? self.actionArgs
//        self.actionType = actionType ?? self.actionType
//
//    }
    
    public class func from_json(_ file: String, ext: String = "json") throws -> ActionDescription {
        let jsonData = try jsonDataFromFile(file, ext)
        let description: ActionDescription = try! JSONDecoder().decode(ActionDescription.self, from: jsonData)
        return description
    }
}
