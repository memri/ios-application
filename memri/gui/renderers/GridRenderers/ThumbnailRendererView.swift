//
//  ThumbnailRendererView.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import ASCollectionView

let registerThumbnailRenderer = {
    Renderers.register(
        name: "thumbnail",
        title: "Default",
        order: 100,
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
    
    var columns: Int { Int(cascadeProperty("columns") as Double? ?? 3) }
    
    var edgeInset: UIEdgeInsets {
        if let edgeInset = cascadePropertyAsCGFloat("edgeInset") {
            return UIEdgeInsets(top: edgeInset, left: edgeInset, bottom: edgeInset, right: edgeInset)
        } else if let x: [Double?] = cascadeProperty("edgeInset") {
            let insetArray = x.compactMap({ $0.map { CGFloat($0) } })
            switch insetArray.count {
            case 2: return UIEdgeInsets(top: insetArray[1], left: insetArray[0], bottom: insetArray[1], right: insetArray[0])
            case 4: return UIEdgeInsets(top: insetArray[0], left: insetArray[3], bottom: insetArray[2], right: insetArray[1])
            default: return .init()
            }
        }
        return .init()
    }
    
    var nsEdgeInset: NSDirectionalEdgeInsets {
        let edgeInset = self.edgeInset
        return NSDirectionalEdgeInsets(top: edgeInset.top, leading: edgeInset.left, bottom: edgeInset.bottom, trailing: edgeInset.right)
    }
    
    //Calculated
    var spacing: (x: CGFloat, y: CGFloat) {
        if let spacing = cascadePropertyAsCGFloat("spacing") {
            return (spacing, spacing)
        } else if let x: [Double?] = cascadeProperty("spacing") {
            let spacingArray = x.compactMap({ $0.map { CGFloat($0) } })
            guard spacingArray.count == 2 else { return (0, 0) }
            return (spacingArray[0], spacingArray[1])
        }
        return (0, 0)
    }
}

struct ThumbnailRendererView: View {
    @EnvironmentObject var context: MemriContext
    
    var name: String="thumbnail"
    
    var renderConfig: CascadingThumbnailConfig {
        self.context.cascadingView.renderConfig as? CascadingThumbnailConfig ?? CascadingThumbnailConfig()
    }
    
    var layout: ASCollectionLayout<Int> {
        ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0) {
            ASCollectionLayoutSection { environment in
                let contentInsets = self.renderConfig.nsEdgeInset
                let numberOfColumns = self.renderConfig.columns
                let xSpacing = self.renderConfig.spacing.x
                let estimatedGridBlockSize = (environment.container.effectiveContentSize.width - contentInsets.leading - contentInsets.trailing - xSpacing * (CGFloat(numberOfColumns) - 1)) / CGFloat(numberOfColumns)
                
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(estimatedGridBlockSize)))

                let itemsGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .estimated(estimatedGridBlockSize)),
                    subitem: item, count: numberOfColumns)
                itemsGroup.interItemSpacing = .fixed(xSpacing)

                let section = NSCollectionLayoutSection(group: itemsGroup)
                section.interGroupSpacing = self.renderConfig.spacing.y
                section.contentInsets = contentInsets
                return section
            }
        }
    }
    
    var section: ASCollectionViewSection<Int> {
        ASCollectionViewSection (id: 0, data: context.items) { dataItem, state in
            ZStack (alignment: .bottomTrailing) {
                // TODO: Error handling
                self.renderConfig.render(item: dataItem)
                    .environmentObject(self.context)

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
            if let press = self.renderConfig.press {
                self.context.executeAction(press, with: self.context.items[safe: index])
            }
        })
    }
    
    var body: some View {
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
                ASCollectionView (section: section)
                    .layout (self.layout)
                    .alwaysBounceVertical()
            }
        }
    }
    
    func onTap(action: Action, dataItem: Item){
        context.executeAction(action, with: dataItem)
    }
}

struct ThumbnailRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailRendererView().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
