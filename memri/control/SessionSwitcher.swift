//
//  SessionSwitcher.swift
//  memri
//
//  Copyright © 2020 Memri. All rights reserved.
//

import SwiftUI

struct SessionSwitcher: View {
    @EnvironmentObject var main: Main
    
    @State private var offset = CGSize.zero
    
    @State private var lastGlobalOffset:CGFloat = 0
    @State private var globalOffset:CGFloat = 0
    
    private func iterate() {
        self.globalOffset += 0.1
        if self.globalOffset > 1.1 { self.globalOffset = 0 }
    }
    
    private func getOffsetX(_ i:CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        return (geometry.size.width - getWidth(i)) / 2
    }
    
    private func getWidth(_ i:CGFloat) -> CGFloat {
        return 360
    }
  
    private func getRotation(_ i:CGFloat, _ geometry: GeometryProxy) -> Double {
//        let baseTop = (geometry.size.height - self.height) / 2
//        var position = getRelativePosition(i, geometry)
        
        
//        var x:Double
//        if i == 0 {
//            x = -40
//        }
////        else if i == 1 {
////            x = -30
////        }
//        else if i == 1 {
//            x = 0
//        }
//        else if i == 2 {
//            x = 5
//        }
//        else if i == 3 {
//            x = 10
//        }
//        else if i == 4 {
//            x = 12
//        }
//        else {
//            x = 14
//        }

//        let baseTop = (geometry.size.height - self.height) / 2
        let position = Double(getRelativePosition(i, geometry))
        var rotation:Double = -40.0
//        distance = CGFloat(position * self.height )
//        print(i)
//        print(position)
//        print(position)
//        print(self.height)
//        print(distance)
        
        let beforeRotation = (40 / 0.23)
        let afterRotation = (14 / (1 - 0.266))
        
        if position > 0.0 {
            let d_in_seg = min(0.2, position)
            rotation += d_in_seg * beforeRotation
        }
        
        if position > 0.17 {
            let d_in_seg = min(0.20, position) - 0.17
            rotation += d_in_seg * beforeRotation
        }
        // 0.05 * 4 height = 0.2
        if position > 0.20 {
            let d_in_seg = min(0.23, position) - 0.20
            rotation += d_in_seg * beforeRotation
        }
        // the cumulatiev distance here shouldnt be more than 0.2 * height
        
        
        if position > 0.23 {
//            let d_in_seg = min(0.266, position) - 0.23
            rotation = 0
        }
        
        if position > 0.266 {
            let d_in_seg = min(0.5, position) - 0.266
            rotation += d_in_seg * afterRotation
        }
        
        if position > 0.5 {
            let d_in_seg = min(1.0, position) - 0.5
            rotation += d_in_seg * afterRotation
        }
//        if i == 0 {
//            rotation = min(rotation, 0.2 *  Double(height))
//        }
        
//        if i == 0 {
//            print(rotation)
//            print()
//        }
        
//        if i == 0.0{
//            distance = 0.0
//        }
        


        return 12 //Double(rotation)
    }
    
    let height:CGFloat = 605
    
    @State private var currentImage:CGFloat = 1
    @State private var lastpos:CGFloat = 0
    
    
    private func getRelativePosition(_ i:CGFloat, _ geometry: GeometryProxy) -> CGFloat {
//        let baseTop = (geometry.size.height - self.height) / 2
        
        let count = self.main.sessions.sessions.count
        
        let normalizedPosition = i / CGFloat(count)
        let maxGlobalOffset = CGFloat(count) * self.height
        let normalizedGlobalState = min(1, max(0, self.globalOffset / maxGlobalOffset))
        let translatedRelativePosition = normalizedGlobalState + (normalizedPosition / 2)
        return translatedRelativePosition / 2.0
    }
    
