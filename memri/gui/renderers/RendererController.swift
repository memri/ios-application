//
//  RendererController.swift
//  memri
//
//  Created by Toby Brennan on 27/8/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public protocol RendererController {
    static var rendererType: RendererType { get }
    var rendererTypeName: String { get }
    init(context: MemriContext, config: CascadingRendererConfig?)
    func makeView() -> AnyView
    func update()
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRendererConfig
}
extension RendererController {
    var rendererTypeName: String { Self.rendererType.name }
}
