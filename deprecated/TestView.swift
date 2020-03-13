//
//  TestVkew.swift
//  memri
//
//  Created by Koen van der Veen on 21/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//

//import SwiftUI
//
//struct TestView: View {
//    @ObservedObject var note: Note
//    var body: some View {
//        VStack{
//            Text(self.note.text)
//            Text("test view")
//            Button(action: {
//                self.note.text="IK BEN VERANDERD"
//            }) {
//                Text("click")
//            }
//        }
//    }
//}
//
//struct TestView_Previews: PreviewProvider {
//    static var previews: some View {
//        TestView(note: DataStore().data[0])
//    }
//}

//
//  CustomNavigation.swift
//  memri
//
//  Created by Koen van der Veen on 24/02/2020.
//  Copyright © 2020 memri. All rights reserved.
//




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

//struct NextView: View {
//    @EnvironmentObject var sessionViewStack: SessionViewStack
//
//     var body: some View {
//         VStack{
//         TopNavigation( title: "I am Next View",  action:{
//             self.sessionViewStack.back()
//              })
//         List{
//             Text("I am NextView")
//         }
//     }
//    }
//}
