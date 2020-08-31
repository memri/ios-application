////
//// ThumbHorizontalGridRendererView.swift
//// Copyright © 2020 memri. All rights reserved.
//
//import ASCollectionView
//import SwiftUI
//
//
//struct ThumbHorizontalGridRendererView: View {
//    @EnvironmentObject var context: MemriContext
//
//    var name: String = "thumbnail_horizontalgrid"
//
//    var selectedIndices: Binding<Set<Int>> {
//        Binding<Set<Int>>(
//            get: { [] },
//            set: {
//                self.context.setSelection($0.compactMap { self.context.items[safe: $0] })
//            }
//        )
//    }
//
//    //    @Environment(\.editMode) private var editMode
//    //    var isEditing: Bool
//    //    {
//    //        editMode?.wrappedValue.isEditing ?? false
//    //    }
//
//    var renderConfig: GridRendererConfig {
//        (context.currentView?.renderConfig as? GridRendererConfig) ??
//            GridRendererConfig()
//    }
//
//    var layout: ASCollectionLayout<Int> {
//        ASCollectionLayout(scrollDirection: .horizontal, interSectionSpacing: 0) {
//            ASCollectionLayoutSection { environment in
//                let contentInsets = self.renderConfig.nsEdgeInset
//                let numberOfRows = self.renderConfig.columns
//                let ySpacing = self.renderConfig.spacing.height
//                let calculatedGridBlockSize = (environment.container.effectiveContentSize
//                    .height - contentInsets.top - contentInsets
//                    .bottom - ySpacing * (CGFloat(numberOfRows) - 1)) / CGFloat(numberOfRows)
//
//                let item = NSCollectionLayoutItem(
//                    layoutSize: NSCollectionLayoutSize(
//                        widthDimension: .fractionalWidth(1.0),
//                        heightDimension: .fractionalHeight(1.0)
//                    )
//                )
//
//                let itemsGroup = NSCollectionLayoutGroup.vertical(
//                    layoutSize: NSCollectionLayoutSize(
//                        widthDimension: .absolute(calculatedGridBlockSize),
//                        heightDimension: .fractionalHeight(1.0)
//                    ),
//                    subitem: item, count: numberOfRows
//                )
//                itemsGroup.interItemSpacing = .fixed(ySpacing)
//
//                let section = NSCollectionLayoutSection(group: itemsGroup)
//                section.interGroupSpacing = self.renderConfig.spacing.width
//                section.contentInsets = contentInsets
//                return section
//            }
//        }
//    }
//
//    var section: ASCollectionViewSection<Int> {
//        ASCollectionViewSection(id: 0, data: context.items,
//                                selectedItems: selectedIndices,
//                                contextMenuProvider: contextMenuProvider) { dataItem, state in
//            ZStack(alignment: .bottomTrailing) {
//                GeometryReader { geom in
//                    self.renderConfig.render(item: dataItem)
//                        .environmentObject(self.context)
//                        .frame(width: geom.size.width, height: geom.size.height)
//                        .clipped()
//                }
//
//                if state.isSelected {
//                    ZStack {
//                        Circle().fill(Color.blue)
//                        Circle().strokeBorder(Color.white, lineWidth: 2)
//                        Image(systemName: "checkmark")
//                            .font(.system(size: 10, weight: .bold))
//                            .foregroundColor(.white)
//                    }
//                    .frame(width: 20, height: 20)
//                    .padding(10)
//                }
//            }
//        }
//        .onSelectSingle { index in
//            if let press = self.renderConfig.press {
//                self.context.executeAction(press, with: self.context.items[safe: index])
//            }
//        }
//    }
//
//    func contextMenuProvider(index: Int, item: Item) -> UIContextMenuConfiguration? {
//        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak context] (suggested) -> UIMenu? in
//            let children: [UIMenuElement] = self.renderConfig.contextMenuActions.map { [weak context] action in
//                UIAction(title: action.getString("title"),
//                         image: nil) { [weak context] (_) in
//                            context?.executeAction(action, with: item)
//                }
//            }
//            return UIMenu(title: "", children: children)
//        }
//    }
//    
//    var body: some View {
//        VStack {
//            if context.currentView?.resultSet.count == 0 {
//                HStack(alignment: .top) {
//                    Spacer()
//                    Text(self.context.currentView?.emptyResultText ?? "")
//                        .multilineTextAlignment(.center)
//                        .font(.system(size: 16, weight: .regular, design: .default))
//                        .opacity(0.7)
//                    Spacer()
//                }
//                .padding(.all, 30)
//                .padding(.top, 40)
//                Spacer()
//            }
//            else {
//                ASCollectionView(section: section)
//                    .layout(self.layout)
//            }
//        }
//        .background(renderConfig.backgroundColor?.color ?? Color(.systemBackground))
//            .id(renderConfig.ui_UUID) // Fix swiftUI wrongly animating between different lists
//    }
//}
//
//struct ThumbGridRendererView_Previews: PreviewProvider {
//    static var previews: some View {
//        ThumbnailRendererView().environmentObject(try! RootContext(name: "").mockBoot())
//    }
//}
