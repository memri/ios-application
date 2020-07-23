//
// ActionErrors.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation

enum ActionError: Error {
    case Error(messages: String)
    case Warning(message: String)
    case Info(message: String)
}
