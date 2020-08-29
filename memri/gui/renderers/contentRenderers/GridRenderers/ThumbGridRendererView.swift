//
// ThumbGridRendererView.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import SwiftUI
//
//let registerThumbGridRenderer = {
//    Renderers.register(
//        name: "thumbnail.grid",
//        title: "Photo Grid",
//        order: 110,
//        icon: "square.grid.3x2.fill",
//        view: AnyView(ThumbGridRendererView()),
//        renderConfigType: CascadingThumbnailConfig.self,
//        canDisplayResults: { _ -> Bool in true }
//    )
//}

struct ThumbGridRendererView: View {
    @EnvironmentObject var context: MemriContext

    var name: String = "thumbnail_grid"

    var selectedIndices: Binding<Set<Int>> {
        Binding<Set<Int>>(
            get: { [] },
            set: {
                self.context.setSelection($0.compactMap { self.context.items[safe: $0] })
            }
        )
    }

    //    @Environment(\.editMode) private var editMode
    //    var isEditing: Bool
    //    {
    //        editMode?.wrappedValue.isEditing ?? false
    //    }

    var renderConfig: CascadingThumbnailConfig {
        context.currentView?.renderConfig as? CascadingThumbnailConfig ?? CascadingThumbnailConfig()
    }

    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0) {
            ASCollectionLayoutSection { environment in
                let contentInset = self.renderConfig.nsEdgeInset
                let columns = 3
                let spacing = self.renderConfig.spacing

                let singleBlockSize = (environment.container.effectiveContentSize.width
					- contentInset.leading - contentInset.trailing
					- spacing.width * CGFloat(columns - 1)) / CGFloat(columns)
                func gridBlockSize(forSize size: Int, sizeY: Int? = nil) -> NSCollectionLayoutSize {
                    let x = CGFloat(size) * singleBlockSize + spacing.width * CGFloat(size - 1)
                    let y = CGFloat(sizeY ?? size) * singleBlockSize
						+ spacing.height * CGFloat((sizeY ?? size) - 1)
                    return NSCollectionLayoutSize(
                        widthDimension: .absolute(x),
                        heightDimension: .absolute(y)
                    )
                }
                let itemSize = gridBlockSize(forSize: 1)

                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let verticalGroupSize = gridBlockSize(forSize: 1, sizeY: 2)
                let verticalGroup = NSCollectionLayoutGroup.vertical(
                    layoutSize: verticalGroupSize,
                    subitem: item,
                    count: 2
                )
                verticalGroup.interItemSpacing = .fixed(spacing.height)

                let featureItemSize = gridBlockSize(forSize: 2)
                let featureItem = NSCollectionLayoutItem(layoutSize: featureItemSize)

                let fullWidthItemSize = gridBlockSize(forSize: 3, sizeY: 1)
                let fullWidthItem = NSCollectionLayoutItem(layoutSize: fullWidthItemSize)

                let verticalAndFeatureGroupSize = gridBlockSize(forSize: 3, sizeY: 2)
                let verticalAndFeatureGroupA = NSCollectionLayoutGroup.horizontal(
                    layoutSize: verticalAndFeatureGroupSize,
                    subitems: [verticalGroup, featureItem]
                )
                verticalAndFeatureGroupA.interItemSpacing = .fixed(spacing.width)
                let verticalAndFeatureGroupB = NSCollectionLayoutGroup.horizontal(
                    layoutSize: verticalAndFeatureGroupSize,
                    subitems: [featureItem, verticalGroup]
                )
                verticalAndFeatureGroupB.interItemSpacing = .fixed(spacing.width)

                let rowGroupSize = gridBlockSize(forSize: 3, sizeY: 1)
                let rowGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: rowGroupSize,
                    subitem: item,
                    count: Int(columns)
                )
                rowGroup.interItemSpacing = .fixed(spacing.width)

                let outerGroupSize = gridBlockSize(forSize: 3, sizeY: 7)
                let outerGroup = NSCollectionLayoutGroup.vertical(
                    layoutSize: outerGroupSize,
                    subitems: [
                        verticalAndFeatureGroupA,
                        rowGroup,
                        fullWidthItem,
                        verticalAndFeatureGroupB,
                        rowGroup,
                    ]
                )
                outerGroup.interItemSpacing = .fixed(spacing.height)

                let section = NSCollectionLayoutSection(group: outerGroup)
                section.contentInsets = contentInset
                section.interGroupSpacing = 1
                return section
            }
        }
    }

    var section: ASCollectionViewSection<Int> {
        ASCollectionViewSection(id: 0, data: context.items,
                                selectedItems: selectedIndices,
                                contextMenuProvider: contextMenuProvider) { dataItem, state in
            ZStack(alignment: .bottomTrailing) {
                GeometryReader { geom in
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
    
    func contextMenuProvider(index: Int, item: Item) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak context] (suggested) -> UIMenu? in
            let children: [UIMenuElement] = self.renderConfig.contextMenuActions.map { [weak context] action in
                UIAction(title: action.getString("title"),
                         image: nil) { [weak context] (_) in
                            context?.executeAction(action, with: item)
                }
            }
            return UIMenu(title: "", children: children)
        }
    }

    var body: some View {
        VStack {
            if context.currentView?.resultSet.count == 0 {
                HStack(alignment: .top) {
                    Spacer()
                    Text(self.context.currentView?.emptyResultText ?? "")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .opacity(0.7)
                    Spacer()
                }
                .padding(.all, 30)
                .padding(.top, 40)
                Spacer()
            }
            else {
                ASCollectionView(section: section)
                    .layout(self.layout)
                    .alwaysBounceVertical()
                    .background(renderConfig.backgroundColor?.color ?? Color(.systemBackground))
            }
        }
            .id(renderConfig.ui_UUID) // Fix swiftUI wrongly animating between different lists
    }
}

struct ThumbHorizontalGridRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbHorizontalGridRendererView()
            .environmentObject(try! RootContext(name: "").mockBoot())
    }
}
