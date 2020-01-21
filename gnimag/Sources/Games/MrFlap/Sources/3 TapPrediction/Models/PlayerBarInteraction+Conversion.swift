//
//  Created by David Knothe on 17.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import GameKit

extension PlayerBarInteraction {
    private typealias Portion = BasicLinearPingPongTracker.LinearSegmentPortion

    /// Create a `PlayerBarInteraction` from the given models and the current time.
    static func from(player: PlayerProperties, bar: BarProperties, playfield: PlayfieldProperties, currentTime: Double) -> PlayerBarInteraction {
        // Calculate when the player will hit the bar
        let direction = player.xSpeed - bar.xSpeed
        let totalSpeed = abs(direction)
        let distanceToCenter = player.currentPosition.x.directedDistance(to: bar.xPosition, direction: direction)
        let timeUntilHittingCenter = distanceToCenter / totalSpeed

        // Calculate remaining properties
        let widths = timeWidths(bar: bar, playfield: playfield, totalSpeed: totalSpeed)
        let fullInteractionRange = SimpleRange(around: timeUntilHittingCenter, diameter: widths.full)
        let curves = boundsCurves(bar: bar, timeUntilHittingCenter: timeUntilHittingCenter, widths: widths, totalSpeed: totalSpeed)
        let movement = holeMovement(bar: bar, currentTime: currentTime, timeUntilHittingCenter: timeUntilHittingCenter, widths: widths, curves: curves)

        // Put everything together
        return PlayerBarInteraction(
            totalSpeed: totalSpeed,
            timeUntilHittingCenter: timeUntilHittingCenter,
            fullInteractionRange: fullInteractionRange,
            widths: widths,
            boundsCurves: curves,
            holeMovement: movement
        )
    }

    /// Calculate the widths of the bar.
    private static func timeWidths(bar: BarProperties, playfield: PlayfieldProperties, totalSpeed: Double) -> BarWidths {
        let lower = bar.angularWidthAtHeight(playfield.lowerRadius) / totalSpeed
        let upper = bar.angularWidthAtHeight(playfield.upperRadius) / totalSpeed
        return BarWidths(lower: lower, upper: upper, full: max(lower, upper))
    }

    /// Calculate the bounds curves of the bar.
    private static func boundsCurves(bar: BarProperties, timeUntilHittingCenter: Double, widths: BarWidths, totalSpeed: Double) -> BoundsCurves {
        // Left and right time ranges
        let leftRange = SimpleRange(from: timeUntilHittingCenter - widths.upper / 2, to: timeUntilHittingCenter - widths.lower / 2, enforceRegularity: true)
        let rightRange = SimpleRange(from: timeUntilHittingCenter + widths.upper / 2, to: timeUntilHittingCenter + widths.lower / 2, enforceRegularity: true)

        // Bar height at a given time-value
        let heightAtX: (Double) -> Double = { x in
            let timeWidth = 2 * abs(x - timeUntilHittingCenter)
            let angularWidth = totalSpeed * timeWidth
            return bar.heightAtAngularWidth(angularWidth)
        }

        let left = BoundsCurves.Curve(function: FunctionWrapper(heightAtX), range: leftRange)
        let right = BoundsCurves.Curve(function: FunctionWrapper(heightAtX), range: rightRange)

        return BoundsCurves(left: left, right: right)
    }

    /// Calculate the hole movement during the relevant time range.
    private static func holeMovement(bar: BarProperties, currentTime: Double, timeUntilHittingCenter: Double, widths: BarWidths, curves: BoundsCurves) -> HoleMovement {
        // Calculate full yCenter movement (i.e. at the full width)
        let fullRange = SimpleRange(around: currentTime + timeUntilHittingCenter, diameter: 150 * widths.full)
        let yCenterMovement = bar.yCenterMovementPortionsForTimeRange(fullRange)

        // Map to HoleMovement.Sections
        let sections = yCenterMovement.compactMap {
            movementSection(from: $0, bar: bar, currentTime: currentTime, widths: widths, curves: curves)
        }

        return HoleMovement(sections: sections)
    }

    /// Convert a LinearSegmentPortion into a HoleMovement.Section.
    /// Returns nil if the section is fully irrelevant, i.e. outside the enclosing curves.
    private static func movementSection(from portion: Portion, bar: BarProperties, currentTime: Double, widths: BarWidths, curves: BoundsCurves) -> HoleMovement.Section? {
        // Shift portion back by currentTime (such that 0 corresponds to currentTime)
        let timeRange = portion.timeRange.shifted(by: -currentTime)
        let line = portion.line.shiftedLeft(by: currentTime)

        /// The linear movement for `line` when translated vertically.
        func linearMovement(forVerticalTranslation translation: Double) -> HoleMovement.Section.LinearMovement {
            let line = line + translation

            /// Calculate the intersection of the translated line with the given boundary curve.
            /// Return the time value which characterizes the respective (upper or lower) bound.
            func rangeBound(of curve: BoundsCurves.Curve, isLower: Bool) -> Double? {
                let intersectionRange = timeRange.intersection(with: curve.range)

                // The segment does not intersect with the bound curve because it is fully inside --> the range starts/end at the full timeRange
                if intersectionRange.isEmpty {
                    return isLower ? timeRange.lower : timeRange.upper
                }

                // Perform approximate intersection
                return BisectionSolver.intersection(of: curve.function, and: line, in: intersectionRange)
            }

            // Calculate interseting range
            let lower = rangeBound(of: curves.left, isLower: true)
            let upper = rangeBound(of: curves.right, isLower: false)

            switch (lower, upper) {
            case let (.some(left), .some(right)):
                return .init(line: line, range: SimpleRange(from: left, to: right))

            default: // No intersection; curve is irrelevant
                return .init(line: line, range: nil)
            }
        }

        let center = linearMovement(forVerticalTranslation: 0)
        let lower = linearMovement(forVerticalTranslation: -bar.holeSize / 2)
        let upper = linearMovement(forVerticalTranslation: +bar.holeSize / 2)

        // Calculate full range
        let validRanges = [center, lower, upper].map { $0.range }.compactMap(id)
        let fullTimeRange = validRanges.reduce(SimpleRange<Double>(from: .infinity, to: -.infinity)) { fullRange, new in
            fullRange.pseudoUnion(with: new)
        }

        return HoleMovement.Section(
            fullTimeRange: fullTimeRange,
            holeSize: bar.holeSize,
            center: center,
            lower: lower,
            upper: upper
        )
    }
}
