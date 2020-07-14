//
//  CalendarView.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 2/7/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import SwiftUI
import ASCollectionView

let registerCalendarRenderer = {
	Renderers.register(
		name: "calendar",
		title: "Calendar",
		order: 500,
		icon: "calendar",
		view: AnyView(CalendarView()),
		renderConfigType: CascadingCalendarConfig.self,
		canDisplayResults: { _ -> Bool in true }
	)
	
	Renderers.register(
		name: "calendar.timeline",
		title: "Timeline",
		order: 500,
		icon: "hourglass.bottomhalf.fill",
		view: AnyView(TimelineRenderer()),
		renderConfigType: CascadingTimelineConfig.self,
		canDisplayResults: { _ -> Bool in true }
	)
}

class CascadingCalendarConfig: CascadingRenderConfig {
	var type: String? = "calendar"
	
//	var press: Action? { cascadeProperty("press") }

	var dateTimeExpression: Expression? { cascadeProperty("dateTime", type: Expression.self) }
}

struct CalendarView: View {
	@EnvironmentObject var context: MemriContext
	
	var renderConfig: CascadingCalendarConfig {
		(context.cascadingView?.renderConfig as? CascadingCalendarConfig) ?? CascadingCalendarConfig([])
	}
	
	var data: [Item] {
		context.items
	}
	
	func resolveExpression<T>(_ expression: Expression?,
							  toType _: T.Type = T.self,
							  forItem dataItem: Item) -> T? {
		let args = try? ViewArguments
			.clone(context.cascadingView?.viewArguments, [".": dataItem], managed: false)
		
		return try? expression?.execForReturnType(T.self, args: args)
	}
	
	@State var scrollPosition: ASCollectionViewScrollPosition? = .bottom
    
    
    var datesWithItems: Set<Date> {
        data.reduce(into: Set<Date>()) { (result, item) in
			guard let dateTime = self.resolveExpression(renderConfig.dateTimeExpression, toType: Date.self, forItem: item),
                  let date = calendarHelper.startOfDay(for: dateTime) else { return }
            result.insert(date)
        }
    }
    var start: Date {
        datesWithItems.min().flatMap { CalendarHelper().startOfMonth(for: $0) } ?? Date()
    }
    var end: Date {
        datesWithItems.max().flatMap { CalendarHelper().endOfMonth(for: $0) } ?? Date()
    }
    
    var calendarHelper = CalendarHelper()
    
    func hasItemOnDay(_ day: Date) -> Bool {
        datesWithItems.contains(day)
    }
    
    func section(forMonth month: Date) -> ASSection<Date> {
		let days = calendarHelper.getPaddedDays(forMonth: month)
        return ASSection(id: month, data: days, dataID: \.self) { day, cellContext in
            Group {
                day.map { day in
                    VStack(spacing: 0) {
                        Spacer()
                        Text(calendarHelper.dayString(for: day))
							.foregroundColor(calendarHelper.isToday(day) ? .red : Color(.label))
                        Circle().fill(hasItemOnDay(day) ? Color.red : Color.clear)
                            .frame(width: 10, height: 10)
                            .padding(4)
                        Spacer()
                        Divider()
                    }
                    .background(cellContext.isHighlighted ? Color(.secondarySystemBackground) : .clear)
                }
            }
        }
        .sectionHeader {
            Text(calendarHelper.monthString(for: month))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
		.onSelectSingle { index in
			guard let day = days[safe: index].flatMap({ $0 }) else { return }
			let formatter = DateFormatter()
			formatter.dateStyle = .long
			formatter.timeStyle = .none
			// handle press on day
			print("Pressed on day: \(formatter.string(from: day))")
			#warning("TODO - this should open a list that's filtered to items on this day")
		}
    }
    
    var sections: [ASSection<Date>] {
        calendarHelper.getMonths(from: start, to: end).map(section(forMonth:))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(calendarHelper.daysInWeek, id: \.self) { dayString in
                    Text(dayString)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .background(Color(.secondarySystemBackground))
            ASCollectionView(sections: sections)
                .scrollPositionSetter($scrollPosition)
                .layout { (layoutEnvironment) -> ASCollectionLayoutSection in
                    .grid(layoutMode: .fixedNumberOfColumns(7), itemSpacing: 0, lineSpacing: 0, itemSize: .absolute(55))
                }
                .contentInsets(UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
                .alwaysBounceVertical()
        }
    }
}
