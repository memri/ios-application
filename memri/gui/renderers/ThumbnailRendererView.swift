//
//  ThumbnailRendererView.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import ASCollectionView

let registerThumbnail = {
    Renderers.register(
        name: "thumbnail",
        title: "Default",
        order: 10,
        icon: "square.grid.3x2.fill",
        view: AnyView(ThumbnailRendererView()),
        renderConfigType: CascadingThumbnailConfig.self,
        canDisplayResults: { items -> Bool in true }
    )
}

class CascadingThumbnailConfig: CascadingRenderConfig {
    var type: String? = "thumbnail"
    
    var longPress: Action? { cascadeProperty("longPress") }
    var press: Action? { cascadeProperty("press") }
    
    var columns:Int? { Int(cascadeProperty("columns") ?? 3) }
    var itemInset:CGFloat? { CGFloat(cascadeProperty("itemInset") ?? 6) }
    var edgeInset:[CGFloat]? { (cascadeProperty("edgeInset") ?? []).map{ CGFloat($0 as Double) } }
}

struct ThumbnailRendererView: View {
    @EnvironmentObject var context: MemriContext
    
    var name: String="thumbnail"
    
    var renderConfig: CascadingThumbnailConfig? {
        self.context.cascadingView.renderConfig as? CascadingThumbnailConfig
    }
    
    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0) {
            ASCollectionLayoutSection { environment in
                let numberOfColumns = CGFloat(self.renderConfig?.columns ?? 3)
                let estimatedGridBlockSize = environment.container.effectiveContentSize.width / numberOfColumns
                
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1 / numberOfColumns),
                        heightDimension: .estimated(estimatedGridBlockSize)))

                let itemsGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(estimatedGridBlockSize)),
                    subitems: [item])

                let section = NSCollectionLayoutSection(group: itemsGroup)
                return section
            }
        }
    }
    
    var section: ASCollectionViewSection<Int> {
        ASCollectionViewSection (id: 0, data: context.items) { dataItem, state in
            ZStack (alignment: .bottomTrailing) {
                // TODO: Error handling
                self.renderConfig?.render(item: dataItem)
                    .environmentObject(self.context)
                .padding(.all, self.renderConfig?.itemInset)

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
        .onSelectSingle({ (index) in
            if let press = self.renderConfig?.press {
                self.context.executeAction(press, with: self.context.items[safe: index])
            }
        })
    }
    
    var edgeInset: UIEdgeInsets {
        UIEdgeInsets(top: renderConfig?.edgeInset?[safe: 0] ?? 0,
                   left: renderConfig?.edgeInset?[safe: 3] ?? 0,
                   bottom: renderConfig?.edgeInset?[safe: 2] ?? 0,
                   right: renderConfig?.edgeInset?[safe: 1] ?? 0)
    }
    
    var body: some View {
        
        return VStack {
            if renderConfig == nil {
                Text("Unable to render this view")
            }
            else if context.cascadingView.resultSet.count == 0 {
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
                ASCollectionView (section: section)
                    .layout (self.layout)
                    .alwaysBounceVertical()
                    .contentInsets(edgeInset)
            }
        }
    }
    
    func onTap(action: Action, dataItem: DataItem){
        context.executeAction(action, with: dataItem)
    }
}

struct ThumbnailRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailRendererView().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
