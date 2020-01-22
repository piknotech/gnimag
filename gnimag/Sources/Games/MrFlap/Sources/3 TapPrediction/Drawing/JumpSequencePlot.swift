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
        // Calculate initial player jump and following jumps
        let playerJumpStartPoint = Point(time: -player.timePassedSinceJumpStart, height: player.lastJumpStart.y)
        let currentPlayerPosition = Point(time: 0, height: player.currentPosition.y)

        let initialJump = JumpSequencePlot.jump(from: playerJumpStartPoint, duration: player.timePassedSinceJumpStart, jumping: jumping)
        let jumps = JumpSequencePlot.jumps(forTimeDistances: sequence.jumpTimeDistances, timeUntilEnd: sequence.timeUntilEnd, startPoint: currentPlayerPosition, jumping: jumping)

        self.init(jumps: [initialJump] + jumps, player: player, playfield: playfield)

        // Draw jumps, distinguishing the initial jump from the remaining jumps
        plot.stroke(initialJump.scatterStrokable, with: .emphasize, alpha: 1, strokeWidth: 1, dash: Dash(on: 3, off: 3))
        jumps.forEach { plot.stroke($0.scatterStrokable, with: .normal) }
    }

    /// Common initializer.
    /// Will create the scatter plot with the points from the (connected!) jumps, but not yet draw the jumps.
    private init(jumps: [Jump], player: PlayerProperties, playfield: PlayfieldProperties) {
        // Calculate data points
        var dataPoints = jumps.reduce(into: []) { $0.append($1.scatterStartPoint) }
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
    func draw(interaction: PlayerBarInteraction, currentTime: Double) {
        let strokable = BarScatterStrokable(interaction: interaction)
        plot.stroke(strokable, with: .normal, alpha: 1, strokeWidth: 1, dash: Dash(on: 1, off: 1))
    }
}
