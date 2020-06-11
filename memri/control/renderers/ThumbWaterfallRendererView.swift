//
//  TumbGridRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import ASCollectionView

let registerThumWaterfall = {
    Renderers.register(
        name: "thumbnail.waterfall",
        title: "Waterfall Grid",
        order: 30,
        icon: "square.grid.3x2.fill",
        view: AnyView(ThumbWaterfallRendererView()),
        renderConfigType: CascadingThumbnailConfig.self,
        canDisplayResults: { items -> Bool in true }
    )
}

struct ThumbWaterfallRendererView: View {
    @EnvironmentObject var context: MemriContext
    
    var name: String = "thumbnail_waterfall"
    
    @State var selectedItems: Set<Int> = []
    
//    @Environment(\.editMode) private var editMode
//    var isEditing: Bool
//    {
//        editMode?.wrappedValue.isEditing ?? false
//    }
    
    var renderConfig: CascadingThumbnailConfig? {
        self.context.cascadingView.renderConfig as? CascadingThumbnailConfig
    }
    
    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout(createCustomLayout: ASWaterfallLayout.init) { layout in
            layout.numberOfColumns = .adaptive(minWidth: 150) // @State var columnMinSize: CGFloat = 150
        }
        // Can also initialise like this when no need to dynamically update values
        /*
         ASCollectionLayout
         {
             let layout = ASWaterfallLayout()
             return layout
         }
         */
    }
    
    var section: ASCollectionViewSection<Int>{
        ASCollectionViewSection(id: 0, data: context.items, selectedItems: $selectedItems) { dataItem, state in
            ZStack(alignment: .bottomTrailing) {
                GeometryReader { geom in
                    // TODO: Error handling
                    self.renderConfig!.render(item: dataItem)
                        .environmentObject(self.context)
                        .onTapGesture {
                            if let press = self.renderConfig?.press {
                                self.context.executeAction(press, with: dataItem)
                            }
                        }
                        .frame(width: geom.size.width, height: geom.size.height)
//                        .opacity(state.isSelected ? 0.7 : 1.0)
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
//            .frame(width: geom.size.width, height: geom.size.height)
//            .clipped()
        }
    }
    
    var body: some View {
        let edgeInset = renderConfig?.edgeInset ?? []
        
        return VStack {
            if context.cascadingView.resultSet.count == 0 {
                HStack (alignment: .top)  {
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
            }
            else {
                ASCollectionView(section: section)
                    .layout(self.layout)
                    .customDelegate(WaterfallScreenLayoutDelegate.init)
                    // TODO REfactor: implement this for the other grids
                    .contentInsets(.init(
                        top: edgeInset[safe: 0] ?? 0,
                        left: edgeInset[safe: 3] ?? 0,
                        bottom: edgeInset[safe: 2] ?? 0,
                        right: edgeInset[safe: 1] ?? 0))
//                    .navigationBarTitle("Waterfall Layout", displayMode: .inline)
//                    .navigationBarItems(
//                        trailing:
//                        HStack(spacing: 20)
//                        {
//                            if self.isEditing
//                            {
//                                Button(action: {
//                                    withAnimation {
//                                        self.selectedItems.forEach { sectionIndex, selected in
//                                            self.data[sectionIndex].remove(atOffsets: IndexSet(selected))
//                                        }
//                                    }
//                                })
//                                {
//                                    Image(systemName: "trash")
//                                }
//                            }
//
//                            EditButton()
//                    })
//                    .initialScrollPosition(startingAtBottom ? .bottom : nil)
            }
        }
    }
    
    func onTap(action: Action, dataItem: DataItem){
        context.executeAction(action, with: dataItem)
    }
}

struct ThumbWaterfallRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailRendererView().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}

class WaterfallScreenLayoutDelegate: ASCollectionViewDelegate, ASWaterfallLayoutDelegate{
    func heightForHeader(sectionIndex: Int) -> CGFloat? {
        0
    }

    /// We explicitely provide a height here. If providing no delegate, this layout will use auto-sizing, however this causes problems if rotating the device (due to limitaitons in UICollecitonView and autosizing cells that are not visible)
    func heightForCell(at indexPath: IndexPath, context: ASWaterfallLayout.CellLayoutContext) -> CGFloat {
//        guard let item: DataItem = getDataForItem(at: indexPath) else { return 100 }
        return context.width / .random(in: 0.3 ... 1.5)
    }
}