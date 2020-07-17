//
//  TimelineHelper.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 12/7/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import Foundation

struct TimelineModel {
    var data: [TimelineGroup]
    var detailLevel: DetailLevel
    var mostRecentFirst: Bool
	
	var itemDateTimeResolver: (Item) -> Date?
    
    let calendarHelper = CalendarHelper()
    
	init(dataItems: [Item], itemDateTimeResolver: @escaping ((Item) -> Date?), detailLevel: DetailLevel, mostRecentFirst: Bool) {
        self.detailLevel = detailLevel
        self.mostRecentFirst = mostRecentFirst
		self.itemDateTimeResolver = itemDateTimeResolver
        
		self.data = TimelineModel.group(dataItems, itemDateTimeResolver: itemDateTimeResolver, level: detailLevel, mostRecentFirst: mostRecentFirst)
    }
    
    static func group(_ data: [Item], itemDateTimeResolver: (Item) -> Date?, level: TimelineModel.DetailLevel, mostRecentFirst: Bool, collapseByTypeWhereCountGreaterThan maxCount: Int = 2) -> [TimelineGroup] {
        let groupedByDay = Dictionary(grouping: data) { dataItem -> Date? in
            guard let date = itemDateTimeResolver(dataItem) else { return nil }
            let components = Calendar.current.dateComponents(level.relevantComponents, from: date)
            guard let day = Calendar.current.date(from: components) else { return nil }
            
            return day
        }
        var sortedGroups = groupedByDay.compactMap { (date, items) -> TimelineGroup? in
            guard let date = date else { return nil }
            return TimelineGroup(date: date, items: group(items, collapseByTypeWhereCountGreaterThan: maxCount))
        }.sorted(by: { ($0.date > $1.date) })
        
        guard !sortedGroups.isEmpty else { return [] }
        
        let largerComponents = level.largerComponents
        sortedGroups[0].isStartOf = largerComponents
        for index in sortedGroups.indices.dropFirst() {
            let difference = Calendar.current.dateComponents(largerComponents, from: sortedGroups[index - 1].date, to: sortedGroups[index].date)
            sortedGroups[index].isStartOf = largerComponents.filter { difference.value(for: $0) ?? 0 < 0 }
        }
     
        return mostRecentFirst ? sortedGroups : sortedGroups.reversed()
    }
    
    static func group(_ data: [Item], collapseByTypeWhereCountGreaterThan maxCount: Int = 2) -> [TimelineElement] {
        let groupedByType = Dictionary(grouping: data) { dataItem -> String in
            dataItem.genericType
        }
        let sortedGroups = groupedByType.flatMap { (type, items) -> [TimelineElement] in
            if items.count > maxCount {
                return [TimelineElement(itemType: type, index: 0, items: items)]
            } else {
                return items.indexed().map { TimelineElement(itemType: type, index: $0.index, items: [$0.element]) }
            }
        }.sorted(by: { $0.items.count > $1.items.count })
        return sortedGroups
    }
}

struct TimelineGroup {
    var date: Date
    var items: [TimelineElement]
    
    // Used to store whether this is the first entry in year/month/day etc (for use in rendering supplementaries)
    var isStartOf: Set<Calendar.Component> = []
}

struct TimelineElement {
    var itemType: String
    var index: Int
    var items: [Item]
    
    var isGroup: Bool { items.first != items.last }
}

extension TimelineElement: Hashable, Identifiable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(itemType)
        hasher.combine(index)
    }
    static func == (lhs: TimelineElement, rhs: TimelineElement) -> Bool {
        lhs.itemType == rhs.itemType && lhs.index == rhs.index
    }
    var id: Int {
        hashValue
    }
}


extension TimelineModel {
	enum DetailLevel: String {
        case year
        case month
        case week
        case day
        case hour
        
        var relevantComponents: Set<Calendar.Component> {
            switch self {
            case .year: return [.year]
            case .month: return [.year, .month]
            case .week: return [.yearForWeekOfYear, .weekOfYear] //Note yearForWeekOfYear is used to correctly account for weeks crossing the new year
            case .day: return [.year, .month, .day]
            case .hour: return [.year, .month, .day, .hour]
            }
        }
        
        var largerComponents: Set<Calendar.Component> {
            switch self {
            case .year: return []
            case .month: return [.year]
            case .week: return [.year] //Note yearForWeekOfYear is used to correctly account for weeks crossing the new year
            case .day: return [.year, .month]
            case .hour: return [.year, .month, .day]
            }
        }
    }
}
