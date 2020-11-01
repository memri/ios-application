//
// CalendarHelper.swift
// Copyright © 2020 memri. All rights reserved.

import Foundation

struct CalendarHelper {
    var calendar = Calendar.current
    var dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    var monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM YYYY"
        return formatter
    }()

    func getMonths(from startDate: Date, to endDate: Date) -> [Date] {
        guard endDate >= startDate,
              let firstMonth = startOfMonth(for: startDate),
              let lastMonth = startOfMonth(for: endDate)
        else { return [] }
        var dates: [Date] = []
        calendar.enumerateDates(
            startingAfter: firstMonth.addingTimeInterval(-1),
            matching: DateComponents(day: 1),
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                dates.append(date)
                if date >= lastMonth { stop = true }
            }
        }
        return dates
    }

    func getDays(forMonth month: Date) -> [Date] {
        guard let endOfMonth = endOfMonth(for: month) else { return [] }
        var dates: [Date] = []
        calendar.enumerateDates(
            startingAfter: month.addingTimeInterval(-1),
            matching: DateComponents(hour: 0),
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                dates.append(date)
                if date >= endOfMonth { stop = true }
            }
        }
        return dates
    }

    func getPaddedDays(forMonth month: Date) -> [Date?] {
        guard let weekdayAtStart = weekdayAtStartOfMonth(for: month),
              let endOfMonth = endOfMonth(for: month) else { return [] }
        let adjustedWeekday = (weekdayAtStart - 1) // 0 = Sunday
        var dates: [Date?] = .init(repeating: nil, count: adjustedWeekday)
        calendar.enumerateDates(
            startingAfter: month.addingTimeInterval(-1),
            matching: DateComponents(hour: 0),
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                dates.append(date)
                if date >= endOfMonth { stop = true }
            }
        }
        return dates
    }

    func areOnSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func isSameAsNow(_ date: Date, byComponents: Set<Calendar.Component>) -> Bool {
        let components = calendar.dateComponents(byComponents, from: date)
        return calendar.date(Date(), matchesComponents: components)
    }

    func dayString(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    func monthString(for date: Date) -> String {
        monthFormatter.string(from: date)
    }

    func monthYearString(for date: Date) -> String {
        if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            return monthFormatter.string(from: date)
        }
        else {
            return monthYearFormatter.string(from: date)
        }
    }

    var daysInWeek: [String] {
        calendar.shortStandaloneWeekdaySymbols
    }

    func weekdayAtStartOfMonth(for date: Date) -> Int? {
        guard let startOfMonth = startOfMonth(for: date) else { return nil }
        return calendar.component(.weekday, from: startOfMonth)
    }

    func startOfDay(for date: Date) -> Date? {
        calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date))
    }

    func startOfMonth(for date: Date) -> Date? {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return nil }
        return interval.start
    }

    func endOfMonth(for date: Date) -> Date? {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return nil }
        return calendar.date(byAdding: DateComponents(day: -1), to: interval.end)
    }

    func startOfYear(for date: Date) -> Date? {
        guard let interval = calendar.dateInterval(of: .year, for: date) else { return nil }
        return interval.start
    }

    func endOfYear(for date: Date) -> Date? {
        guard let interval = calendar.dateInterval(of: .year, for: date) else { return nil }
        return calendar.date(byAdding: DateComponents(day: -1), to: interval.end)
    }
}
