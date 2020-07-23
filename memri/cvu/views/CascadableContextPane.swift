//
// CascadableContextPane.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation
import RealmSwift
import SwiftUI

public class CascadableContextPane: Cascadable {
    var buttons: [Action] {
        get { cascadeList("buttons") }
        set(value) { setState("buttons", value) }
    }

    var actions: [Action] {
        get { cascadeList("actions") }
        set(value) { setState("actions", value) }
    }

    var navigate: [Action] {
        get { cascadeList("navigate") }
        set(value) { setState("navigate", value) }
    }
}
