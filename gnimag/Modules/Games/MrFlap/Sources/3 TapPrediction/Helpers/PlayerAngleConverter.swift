//
//  Created by David Knothe on 10.01.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import GameKit

/// PlayerAngleConverter provides methods to convert from player angle time system to real time system and back.
/// This is required because in game model collection, many trackers are not time-based on the real time, but on the player angle (which is just a linear transformation).
struct PlayerAngleConverter {
    typealias Angle = Double
    typealias Time = Double

    /// The time to angle conversion function.
    let timeToAngle: LinearFunction

    /// The angle conversion function.
    let angleToTime: LinearFunction

    /// Create a PlayerAngleConverter from the given player tracker.
    init?(player: PlayerTracker) {
        guard let angle = player.angle.tracker.regression else { return nil }

        timeToAngle = angle
        angleToTime = angle.inverse
    }

    // MARK: Value Conversion

    /// Convert a time value into an angular value.
    func angle(from time: Time) -> Angle {
        timeToAngle.at(time)
    }

    /// Convert an angular value into a time value.
    func time(from angle: Angle) -> Time {
        angleToTime.at(angle)
    }

    // MARK: Linear Function Conversion

    /// Convert a linear function whose argument is time into the same linear function whose argument is angle.
    func angleBasedLinearFunction(from function: LinearFunction) -> LinearFunction {
        LinearFunction(
            slope: function.slope * angleToTime.slope,
            intercept: function.slope * angleToTime.intercept + function.intercept
        )
    }

    /// Convert a linear function whose argument is angle into the same linear function whose argument is time.
    func timeBasedLinearFunction(from function: LinearFunction) -> LinearFunction {
        LinearFunction(
            slope: function.slope * timeToAngle.slope,
            intercept: function.slope * timeToAngle.intercept + function.intercept
        )
    }

    // MARK: Jumping Parabola Conversion

    /// Convert a parabola whose argument is time into the same parabola whose argument is angle.
    func angleBasedParabola(from parabola: Parabola) -> Parabola {
        var poly = Polynomial([parabola.c, parabola.b, parabola.a])
        poly = linearTransform(polynomial: poly, by: angleToTime)
        return Parabola(a: poly.a, b: poly.b, c: poly.c)
    }

    /// Convert a parabola whose argument is angle into the same parabola whose argument is time.
    func timeBasedParabola(from parabola: Parabola) -> Parabola {
        var poly = Polynomial([parabola.c, parabola.b, parabola.a])
        poly = linearTransform(polynomial: poly, by: timeToAngle)
        return Parabola(a: poly.a, b: poly.b, c: poly.c)
    }

    /// Convert a jumping parabola (i.e. a parabola going through (0,0)) whose argument is time into the same parabola whose argument is angle.
    /// Therefore, the point at (0,0) is retained.
    func angleBasedParabolaIgnoringIntercept(from parabola: Parabola) -> Parabola {
        let factor = angleToTime.slope
        return Parabola(a: parabola.a * factor * factor, b: parabola.b * factor, c: parabola.c)
    }

    /// Convert a jumping parabola (i.e. a parabola going through (0,0)) whose argument is angle into the same parabola whose argument is time.
    /// Therefore, the point at (0,0) is retained.
    func timeBasedParabolaIgnoringIntercept(from parabola: Parabola) -> Parabola {
        let factor = timeToAngle.slope
        return Parabola(a: parabola.a * factor * factor, b: parabola.b * factor, c: parabola.c)
    }

    // MARK: Polynomial Conversion

    /// Convert a polynomial whose argument is time into the same polynomial whose argument is angle.
    func angleBasedPolynomial(from polynomial: Polynomial) -> Polynomial {
        linearTransform(polynomial: polynomial, by: angleToTime)
    }

    /// Convert a polynomial whose argument is angle into the same polynomial whose argument is time.
    func timeBasedPolynomial(from polynomial: Polynomial) -> Polynomial {
        linearTransform(polynomial: polynomial, by: timeToAngle)
    }

    /// Convert a polynomial whose argument is time into the same polynomial whose argument is angle.
    /// Here, the intercept of the conversion function is ignored, just coefficient multiplication is performed. This retains the value of the function at 0.
    func angleBasedPolynomialIgnoringIntercept(from polynomial: Polynomial) -> Polynomial {
        let valueTransform = angleToTime - angleToTime.intercept
        return linearTransform(polynomial: polynomial, by: valueTransform)
    }

    /// Convert a polynomial whose argument is angle into the same polynomial whose argument is time.
    /// Here, the intercept of the conversion function is ignored, just coefficient multiplication is performed. This retains the value of the function at 0.
    func timeBasedPolynomialIgnoringIntercept(from polynomial: Polynomial) -> Polynomial {
        let valueTransform = timeToAngle - timeToAngle.intercept
        return linearTransform(polynomial: polynomial, by: valueTransform)
    }

    /// Transform the polynomial f linearly, such that g(x) = f(slope * x + intercept).
    private func linearTransform(polynomial: Polynomial, by transform: LinearFunction) -> Polynomial {
        // Slope = 0: Constant value
        if transform.slope == 0 {
            let constant = polynomial.at(transform.intercept)
            return Polynomial([constant])
        }

        // Slope = 1: Shift in x-direction
        else if transform.slope == 1 {
            return polynomial.shiftedLeft(by: transform.intercept)
        }

        // Stretch in x-direction
        else {
            // fixpoint = slope * fixpoint + intercept
            let fixpoint = transform.intercept / (1 - transform.slope)
            return polynomial.stretched(by: 1 / transform.slope, center: fixpoint)
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
        let line = angleBasedLinearFunction(from: portion.line)

        return LinearPortion(index: portion.index, timeRange: timeRange, line: line)
    }

    /// Convert a LinearSegmentPortion whose argument is angle into the same LinearSegmentPortion whose argument is time.
    func timeBasedLinearSegmentPortion(from portion: LinearPortion) -> LinearPortion {
        let timeRange = timeBasedRange(from: portion.timeRange)
        let line = timeBasedLinearFunction(from: portion.line)

        return LinearPortion(index: portion.index, timeRange: timeRange, line: line)
    }
}
