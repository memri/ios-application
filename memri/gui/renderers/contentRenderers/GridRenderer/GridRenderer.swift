//
// ThumbnailRendererView.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import SwiftUI

class GridRendererController: RendererController, ObservableObject {
    static let rendererType = RendererType(name: "grid", icon: "square.grid.3x2.fill", makeController: GridRendererController.init, makeConfig: GridRendererController.makeConfig)
    
    required init(context: MemriContext, config: CascadingRendererConfig?) {
        self.context = context
        self.config = (config as? GridRendererConfig) ?? GridRendererConfig()
    }
    
    let context: MemriContext
    let config: GridRendererConfig
    
    func makeView() -> AnyView {
        GridRendererView(controller: self).eraseToAnyView()
    }
    
    func update() {
        objectWillChange.send()
    }
    
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig {
        GridRendererConfig(head, tail, host)
    }
    
    var hasItems: Bool {
        !context.items.isEmpty
    }
    var items: [Item] {
        context.items
    }

    func view(for item: Item) -> some View {
        config.render(item: item)
            .environmentObject(context)
    }
    
    var isEditing: Bool {
        context.currentSession?.editMode ?? false
    }
    
    func contextMenuProvider(index: Int, item: Item) -> UIContextMenuConfiguration? {
        let children: [UIMenuElement] = config.contextMenuActions.map { [weak context] action in
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
    
    func onSelectSingleItem(index: Int) {
        if let press = config.press {
            self.context.executeAction(press, with: self.context.items[safe: index])
        }
    }
}

class GridRendererConfig: CascadingRendererConfig {
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
    
    var scrollDirection: UICollectionView.ScrollDirection {
        switch cascadeProperty("scrollDirection", type: String.self) {
        case "horizontal": return .horizontal
        case "vertical": return .vertical
        default: return .vertical
        }
    }
    
}

struct GridRendererView: View {
    @ObservedObject var controller: GridRendererController

    var scrollDirection: UICollectionView.ScrollDirection {
        controller.config.scrollDirection
    }
    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout(scrollDirection: scrollDirection, interSectionSpacing: 0) {
            ASCollectionLayoutSection { environment in
                let contentInsets = self.controller.config.nsEdgeInset
                let numberOfColumns = self.controller.config.columns
                
                switch scrollDirection {
                case .horizontal:
                    let ySpacing = self.controller.config.spacing.height
                    let estimatedGridBlockSize = (environment.container.effectiveContentSize
                                                    .height - contentInsets.top - contentInsets
                                                    .bottom - ySpacing * (CGFloat(numberOfColumns) - 1)) /
                        CGFloat(numberOfColumns)
                    
                    let item = NSCollectionLayoutItem(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .estimated(estimatedGridBlockSize),
                            heightDimension: .fractionalHeight(1.0)
                        )
                    )
                    
                    let itemsGroup = NSCollectionLayoutGroup.vertical(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .estimated(estimatedGridBlockSize),
                            heightDimension: .fractionalHeight(1.0)
                        ),
                        subitem: item, count: numberOfColumns
                    )
                    itemsGroup.interItemSpacing = .fixed(ySpacing)
                    
                    let section = NSCollectionLayoutSection(group: itemsGroup)
                    section.interGroupSpacing = self.controller.config.spacing.width
                    section.contentInsets = contentInsets
                    return section
                default:
                    let xSpacing = self.controller.config.spacing.width
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
                    section.interGroupSpacing = self.controller.config.spacing.height
                    section.contentInsets = contentInsets
                    return section
                }
                
                
               
            }
        }
    }

    var section: ASCollectionViewSection<Int> {
        ASCollectionViewSection(id: 0,
                                data: controller.items,
                                selectionMode: selectionMode,
                                contextMenuProvider: controller.contextMenuProvider)
        { dataItem, state in
            ZStack(alignment: .bottomTrailing) {
                self.controller.view(for: dataItem)

                if self.controller.isEditing && !state.isSelected {
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
    }
    
    var selectionMode: ASSectionSelectionMode {
        if controller.isEditing {
            return .selectMultiple(controller.context.selectedIndicesBinding)
        } else {
            return .selectSingle(controller.onSelectSingleItem)
        }
    }

    var body: some View {
        VStack {
            if controller.hasItems {
                ASCollectionView(editMode: controller.isEditing, section: section)
                    .layout(self.layout)
                    .alwaysBounceHorizontal(scrollDirection == .horizontal)
                    .alwaysBounceVertical(scrollDirection == .vertical)
                    .background(controller.config.backgroundColor?.color ?? Color(.systemBackground))
            } else {
                HStack(alignment: .top) {
                    Spacer()
                    Text(controller.context.currentView?.emptyResultText ?? "No results")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .opacity(0.7)
                    Spacer()
                }
                .padding(.all, 30)
                .padding(.top, 40)
                Spacer()
            }
        }
            .id(controller.config.ui_UUID) // Fix swiftUI wrongly animating between different lists
    }
}
