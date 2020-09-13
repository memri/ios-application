//
//  CVU_Text.swift
//  memri
//
//  Created by Toby Brennan on 13/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct CVU_Text: View {
    var nodeResolver: UINodeResolver
    
    var content: String? {
        nodeResolver.string(for: "text")?.nilIfBlank
    }
    
    @ViewBuilder
    var body: some View {
        content.map {
            Text($0)
        }
    }
}

struct CVU_SmartText: View {
    var nodeResolver: UINodeResolver
    
    var content: String? {
        nodeResolver.string(for: "text")?.nilIfBlank
    }
    
    @ViewBuilder
    var body: some View {
        content.map { MemriSmartTextView(string: $0, font: nodeResolver.font(), color: nodeResolver.color()) }
    }
}
