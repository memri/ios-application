//
//  CustomNavigation.swift
//  memri
//
//  Created by Koen van der Veen on 24/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.
//

import SwiftUI

struct TopNavigation: View {
    var title: String = ""
    var action: ()->Void = {}
    var hideBack:Bool = false
    
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.gray)
                    .font(Font.system(size: 20, weight: .medium))
            }.padding(.horizontal , 5)

            Button(action: self.action) {
                Image(systemName: "chevron.left")
                .foregroundColor(.gray)

            }.padding(.horizontal , 5)

            Spacer()

            Text(title).font(.headline)

            Spacer()

            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                Image(systemName: "plus")
            }.padding(.horizontal , 5)
             .foregroundColor(.green)


            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                Image(systemName: "ellipsis")
            }.padding(.horizontal , 5)
            .foregroundColor(.gray)


        }.padding(.all, 30)
    }
}

//struct HomeView: View {
//    @EnvironmentObject var sessionViewStack: SessionViewStack
//    
//    var body: some View {
//     VStack{
//        TopNavigation(title: "Home view", action:{}, hideBack: true)
//           List{
//              Text("Move to NextView").onTapGesture {
//                    self.sessionViewStack.advance( sessionView( view: AnyView(NextView())))
//                }
//           }
//     }
//     }
//}

struct NextView: View {
    @EnvironmentObject var sessionViewStack: SessionViewStack
    
     var body: some View {
         VStack{
         TopNavigation( title: "I am Next View",  action:{
             self.sessionViewStack.back()
              })
         List{
             Text("I am NextView")
         }
     }
    }
}

struct sessionView{
    var rendererName: String = "List"
    var data: Note?
//    var view: AnyView
}

final class SessionViewStack: ObservableObject  {
    @Published var stack: [sessionView] = []
    @Published var currentSessionView: sessionView

    init(_ currentView: sessionView ){
        self.currentSessionView = currentView
    }

    func back(){
        if stack.count == 0{
            return
        }

        let last = stack.count - 1
        currentSessionView = stack[last]
        stack.remove(at: last)
    }
    
    func openView(_ view:sessionView){
        stack.append( currentSessionView)
        currentSessionView = view
    }

    func advance(_ view:sessionView){
        stack.append( currentSessionView)
        currentSessionView = view
    }
    
}

//struct Browser2: View{
//    @EnvironmentObject var sessionViewStack: SessionViewStack
//
//    var body: some View {
//        self.sessionViewStack.currentSessionView.view
//    }
//}


//struct Application: View {
//    @EnvironmentObject var sessionViewStack: SessionViewStack
//
//    var body: some View {
//        Browser2()
//    }
//}

//struct Application_Previews: PreviewProvider {
//    static var previews: some View {
//        Application()
//            .environmentObject(SessionViewStack( sessionView(view: AnyView(HomeView()))))
//    }
//}
