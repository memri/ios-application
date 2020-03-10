//
//  Renderer.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI
import Combine


public class RenderConfig: Codable {
    var name: String
    var icon: String
    var category: String
    var items: [ActionDescription]
    var options1: [ActionDescription]
    var options2: [ActionDescription]
    
    init(name: String, icon: String, category: String, items: [ActionDescription], options1: [ActionDescription],
         options2: [ActionDescription]){
        self.name=name
        self.icon=icon
        self.category=category
        self.items=items
        self.options1=options1
        self.options2=options2
    }
}

public class RenderState{}


public protocol Renderer: View {
    var name: String {get set}
    var icon: String {get set}
    var category: String {get set}
    
    var renderModes: [ActionDescription]  {get set}
    var options1: [ActionDescription] {get set}
    var options2: [ActionDescription] {get set}
    var editMode: Bool {get set}
    var renderConfig: RenderConfig {get set}

    func setState(_ state:RenderState) -> Bool
    func getState() -> RenderState
    func setCurrentView(_ session:Session, _ callback:(_ error:Error, _ success:Bool) -> Void)
}

