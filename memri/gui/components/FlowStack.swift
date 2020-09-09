//
// FlowStack.swift
// Copyright © 2020 memri. All rights reserved.

import ASCollectionView
import Foundation
import SwiftUI

public struct FlowStack<Data: RandomAccessCollection, ID, Content>: View
    where ID == Data.Element.ID, Content: View, Data.Element: Identifiable, Data.Element: Equatable,
    Data.Index == Int {
    let data: Data
    let content: (_ item: Data.Element) -> Content

    init(_ data: Data, @ViewBuilder content: @escaping (_ item: Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(self.data) { item in
                    self.content(item)
                }
            }
        }
    }
}

/*
 ASCollectionView(
 	section: ASCollectionViewSection(id: 0, data: self.data) { item, _ in
 		self.content(item)
 	}
 	.selfSizingConfig { _ in
 		ASSelfSizingConfig(canExceedCollectionWidth: false)
 	}
 )
 .layout {
 	let fl = AlignedFlowLayout()
 	fl.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
 	return fl
 }
 .shrinkToContentSize(isEnabled: true, dimension: .vertical)
 */

// ASCollectionView. Created by Apptek Studios 2019
// MIT Licensed
/*
 class AlignedFlowLayout: UICollectionViewFlowLayout {
 	override func shouldInvalidateLayout(forBoundsChange _: CGRect) -> Bool {
 		true
 	}

 	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
 		let attributes = super.layoutAttributesForElements(in: rect)

 		attributes?.forEach
 		{ layoutAttribute in
 			guard layoutAttribute.representedElementCategory == .cell else {
 				return
 			}
 			layoutAttributesForItem(at: layoutAttribute.indexPath).map { layoutAttribute.frame = $0.frame }
 		}

 		return attributes
 	}

 	private var leftEdge: CGFloat {
 		guard let insets = collectionView?.adjustedContentInset else {
 			return sectionInset.left
 		}
 		return insets.left + sectionInset.left
 	}

 	private var contentWidth: CGFloat? {
 		guard let collectionViewWidth = collectionView?.frame.size.width,
 			let insets = collectionView?.adjustedContentInset else {
 			return nil
 		}
 		return collectionViewWidth - insets.left - insets.right - sectionInset.left - sectionInset.right
 	}

 	fileprivate func isFrame(for firstItemAttributes: UICollectionViewLayoutAttributes, inSameLineAsFrameFor secondItemAttributes: UICollectionViewLayoutAttributes) -> Bool {
 		guard let lineWidth = contentWidth else {
 			return false
 		}
 		let firstItemFrame = firstItemAttributes.frame
 		let lineFrame = CGRect(
 			x: leftEdge,
 			y: firstItemFrame.origin.y,
 			width: lineWidth,
 			height: firstItemFrame.size.height
 		)
 		return lineFrame.intersects(secondItemAttributes.frame)
 	}

 	override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
 		guard let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else {
 			return nil
 		}
 		guard attributes.representedElementCategory == .cell else {
 			return attributes
 		}
 		guard
 			indexPath.item > 0,
 			let previousAttributes = layoutAttributesForItem(at: IndexPath(item: indexPath.item - 1, section: indexPath.section))
 		else {
 			attributes.frame.origin.x = leftEdge // first item of the section should always be left aligned
 			return attributes
 		}

 		if isFrame(for: attributes, inSameLineAsFrameFor: previousAttributes) {
 			attributes.frame.origin.x = previousAttributes.frame.maxX + minimumInteritemSpacing
 		} else {
 			attributes.frame.origin.x = leftEdge
 		}

 		return attributes
 	}
 }
 */
