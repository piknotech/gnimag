//
//  Created by David Knothe on 17.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import GameKit

extension PlayerBarInteraction {
    private typealias Portion = BasicLinearPingPongTracker.LinearSegmentPortion

    /// Create a `PlayerBarInteraction` from the given models and the current time.
    init(player: PlayerProperties, bar: BarProperties, playfield: PlayfieldProperties, currentTime: Double, barTracker: BarTracker) {
        self.currentTime = currentTime
        self.barTracker = barTracker
        
        // Calculate when the player will hit the bar
        let direction = player.xSpeed - bar.xSpeed
        totalSpeed = abs(direction)
        let distanceToCenter = player.currentPosition.x.directedDistance(to: bar.xPosition, direction: direction)
        timeUntilHittingCenter = distanceToCenter / totalSpeed

        // Calculate remaining properties
        widths = Self.timeWidths(bar: bar, playfield: playfield, totalSpeed: totalSpeed)
        fullInteractionRange = SimpleRange(around: timeUntilHittingCenter, diameter: widths.full)
        boundsCurves = Self.boundsCurves(bar: bar, timeUntilHittingCenter: timeUntilHittingCenter, widths: widths, totalSpeed: totalSpeed)
        holeMovement = Self.holeMovement(bar: bar, currentTime: currentTime, timeUntilHittingCenter: timeUntilHittingCenter, widths: widths, curves: boundsCurves)
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
        let fullRange = SimpleRange(around: currentTime + timeUntilHittingCenter, diameter: widths.full)
        let yCenterMovement = bar.yCenterMovementPortionsForTimeRange(fullRange)

        // Map to HoleMovement.Sections
        let sections = yCenterMovement.compactMap {
            movementSection(from: $0, bar: bar, currentTime: currentTime, widths: widths, curves: curves)
        }

        // Calculate intersections with bounds curves
        let leftIntersection = intersection(of: sections, with: curves.left, isLeft: true)
        let rightIntersection = intersection(of: sections, with: curves.right, isLeft: false)
        let intersections = HoleMovement.IntersectionsWithBoundsCurves(left: leftIntersection, right: rightIntersection)

        return HoleMovement(holeSize: bar.holeSize, intersectionsWithBoundsCurves: intersections, sections: sections)
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

                // Try simple intersection
                if let intersection = BisectionSolver.intersection(of: curve.function, and: line, in: intersectionRange) { return intersection }

                // No intersection found; the line segment is either fully inside or outside the bar
                // Intersect the curve with the horizontal line x = const.
                let playfieldYRange = SimpleRange(from: curve.function.at(curve.range.lower), to: curve.function.at(curve.range.upper), enforceRegularity: true)
                let lower = line.at(timeRange.lower), upper = line.at(timeRange.upper)
                guard let const = playfieldYRange.contains(lower) ? lower : playfieldYRange.contains(upper) ? upper : nil else { return nil }

                guard let intersection = BisectionSolver.solve(curve.function, equals: const, in: curve.range) else { return nil }

                // Depending on wether the intersection is left or right of the range of the segment line, the segment is either inside or outside the bar
                if (intersection < timeRange.lower) == isLower {
                    return isLower ? timeRange.lower : timeRange.upper 
                } else {
                    return nil
                }
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

        let lower = linearMovement(forVerticalTranslation: -bar.holeSize / 2)
        let upper = linearMovement(forVerticalTranslation: +bar.holeSize / 2)

        // Calculate full range
        let validRanges = [lower, upper].map(\.range).compactMap(id)
        let fullTimeRange = validRanges.reduce(SimpleRange<Double>(from: .infinity, to: -.infinity)) { fullRange, new in
            fullRange.pseudoUnion(with: new)
        }

        // Discard irrelevant sections
        if fullTimeRange.isEmpty { return nil }

        return HoleMovement.Section(
            fullTimeRange: fullTimeRange,
            lower: lower,
            upper: upper
        )
    }

    /// Calculate the intersection of the sections with a single enclosing bound curve.
    /// Attention: if sections is empty (which it never should be), this will not yield the expected results.
    private static func intersection(of sections: [HoleMovement.Section], with curve: BoundsCurves.Curve, isLeft: Bool) -> HoleMovement.IntersectionsWithBoundsCurves.IntersectionWithBoundsCurve {
        // Intersect curve with lower movement
        let lowerRanges = sections.map(\.lower.range).compactMap(id)
        let lowerRange = (isLeft ? lowerRanges.first : lowerRanges.last) ?? curve.range
        let lowerBound = isLeft ? lowerRange.lower : lowerRange.upper

        // Intersect curve with upper movement
        let upperRanges = sections.map(\.upper.range).compactMap(id)
        let upperRange = (isLeft ? upperRanges.first : upperRanges.last) ?? curve.range
        let upperBound = isLeft ? upperRange.lower : upperRange.upper

        let xRange = SimpleRange(from: lowerBound, to: upperBound, enforceRegularity: true)
        let yRange = SimpleRange(from: curve.function.at(lowerBound), to: curve.function.at(upperBound), enforceRegularity: true)

        return .init(xRange: xRange, yRange: yRange)
    }
}
