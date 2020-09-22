//
// CalendarRenderer.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import SwiftUI

class CalendarRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "calendar", icon: "calendar", makeController: CalendarRendererController.init, makeConfig: CalendarRendererController.makeConfig)
    
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? CalendarRendererConfig) ?? CalendarRendererConfig()
    }
    
    let context: MemriContext
    let config: CalendarRendererConfig
    
    func makeView() -> AnyView {
        CalendarRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        CalendarRendererConfig(head, tail, host)
    }
    
    
    func view(for item: Item) -> some View {
        config.render(item: item)
            .environmentObject(context)
    }
    
    func resolveExpression<T>(
        _ expression: Expression?,
        toType _: T.Type = T.self,
        forItem dataItem: Item
    ) -> T? {
        let args = ViewArguments(context.currentView?.viewArguments, dataItem)
        return try? expression?.execForReturnType(T.self, args: args)
    }
    
    func resolveItemDateTime(_ item: Item) -> Date? {
        resolveExpression(config.dateTimeExpression, toType: Date.self, forItem: item)
    }
    
    var calendarHelper = CalendarHelper()
    
    var calcs: CalendarCalculations {
        CalendarCalculations(calendarHelper: calendarHelper,
                             data: context.items,
                             dateResolver: {
                                self.resolveExpression(
                                    config.dateTimeExpression,
                                    forItem: $0
                                )
        },
                             renderConfig: config)
    }
}

class CalendarRendererConfig: CascadingRendererConfig, ConfigurableRenderConfig {
    var showSortInConfig: Bool = false
    func configItems(context: MemriContext) -> [ConfigPanelModel.ConfigItem] {
        []
    }
    let showContextualBarInEditMode: Bool = false
    
    var dateTimeExpression: Expression? { cascadeProperty("timeProperty", type: Expression.self) }
}

struct CalendarCalculations {
    init(
        calendarHelper: CalendarHelper,
        data: [Item],
        dateResolver: (Item) -> Date?,
        renderConfig: CalendarRendererConfig
    ) {
        let datesWithItems: [Date: [Item]] = data.reduce(into: [:]) { result, item in
            guard let dateTime = dateResolver(item),
                let date = calendarHelper.startOfDay(for: dateTime) else { return }
            result[date] = (result[date] ?? []) + [item]
        }
        self.datesWithItems = datesWithItems
        start = datesWithItems.keys.min()
            .flatMap { CalendarHelper().startOfMonth(for: $0) } ?? Date()
        end = datesWithItems.keys.max().flatMap { CalendarHelper().endOfMonth(for: $0) } ?? Date()
    }

    var datesWithItems: [Date: [Item]]
    var start: Date
    var end: Date

    func hasItemOnDay(_ day: Date) -> Bool {
        datesWithItems.keys.contains(day)
    }

    func itemsOnDay(_ day: Date) -> [Item] {
        datesWithItems[day] ?? []
    }
}

struct CalendarRendererView: View {
    @ObservedObject var controller: CalendarRendererController

    @State var scrollPosition: ASCollectionViewScrollPosition? = .bottom


    var body: some View {
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(controller.calendarHelper.daysInWeek, id: \.self) { dayString in
                    Text(dayString)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
			.background(Color.gray.opacity(0.2))
            ASCollectionView(sections: sections(withCalcs: controller.calcs))
                .scrollPositionSetter($scrollPosition)
                .layout(ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 4) {
                    ASCollectionLayoutSection { (_) -> NSCollectionLayoutSection in
                        let columns = 7

                        let itemSize = NSCollectionLayoutDimension.absolute(55)

                        let itemLayoutSize = NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1.0),
                            heightDimension: itemSize
                        )
                        let groupSize = NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1.0),
                            heightDimension: itemSize
                        )
                        let supplementarySize = NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1.0),
                            heightDimension: .absolute(30)
                        )

                        let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)

                        let group = NSCollectionLayoutGroup.horizontal(
                            layoutSize: groupSize,
                            subitem: item,
                            count: columns
                        )

                        let section = NSCollectionLayoutSection(group: group)
                        section.interGroupSpacing = 0
                        section.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
                        section
                            .visibleItemsInvalidationHandler = { _, _, _ in
                            } // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells

                        let headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                            layoutSize: supplementarySize,
                            elementKind: UICollectionView.elementKindSectionHeader,
                            alignment: .top
                        )
                        let footerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                            layoutSize: supplementarySize,
                            elementKind: UICollectionView.elementKindSectionFooter,
                            alignment: .bottom
                        )
                        section.boundarySupplementaryItems = [
                            headerSupplementary,
                            footerSupplementary,
                        ]
                        return section
                    }
				})
                .contentInsets(UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
                .alwaysBounceVertical()
        }
        .background(controller.config.backgroundColor?.color ?? Color(.systemBackground))
    }

    func sections(withCalcs calcs: CalendarCalculations) -> [ASSection<Date>] {
        controller.calendarHelper.getMonths(from: calcs.start, to: calcs.end)
            .map { section(forMonth: $0, withCalcs: calcs) }
    }

    func section(forMonth month: Date, withCalcs calcs: CalendarCalculations) -> ASSection<Date> {
        let days = controller.calendarHelper.getPaddedDays(forMonth: month)
        return ASSection(id: month, data: days, dataID: \.self, selectionMode: .selectSingle { index in
            guard let day = days[safe: index].flatMap({ $0 }) else { return }
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            // handle press on day
            let items = calcs.itemsOnDay(day)
            let uids = items.compactMap { $0.uid }
            
            guard let itemType = items.first?.genericType, !uids.isEmpty else { return }
            
            try? ActionOpenViewWithUIDs(self.controller.context).exec(["itemType": itemType, "uids": uids])
        }) { day, cellContext in
            Group {
                day.map { day in
                    VStack(spacing: 0) {
                        Spacer()
                        Text(self.controller.calendarHelper.dayString(for: day))
                            .foregroundColor(self.controller.calendarHelper
                                .isToday(day) ? self.controller.config.primaryColor.color : Color(.label))
					
						HStack(spacing: 0) {
							Circle()
                                .fill(calcs.itemsOnDay(day).isEmpty ? .clear : self.controller.config.primaryColor.color)
								.frame(width: 10, height: 10)
								.padding(4)
							if calcs.itemsOnDay(day).count > 1 {
								Text("×\(calcs.itemsOnDay(day).count)")
									.font(Font.caption.bold())
									.foregroundColor(self.controller.config.primaryColor.color)
									.fixedSize()
							}
						}
						
                        Spacer()
                        Divider()
                    }
                    .background(cellContext
					.isHighlighted ? Color(.darkGray).opacity(0.3) : .clear)
                }
            }
        }
        .sectionHeader {
            Text(controller.calendarHelper.monthYearString(for: month))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

//struct CalendarDotShape: Shape {
//    var count: Int
//    func path(in rect: CGRect) -> Path {
//        Path { path in
//            guard count > 0 else { return }
//            let boundedCountInt = max(min(count, 4), 0)
//            let boundedCount = CGFloat(boundedCountInt)
//            let radius = min(rect.width / 2 / (boundedCount + 1) - 1, rect.height * 0.5)
//            let spacing = rect.width / (boundedCount + 1)
//            for i in 1 ... boundedCountInt {
//                path.addEllipse(in: CGRect(
//                    x: spacing * CGFloat(i) - radius,
//                    y: rect.midY - radius,
//                    width: radius * 2,
//                    height: radius * 2
//                ))
//            }
//        }
//    }
//}
