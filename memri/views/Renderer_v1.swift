//
//  Renderer_v1.swift
//  memri
//
//  Created by Koen van der Veen on 24/02/2020.
//  Copyright © 2020 Koen van der Veen. All rights reserved.

//
//import SwiftUI
//
//struct SortButton: Identifiable {
//    var id = UUID()
//    var name: String
//    var selected: Bool
//    var color: Color {self.selected ? Color.green : Color.black}
//    var fontWeight: Font.Weight? {self.selected ? .bold : .none}
//}
//
//struct BrowseSetting: Identifiable {
//    var id = UUID()
//    var name: String
//    var selected: Bool
//    var color: Color {self.selected ? Color.green : Color.black}
//    var fontWeight: Font.Weight? {self.selected ? .bold : .none}
//}
//
//struct ViewTypeButton: Identifiable {
//    var id = UUID()
//    var imgName: String
//    var selected: Bool
//    var backGroundColor: Color { self.selected ? Color(white: 0.95) : Color(white: 1.0)}
//    var foreGroundColor: Color { self.selected ? Color.green : Color.gray}
//}
//
//
//
//struct Renderer: View {
//    
//    @State var currentNote: Note? = nil
//    @ObservedObject var dataStore: DataStore
//    
//    
////    @ViewBuilder
//    var body: some View {
//            NavigationView {
//                List{
//                    ForEach(dataStore.data) { note in
//                        NavigationLink(destination: TextView(note: note)
//                            .onReceive(note.objectWillChange){ _ in self.dataStore.objectWillChange.send()
//                            }
//                        )
//                        {
//                            VStack{
//                                Text(note.title)
//                                    .bold()
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                Text(note.text)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            }.navigationBarTitle("back")
////                             .navigationBarHidden(true)
//                        }
//                    }
//                }
//        }
//    }
//}
//
//struct Renderer_Previews: PreviewProvider {
//    static var previews: some View {
//        return Renderer(dataStore: DataStore())
//    }
//}
