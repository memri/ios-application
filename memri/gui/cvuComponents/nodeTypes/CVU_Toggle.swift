//
//  CVU_Text.swift
//  memri
//
//  Created by Toby Brennan on 13/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct CVU_Toggle: View {
    var nodeResolver: UINodeResolver
    
    var binding: Binding<Bool> {
        nodeResolver.binding(for: "value", defaultValue: false)
    }
    
    var body: some View {
        Toggle(isOn: binding) { EmptyView() }
            .labelsHidden()
    }
}
