//
//  SessionSwitcher.swift
//  memri
//
//  Copyright © 2020 Memri. All rights reserved.
//

import SwiftUI

struct SessionSwitcher: View {
    @EnvironmentObject var main: Main
    let items: [CGFloat] = [0,1,2,3,4,5,6,7,8,9]

    
    @State private var offset = CGSize.zero
    
    @State private var lastGlobalOffset:CGFloat = 0
    @State private var globalOffset:CGFloat = 0
    
    let height:CGFloat = 738
    
    @State private var currentImage:CGFloat = 1
    @State private var lastpos:CGFloat = 0
    
    let bounds: [CGFloat] = [0.0, 0.17, 0.2, 0.23, 0.245, 0.266, 0.5, 1.0]
    
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
    
//    let heightInPoints = image.size.height
//    let heightInPixels = heightInPoints * image.scale
//
//    let widthInPoints = image.size.width
//    let widthInPixels = widthInPoints * image.scale
    
    private func getAnchorZ(_ i:CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        let speeds: [CGFloat] = [0,-2000,-4000,0,1000,0,0] //[0, -1000, -2000, 1000, 0, 0, 0]
        
        let position = getRelativePosition(i, geometry)
        var anchorZ: CGFloat = 300
        for i in 0..<(bounds.count - 1){
            let lower = bounds[i]
            if position > lower{
                let upper = bounds[i+1]
                let d_in_seg = min(upper, position) - lower
                anchorZ += d_in_seg  * speeds[i]
            }
        }
        return anchorZ
    }
    
    private func getPerspective(_ i:CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        let speeds: [CGFloat] = [-2,0,0,0,0,0,0] //[-2, -20, 20, 0, 0, 0, 0]
        
        let position = getRelativePosition(i, geometry)
        var perspective: CGFloat = 1
        for i in 0..<(bounds.count - 1){
            let lower = bounds[i]
            if position > lower{
                let upper = bounds[i+1]
                let d_in_seg = min(upper, position) - lower
                perspective += d_in_seg  * speeds[i]
            }
        }
        return perspective
    }
        
    private func getOffsetY(_ i:CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        let speeds: [CGFloat] = [0.5,3,6,10,30,10,0] //[0.5, 10, 40, 100, 40, 0, 0]
        
        let position = getRelativePosition(i, geometry)
        var distance:CGFloat = 0.0
        for i in 0..<(bounds.count - 1){
            let lower = bounds[i]
            if position > lower{
                let upper = bounds[i+1]
                let d_in_seg = min(upper, position) - lower
                distance += d_in_seg * self.height * speeds[i]
            }
        }
        return distance - 120
    }
  
    private func getRotation(_ i:CGFloat, _ geometry: GeometryProxy) -> Double {
//        let speeds: [Double] = [0,100,-100,-100,0,0,0] //[0.0, 500, -1000, -500, 0, 500, 0]
        let speeds: [Double] = [0,100,-100,0,-200,0,0] //[0.0, 500, -1000, -500, 0, 500, 0]
//        let speeds: [Double] = [0,0,-200,200,200,0,0] //[0.0, 500, -1000, -500, 0, 500, 0]

        let position = getRelativePosition(i, geometry)
        var rotation: Double = 0.0
        for i in 0..<(bounds.count - 1){
            let lower = bounds[i]
            if position > lower{
                let upper = bounds[i+1]
                let d_in_seg = min(upper, position) - lower
                rotation += Double(d_in_seg)  * speeds[i]
            }
        }
        return rotation
    }
    
    private func getRelativePosition(_ i:CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        let normalizedPosition = i / CGFloat(self.main.sessions.sessions.count)
        let maxGlobalOffset = CGFloat(self.main.sessions.sessions.count) * self.height
        let normalizedGlobalState = min(1, max(0, self.globalOffset / maxGlobalOffset))
        let translatedRelativePosition = normalizedGlobalState + (normalizedPosition / 2)
        return translatedRelativePosition / 2.0
    }
    
    private func hide(){
        self.main.showSessionSwitcher = false
    }
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            HStack(alignment: .top, spacing: 0) {
                Action(action: ActionDescription(actionName: .showSessionSwitcher))
                    .fixedSize()
                    .font(Font.system(size: 20, weight: .medium))
                    .rotationEffect(.degrees(90))
                    .padding(.vertical, 7)
                    .padding(.horizontal, 4)
                    .background(Color(hex: "#ddd"))
                    .cornerRadius(25)
                    .zIndex(1000)
                    .offset(x: -11, y: 68)
            }
            .zIndex(100)
            
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
                        .clipShape(RoundedRectangle(cornerRadius: 24)
                            .size(width: 360, height: self.height)
                            .offset(x: 0, y: 35)
                        )
                        .offset(x: self.getOffsetX(CGFloat(i as! Int), geometry),
                                y: self.getOffsetY(CGFloat(i as! Int), geometry))
                        .shadow(color: .init(.sRGB, red: 0.13, green: 0.13, blue: 0.13, opacity: 0.5), radius: 15, x: 10, y: 10)
                        .rotation3DEffect(.degrees(self.getRotation(CGFloat(i), geometry)), axis: (x: 1, y: 0, z: 0), anchor: .center, anchorZ: self.getAnchorZ(CGFloat(i), geometry), perspective: self.getPerspective(CGFloat(i), geometry))
                        .zIndex(Double(0))
//                            .opacity(0.7)
                        .onTapGesture {
                            let session = self.main.sessions.sessions[i]
                            self.main.openSession(session)
                            self.hide()
                        }
                }
            }
        }
        .edgesIgnoringSafeArea(.vertical)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    self.offset = gesture.translation
                    let maxGlobalOffset:CGFloat = CGFloat(self.main.sessions.sessions.count) * self.height / 2
                    self.globalOffset = min(maxGlobalOffset, max(0, self.lastGlobalOffset + self.offset.height))
                }

                .onEnded { _ in
                    print(CGFloat(self.items.count) * self.height)
                    let maxGlobalOffset:CGFloat = CGFloat(self.main.sessions.sessions.count) * self.height / 2
                    self.globalOffset = min(maxGlobalOffset, max(0, self.lastGlobalOffset + self.offset.height))
                    self.lastGlobalOffset = self.globalOffset
                }
        )
    }
}

struct SessionSwitcher_Previews: PreviewProvider {
    static var previews: some View {
        SessionSwitcher().environmentObject(Main(name: "", key: "").mockBoot())
    }
}
