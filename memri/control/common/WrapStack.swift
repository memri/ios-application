//
//  wrappingHStack.swift
//  memri
//
//  Created by Ruben Daniels on 4/17/20.
//  Copyright © 2020 memri. All rights reserved.
//

import Foundation
import SwiftUI

public struct WrapStack<Data:RandomAccessCollection, ID, Content> : View
  where ID == Data.Element.ID, Content : View, Data.Element : Identifiable, Data.Element : Equatable {
    
    let data: Data
    let content: (_ item:Data.Element) -> Content
    
    init(_ data:Data, @ViewBuilder content: @escaping (_ item:Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
    
    public var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        // TODO I cant get Geometry reader to work without collapsing the row
//                    GeometryReader { geometry in
        return ZStack(alignment: .topLeading) {
            ForEach(self.data, id: \.id) { item in
                self.content(item)
                    .padding([.trailing, .bottom], 5)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > 360) {
                            width = 0
                            height -= d.height
                        }
                        
                        let result = width
                        if item == self.data.last! {
                            width = 0 //last item
                        }
                        else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: {d in
                        let result = height
                        if item == self.data.last! {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }
    }
}
