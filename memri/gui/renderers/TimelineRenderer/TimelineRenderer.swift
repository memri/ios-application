//
//  TimelineRenderer.swift
//  MemriPlayground
//
//  Created by Toby Brennan on 28/6/20.
//  Copyright © 2020 Memri. All rights reserved.
//

import SwiftUI
import ASCollectionView

class CascadingTimelineConfig: CascadingRenderConfig {
	var type: String? = "calendar.timeline"
	
	var press: Action? { cascadeProperty("press") }
	var mostRecentFirst: Bool = true
	
	var dateTimeExpression: Expression? { cascadeProperty("dateTime", type: Expression.self) }
	var detailLevelString: String? { cascadeProperty("detailLevel") }
	var detailLevel: TimelineModel.DetailLevel { detailLevelString.flatMap(TimelineModel.DetailLevel.init) ?? .day }
}

struct TimelineRenderer: View {
	@EnvironmentObject var context: MemriContext
	
	var renderConfig: CascadingTimelineConfig {
		(context.cascadingView?.renderConfig as? CascadingTimelineConfig) ?? CascadingTimelineConfig([])
	}
	func resolveExpression<T>(_ expression: Expression?,
							  toType _: T.Type = T.self,
							  forItem dataItem: Item) -> T? {
		let args = try? ViewArguments
			.clone(context.cascadingView?.viewArguments, [".": dataItem], managed: false)
		
		return try? expression?.execForReturnType(T.self, args: args)
	}
	
	func resolveItemDateTime(_ item: Item) -> Date? {
		resolveExpression(renderConfig.dateTimeExpression, toType: Date.self, forItem: item)
	}
    
    var sections: [ASSection<Date>] {
		let model = TimelineModel(dataItems: context.items, itemDateTimeResolver: resolveItemDateTime, detailLevel: renderConfig.detailLevel, mostRecentFirst: renderConfig.mostRecentFirst)
        return model.data.map { group in
            let matchesNow = model.calendarHelper.isSameAsNow(group.date, byComponents: model.detailLevel.relevantComponents)
            return ASSection<Date>(id: group.date, data: group.items) { element, cellContext in
                renderElement(element)
					.if(group.items.count < 2) { $0.frame(minHeight: 35) }
            }
			.onSelectSingle({ (index) in
				guard let element = group.items[safe: index] else { return }
				if element.isGroup {
					let uids = element.items.compactMap { $0.uid }
					try? ActionOpenViewWithUIDs(context).exec(["itemType": element.itemType, "uids": uids])
				} else {
					if let press = self.renderConfig.press, let item = element.items.first {
						context.executeAction(press, with: item)
					}
				}
			})
            .sectionHeader {
                VStack(spacing: 0) {
                    smallString(forDate: group.date).map { string in
                        Text(string)
                        .font(Font.system(size: 15))
                        .foregroundColor(matchesNow ? Color.red : Color(.secondaryLabel))
                    }
                    largeString(forDate: group.date).map { string in
                        Text(string)
                        .font(Font.system(size: 25))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(matchesNow ? (useFillToIndicateNow ? Color.white : .red) : Color(.label))
                        .padding(matchesNow ? 3 : 0)
                        .background(
                            Circle().fill((useFillToIndicateNow && matchesNow) ? Color.red : .clear)
                                .frame(minWidth: 35, minHeight: 35)
                        )
                    }
                }
                .padding(8)
            }
            .sectionFooter {
                VStack {
                    Divider()
                }
            }
            .selfSizingConfig { (context) -> ASSelfSizingConfig? in
                .init(selfSizeHorizontally: false, selfSizeVertically: true, canExceedCollectionWidth: false, canExceedCollectionHeight: true)
            }
        }
    }
    
    @ViewBuilder
	func renderElement(_ element: TimelineElement) -> some View {
		if element.isGroup {
			TimelineItemView(icon: Image(systemName: "rectangle.stack"),
							 title: "\(element.items.count) \(element.itemType.camelCaseToTitleCase())\(element.items.count != 1 ? "s" : "")",
							 backgroundColor: ItemFamily(rawValue: element.itemType)?.backgroundColor ?? .gray)
				.frame(maxWidth: .infinity, alignment: .leading)
			#warning("@Ruben: I couldn't figure out a way using current CVU options to provide a way to render for a `group` of items")
		} else if let item = element.items.first {
			self.renderConfig.render(item: item)
				.frame(maxWidth: .infinity, alignment: .leading)
				.environmentObject(context)
		}
	}
    
    var body: some View {
       ASCollectionView(sections: sections)
        .layout(layout)
        .alwaysBounceVertical()
    }
    
    var leadingInset: CGFloat {
        60
    }
    
    var layout: ASCollectionLayout<Date> {
        ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0) { () -> ASCollectionLayoutSection in
            ASCollectionLayoutSection { layoutEnvironment -> NSCollectionLayoutSection in
                let hasFullWidthHeader: Bool = renderConfig.detailLevel == .year
                
                
                let itemLayoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(20))
                
                let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
                
                let section = NSCollectionLayoutSection(group: group)
                
                section.contentInsets = .init(top: 15, leading: hasFullWidthHeader ? 10 : leadingInset + 5 , bottom: 15, trailing: 10)
                section.interGroupSpacing = 10
                section.visibleItemsInvalidationHandler = { visibleItems, contentOffset, layoutEnvironment in
                    // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells
                }
                
                var headerSupplementary: NSCollectionLayoutBoundarySupplementaryItem
                if hasFullWidthHeader {
                    let supplementarySize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(35))
                    headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: supplementarySize,
                        elementKind: UICollectionView.elementKindSectionHeader,
                        alignment: .topLeading)
                    headerSupplementary.extendsBoundary = true
                    headerSupplementary.pinToVisibleBounds = false
                } else {
                    let supplementarySize = NSCollectionLayoutSize(widthDimension: .absolute(leadingInset), heightDimension: .absolute(64))
                    headerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: supplementarySize,
                        elementKind: UICollectionView.elementKindSectionHeader,
                        alignment: .topLeading)
                    headerSupplementary.extendsBoundary = false
                    headerSupplementary.pinToVisibleBounds = true
                }
                
                let footerSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1)),
                    elementKind: UICollectionView.elementKindSectionFooter,
                    alignment: .bottom)

                section.supplementariesFollowContentInsets = false
                section.boundarySupplementaryItems = [headerSupplementary, footerSupplementary]
                return section
            }
        }
    }
}

extension TimelineRenderer {
    
    func largeString(forDate date: Date) -> String? {
        switch renderConfig.detailLevel {
        case .hour:
            return nil
        case .day:
            let format = DateFormatter()
            format.dateFormat = "d"
            return format.string(from: date)
        case .week:
            let format = DateFormatter()
            format.dateFormat = "ww"
            return format.string(from: date)
        case .month:
            let format = DateFormatter()
            format.dateFormat = "MMM"
            return format.string(from: date)
        case .year:
            let format = DateFormatter()
            format.dateFormat = "YYYY"
            return format.string(from: date)
        }
    }
    
    func smallString(forDate date: Date) -> String? {
        switch renderConfig.detailLevel {
        case .hour:
            let format = DateFormatter()
            format.dateFormat = "h a"
            return format.string(from: date)
        case .day:
            let format = DateFormatter()
            format.dateFormat = "MMM"
            return format.string(from: date)
        case .week:
            return "Week"
        default:
            return nil
        }
    }
    
    var useFillToIndicateNow: Bool {
        switch renderConfig.detailLevel {
        case .day:
            return true
        default:
            return false
        }
    }
}
