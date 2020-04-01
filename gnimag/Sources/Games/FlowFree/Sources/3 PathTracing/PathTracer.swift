//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Tapping

infix operator &

/// PathTracer uses the screen layout to draw level solutions.
class PathTracer {
    private let underlyingDragger: Dragger

    /// The screen layout. Before using PathTracer, this must be set from outside.
    var screen: ScreenLayout!

    /// Default initializer.
    init(underlyingDragger: Dragger) {
        self.underlyingDragger = underlyingDragger
    }

    /// Synchronously draw the solution to a level onto the screen.
    /// Returns when drawing has finished.
    func draw(solution: Solution, to level: Level) {
        let order = level.bestPathTracingOrder

        for pathBegin in order {
            var path = solution.paths[pathBegin.colorIndex]

            // Reverse path if required
            if !pathBegin.isColorStart {
                path = path.reversed
            }

            draw(path: path)
        }
    }

    /// Position the pointing device at the center of the board.
    /// Do NOT wait for completion.
    func center() {
        let center = relativeScreenLocation(for: screen.board.aabb.center)
        _ = underlyingDragger.move(to: center)
    }

    /// Synchronously draw a single path onto the screen.
    /// Returns when drawing has finished.
    private func draw(path: Solution.Path) {
        // Begin at start
        let start = relativeScreenLocation(for: path.start)
        await & underlyingDragger.move(to: start)
        await & underlyingDragger.down()

        // Perform drag sequence
        for vertex in path.vertices + [path.end] {
            let point = relativeScreenLocation(for: vertex)
            await & underlyingDragger.move(to: point)
        }

        underlyingDragger.up()
    }

    /// Get the relative screen location from a position on the board.
    private func relativeScreenLocation(for position: Position) -> CGPoint {
        let absolute = screen.board.center(ofCellAt: position)
        return relativeScreenLocation(for: absolute)
    }

    /// Get the relative screen location from a CGPoint.
    private func relativeScreenLocation(for point: CGPoint) -> CGPoint {
        let x = point.x / screen.size.width
        let y = point.y / screen.size.height
        return CGPoint(x: x, y: y)
    }
}
