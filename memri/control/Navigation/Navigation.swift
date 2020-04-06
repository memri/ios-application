//
//  Navigation.swift
//  memri
//
//  Created by Koen van der Veen on 20/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI

struct Navigation: View {
    @EnvironmentObject var main: Main
    @State var dragOffset = CGSize.zero
    
    private let foreGroundPercentageWidth: CGFloat = 0.9
    
    var offsetLeft: CGFloat {
        return -(1.0 - foreGroundPercentageWidth) * (UIScreen.main.bounds.width)
    }
    
    var body: some View {

        VStack{
            VStack{
                EmptyView()
            }
            VStack{
                ScrollView(.vertical) {
                    ForEach(self.main.navigation.items){ navigationItem in
                        self.item(navigationItem: navigationItem)
                    }
                }
            }
            .offset(x: -offsetLeft, y: 15)
        }
        .frame(width: UIScreen.main.bounds.width * 0.9,
               height: UIScreen.main.bounds.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.22, green: 0.15, blue: 0.35))
        .offset(x:  offsetLeft  + min(self.dragOffset.width, 0) )

        .gesture(DragGesture()
            .onChanged({ value in
               self.dragOffset = value.translation
            })
            .onEnded{ value in
                try! self.main.realm.write {
                    self.main.sessions.showNavigation.toggle()
                }
                self.main.scheduleUIUpdate()
            })
        .edgesIgnoringSafeArea(.vertical)
    }

    
    func item(navigationItem: NavigationItem) -> AnyView{
        switch navigationItem.type{
        case "item":
            return AnyView(NavigationItemView(item: navigationItem))
        case "heading":
            return AnyView(NavigationHeadingView(title: navigationItem.title))
        case "line":
            return AnyView(NavigationLineView())
        default:
            return AnyView(NavigationItemView(item: navigationItem))
        }
    }
}

struct NavigationItemView: View{
    @EnvironmentObject var main: Main
    
    var item: NavigationItem
    
    var body: some View {
        HStack{
            Text(item.title.firstUppercased)
                .font(.body)
                .padding(.vertical, 15)
                .padding(.horizontal, 50)
                .foregroundColor(Color(red: 0.85,
                                       green: 0.85,
                                       blue: 0.85))
            Spacer()
        }
        .onTapGesture {
            self.main.openView(self.item.view!)
        }
    }
}

struct NavigationHeadingView: View{
    var title: String?

    var body: some View {
        HStack{
            Text(title != nil ? title!.uppercased() : "")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal, 25)
                .padding(.vertical, 8)
                .foregroundColor(Color(red: 0.55, green: 0.5, blue: 0.7))
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
