//
// ThumbnailRendererView.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import SwiftUI

let registerThumbnailRenderer = {
    Renderers.register(
        name: "thumbnail",
        title: "Default",
        order: 100,
        icon: "square.grid.3x2.fill",
        view: AnyView(ThumbnailRendererView()),
        renderConfigType: CascadingThumbnailConfig.self,
        canDisplayResults: { _ -> Bool in true }
    )
}

class CascadingThumbnailConfig: CascadingRenderConfig {
    var type: String? = "thumbnail"

    var longPress: Action? {
        get { cascadeProperty("longPress") }
        set(value) { setState("longPress", value) }
    }

    var press: Action? {
        get { cascadeProperty("press") }
        set(value) { setState("press", value) }
    }

    var columns: Int {
        get { Int(cascadeProperty("columns") as Double? ?? 3) }
        set(value) { setState("columns", value) }
    }
}

struct ThumbnailRendererView: View {
    @EnvironmentObject var context: MemriContext
    var selectedIndices: Binding<Set<Int>> {
        Binding<Set<Int>>(
            get: { [] },
            set: {
                self.context.setSelection($0.compactMap { self.context.items[safe: $0] })
            }
        )
    }

    var name: String = "thumbnail"

    var renderConfig: CascadingThumbnailConfig {
        context.currentView?.renderConfig as? CascadingThumbnailConfig ?? CascadingThumbnailConfig()
    }

    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0) {
            ASCollectionLayoutSection { environment in
                let contentInsets = self.renderConfig.nsEdgeInset
                let numberOfColumns = self.renderConfig.columns
                let xSpacing = self.renderConfig.spacing.width
                let estimatedGridBlockSize = (environment.container.effectiveContentSize
                    .width - contentInsets.leading - contentInsets
                    .trailing - xSpacing * (CGFloat(numberOfColumns) - 1)) /
                    CGFloat(numberOfColumns)

                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(estimatedGridBlockSize)
                    )
                )

                let itemsGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(estimatedGridBlockSize)
                    ),
                    subitem: item, count: numberOfColumns
                )
                itemsGroup.interItemSpacing = .fixed(xSpacing)

                let section = NSCollectionLayoutSection(group: itemsGroup)
                section.interGroupSpacing = self.renderConfig.spacing.height
                section.contentInsets = contentInsets
                return section
            }
        }
    }

    var section: ASCollectionViewSection<Int> {
        ASCollectionViewSection(id: 0,
                                data: context.items,
                                selectedItems: selectedIndices,
                                contextMenuProvider: contextMenuProvider)
        { dataItem, state in
            ZStack(alignment: .bottomTrailing) {
                self.renderConfig.render(item: dataItem)
                    .environmentObject(self.context)

                if self.context.currentSession?.editMode ?? false && !state.isSelected {
                    Color.white.opacity(0.15)
                }
                if state.isSelected {
                    ZStack {
                        Circle().fill(Color.blue)
                        Circle().strokeBorder(Color.white, lineWidth: 2)
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 30, height: 30)
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
        let children: [UIMenuElement] = self.renderConfig.contextMenuActions.map { [weak context] action in
            UIAction(title: action.getString("title"),
                     image: nil) { [weak context] (_) in
                        context?.executeAction(action, with: item)
            }
        }
        guard !children.isEmpty else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (suggested) -> UIMenu? in
            return UIMenu(title: "", children: children)
        }
    }

    var body: some View {
        VStack {
            if (context.currentView?.resultSet.count ?? 0) == 0 {
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
                    .environment(\.editMode, Binding<EditMode>(
                        get: { self.context.currentSession?.swiftUIEditMode ?? EditMode.inactive },
                        set: { self.context.currentSession?.swiftUIEditMode = $0 }
                    ))
                    .background(renderConfig.backgroundColor?.color ?? Color(.systemBackground))
            }
        }
            .id(renderConfig.ui_UUID) // Fix swiftUI wrongly animating between different lists
    }
}

struct ThumbnailRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailRendererView().environmentObject(try! RootContext(name: "").mockBoot())
    }
}
