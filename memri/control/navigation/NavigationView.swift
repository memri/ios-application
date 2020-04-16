//
//  Navigation.swift
//  memri
//
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct Navigation: View {
    @EnvironmentObject var main: Main
    
    @State var dragOffset = CGSize.zero
    @State var showSettings: Bool = false
    
    private let foreGroundPercentageWidth: CGFloat = 0.9
    
    var offsetLeft: CGFloat {
        return -(1.0 - foreGroundPercentageWidth) * (UIScreen.main.bounds.width)
    }
    
    public func hide(){
        try! self.main.realm.write {
            self.main.showNavigation = false
        }
    }
    
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
            .padding(.leading, -offsetLeft + 20)
            .padding(.trailing, 20)
            .frame(minHeight: 95)
            .background(Color(hex:"#492f6c"))
            
            ScrollView(.vertical) {
                VStack (spacing:0) {
                    ForEach(self.main.navigation.getItems(), id: \.self){
                        self.item($0)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.leading, -offsetLeft)
        }
        .edgesIgnoringSafeArea(.vertical)
        .frame(width: UIScreen.main.bounds.width * 0.95,
               height: UIScreen.main.bounds.height)
        .background(Color(hex: "543184"))
        .padding(.leading, offsetLeft + min(self.dragOffset.width, 0) )

        .gesture(DragGesture()
            .onChanged{ value in
               self.dragOffset = value.translation
            }
            .onEnded{ value in
                self.hide()
            })
    }

    func item(_ navigationItem: NavigationItem) -> AnyView{
        switch navigationItem.type{
        case "item":
            return AnyView(NavigationItemView(item: navigationItem, hide: hide))
        case "heading":
            return AnyView(NavigationHeadingView(title: navigationItem.title))
        case "line":
            return AnyView(NavigationLineView())
        default:
            return AnyView(NavigationItemView(item: navigationItem, hide: hide))
        }
    }
}

struct NavigationItemView: View{
    @EnvironmentObject var main: Main
    
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
                self.main.openSession(viewName)
                
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
        Navigation().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
