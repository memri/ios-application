//
//  CVU_EditorSection.swift
//  memri
//
//  Created by Toby Brennan on 30/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct CVU_EditorSection: View {
    var nodeResolver: UINodeResolver
    
    @ViewBuilder
    var header: some View {
        if let title = nodeResolver.string(for: "title") {
            Text(title)
        } else {
            EmptyView()
        }
    }
    
    var body: some View {
        Section(header: header) {
            nodeResolver.childrenInForEach
        }
    }
}

struct CVU_EditorRow: View {
    var nodeResolver: UINodeResolver
    
    @ViewBuilder
    var header: some View {
        if let title = nodeResolver.string(for: "title") {
            Text(title).bold()
        } else {
            EmptyView()
        }
    }
    
    var content: some View {
        nodeResolver.childrenInForEach
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header.padding(.vertical, 4)
            content
        }
        .if(!nodeResolver.bool(for: "nopadding", defaultValue: false)) { $0.padding(.horizontal) }
    }
}
