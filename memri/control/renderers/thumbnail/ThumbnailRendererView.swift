//
//  TumbnailRenderer.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import ASCollectionView

struct ThumbnailRendererView: View {
    @EnvironmentObject var main: Main
    
    var name: String="thumbnail"
    
    var renderConfig: ThumbnailConfig {
        if self.main.computedView.renderConfigs[name] == nil {
            print ("Warning: Using default render config for thumbnail")
        }
        
        return self.main.computedView.renderConfigs[name] as? ThumbnailConfig ?? ThumbnailConfig()
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
        VStack {
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
                ASCollectionView (section: section).layout (self.layout)
            }
        }
    }
    
    func onTap(actionDescription: ActionDescription, dataItem: DataItem){
        main.executeAction(actionDescription, dataItem)
    }
}

struct ThumbnailRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailRendererView().environmentObject(RootMain(name: "", key: "").mockBoot())
    }
}
