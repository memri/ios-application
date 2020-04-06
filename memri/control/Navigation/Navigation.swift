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

    var navigationItems: [NavigationItem] = try! NavigationItem.fromJSON("navigationItems")
    
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
                    ForEach(navigationItems){ navigationItem in
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
