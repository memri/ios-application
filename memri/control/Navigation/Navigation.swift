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
    var navigationItems: [NavigationItem] = try! NavigationItem.fromJSON("navigationItems")
    
    var body: some View {

        VStack{
            VStack{
                EmptyView()
            }.padding(.vertical, 20)
            VStack{
                ScrollView(.vertical) {
                    ForEach(navigationItems){ navigationItem in
                        self.item(navigationItem: navigationItem)
                    }
                }.padding(.vertical, 20)
            }.background(
                Color(red: 0.25, green: 0.11, blue: 0.4)
            )
        }.background(Color(red: 0.22, green: 0.15, blue: 0.35))
         .edgesIgnoringSafeArea(.vertical)
    }
    
    func item(navigationItem: NavigationItem) -> AnyView{
        switch navigationItem.type{
        case .item:
            return AnyView(NavigationItemView(title: navigationItem.title))
        case .heading:
            return AnyView(NavigationHeadingView(title: navigationItem.title))
        case .line:
            return AnyView(NavigationLineView())
        }
    }
}

struct Navigation_Previews: PreviewProvider {
    static var previews: some View {
        Navigation().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
