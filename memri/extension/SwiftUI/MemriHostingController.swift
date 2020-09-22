//
//  MemriHostingController.swift
//  memri
//
//  Created by Toby Brennan on 21/9/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

class MemriHostingController: UIHostingController<AnyView> {
    let extraEnvironment = ExtraEnvironment()
    init<Content: View>(rootView: Content) {
        super.init(rootView: rootView.environmentObject(extraEnvironment).eraseToAnyView())
        updateExtraEnvironment()
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateExtraEnvironment()
    }
    
    func updateExtraEnvironment() {
        extraEnvironment.screenSize = view.window?.frame.size ?? .zero
    }
}

class ExtraEnvironment: ObservableObject {
    @Published
    var screenSize: CGSize = .zero
}
