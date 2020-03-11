//
//  ContentPane.swift
//  memri
//
//  Created by Jess Taylor on 3/10/20.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct ContextPane: View {
    
    let text = NSLocalizedString("application_name", comment: "")

    var body: some View {
        VStack {
            Text("This is the context pane for \(text)")
        }
    }
}

struct ContentPane_Previews: PreviewProvider {
    static var previews: some View {
        ContextPane()
    }
}
