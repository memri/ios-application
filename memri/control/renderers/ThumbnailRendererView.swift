//
//  TumbnailRenderer.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import ASCollectionView

private var register:Void = {
    Renderers.register(
        name: "thumbnail",
        title: "Default",
        order: 10,
        icon: "square.grid.3x2.fill",
        view: AnyView(ThumbnailRendererView()),
        canDisplayResults: { items -> Bool in true }
    )
}()

class CascadingThumbnailConfig: CascadingRenderConfig {
    var type: String? = "thumbnail"
    
    var longPress: Action? { cascadeProperty("longPress", nil) }
    var press: Action? { cascadeProperty("press", nil) }
    
    var columns:Int? { cascadeProperty("column", nil) }
    var itemInset:Int? { cascadeProperty("itemInset", nil) }
    var edgeInset:[Int]? { cascadeProperty("edgeInset", nil) }
}

struct ThumbnailRendererView: View {
    @EnvironmentObject var main: Main
    
    var name: String="thumbnail"
    
    var renderConfig: CascadingThumbnailConfig {
        if self.main.cascadingView.renderConfigs[name] == nil {
            print ("Warning: Using default render config for thumbnail")
        }
        
        return self.main.cascadingView.renderConfigs[name] as? CascadingThumbnailConfig ?? CascadingThumbnailConfig()
    }
    
    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0) {
            ASCollectionLayoutSection {
                let gridBlockSize = NSCollectionLayoutDimension
                    .fractionalWidth(1 / CGFloat(self.renderConfig.columns.value ?? 3))
                
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: gridBlockSize,
                        heightDimension: .fractionalHeight(1.0)))
                
                let inset = CGFloat(self.renderConfig.itemInset.value ?? 5)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: inset, leading: inset, bottom: inset, trailing: inset)

                let itemsGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: gridBlockSize),
                    subitems: [item])

                let section = NSCollectionLayoutSection(group: itemsGroup)
                return section
            }
        }
    }
    
    var section: ASCollectionViewSection<Int> {
        ASCollectionViewSection (id: 0, data: main.items) { dataItem, state in
            ZStack (alignment: .bottomTrailing) {
                self.renderConfig.render(item: dataItem)
                    .onTapGesture {
                        if let press = self.renderConfig.press {
                            self.main.executeAction(press, dataItem)
                        }
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
            if main.cascadingView.resultSet.count == 0 {
                HStack (alignment: .top)  {
                    Spacer()
                    Text(self.main.cascadingView.emptyResultText)
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
                ASCollectionView (section: section)
                    .layout (self.layout)
                    .contentInsets(.init(
                        top: edgeInset[safe: 0] ?? 0,
                        left: edgeInset[safe: 3] ?? 0,
                        bottom: edgeInset[safe: 2] ?? 0,
                        right: edgeInset[safe: 1] ?? 0))
            }
        }
    }
    
    func onTap(Action: Action, dataItem: DataItem){
        main.executeAction(Action, dataItem)
    }
}

struct ThumbnailRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailRendererView().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
