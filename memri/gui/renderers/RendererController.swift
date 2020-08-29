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
    static var rendererTypeName: String { get }
    var rendererTypeName: String { get }
    init(context: MemriContext, config: CascadingRenderConfig?)
    func makeView() -> AnyView
    static func makeConfig(head: CVUParsedDefinition?, tail: [CVUParsedDefinition]?, host: Cascadable?) -> CascadingRenderConfig
}
extension RendererController {
    var rendererTypeName: String { Self.rendererTypeName }
}
