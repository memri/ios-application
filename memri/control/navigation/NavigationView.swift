//
//  Navigation.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct Navigation: View {
    @EnvironmentObject var main: MemriContext
    
    @ObservedObject var keyboardResponder = KeyboardResponder()
    
    @State var showSettings: Bool = false
        
    var body: some View {
        VStack{
            HStack (spacing: 20) {
                Button(action: {
                    self.showSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(Font.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(hex:"#d9d2e9"))
                }.sheet(isPresented: self.$showSettings) {
                    SettingsPane().environmentObject(self.main)
                }
                
                TextField("Jump to...", text: $main.navigation.filterText)
                    .padding(5)
                    .padding(.horizontal, 5)
                    .foregroundColor(Color(hex:"#8a66bc"))
                    .background(Color(hex:"#341e51"))
                    .cornerRadius(5)
                
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .font(Font.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(hex:"#d9d2e9"))
                }
                
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(Font.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(hex:"#d9d2e9"))
                }
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
            .frame(minHeight: 95)
            .background(Color(hex:"#492f6c"))
            
            TableView<NavigationItem, AnyView>(main: self.main)
            .padding(.top, 10)

//            ScrollView(.vertical) {
//                VStack (spacing:0) {
//                    ForEach(self.main.navigation.getItems(), id: \.self){
//                        self.item($0)
//                    }
//                }
//            }
//            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "543184"))
        .padding(.bottom, keyboardResponder.currentHeight)
    }

//
// TODO -   This functionality (below) has been temporaily moved to TableView and it should remain here
//          so this is a refactoring task

//
//    public func hide(){
//        withAnimation {
//            self.main.showNavigation = false
//        }
//    }

//    func item(_ navigationItem: NavigationItem) -> AnyView{
//        switch navigationItem.type{
//        case "item":
//            return AnyView(NavigationItemView(item: navigationItem, hide: hide))
//        case "heading":
//            return AnyView(NavigationHeadingView(title: navigationItem.title))
//        case "line":
//            return AnyView(NavigationLineView())
//        default:
//            return AnyView(NavigationItemView(item: navigationItem, hide: hide))
//        }
//    }
    
}

struct NavigationItemView: View{
    @EnvironmentObject var main: MemriContext
    
    var item: NavigationItem
    
    var hide: () -> Void
    
    var body: some View {
        HStack{
            Text(item.title.firstUppercased)
                .font(.system(size: 18, weight: .regular))
                .padding(.vertical, 10)
                .padding(.horizontal, 35)
                .foregroundColor(Color(hex: "#d9d2e9"))
            Spacer()
        }
        .onTapGesture {
            if let viewName = self.item.view {
                // TODO 
                do { try ActionOpenSessionByName.exec(self.main, ["name": viewName]) }
                catch{}
                
                self.hide()
            }
        }
    }
}

struct NavigationHeadingView: View{
    var title: String?

    var body: some View {
        HStack{
            Text((title ?? "").uppercased())
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .foregroundColor(Color(hex:"#8c73af"))
            Spacer()
        }
    }
}

struct NavigationLineView: View{
    var body: some View {
        VStack {
            Divider().background(Color(.black))
        }.padding(.horizontal,50)
    }
}

struct Navigation_Previews: PreviewProvider {
    static var previews: some View {
        Navigation().environmentObject(RootContext(name: "", key: "").mockBoot())
    }
}
