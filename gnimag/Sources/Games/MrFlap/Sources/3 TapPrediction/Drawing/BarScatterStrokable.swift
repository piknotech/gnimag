//
//  Created by David Knothe on 15.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import GameKit
import TestingTools

/// BarScatterStrokable strokes a bar.
struct BarScatterStrokable: ScatterStrokable {
    let bar: BarProperties
    let player: PlayerProperties
    let playfield: PlayfieldProperties

    /// Return a MultiStrokable consisting of multiple lines and curves.
    func concreteStrokable(for scatterPlot: ScatterPlot) -> Strokable {
        // Calculate when the bar will be hit by the player
        let speed = player.xSpeed - bar.xSpeed
        let distanceToBar = player.currentPosition.x.directedDistance(to: bar.xPosition, direction: speed)
        let barCenterTime = distanceToBar / speed

        // Outer bar lines
        let outerLines = outerBarLines(barCenterTime: barCenterTime)
        let outerCurves = outerBarCurves(barCenterTime: barCenterTime)
        let components = outerLines + outerCurves

        return MultiScatterStrokable(components: components).concreteStrokable(for: scatterPlot)
    }

    /// Create the two lines enclosing the bar from the left and the right.
    private func outerBarLines(barCenterTime: Double) -> [ScatterStrokable] {
        let upperWidth = player.converter.time(from: bar.angularWidthAtHeight(playfield.upperRadius))
        let lowerWidth = player.converter.time(from: bar.angularWidthAtHeight(playfield.lowerRadius))

        // Calculate left and right end points
        let left1 = (x: barCenterTime - upperWidth / 2, y: playfield.upperRadius)
        let left2 = (x: barCenterTime - lowerWidth / 2, y: playfield.lowerRadius)

        let right1 = (x: barCenterTime + upperWidth / 2, y: playfield.upperRadius)
        let right2 = (x: barCenterTime + lowerWidth / 2, y: playfield.lowerRadius)

        let leftLine = LinearScatterStrokable(line: LinearFunction(through: left1, and: left2), drawingRange: SimpleRange(from: left1.x, to: left2.x))
        let rightLine = LinearScatterStrokable(line: LinearFunction(through: right1, and: right2), drawingRange: SimpleRange(from: right1.x, to: right2.x))

        return [leftLine, rightLine]
    }

    /// Create the two curves enclosing the bar from the left and the right.
    private func outerBarCurves(barCenterTime: Double) -> [ScatterStrokable] {
        let upperWidth = player.converter.time(from: bar.angularWidthAtHeight(playfield.upperRadius))
        let lowerWidth = player.converter.time(from: bar.angularWidthAtHeight(playfield.lowerRadius))

        // Calculate left and right end points
        let leftRange = SimpleRange(from: barCenterTime - upperWidth / 2, to: barCenterTime - lowerWidth / 2, enforceRegularity: true)
        let rightRange = SimpleRange(from: barCenterTime + upperWidth / 2, to: barCenterTime + lowerWidth / 2, enforceRegularity: true)

        // Bar height at a given time-value
        let heightAtX: (Double) -> Double = { x in
            let timeWidth = 2 * abs(x - barCenterTime)
            let angularWidth = self.player.converter.angle(from: timeWidth)
            return self.bar.heightAtAngularWidth(angularWidth)
        }

        let leftLine = ArbitraryFunctionScatterStrokable(function: BlockFunction(block: heightAtX), drawingRange: leftRange, interpolationPoints: 20)
        let rightLine = ArbitraryFunctionScatterStrokable(function: BlockFunction(block: heightAtX), drawingRange: rightRange, interpolationPoints: 20)

        return [leftLine, rightLine]
    }
}

/// A Function which is defined by a closure.
fileprivate struct BlockFunction: Function {
    let block: (Value) -> Value

    func at(_ x: Self.Value) -> Self.Value {
        block(x)
    }
}