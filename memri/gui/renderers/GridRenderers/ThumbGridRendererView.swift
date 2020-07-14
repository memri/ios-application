//
//  TumbGridRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import ASCollectionView
import SwiftUI

let registerThumbGridRenderer = {
	Renderers.register(
		name: "thumbnail.grid",
		title: "Photo Grid",
		order: 110,
		icon: "square.grid.3x2.fill",
		view: AnyView(ThumbGridRendererView()),
		renderConfigType: CascadingThumbnailConfig.self,
		canDisplayResults: { _ -> Bool in true }
	)
}

struct ThumbGridRendererView: View {
	@EnvironmentObject var context: MemriContext

	var name: String = "thumbnail_grid"

	@State var selectedItems: Set<Int> = []

	//    @Environment(\.editMode) private var editMode
	//    var isEditing: Bool
	//    {
	//        editMode?.wrappedValue.isEditing ?? false
	//    }

	var renderConfig: CascadingThumbnailConfig {
		context.cascadingView?.renderConfig as? CascadingThumbnailConfig ?? CascadingThumbnailConfig()
	}

	var layout: ASCollectionLayout<Int> {
		ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0) {
			ASCollectionLayoutSection { environment in
				let contentInset = self.renderConfig.nsEdgeInset
				let columns = 3
				let spacing = self.renderConfig.spacing

				let singleBlockSize = (environment.container.effectiveContentSize.width - contentInset.leading - contentInset.trailing - spacing.x * CGFloat(columns - 1)) / CGFloat(columns)
				func gridBlockSize(forSize size: Int, sizeY: Int? = nil) -> NSCollectionLayoutSize {
					let x = CGFloat(size) * singleBlockSize + spacing.x * CGFloat(size - 1)
					let y = CGFloat(sizeY ?? size) * singleBlockSize + spacing.y * CGFloat((sizeY ?? size) - 1)
					return NSCollectionLayoutSize(widthDimension: .absolute(x), heightDimension: .absolute(y))
				}
				let itemSize = gridBlockSize(forSize: 1)

				let item = NSCollectionLayoutItem(layoutSize: itemSize)

				let verticalGroupSize = gridBlockSize(forSize: 1, sizeY: 2)
				let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: verticalGroupSize, subitem: item, count: 2)
				verticalGroup.interItemSpacing = .fixed(spacing.y)

				let featureItemSize = gridBlockSize(forSize: 2)
				let featureItem = NSCollectionLayoutItem(layoutSize: featureItemSize)

				let fullWidthItemSize = gridBlockSize(forSize: 3, sizeY: 1)
				let fullWidthItem = NSCollectionLayoutItem(layoutSize: fullWidthItemSize)

				let verticalAndFeatureGroupSize = gridBlockSize(forSize: 3, sizeY: 2)
				let verticalAndFeatureGroupA = NSCollectionLayoutGroup.horizontal(layoutSize: verticalAndFeatureGroupSize, subitems: [verticalGroup, featureItem])
				verticalAndFeatureGroupA.interItemSpacing = .fixed(spacing.x)
				let verticalAndFeatureGroupB = NSCollectionLayoutGroup.horizontal(layoutSize: verticalAndFeatureGroupSize, subitems: [featureItem, verticalGroup])
				verticalAndFeatureGroupB.interItemSpacing = .fixed(spacing.x)

				let rowGroupSize = gridBlockSize(forSize: 3, sizeY: 1)
				let rowGroup = NSCollectionLayoutGroup.horizontal(layoutSize: rowGroupSize, subitem: item, count: Int(columns))
				rowGroup.interItemSpacing = .fixed(spacing.x)

				let outerGroupSize = gridBlockSize(forSize: 3, sizeY: 7)
				let outerGroup = NSCollectionLayoutGroup.vertical(layoutSize: outerGroupSize, subitems: [verticalAndFeatureGroupA, rowGroup, fullWidthItem, verticalAndFeatureGroupB, rowGroup])
				outerGroup.interItemSpacing = .fixed(spacing.y)

				let section = NSCollectionLayoutSection(group: outerGroup)
				section.contentInsets = contentInset
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
			if context.cascadingView?.resultSet.count == 0 {
				HStack(alignment: .top) {
					Spacer()
					Text(self.context.cascadingView?.emptyResultText ?? "")
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
					.alwaysBounceVertical()
			}
		}
	}
}

struct ThumbHorizontalGridRendererView_Previews: PreviewProvider {
	static var previews: some View {
		ThumbHorizontalGridRendererView().environmentObject(try! RootContext(name: "", key: "").mockBoot())
	}
}
