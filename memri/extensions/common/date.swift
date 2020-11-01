//
// date.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation

extension Date {
    var timeDelta: String? {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]

        guard let deltaString = formatter.string(from: self, to: Date()) else {
            return nil
        }
        return deltaString
    }

    var timestampString: String? {
        guard let timeString = timeDelta else {
            return nil
        }
        let formatString = NSLocalizedString("%@ ago", comment: "")
        return String(format: formatString, timeString)
    }
}
