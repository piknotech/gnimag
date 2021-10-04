//
//  ContentView.swift
//  Calibrate
//
//  Created by David Knothe on 04.10.21.
//

import SwiftUI

struct ContentView: View {
    private let highlightingColor = Color.blue
    @State var highlightedPoint: CGPoint?

    var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { highlightedPoint = $0.location }
            .onEnded { _ in highlightedPoint = nil }
    }

    var body: some View {
        GeometryReader { geometry in
            makePath(for: geometry, point: highlightedPoint).stroke(highlightingColor, lineWidth: 2)
        }
        .background(Color.white)
        .gesture(drag)
    }

    private func makePath(for geometry: GeometryProxy, point: CGPoint?) -> Path {
        guard let point = point else {
            return Path { _ in }
        }

        return Path { path in
            path.move(to: CGPoint(x: 0, y: point.y))
            path.addLine(to: CGPoint(x: geometry.size.width, y: point.y))
            path.move(to: CGPoint(x: point.x, y: 0))
            path.addLine(to: CGPoint(x: point.x, y: geometry.size.height))
        }
    }
}
