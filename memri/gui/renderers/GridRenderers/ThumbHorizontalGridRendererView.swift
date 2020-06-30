//
//  TumbGridRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import ASCollectionView
import SwiftUI

let registerThumbHorizontalGridRenderer = {
	Renderers.register(
		name: "thumbnail.horizontalgrid",
		title: "Horizontal Grid",
		order: 120,
		icon: "square.grid.3x2.fill",
		view: AnyView(ThumbHorizontalGridRendererView()),
		renderConfigType: CascadingThumbnailConfig.self,
		canDisplayResults: { _ -> Bool in true }
	)
}

struct ThumbHorizontalGridRendererView: View {
	@EnvironmentObject var context: MemriContext

	var name: String = "thumbnail_horizontalgrid"

	@State var selectedItems: Set<Int> = []

	//    @Environment(\.editMode) private var editMode
	//    var isEditing: Bool
	//    {
	//        editMode?.wrappedValue.isEditing ?? false
	//    }

	var renderConfig: CascadingThumbnailConfig {
		(context.cascadingView.renderConfig as? CascadingThumbnailConfig) ?? CascadingThumbnailConfig()
	}

	var layout: ASCollectionLayout<Int> {
		ASCollectionLayout(scrollDirection: .horizontal, interSectionSpacing: 0) {
			ASCollectionLayoutSection { environment in
				let contentInsets = self.renderConfig.nsEdgeInset
				let numberOfRows = self.renderConfig.columns
				let ySpacing = self.renderConfig.spacing.y
				let calculatedGridBlockSize = (environment.container.effectiveContentSize.height - contentInsets.top - contentInsets.bottom - ySpacing * (CGFloat(numberOfRows) - 1)) / CGFloat(numberOfRows)

				let item = NSCollectionLayoutItem(
					layoutSize: NSCollectionLayoutSize(
						widthDimension: .fractionalWidth(1.0),
						heightDimension: .fractionalHeight(1.0)
					))

				let itemsGroup = NSCollectionLayoutGroup.vertical(
					layoutSize: NSCollectionLayoutSize(
						widthDimension: .absolute(calculatedGridBlockSize),
						heightDimension: .fractionalHeight(1.0)
					),
					subitem: item, count: numberOfRows
				)
				itemsGroup.interItemSpacing = .fixed(ySpacing)

				let section = NSCollectionLayoutSection(group: itemsGroup)
				section.interGroupSpacing = self.renderConfig.spacing.x
				section.contentInsets = contentInsets
				return section
			}
		}
	}

	var section: ASCollectionViewSection<Int> {
		ASCollectionViewSection(id: 0, data: context.items, selectedItems: $selectedItems) { dataItem, state in
			ZStack(alignment: .bottomTrailing) {
				GeometryReader { geom in
					// TODO: Error handling
					self.renderConfig.render(item: dataItem)
						.environmentObject(self.context)
						.frame(width: geom.size.width, height: geom.size.height)
						.clipped()
				}

				if state.isSelected {
					ZStack {
						Circle().fill(Color.blue)
						Circle().strokeBorder(Color.white, lineWidth: 2)
						Image(systemName: "checkmark")
							.font(.system(size: 10, weight: .bold))
							.foregroundColor(.white)
					}
					.frame(width: 20, height: 20)
					.padding(10)
				}
			}
		}
		.onSelectSingle { index in
			if let press = self.renderConfig.press {
				self.context.executeAction(press, with: self.context.items[safe: index])
			}
		}
	}

	var body: some View {
		VStack {
			if context.cascadingView.resultSet.count == 0 {
				HStack(alignment: .top) {
					Spacer()
					Text(self.context.cascadingView.emptyResultText)
						.multilineTextAlignment(.center)
						.font(.system(size: 16, weight: .regular, design: .default))
						.opacity(0.7)
					Spacer()
				}
				.padding(.all, 30)
				.padding(.top, 40)
				Spacer()
			} else {
				ASCollectionView(section: section)
					.layout(self.layout)
			}
		}
	}
}

struct ThumbGridRendererView_Previews: PreviewProvider {
	static var previews: some View {
		ThumbnailRendererView().environmentObject(RootContext(name: "", key: "").mockBoot())
	}
}
