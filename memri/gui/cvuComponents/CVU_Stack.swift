//
//  CVU_HStack.swift
//  memri
//
//  Created by Toby Brennan on 13/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct CVU_HStack: View {
    var nodeResolver: UINodeResolver
    
    var body: some View {
        HStack(alignment: nodeResolver.alignment().vertical, spacing: nodeResolver.spacing.x) {
            nodeResolver.childrenInForEach
        }
    }
}

struct CVU_VStack: View {
    var nodeResolver: UINodeResolver
    
    var body: some View {
        VStack(alignment: nodeResolver.alignment().horizontal, spacing: nodeResolver.spacing.y) {
            nodeResolver.childrenInForEach
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

