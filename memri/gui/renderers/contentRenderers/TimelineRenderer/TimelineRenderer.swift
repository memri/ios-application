//
// TimelineRenderer.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import SwiftUI

class TimelineRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "timeline", icon: "hourglass.bottomhalf.fill", makeController: TimelineRendererController.init, makeConfig: TimelineRendererController.makeConfig)
    
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? TimelineRendererConfig) ?? TimelineRendererConfig()
    }
    
    let context: MemriContext
    let config: TimelineRendererConfig
    
    func makeView() -> AnyView {
        TimelineRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        TimelineRendererConfig(head, tail, host)
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
    
    var model: TimelineModel {
        TimelineModel(
            dataItems: context.items,
            itemDateTimeResolver: resolveItemDateTime,
            detailLevel: config.detailLevel,
            mostRecentFirst: config.mostRecentFirst
        )
    }
}

class TimelineRendererConfig: CascadingRendererConfig, ConfigurableRenderConfig {
    var press: Action? { cascadeProperty("press") }
    var mostRecentFirst: Bool = true

    var dateTimeExpression: Expression? { cascadeProperty("timeProperty", type: Expression.self) }
    var detailLevelString: String? { cascadeProperty("detailLevel") }
    var detailLevel: TimelineModel
        .DetailLevel { detailLevelString.flatMap(TimelineModel.DetailLevel.init) ?? .day }
    
    
    var showSortInConfig: Bool = false
    func configItems(context: MemriContext) -> [ConfigPanelModel.ConfigItem] {[
        ConfigPanelModel.ConfigItem(displayName: "Time level", propertyName: "detailLevel", type: .special(.timeLevel), isItemSpecific: false)
    ]}
    var showContextualBarInEditMode: Bool = false
}

struct TimelineRendererView: View {
    @ObservedObject var controller: TimelineRendererController

    let minSectionHeight: CGFloat = 40

    func sections(withModel model: TimelineModel) -> [ASSection<Date>] {
        model.data.map { group in
            ASSection<Date>(id: group.date,
                            data: group.items,
                            selectionMode: .selectSingle { index in
                                guard let element = group.items[safe: index] else { return }
                                if element.isGroup {
                                    let uids = element.items.compactMap { $0.uid }
                                    try? ActionOpenViewWithUIDs(self.controller.context)
                                        .exec(["itemType": element.itemType, "uids": uids])
                                }
                                else {
                                    if let press = self.controller.config.press, let item = element.items.first {
                                        self.controller.context.executeAction(press, with: item)
                                    }
                                }
                            }
            ) { element, _ in
                self.renderElement(element)
                    .if(group.items.count < 2) { $0.frame(minHeight: self.minSectionHeight) }
            }
            .sectionHeader {
                header(for: group, calendarHelper: model.calendarHelper)
            }
            .sectionFooter {
                VStack {
                    Divider()
                }
            }
            .selfSizingConfig { (_) -> ASSelfSizingConfig? in
                .init(
                    selfSizeHorizontally: false,
                    selfSizeVertically: true,
                    canExceedCollectionWidth: false,
                    canExceedCollectionHeight: true
                )
            }
        }
    }

