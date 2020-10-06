//
//  CVU_MemriButton.swift
//  memri
//
//  Created by Toby Brennan on 30/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct CVU_MemriButton: View {
    var nodeResolver: UINodeResolver
    
    var body: some View {
        MemriButton(
            item: nodeResolver.resolve("item"),
            edge: nodeResolver.resolve("edge")
        )
    }
}
