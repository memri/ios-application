//
// ConfigPanelModel.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift
import SwiftUI

struct ConfigPanelModel {
    struct ConfigItem {
        var displayName: String
        var propertyName: String
        var type: ConfigItemType
        var isItemSpecific: Bool
    }

    enum ConfigItemType {
        case any
        case bool
        case string
        case number
        case special(SpecialTypes)

        var supportedRealmTypes: Set<PropertyType> {
            switch self {
            case .any: return [.bool, .data, .date, .double, .float, .int, .object, .string]
            case .bool: return [.bool]
            case .string: return [.date, .double, .float, .int, .string]
            case .number: return [.double, .float, .int]
            case .special: return []
            }
        }
    }

    struct PossibleExpression {
        var propertyName: String
        var isComputed: Bool = false

        var displayName: String {
            propertyName.camelCaseToWords()
        }

        var expressionString: String {
            ".\(propertyName)\(isComputed ? "()" : "")"
        }
    }

    enum SpecialTypes {
        case chartType
        case timeLevel
    }
}
