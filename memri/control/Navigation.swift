//
//  Navigation.swift
//  memri
//
//  Created by Koen van der Veen on 20/03/2020.
//  Copyright © 2020 memri. All rights reserved.
//

import SwiftUI


class NavigationItem: ObservableObject{
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

        public var type: Int = 0
}


struct Navigation: View {
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
