//
//  Created by David Knothe on 10.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import GameKit

/// PlayerAngleConverter provides methods to convert from player angle time system to real time system and back.
/// This is required because in game model collection, many trackers are not time-based on the real time, but on the player angle (which is just a linear transformation).
struct PlayerAngleConverter {
    typealias Angle = Double
    typealias Time = Double

    // TODO: REPLACE THESE with 2 LinearFunctions

    /// The slope and intercept of the time to angle conversion function.
    private let timeToAngle: (slope: Double, intercept: Double)

    /// The slope and intercept of the time to angle conversion function.
    private let angleToTime: (slope: Double, intercept: Double)

    /// Create a PlayerAngleConverter from the given player tracker.
    static func from(player: PlayerCourse) -> PlayerAngleConverter? {
        guard let (slope, intercept) = player.angle.tracker.slopeAndIntercept else { return nil }

        return PlayerAngleConverter(
            timeToAngle: (slope, intercept),
            angleToTime: (1 / slope, -intercept / slope)
        )
    }

    // MARK: Value Conversion

    func angle(from time: Time) -> Angle {
        timeToAngle.slope * time + timeToAngle.intercept
    }

    func time(from angle: Angle) -> Time {
        angleToTime.slope * angle + angleToTime.intercept
    }

    // MARK: Linear Function Conversion

    /// Convert a linear function whose argument is time into the same linear function whose argument is angle.
    func angleBasedLinearFunction(from function: (slope: Double, intercept: Double)) -> (slope: Double, intercept: Double) {
        (function.slope * angleToTime.slope,
         function.slope * angleToTime.intercept + function.intercept)
    }

    /// Convert a linear function whose argument is angle into the same linear function whose argument is time.
    func timeBasedLinearFunction(from function: (slope: Double, intercept: Double)) -> (slope: Double, intercept: Double) {
        (function.slope * timeToAngle.slope,
         function.slope * timeToAngle.intercept + function.intercept)
    }

    // MARK: Polynomial Conversion

    /// Convert a polynomial whose argument is time into the same polynomial whose argument is angle.
    func angleBasedPolynomial(from polynomial: Polynomial) -> Polynomial {
        linearTransform(polynomial: polynomial, slope: angleToTime.slope, intercept: angleToTime.intercept)
    }

    /// Convert a polynomial whose argument is angle into the same polynomial whose argument is time.
    func timeBasedPolynomial(from polynomial: Polynomial) -> Polynomial {
        linearTransform(polynomial: polynomial, slope: timeToAngle.slope, intercept: timeToAngle.intercept)
    }

    /// Transform the polynomial f linearly, such that g(x) = f(slope * x + intercept).
    private func linearTransform(polynomial: Polynomial, slope: Double, intercept: Double) -> Polynomial {
        // Slope = 0: Constant value
        if slope == 0 {
            let constant = polynomial.at(intercept)
            return Polynomial([constant])
        }

        // Slope = 1: Shift in x-direction
        else if slope == 1 {
            return polynomial.shiftedLeft(by: intercept)
        }

        // Stretch in x-direction
        else {
            let fixpoint = intercept / (1 - slope) // fixpoint = slope * fixpoint + intercept
            return polynomial.stretched(by: 1 / slope, center: fixpoint)
        }
    }

    // MARK: Range Conversion

    /// Convert a range whose value is angle into the same range whose value is time.
    /// No regularity correction is performed.
    func angleBasedRange(from range: SimpleRange<Time>) -> SimpleRange<Angle> {
        let lower = angle(from: range.lower)
        let upper = angle(from: range.upper)
        return SimpleRange(from: lower, to: upper)
    }

    /// Convert a range whose value is time into the same range whose value is angle.
    /// No regularity correction is performed.
    func timeBasedRange(from range: SimpleRange<Time>) -> SimpleRange<Angle> {
        let lower = time(from: range.lower)
        let upper = time(from: range.upper)
        return SimpleRange(from: lower, to: upper)
    }

    // MARK: LinearSegmentPortion Conversion

    typealias LinearPortion = BasicLinearPingPongTracker.LinearSegmentPortion

    /// Convert a LinearSegmentPortion whose argument is time into the same LinearSegmentPortion whose argument is angle.
    func angleBasedLinearSegmentPortion(from portion: LinearPortion) -> LinearPortion {
        let timeRange = angleBasedRange(from: portion.timeRange)
        let function = angleBasedPolynomial(from: portion.function)

        return LinearPortion(index: portion.index, timeRange: timeRange, function: function)
    }

    /// Convert a LinearSegmentPortion whose argument is angle into the same LinearSegmentPortion whose argument is time.
    func timeBasedLinearSegmentPortion(from portion: LinearPortion) -> LinearPortion {
        let timeRange = timeBasedRange(from: portion.timeRange)
        let function = timeBasedPolynomial(from: portion.function)

        return LinearPortion(index: portion.index, timeRange: timeRange, function: function)
    }
}
