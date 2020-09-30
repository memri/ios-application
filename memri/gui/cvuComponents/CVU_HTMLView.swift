//
//  CVU_HTMLView.swift
//  memri
//
//  Created by Toby Brennan on 30/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct CVU_HTMLView: View {
    var nodeResolver: UINodeResolver
    
    var body: some View {
        EmailView(emailHTML: nodeResolver.string(for: "content"))
    }
}
