//
//  ActionName.swift
//  memri
//
//  Created by Koen van der Veen on 31/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

extension String {
    func camelCaseToWords() -> String {
        return unicodeScalars.reduce("") {
            if CharacterSet.uppercaseLetters.contains($1) {
                return ($0 + " " + String($1))
            }
            else {
                return $0 + String($1)
            }
        }
    }
}

public enum ActionName: String, Codable {
    case back, add, openView, openViewByName, toggleEdit, toggleFilterPanel, star, showStarred,
        showContextPane, showOverlay, openContextView, share, showNavigation, addToPanel, duplicate,
        schedule, addToList, duplicateNote, noteTimeline, starredNotes, allNotes, exampleUnpack,
        noop
    
    var defaultIcon: String {
        switch self {
        case .back:
            return "chevron.left"
        case .add:
            return "plus"
        case .toggleEdit:
            return "pencil"
        case .toggleFilterPanel:
            return "rhombus.fill"
        case .showStarred:
            return "star.fill"
        case .showContextPane:
            return "ellipsis"
        case .showNavigation:
            return "line.horizontal.3"
        default:
            // this icon looks like an error
            return "exclamationmark.bubble"
        }
    }
    
    var defaultTitle: String {
        switch self {
        case .back:
            return "back"
        default:
            return self.rawValue.camelCaseToWords().lowercased()
        }
    }
    
//    var defaultArguments: [AnyCodable]{
//        switch self {
//        case
//        default:
//            return []
//        }
//    }
    
    var argumentTypes: [Any.Type] {
        switch self {
        case .add:
            return [DataItemFamily.self]
        case .openView:
            return [SessionView.self]
        case .openViewByName:
            return [String.self]
        default:
            return []
        }
    }
    
    var defaultHasState: Bool {
        switch self {
        case .star, .showStarred, .toggleEdit, .toggleFilterPanel:
            return true
        default:
            return false
        }
    }
    
    var defaultActiveColor: UIColor? {
        switch self {
        case .toggleEdit:
            return .systemGreen
        case .showStarred:
            return .systemYellow
        default:
            return nil
        }
    }
    
    var defaultInactiveColor: UIColor? {
        switch self {
        case .back, .add, .openView, .openViewByName, .toggleEdit, .toggleFilterPanel, .star,
             .showStarred, .showContextPane, .showOverlay, .openContextView, .share, .showNavigation,
             .addToPanel, .duplicate, .schedule, .addToList, .duplicateNote, .noteTimeline,
             .starredNotes, .allNotes, .exampleUnpack:
            return .systemGray
        default:
            return nil
        }
    }
    
    var defaultActionState: Bool {
        return false
    }
    
    
}

public enum ActionType: String, Codable{
    case button, emptytype
}
