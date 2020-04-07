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
    case back, add, openView, openViewByName, toggleEditMode, toggleFilterPanel, star, showStarred,
        showContextPane, showOverlay, share, showNavigation, addToPanel, duplicate,
        schedule, addToList, duplicateNote, noteTimeline, starredNotes, allNotes, exampleUnpack,
        delete, setRenderer, select, selectAll, unselectAll, showAddLabel, openLabelView, noop
    
    var defaultIcon: String {
        switch self {
        case .back:
            return "chevron.left"
        case .add:
            return "plus"
        case .toggleEditMode:
            return "pencil"
        case .toggleFilterPanel:
            return "rhombus.fill"
        case .showStarred, .star:
            return "star.fill"
        case .showContextPane:
            return "ellipsis"
        case .showNavigation:
            return "line.horizontal.3"
        case .schedule:
            return "alarm"
        default:
            // this icon looks like an error
            return "exclamationmark.bubble"
        }
    }
    
    var defaultTitle: String {
        switch self {
        case .back:
            return "back"
        case .showAddLabel:
            return "Add Label"
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
        case .star, .showStarred, .toggleEditMode, .toggleFilterPanel, .showContextPane, .showNavigation:
            return true
        default:
            return false
        }
    }
    
    var defaultActionStateName: String? {
        switch self {
        case .star:
            return "{dataItem.starred}"
        case .showStarred:
            return "showStarred" // uses openView underneath
        case .toggleEditMode:
            return "{currentSession.editMode}"
        case .toggleFilterPanel:
            return "{currentSession.showFilterPanel}"
        case .showContextPane:
            return "{currentSession.showContextPane}"
        case .showNavigation:
            return "{sessions.showNavigation}"
        default:
            return nil
        }
    }
    
    var opensView: Bool {
        switch self {
        case .showStarred, .openView, .openViewByName:
            return true
        default:
            return false
        }
    }

    
    var defaultColor: UIColor {
        switch self{
        case .add:
            return .systemGreen
        default:
            return .systemGray
        }
    }
    
    var defaultBackgroundColor: UIColor{
        return .white
    }
    
    var defaultActiveColor: UIColor? {
        switch self {
        case .toggleEditMode, .toggleFilterPanel:
            return .systemGreen
        case .showStarred:
            return .systemYellow
        default:
            return nil
        }
    }
    
    var defaultInactiveColor: UIColor? {
        switch self {
        case .back, .add, .openView, .openViewByName, .toggleEditMode, .toggleFilterPanel, .star,
             .showStarred, .showContextPane, .showOverlay, .share, .showNavigation,
             .addToPanel, .duplicate, .schedule, .addToList, .duplicateNote, .noteTimeline,
             .starredNotes, .allNotes, .delete, .select, .selectAll, .unselectAll, .exampleUnpack:
            return .systemGray
        default:
            return nil
        }
    }
    
    var defaultState: Bool {
        return false
    }
    
    var defaultActiveBackGroundColor: UIColor{
        return .white
    }
    
    var defaultInactiveBackGroundColor: UIColor{
        return .white
    }
    
    
}

public enum ActionType: String, Codable{
    case button, emptytype
}
