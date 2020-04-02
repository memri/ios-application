//
//  TextRenderer.swift
//  memri
//
//  Created by Koen van der Veen on 10/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import Combine
import SwiftUI


struct RichTextRenderer: Renderer {
    var name: String="singleItem"
    var icon: String=""
    var category: String=""
    var renderModes: [ActionDescription]=[]
    var options1: [ActionDescription]=[]
    var options2: [ActionDescription]=[]
    var editMode: Bool=false
    var renderConfig: RenderConfig=RenderConfig()

    func setState(_ state:RenderState) -> Bool {return false}
    func getState() -> RenderState {RenderState()}
    func setCurrentView(_ session:Session, _ callback:(_ error:Error, _ success:Bool) -> Void) {}
    
    @EnvironmentObject var main: Main

    var body: some View {
        return VStack{
                RichTextEditor(dataItem: main.computedView.searchResult.data[0])
        }
    }
}

struct RichTextRenderer_Previews: PreviewProvider {
    static var previews: some View {
        RichTextRenderer().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
