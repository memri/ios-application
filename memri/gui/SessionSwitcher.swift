//
// SessionSwitcher.swift
// Copyright © 2020 memri. All rights reserved.

import SwiftUI

struct SessionSwitcher: View {
    @EnvironmentObject var context: MemriContext
    let items: [CGFloat] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

    @State private var _globalOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    
    var count: Int {
        min(10, self.context.sessions.count)
    }
    
    var countIndexOffset: Int {
        self.context.sessions.count - count
    }
    
    private var globalOffset: CGFloat {
        min(
            CGFloat(count) * self
                .height / 2,
            max(0, _globalOffset + dragOffset))
    }

    let height: CGFloat = 738

    @State private var currentImage: CGFloat = 1
    @State private var lastpos: CGFloat = 0

    let bounds: [CGFloat] = [0.0, 0.17, 0.2, 0.23, 0.245, 0.266, 0.5, 1.0]

    private func getOffsetX(_ i: CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        (geometry.size.width - getWidth(i)) / 2
    }

    private func getWidth(_: CGFloat) -> CGFloat {
        360
    }
    
    private func getAnchorZ(_ i: CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        let speeds: [CGFloat] = [0, -2000, -4000, 0, 1000, 0, 0] // [0, -1000, -2000, 1000, 0, 0, 0]

        let position = getRelativePosition(i, geometry)
        var anchorZ: CGFloat = 300
        for i in 0 ..< (bounds.count - 1) {
            let lower = bounds[i]
            if position > lower {
                let upper = bounds[i + 1]
                let d_in_seg = min(upper, position) - lower
                anchorZ += d_in_seg * speeds[i]
            }
        }
        return anchorZ
    }

    private func getPerspective(_ i: CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        let speeds: [CGFloat] = [-2, 0, 0, 0, 0, 0, 0] // [-2, -20, 20, 0, 0, 0, 0]

        let position = getRelativePosition(i, geometry)
        var perspective: CGFloat = 1
        for i in 0 ..< (bounds.count - 1) {
            let lower = bounds[i]
            if position > lower {
                let upper = bounds[i + 1]
                let d_in_seg = min(upper, position) - lower
                perspective += d_in_seg * speeds[i]
            }
        }
        return perspective
    }

    private func getOffsetY(_ i: CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        let speeds: [CGFloat] = [0.5, 3, 6, 10, 30, 10, 0] // [0.5, 10, 40, 100, 40, 0, 0]

        let position = getRelativePosition(i, geometry)
        var distance: CGFloat = 0.0
        for i in 0 ..< (bounds.count - 1) {
            let lower = bounds[i]
            if position > lower {
                let upper = bounds[i + 1]
                let d_in_seg = min(upper, position) - lower
                distance += d_in_seg * height * speeds[i]
            }
        }
        return distance - 120
    }

    private func getRotation(_ i: CGFloat, _ geometry: GeometryProxy) -> Double {
        //        let speeds: [Double] = [0,100,-100,-100,0,0,0] //[0.0, 500, -1000, -500, 0, 500, 0]
        let speeds: [Double] = [0, 100, -100, 0, -200, 0, 0] // [0.0, 500, -1000, -500, 0, 500, 0]
        //        let speeds: [Double] = [0,0,-200,200,200,0,0] //[0.0, 500, -1000, -500, 0, 500, 0]

        let position = getRelativePosition(i, geometry)
        var rotation: Double = 0.0
        for i in 0 ..< (bounds.count - 1) {
            let lower = bounds[i]
            if position > lower {
                let upper = bounds[i + 1]
                let d_in_seg = min(upper, position) - lower
                rotation += Double(d_in_seg) * speeds[i]
            }
        }
        return rotation
    }

    private func getRelativePosition(_ i: CGFloat, _: GeometryProxy) -> CGFloat {
        let normalizedPosition = i / CGFloat(count)
        let maxGlobalOffset = CGFloat(count) * height
        let normalizedGlobalState = min(1, max(0, globalOffset / maxGlobalOffset))
        let translatedRelativePosition = normalizedGlobalState + (normalizedPosition / 2)
        return translatedRelativePosition / 2.0
    }

    private func hide() {
        context.showSessionSwitcher = false
    }

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            HStack(alignment: .top, spacing: 10) {
                ActionButton(action: ActionShowSessionSwitcher(context))
                    .fixedSize()
                    .font(Font.system(size: 20, weight: .medium))
                    .rotationEffect(.degrees(90))
                    .padding(.vertical, 7)
                    .padding(.horizontal, 4)
                    .background(Color(hex: "#ddd"))
                    .cornerRadius(25)
                    .zIndex(1000)
                    .offset(x: 4, y: -7)
            }
            .padding(.top, 15)
            .padding(.bottom, 10)
            .padding(.leading, 15)
            .padding(.trailing, 15)
            .frame(height: 50, alignment: .top)
            .zIndex(100)

            GeometryReader { geometry in
                Image("session-switcher-tile")
                    .resizable(resizingMode: .tile)
                    .edgesIgnoringSafeArea(.vertical)
                
                ForEach(0 ..< self.count, id: \.self) { i in
                    { () -> AnyView in
                        if let session = self.context.sessions[i + self.countIndexOffset],
                            let screenShot = session.screenshot,
                            let uiImage = FileStorageController.getImage(fromFileForUUID: screenShot.getFilename()) {
                            return Image(uiImage: uiImage).resizable().eraseToAnyView()
                        } else {
                            return Color(.secondarySystemBackground).eraseToAnyView()
                        }
                    }()
                        .scaledToFit()
                        .frame(width: self.getWidth(CGFloat(i)), height: nil, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 24)
                            .size(width: 360, height: self.height)
                            .offset(x: 0, y: 35))
                        .offset(x: self.getOffsetX(CGFloat(i as Int), geometry),
                                y: self.getOffsetY(CGFloat(i as Int), geometry))
                        .shadow(
                            color: .init(.sRGB, red: 0.13, green: 0.13, blue: 0.13, opacity: 0.5),
                            radius: 15,
                            x: 10,
                            y: 10
                    )
                        .rotation3DEffect(.degrees(self.getRotation(CGFloat(i), geometry)),
                                          axis: (x: 1, y: 0, z: 0),
                                          anchor: .center,
                                          anchorZ: self.getAnchorZ(CGFloat(i), geometry),
                                          perspective: self.getPerspective(CGFloat(i), geometry))
                        .zIndex(Double(0))
                        //                            .opacity(0.7)
                        .onTapGesture {
                            if let session = self.context.sessions[i + self.countIndexOffset] {
                                // TODO:
                                do { try ActionOpenSession.exec(self.context, ["session": session])
                                }
                                catch {}
                            }
                            self.hide()
                    }
                }
            }
            .edgesIgnoringSafeArea(.vertical)
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { gestureState in
                    self.dragOffset = gestureState.translation.height
                }

                .onEnded { gestureState in
                    self.dragOffset = .zero
                    let origOffset = self._globalOffset
                    self._globalOffset = origOffset + gestureState.translation.height
                    //Add inertia
                    withAnimation(.easeOut(duration: 0.5)) {
                        self._globalOffset = origOffset + gestureState.predictedEndTranslation.height
                    }
                }
        )
    }
}

struct SessionSwitcher_Previews: PreviewProvider {
    static var previews: some View {
        SessionSwitcher().environmentObject(try! RootContext(name: "").mockBoot())
    }
}
