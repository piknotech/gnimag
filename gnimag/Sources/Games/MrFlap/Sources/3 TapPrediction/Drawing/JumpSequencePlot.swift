//
//  Created by David Knothe on 12.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Geometry
import TestingTools

/// A class which can draw a playfield and a jump sequence.
/// The class can both draw `JumpSequenceFromSpecificPosition` and `JumpSequenceFromCurrentPosition`.
/// The plot is a time/height-plot; no (angular) x-values are plotted!
final class JumpSequencePlot {
    let plot: ScatterPlot

    /// Create a JumpSequencePlot from a jump sequence starting at a specific (player-independent) position (where the current time corresponds to 0).
    convenience init(sequence: JumpSequenceFromSpecificPosition, player: PlayerProperties, playfield: PlayfieldProperties, jumping: JumpingProperties) {
        let jumps = JumpSequencePlot.jumps(forTimeDistances: sequence.jumpTimeDistances, timeUntilEnd: sequence.timeUntilEnd, startPoint: sequence.startingPoint, jumping: jumping)

        self.init(jumps: jumps, player: player, playfield: playfield)

        // Draw jumps
        jumps.forEach { plot.stroke($0.scatterStrokable, with: .normal) }
    }

    /// Create a JumpSequencePlot from a jump sequence starting at the current player position (and time=0).
    convenience init(sequence: JumpSequenceFromCurrentPosition, player: PlayerProperties, playfield: PlayfieldProperties, jumping: JumpingProperties) {
        // Calculate current player jump and sequenced jumps
        let jumpStartPoint = Point(time: -player.timePassedSinceJumpStart, height: player.lastJumpStart.y)

        let initialJump = JumpSequencePlot.jump(from: jumpStartPoint, duration: player.timePassedSinceJumpStart + sequence.timeUntilStart, jumping: jumping)
        let jumps = JumpSequencePlot.jumps(forTimeDistances: sequence.jumpTimeDistances, timeUntilEnd: sequence.timeUntilEnd, startPoint: initialJump.endPoint, jumping: jumping)

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
        var dataPoints = jumps.map { $0.scatterStartPoint } + extraDataPoints
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
