//
//  Created by David Knothe on 12.01.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import GameKit
import Geometry
import TestingTools

/// A class which can draw a playfield and a Solution.
/// The plot is a time/height-plot; no (angular) x-values are plotted!
final class SolutionPlot {
    let plot: ScatterPlot

    /// Create a SolutionPlot from a frame and a solution.
    /// Draw both the jump sequence and the player-bar interaction.
    convenience init(frame: PredictionFrame, solution: Solution) {
        self.init(solution: solution, player: frame.player, playfield: frame.playfield, jumping: frame.jumping)
        frame.bars.forEach(draw(interaction:))
    }

    /// Create a SolutionPlot from a jump sequence starting at the current player position (and time=0).
    private convenience init(solution: Solution, player: PlayerProperties, playfield: PlayfieldProperties, jumping: JumpingProperties) {
        let initialJump = solution.currentJump(for: player, with: jumping, startingAt: .currentJumpStart)
        let jumps = solution.jumps(for: player, with: jumping)

        let currentPlayerPosition = ScatterDataPoint(x: 0, y: player.currentPosition.y)

        self.init(jumps: [initialJump] + jumps, extraDataPoints: [currentPlayerPosition], player: player, playfield: playfield)

        // Draw jumps, distinguishing the initial jump from the remaining jumps
        plot.stroke(initialJump.scatterStrokable, with: .emphasize, alpha: 1, strokeWidth: 1, dash: Dash(on: 3, off: 3))
        jumps.forEach { plot.stroke($0.scatterStrokable, with: .normal) }
    }

    /// Common initializer.
    /// Will create the scatter plot with the points from the (connected!) jumps, but not yet draw the jumps.
    private init(jumps: [Jump], extraDataPoints: [ScatterDataPoint] = [], player: PlayerProperties, playfield: PlayfieldProperties) {
        // Calculate data points
        var dataPoints = jumps.map(\.scatterStartPoint) + extraDataPoints
        dataPoints.append(jumps.last!.scatterEndPoint)

        // Create ScatterPlot
        let yRange = SimpleRange(from: playfield.lowerRadius, to: playfield.upperRadius)
        plot = ScatterPlot(dataPoints: dataPoints, yRange: yRange)

        // Draw playfield
        let lowerPlayfieldLine = HorizontalLineScatterStrokable(y: playfield.lowerRadius)
        let upperPlayfieldLine = HorizontalLineScatterStrokable(y: playfield.upperRadius)
        plot.stroke(lowerPlayfieldLine, with: .normal)
        plot.stroke(upperPlayfieldLine, with: .normal)
    }

    /// Write the plot to a given destination.
    func write(to file: String) {
        plot.write(to: file)
    }

    /// Write the plot to the users desktop.
    func writeToDesktop(name: String) {
        plot.writeToDesktop(name: name)
    }

    /// Draw the bar defined by the given interaction.
    func draw(interaction: PlayerBarInteraction) {
        let strokable = BarScatterStrokable(interaction: interaction)
        plot.stroke(strokable, with: .normal, alpha: 1, strokeWidth: 1, dash: Dash(on: 1, off: 1))
    }
}

// MARK: ScatterDataPoints and ScatterStrokables for Jumps

extension Jump {
    /// The start point as ScatterDataPoint.
    var scatterStartPoint: ScatterDataPoint {
        ScatterDataPoint(x: startPoint.time, y: startPoint.height)
    }

    /// The end point as ScatterDataPoint.
    var scatterEndPoint: ScatterDataPoint {
        ScatterDataPoint(x: endPoint.time, y: endPoint.height)
    }

    /// The ScatterStrokable representing the parabola.
    var scatterStrokable: ScatterStrokable {
        QuadCurveScatterStrokable(parabola: parabola, drawingRange: SimpleRange(from: startPoint.time, to: endPoint.time))
    }
}
