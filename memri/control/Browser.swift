//
//  ContentView.swift
//  memri
//
//  Created by Koen van der Veen on 11/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI
import Combine


struct Browser: View {
    @EnvironmentObject var main: Main
    @State var isEditMode: EditMode = .inactive
    
    var renderers: [String: Renderer.Type] = ["list": ListRenderer.self,
                      "thumbnail": ThumbnailRenderer.self]

//    var renderers: [String: AnyView] = ["list": AnyView(ListRenderer(isEditMode: .constant(.inactive))), // TODO Koen??
//                                        "richTextEditor": AnyView(RichTextRenderer()),
//                                        "thumbnail": AnyView(ThumbnailRenderer())]
    
//    var currentRenderer: Renderer { renderers[main.currentView.rendererName!,
//                                              default: ThumbnailRenderer(main: main)]
//    }
    
    var body: some View {
        ZStack {
            VStack() {
                TopNavigation(isEditMode: $isEditMode)
                getRenderer().getRenderer().fullHeight()
//                Search(renderers: Array(renderers.values))
            }.fullHeight()
            if self.main.currentSession.showContextPane {
                animateInContextPane()
            }
            if self.main.currentSession.showNavigation{
                Navigation()
                    .transition(.move(edge: .leading))
                    .animation(.easeOut(duration: 0.3))
            }
        }
    }
    
    func getRenderer() -> Renderer {
        type(of: self.renderers[self.main.currentView.rendererName!]!.init()).init(main: self.main)
    
    }
//        return  ThumbnailRenderer()
//        if false{
////            return RichTextRenderer()
//        }else{
//            return RichTextRenderer()
//        }
//
//        switch self.main.currentView.rendererName{
//        case "list":
//            return AnyView(ListRenderer(isEditMode: $isEditMode))
//        case "richTextEditor":
//            return AnyView(RichTextRenderer())
//        case "thumbnail":
//            return AnyView(ThumbnailRenderer())
//        default:
//            return AnyView(ThumbnailRenderer())
//        }
//    }
    
    
    init(){

    }
}
struct animateInContextPane: View {

    @EnvironmentObject var main: Main

    var body: some View {
        ContextPane()
            .transition(.move(edge: .trailing))
            .animation(.easeOut(duration: 0.3))
    }
}

struct Browser_Previews: PreviewProvider {
    static var previews: some View {
        Browser().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
