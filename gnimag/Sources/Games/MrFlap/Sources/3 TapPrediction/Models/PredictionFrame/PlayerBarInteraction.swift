//
//  Created by David Knothe on 16.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import GameKit

/// PlayerBarInteraction describes the interaction between a player and a bar – on a given playfield – focusing on the time range during which the player passes through the bar.
/// All properties and functions in this class are time-based (instead of angle-based) and are offset so that 0 corresponds to the currentTime.
struct PlayerBarInteraction {
    /// The current reference time, corresponding to 0.
    let currentTime: Double

    /// The total (absolute) speed with which the player and the bar are approaching each other.
    let totalSpeed: Double

    /// The time until the player hits the bar's center.
    /// This can be negative.
    let timeUntilHittingCenter: Double

    /// The time until the player fully leaves the bar.
    /// This is always non-negative!
    let timeUntilLeaving: Double

    /// The maximum time range during which the bar and the player could interact (e.g. at the furthest outward points).
    /// This is a range centered around `timeUntilHittingCenter`.
    let fullInteractionRange: SimpleRange<Double>

    /// The lower and upper widths of the bar (time-wise).
    /// These widths are time-wise, i.e. the duration required to pass the corresponding length.
    let widths: BarWidths

    /// The two curves describing the outer bounds of the bar.
    /// Because the bar width is height-dependent, these are not just vertical lines.
    let boundsCurves: BoundsCurves

    /// The full hole movement which is happening during `fullInteractionRange`.
    let holeMovement: HoleMovement

    /// The actual bar tracker object from which this interaction emerged
    /// Do not use it except for debugging purposes.
    let barTracker: BarTracker

    // MARK: Subtypes

    /// Time-valued widths of the bar, i.e. describing the required duration to pass the bar.
    struct BarWidths {
        let lower: Double
        let upper: Double

        /// The full width, i.e. the higher value of `lower` and `upper`.
        /// This is exactly the diameter of `fullInteractionRange`.
        let full: Double
    }

    /// BoundsCurves describes the two curves that enclose the bar.
    /// They are centered around `timeUntilHittingCenter`.
    struct BoundsCurves {
        let left: Curve
        let right: Curve

        /// A single curve, defined by a function in an interval.
        struct Curve {
            let function: Function
            let range: SimpleRange<Double>
        }
    }

    /// HoleMovement describes the movement of a hole which moves upwards and downwards alternately (but has a fixed vertical size).
    struct HoleMovement {
        let holeSize: Double

        /// The intersections of the furthest outward sections with the bar boundary curves.
        let intersectionsWithBoundsCurves: IntersectionsWithBoundsCurves
        struct IntersectionsWithBoundsCurves {
            let left: IntersectionWithBoundsCurve
            let right: IntersectionWithBoundsCurve

            struct IntersectionWithBoundsCurve {
                /// The regular x- and y-ranges of the intersection, i.e. the range between the intersection of the lower and the upper bound.
                let xRange: SimpleRange<Double>
                let yRange: SimpleRange<Double>
            }
        }

        /// The movement section. Each section is a linear movement, either upwards or downwards, alternately.
        let sections: [Section]
        struct Section {
            /// The full range during which this section is active.
            /// The different section bounds are not active during the exact same range because the bar curves are not vertical.
            let fullTimeRange: SimpleRange<Double>

            let lower: LinearMovement // lower = center - 0.5 * holeSize
            let upper: LinearMovement // upper = center + 0.5 * holeSize

            struct LinearMovement {
                let line: LinearFunction

                /// The range during which the movement is relevant; i.e. this range is always inside `fullInteractionRange`.
                /// Is nil if the line is not relevant at all.
                let range: SimpleRange<Double>?
            }
        }
    }
}