    private func getOffsetY(_ i:CGFloat, _ geometry: GeometryProxy) -> CGFloat {
//        let baseTop = (geometry.size.height - self.height) / 2
        let position = getRelativePosition(i, geometry)
        var distance:CGFloat = 0.0
//        distance = CGFloat(position * self.height )
//        print(i)
//        print(position)
//        print(position)
//        print(self.height)
//        print(distance)
        
        
        if position > 0.0 {
            let d_in_seg = min(0.2, position)
            distance += d_in_seg * self.height * 0.1
        }
        
        if position > 0.17 {
            let d_in_seg = min(0.20, position) - 0.17
            distance += d_in_seg * self.height * 2
        }
        // 0.05 * 4 height = 0.2
        if position > 0.20 {
            let d_in_seg = min(0.23, position) - 0.20
            distance += d_in_seg * self.height * 4
        }
        // the cumulatiev distance here shouldnt be more than 0.2 * height
        
        
        if position > 0.23 {
            let d_in_seg = min(0.266, position) - 0.23
            distance += d_in_seg * self.height * 32
        }
        
        if position > 0.266 {
            let d_in_seg = min(0.5, position) - 0.266
            distance += d_in_seg * self.height
        }
        
        if position > 0.5 {
            let d_in_seg = min(1.0, position) - 0.5
            distance += d_in_seg * self.height * 0.05
        }
        if i == 0 {
            distance = min(distance, 0.2 *  height)
        }
//
//        print(distance)
//        print()
        
//        if i == 0.0{
//            distance = 0.0
//        }
        


        return distance
    }
    
//    private func getRotation(_ i:CGFloat) -> Double {
//        var x:Double
//        if i == 0 {
//            x = -40
//        }
//        else if i == 1 {
//            x = -30
//        }
//        else if i == 2 {
//            x = 0
//        }
//        else if i == 3 {
//            x = 5
//        }
//        else if i == 4 {
//            x = 10
//        }
//        else if i == 5 {
//            x = 12
//        }
//        else {
//            x = 14
//        }
//
//        return x
//    }
//
//    let height:CGFloat = 605
//    private func getOffsetY(_ i:CGFloat, _ geometry: GeometryProxy) -> CGFloat {
//        let baseTop = (geometry.size.height - self.height) / 2
//
////        let posWhileScrolling = self.globalOffset % 200
//        var currentImage:CGFloat = 2
//
//        var distance:CGFloat
//
//        if i == currentImage - 2 {
//            distance = baseTop + self.height + 700
//        }
//        else if i == currentImage - 1 {
//            distance = baseTop + self.height + 400
//        }
//        else if i == currentImage {
//            distance = baseTop + 25
//        }
//        else if i == currentImage + 1 {
//            distance = 90
//        }
//        else if i == currentImage + 2 {
//            distance = 40
//        }
//        else if i == currentImage + 3 {
//            distance = 18
//        }
//        else {
//            distance = -5 * (i - 6)
//        }
//
//        return CGFloat(baseTop + distance) - 170
//    }
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 0) {
                Action(action: ActionDescription(actionName: .showSessionSwitcher))
                    .fixedSize()
                    .font(Font.system(size: 20, weight: .medium))
                    .rotationEffect(.degrees(90))
                    .padding(.vertical, 200)
                    .background(Color.white)
                    .border(Color.purple, width: 5)
                    .frame(width: nil, height: 20, alignment: .trailing)
                    .zIndex(1000)
            }
            ZStack {
                GeometryReader { (geometry) in
                    Image("session-switcher-tile")
                        .resizable(resizingMode: .tile)
                        .edgesIgnoringSafeArea(.vertical)
                    
                    ForEach(0..<self.main.sessions.sessions.count, id: \.self) { i in
                        { () -> Image in
                            let session = self.main.sessions.sessions[i]
                            if let screenShot = session.screenShot,
                               let uiImage = screenShot.asUIImage {
                                return Image(uiImage: uiImage)
                            }
                            return Image("screenshot-example")
                        }()
                            .resizable()
                            .scaledToFit()
                            .frame(width: self.getWidth(CGFloat(i)), height: nil, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 32))
                            .offset(x: self.getOffsetX(CGFloat(i), geometry),
                                    y: self.getOffsetY(CGFloat(i), geometry))
                            .shadow(color: .init(hex: "#222"), radius: 15, x: 10, y: 10)
                            .rotation3DEffect(.degrees(self.getRotation(0, geometry)), axis: (x: 1, y: 0, z: 0), anchor: .top, anchorZ: 400, perspective: 0.4)
                            .zIndex(Double(0))
                    }
                    
                    Text("\(self.main.sessions.sessions.count)").zIndex(20.0).padding(20).foregroundColor(.white)
                    Text("\(self.globalOffset)").zIndex(40.0).padding(40).foregroundColor(.white)
                    Text("\(self.lastGlobalOffset)").zIndex(60.0).padding(60).foregroundColor(.white)
                }
            }
            .edgesIgnoringSafeArea(.vertical)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        self.offset = gesture.translation
                        self.globalOffset = max(0, self.lastGlobalOffset + self.offset.height)
                    }

                    .onEnded { _ in
                        self.globalOffset = max(0, self.lastGlobalOffset + self.offset.height)
                        self.lastGlobalOffset = self.globalOffset
                    }
            )
        }
    }
}

struct SessionSwitcher_Previews: PreviewProvider {
    static var previews: some View {
        SessionSwitcher().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
