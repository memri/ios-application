//
//  Renderer.swift
//  memri
//
//  Created by Koen van der Veen on 19/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine


public class RenderConfig: Decodable {
    var name: String = ""
    var icon: String = ""
    var category: String = ""
    var items: [ActionDescription] = []
    var options1: [ActionDescription] = []
    var options2: [ActionDescription] = []
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.name = try decoder.decodeIfPresent("name") ?? self.name
            self.icon = try decoder.decodeIfPresent("icon") ?? self.icon
            self.category = try decoder.decodeIfPresent("category") ?? self.category
            self.items = try decoder.decodeIfPresent("items") ?? self.items
            self.options1 = try decoder.decodeIfPresent("options1") ?? self.options1
            self.options2 = try decoder.decodeIfPresent("options2") ?? self.options2
        }
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
