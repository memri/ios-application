//
//  TumbGridRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import ASCollectionView

private var register:Void = {
    Renderers.register(
        name: "thumbnail.grid",
        title: "Photo Grid",
        order: 20,
        icon: "square.grid.3x2.fill",
        view: AnyView(ThumbnailRendererView()),
        canDisplayResults: { items -> Bool in true }
    )
}()

struct ThumbGridRendererView: View {
    @EnvironmentObject var main: Main
    
    var name: String = "thumbnail_grid"
    
    @State var selectedItems: Set<Int> = []
    
//    @Environment(\.editMode) private var editMode
//    var isEditing: Bool
//    {
//        editMode?.wrappedValue.isEditing ?? false
//    }
    
    var renderConfig: CascadingThumbnailConfig {
        if self.main.computedView.renderConfigs["thumbnail"] == nil {
            print ("Warning: Using default render config for thumbnail.grid")
        }
        
        // TODO Refactor: How can we try other render configs?? e.g. ThumbnailConfig
        return self.main.computedView.renderConfigs["thumbnail"] as? CascadingThumbnailConfig ?? CascadingThumbnailConfig()
    }
    
    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0) {
            ASCollectionLayoutSection { environment in
                let isWide = environment.container.effectiveContentSize.width > 500
                let columns = CGFloat(isWide ? self.renderConfig.columnsWide.value ?? 5 : self.renderConfig.columns.value ?? 3)
                
                let gridBlockSize = environment.container.effectiveContentSize.width / columns
                let inset = CGFloat(self.renderConfig.itemInset.value ?? 5)
                let gridItemInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
                let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize), heightDimension: .absolute(gridBlockSize))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = gridItemInsets
                let verticalGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize), heightDimension: .absolute(gridBlockSize * 2))
                let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: verticalGroupSize, subitem: item, count: 2)

                let featureItemSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize * 2), heightDimension: .absolute(gridBlockSize * 2))
                let featureItem = NSCollectionLayoutItem(layoutSize: featureItemSize)
                featureItem.contentInsets = gridItemInsets

                let fullWidthItemSize = NSCollectionLayoutSize(widthDimension: .absolute(environment.container.effectiveContentSize.width), heightDimension: .absolute(gridBlockSize * 2))
                let fullWidthItem = NSCollectionLayoutItem(layoutSize: fullWidthItemSize)
                fullWidthItem.contentInsets = gridItemInsets

                let verticalAndFeatureGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize * 2))
                let verticalAndFeatureGroupA = NSCollectionLayoutGroup.horizontal(layoutSize: verticalAndFeatureGroupSize, subitems: isWide ? [verticalGroup, verticalGroup, featureItem, verticalGroup] : [verticalGroup, featureItem])
                let verticalAndFeatureGroupB = NSCollectionLayoutGroup.horizontal(layoutSize: verticalAndFeatureGroupSize, subitems: isWide ? [verticalGroup, featureItem, verticalGroup, verticalGroup] : [featureItem, verticalGroup])

                let rowGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize))
                let rowGroup = NSCollectionLayoutGroup.horizontal(layoutSize: rowGroupSize, subitem: item, count: Int(columns))

                let outerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize * 8))
                let outerGroup = NSCollectionLayoutGroup.vertical(layoutSize: outerGroupSize, subitems: [verticalAndFeatureGroupA, rowGroup, fullWidthItem, verticalAndFeatureGroupB, rowGroup])

                let section = NSCollectionLayoutSection(group: outerGroup)
                return section
            }
        }
    }
    
    var section: ASCollectionViewSection<Int>{
        ASCollectionViewSection(id: 0, data: main.items, selectedItems: $selectedItems) { dataItem, state in
            ZStack(alignment: .bottomTrailing) {
                GeometryReader { geom in
                    self.renderConfig.render(item: dataItem)
                        .onTapGesture {
                            if let press = self.renderConfig.press {
                                self.main.executeAction(press, dataItem)
                            }
                        }
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
    }
    
    var body: some View {
        let edgeInset:[CGFloat] = renderConfig.edgeInset.map{ CGFloat($0) }
        
        return VStack {
            if main.computedView.resultSet.count == 0 {
                HStack (alignment: .top)  {
                    Spacer()
                    Text(self.main.computedView.emptyResultText)
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
                        .contentInsets(.init(
                            top: edgeInset[safe: 0] ?? 0,
                            left: edgeInset[safe: 3] ?? 0,
                            bottom: edgeInset[safe: 2] ?? 0,
                            right: edgeInset[safe: 1] ?? 0))
//                    .initialScrollPosition(startingAtBottom ? .bottom : nil)
//                    .edgesIgnoringSafeArea(.all)
//                    .navigationBarTitle("Explore", displayMode: .large)
//                    .navigationBarItems(
//                        trailing:
//                        HStack(spacing: 20)
//                        {
//                            if self.isEditing
//                            {
//                                Button(action: {
//                                    withAnimation {
//                                        // We want the cell removal to be animated, so explicitly specify `withAnimation`
//                                        self.data.remove(atOffsets: IndexSet(self.selectedItems))
//                                    }
//                                })
//                                {
//                                    Image(systemName: "trash")
//                                }
//                            }
//
//                            EditButton()
//                    })
            }
        }
    }
    
    func onTap(Action: Action, dataItem: DataItem){
        main.executeAction(Action, dataItem)
    }
}

struct ThumbGridRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailRendererView().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
