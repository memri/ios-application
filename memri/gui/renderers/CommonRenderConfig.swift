//
//  CommonRenderConfig.swift
//  memri
//
//  Created by Toby Brennan on 27/7/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift

protocol ConfigurableRenderConfig {
    var showSortInConfig: Bool { get }
    var showContextualBarInEditMode: Bool { get }
	func configItems(context: MemriContext) -> [ConfigPanelModel.ConfigItem]
}

// MARK: Common variables needed by renderers
extension CascadingRenderConfig {
	var primaryColor: ColorDefinition {
		get { cascadeProperty("color") ?? ColorDefinition.system(.systemBlue) }
		set(value) { setState("color", value) }
	}
	
	var backgroundColor: ColorDefinition? {
		get { cascadeProperty("background") }
		set(value) { setState("background", value) }
	}
	
	var spacing: CGSize {
		get {
			if let spacing = cascadePropertyAsCGFloat("spacing") {
				return CGSize(width: spacing, height: spacing)
			}
			else if let x: [Double?] = cascadeProperty("spacing") {
				let spacingArray = x.compactMap { $0.map { CGFloat($0) } }
				guard spacingArray.count == 2 else { return .zero }
				return CGSize(width: spacingArray[0], height: spacingArray[1])
			}
			return .zero
		}
		set(value) { setState("spacing", value) }
	}
	
	var edgeInset: UIEdgeInsets {
		get {
			if let edgeInset = cascadePropertyAsCGFloat("edgeInset") {
				return UIEdgeInsets(
					top: edgeInset,
					left: edgeInset,
					bottom: edgeInset,
					right: edgeInset
				)
			}
			else if let x: [Double?] = cascadeProperty("edgeInset") {
				let insetArray = x.compactMap { $0.map { CGFloat($0) } }
				switch insetArray.count {
				case 2: return UIEdgeInsets(
					top: insetArray[1],
					left: insetArray[0],
					bottom: insetArray[1],
					right: insetArray[0]
					)
				case 4: return UIEdgeInsets(
					top: insetArray[0],
					left: insetArray[3],
					bottom: insetArray[2],
					right: insetArray[1]
					)
				default: return .init()
				}
			}
			return .init()
		}
		set(value) { setState("edgeInset", value) }
	}
	
	var nsEdgeInset: NSDirectionalEdgeInsets {
		let edgeInset = self.edgeInset
		return NSDirectionalEdgeInsets(
			top: edgeInset.top,
			leading: edgeInset.left,
			bottom: edgeInset.bottom,
			trailing: edgeInset.right
		)
	}
    
    var contextMenuActions: [Action] {
        get { cascadeList("contextMenu") }
        set(value) { setState("contextMenu", value) }
    }
}
