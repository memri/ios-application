//
// CVU_Stack.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct CVU_HStack: View {
    var nodeResolver: UINodeResolver

    var body: some View {
        HStack(alignment: nodeResolver.alignment().vertical, spacing: nodeResolver.spacing.x) {
            nodeResolver.childrenInForEach
        }
        .if(nodeResolver.bool(for: "fillWidth", defaultValue: false)) {
            $0.frame(maxWidth: .infinity, alignment: nodeResolver.alignment())
        }
    }
}

struct CVU_VStack: View {
    var nodeResolver: UINodeResolver

    var body: some View {
        VStack(alignment: nodeResolver.alignment().horizontal, spacing: nodeResolver.spacing.y) {
            nodeResolver.childrenInForEach
        }
        .if(nodeResolver.bool(for: "fillHeight", defaultValue: false)) {
            $0.frame(maxHeight: .infinity, alignment: nodeResolver.alignment())
        }
    }
}

struct CVU_ZStack: View {
    var nodeResolver: UINodeResolver

    var body: some View {
        ZStack(alignment: nodeResolver.alignment()) {
            nodeResolver.childrenInForEach
        }
    }
}
