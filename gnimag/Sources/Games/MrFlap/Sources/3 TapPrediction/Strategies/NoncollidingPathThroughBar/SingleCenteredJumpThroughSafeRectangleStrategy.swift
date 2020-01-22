//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common

/// This NoncollidingPathThroughBarStrategy consists only of a single jump.
/// This jump passes the bar in such a way that the minimal distance to the upper and lower line of the safe rectangle for points inside the safe rectangle is maximized.
/// Thereby, the safe rectangle is the smallest rectangle fully inside the full hole movement during the player-bar-interaction.
/// This is achieved by creating a parabola x-centered at the bar's x-center, and y-aligned such that the minimal distances to the top and to the bottom are equal.
/// This strategy requires the bar to be thin enough in relation to the jump and player properties – else, a single jump won't be enough to pass the bar without colliding.
struct SingleCenteredJumpThroughSafeRectangleStrategy: NoncollidingPathThroughBarStrategy {
    func jumpSequence(through bar: BarProperties, in playfield: PlayfieldProperties, with player: PlayerProperties, jumping: JumpingProperties, currentTime: Double) -> JumpSequenceFromSpecificPosition {
        let interaction = PlayerBarInteraction.from(player: player, bar: bar, playfield: playfield, currentTime: currentTime)
        let safeRectangle = interaction.safeRectangle(for: playfield)

        // Testing: draw a plot
        let seq = JumpSequenceFromCurrentPosition(timeUntilStart: 0, jumpTimeDistances: [Double](repeating: jumping.horizontalJumpLength, count: 3), timeUntilEnd: 0)

        let plot = JumpSequencePlot(sequence: seq, player: player, playfield: playfield, jumping: jumping)
        plot.draw(interaction: interaction, currentTime: currentTime)
        let rect = CGRectScatterStrokable(rect: safeRectangle!)
        plot.plot.stroke(rect, with: .custom(.lightBlue))
        plot.writeToDesktop(name: "plotNew.png")

        return JumpSequenceFromSpecificPosition(startingPoint: Position(x: Angle(Double(0)), y: 0), jumpTimeDistances: [], timeUntilEnd: 0)
    }
}

// MARK: Safe Rectangle

private extension PlayerBarInteraction {
    /// The smallest rect which, when passed, guarantees a valid passing of the bar.
    /// In addition to hole movement, the playfield is taken to account (as the bar movement could be partially outside the playfield).
    /// Nil if there is no such rectangle (i.e. if the hole moves too rapid).
    func safeRectangle(for playfield: PlayfieldProperties) -> CGRect? {
        guard !holeMovement.verticalSafeRange.isEmpty else { return nil }

        let horizontalRange = holeMovement.horizontalFullRange
        let verticalRange = holeMovement.verticalSafeRange.intersection(with: playfield.range)

        return rect(xRange: horizontalRange, yRange: verticalRange)
    }

    /// Create a CGRect by cartesially multiplying the two ranges.
    private func rect(xRange x: SimpleRange<Double>, yRange y: SimpleRange<Double>) -> CGRect {
        CGRect(x: x.lower, y: y.lower, width: x.upper - x.lower, height: y.upper - y.lower)
    }
}

private extension PlayerBarInteraction.HoleMovement {
    /// The vertical safe range for hole movement. This means, no hole bound (lower or upper) will pass through this range.
    /// Can be irregular if hole movement is too rapid.
    var verticalSafeRange: SimpleRange<Double> {
        let lowerMaximum = sections.compactMap { $0.lowerMaximum }.max() ?? -.infinity
        let upperMinimum = sections.compactMap { $0.upperMinimum }.min() ?? +.infinity
        return SimpleRange(from: lowerMaximum, to: upperMinimum)
    }

    /// The full x-range during which hole movement happens.
    var horizontalFullRange: SimpleRange<Double> {
        let lower = intersectionsWithBoundsCurves.left.xRange.lower
        let upper = intersectionsWithBoundsCurves.right.xRange.upper
        return SimpleRange(from: lower, to: upper)
    }
}

private extension PlayerBarInteraction.HoleMovement.Section {
    /// The minimum value of the upper section inside it's range.
    var upperMinimum: Double? { upper.minimum }

    /// The minimum value of the upper section inside it's range.
    var lowerMaximum: Double? { lower.maximum }
}

private extension PlayerBarInteraction.HoleMovement.Section.LinearMovement {
    /// The maximum value the linear movement takes inside it's range, if the range is valid.
    var minimum: Double? {
        guard let range = range else { return nil }
        return min(line.at(range.lower), line.at(range.upper))
    }

    /// The maximum value the linear movement takes inside it's range, if the range is valid.
    var maximum: Double? {
        guard let range = range else { return nil }
        return max(line.at(range.lower), line.at(range.upper))
    }
}
