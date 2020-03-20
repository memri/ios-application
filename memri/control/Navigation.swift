//
//  Navigation.swift
//  memri
//
//  Created by Koen van der Veen on 20/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI


enum NavigationType: Int, Decodable {
    case item, heading, line
}

class NavigationItem: ObservableObject, Decodable{
        /**
         * Used as the caption in the navigation
         */
        public var title: String? = nil
        /**
         * Name of the view it opens
         */
        public var view: String? = nil
        /**
         * Defines the position in the navigation
         */
        public var count: Int = 0
        /**
         *  0 = Item
         *  1 = Heading
         *  2 = Line
         */
        public var type: NavigationType = .item
    
    public convenience required init(from decoder: Decoder) throws {
        self.init()
        
        jsonErrorHandling(decoder) {
            self.title = try decoder.decodeIfPresent("title") ?? self.title
            self.view = try decoder.decodeIfPresent("view") ?? self.view
            self.count = try decoder.decodeIfPresent("count") ?? self.count
            self.type = try decoder.decodeIfPresent("type") ?? self.type
        }
    }
}


struct Navigation: View {
    @EnvironmentObject var main: Main

    
    var navigationItems: [NavigationItem] = [NavigationItem()]
    
    var body: some View {
        VStack{
            HStack{
                Text("11.11").padding(.horizontal)
                Spacer()
            }.background(Color.purple)

        
        }
    }
}

struct Navigation_Previews: PreviewProvider {
    static var previews: some View {
        Navigation()
    }
}
