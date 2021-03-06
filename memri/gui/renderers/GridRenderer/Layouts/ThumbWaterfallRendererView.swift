//
// ThumbWaterfallRendererView.swift
// Copyright © 2020 memri. All rights reserved.

////
//// ThumbWaterfallRendererView.swift
//// Copyright © 2020 memri. All rights reserved.
//
// import ASCollectionView
// import SwiftUI
//
// struct ThumbWaterfallRendererView: View {
//    @EnvironmentObject var context: MemriContext
//
//    var name: String = "thumbnail_waterfall"
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
//        context.currentView?.renderConfig as? GridRendererConfig ?? GridRendererConfig()
//    }
//
//    var layout: ASCollectionLayout<Int> {
//        ASCollectionLayout(createCustomLayout: ASWaterfallLayout.init) { layout in
//            let spacing = self.renderConfig.spacing
//            layout.columnSpacing = spacing.width
//            layout.itemSpacing = spacing.height
//            layout
//                .numberOfColumns =
//                .adaptive(minWidth: 150) // @State var columnMinSize: CGFloat = 150
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
//                        .opacity(state.isSelected ? 0.7 : 1.0)
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
//                    .customDelegate(WaterfallScreenLayoutDelegate.init)
//                    .alwaysBounceVertical()
//                    .contentInsets(renderConfig.edgeInset)
//                    .background(renderConfig.backgroundColor?.color ?? Color(.systemBackground))
//            }
//        }
//            .id(renderConfig.ui_UUID) // Fix swiftUI wrongly animating between different lists
//    }
// }
//
// struct ThumbWaterfallRendererView_Previews: PreviewProvider {
//    static var previews: some View {
//        ThumbnailRendererView().environmentObject(try! RootContext(name: "").mockBoot())
//    }
// }
//
// class WaterfallScreenLayoutDelegate: ASCollectionViewDelegate, ASWaterfallLayoutDelegate {
//    func heightForHeader(sectionIndex _: Int) -> CGFloat? {
//        0
//    }
//
//    let heights: [CGFloat] = [1.5, 1.0, 0.75, 1.75, 0.6]
//    /// We explicitely provide a height here. If providing no delegate, this layout will use auto-sizing, however this causes problems if rotating the device (due to limitaitons in UICollecitonView and autosizing cells that are not visible)
//    func heightForCell(
//        at indexPath: IndexPath,
//        context: ASWaterfallLayout.CellLayoutContext
//    ) -> CGFloat {
//        //        guard let item: Item = getDataForItem(at: indexPath) else { return 100 }
//        let rand = indexPath.item % heights.count
//        return context.width * (heights[safe: rand] ?? 1)
//    }
// }