    @ViewBuilder
    func renderElement(_ element: TimelineElement) -> some View {
        if element.isGroup {
            TimelineItemView(icon: Image(systemName: "rectangle.stack"),
                             title: "\(element.items.count) \(element.itemType.titleCase())\(element.items.count != 1 ? "s" : "")",
                             backgroundColor: ItemFamily(rawValue: element.itemType)?
                                 .backgroundColor ?? .gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        else {
            element.items.first.map {
                self.controller.view(for: $0)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    var body: some View {
        return ASCollectionView(sections: sections(withModel: controller.model))
            .layout(layout)
            .alwaysBounceVertical()
    }

    var leadingInset: CGFloat {
        60
    }

    var layout: ASCollectionLayout<Date> {
        ASCollectionLayout(scrollDirection: .vertical,
                           interSectionSpacing: 0) { () -> ASCollectionLayoutSection in
            ASCollectionLayoutSection { _ -> NSCollectionLayoutSection in
                let hasFullWidthHeader: Bool = self.controller.config.detailLevel == .year

                let itemLayoutSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(20)
                )
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(20)
                )

                let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitem: item,
                    count: 1
                )

                let section = NSCollectionLayoutSection(group: group)

                section.contentInsets = .init(
                    top: 8,
                    leading: hasFullWidthHeader ? 10 : self.leadingInset + 5,
                    bottom: 8,
                    trailing: 10
                )
                section.interGroupSpacing = 10
                section.visibleItemsInvalidationHandler = { _, _, _ in
                    // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells
                }

                var headerSupplementary: NSCollectionLayoutBoundarySupplementaryItem
                if hasFullWidthHeader {
                    let supplementarySize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(35)
                    )
                    headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: supplementarySize,
                        elementKind: UICollectionView.elementKindSectionHeader,
                        alignment: .topLeading
                    )
                    headerSupplementary.extendsBoundary = true
                    headerSupplementary.pinToVisibleBounds = false
                }
                else {
                    let supplementarySize = NSCollectionLayoutSize(
                        widthDimension: .absolute(self.leadingInset),
                        heightDimension: .absolute(self.minSectionHeight + 16)
                    )
                    headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: supplementarySize,
                        elementKind: UICollectionView.elementKindSectionHeader,
                        alignment: .topLeading
                    )
                    headerSupplementary.extendsBoundary = false
                    headerSupplementary.pinToVisibleBounds = true
                }

                let footerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(1)
                    ),
                    elementKind: UICollectionView.elementKindSectionFooter,
                    alignment: .bottom
                )

                section.supplementariesFollowContentInsets = false
                section.boundarySupplementaryItems = [headerSupplementary, footerSupplementary]
                return section
            }
        }
    }
}

extension TimelineRendererView {
    // TODO: Clean up this function. Should probably define for each `DetailLevel` individually
    func header(for group: TimelineGroup, calendarHelper: CalendarHelper) -> some View {
        let matchesNow = calendarHelper.isSameAsNow(
            group.date,
            byComponents: controller.config.detailLevel.relevantComponents
        )

        let flipOrder: Bool = {
            switch controller.config.detailLevel {
            case .hour: return true
            default:
                return false
            }
        }()

        let alignment: HorizontalAlignment = {
            switch controller.config.detailLevel {
            case .year: return .leading
            case .day: return .center
            default: return .trailing
            }
        }()

        let largeString: String? = {
            switch controller.config.detailLevel {
            case .hour:
                if group.isStartOf.contains(.day) {
                    let format = DateFormatter()
                    format.dateFormat = "dd/MM"
                    return format.string(from: group.date)
                }
            case .day:
                let format = DateFormatter()
                format.dateFormat = "d"
                return format.string(from: group.date)
            case .week:
                let format = DateFormatter()
                format.dateFormat = "ww"
                return format.string(from: group.date)
            case .month:
                let format = DateFormatter()
                format.dateFormat = "MMM"
                return format.string(from: group.date)
            case .year:
                let format = DateFormatter()
                format.dateFormat = "YYYY"
                return format.string(from: group.date)
            }
            return nil
        }()

        let smallString: String? = {
            switch controller.config.detailLevel {
            case .hour:
                let format = DateFormatter()
                format.dateFormat = "h a"
                return format.string(from: group.date)
            case .day:
                let format = DateFormatter()
                format.dateFormat = group.isStartOf.contains(.year) ? "MMM YY" : "MMM"
                return format.string(from: group.date)
            case .week:
                return "Week"
            case .month:
                if group.isStartOf.contains(.year) {
                    let format = DateFormatter()
                    format.dateFormat = "YYYY"
                    return format.string(from: group.date)
                }
            default: break
            }
            return nil
        }()

        let small: some View = {
            smallString.map { string in
                Text(string)
                    .font(Font.system(size: 14))
                    .foregroundColor(matchesNow ? Color.red : Color(.secondaryLabel))
            }
        }()

        return VStack(alignment: alignment, spacing: 0) {
            if !flipOrder {
                small
            }
            largeString.map { string in
                Text(string)
                    .font(Font.system(size: 20))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(matchesNow ? (useFillToIndicateNow ? Color.white : .red) :
                        Color(.label))
                    .padding(.vertical, matchesNow ? 3 : 0)
                    .background(
                        Circle().fill((useFillToIndicateNow && matchesNow) ? Color.red : .clear)
                            .frame(minWidth: 30, minHeight: 30)
                    )
            }
            if flipOrder {
                small
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
    }

    var useFillToIndicateNow: Bool {
        switch controller.config.detailLevel {
        case .day:
            return true
        default:
            return false
        }
    }
}
