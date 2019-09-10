//
//  Created by David Knothe on 08.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//  

import Common
import Foundation

public protocol LineType {
    /// The starting point of the line, or any point on the line if the line has no starting point.
    /// When the line has no starting point, that means that `normalizedBounds` are just the real numbers.
    var zeroPoint: CGPoint { get }

    /// True iff the direction is zero, which means that the line is actually just a single point (`zeroPoint`).
    var directionIsZero: Bool { get }

    /// The direction of the line, normalized.
    /// When the `directionIsZero`, the result is unspecified.
    var normalizedDirection: CGPoint { get }

    /// The range of the line, in respect to zeroPoint and normalizedDirection.
    /// This means: for any `t` inside `normalizedBounds`: `zeroPoint + t * normalizedDirection` is on the line.
    var normalizedBounds: SimpleRange<CGFloat> { get }
}

public extension LineType {
    /// Calculate the unsigned distance to a point.
    func distance(to point: CGPoint) -> CGFloat {
        if directionIsZero { return zeroPoint.distance(to: point) }

        let t = normalizedDirection.dot(point - zeroPoint)
        let clamped = normalizedBounds.clamp(t)
        let projection = zeroPoint + clamped * normalizedDirection
        return projection.distance(to: point)
    }

    /// Find the intersection point of two lines.
    /// If there are multiple (the lines are collinear), return one of them.
    func intersection(with other: LineType) -> CGPoint? {
        // Check for zero directions before starting the real intersection check
        switch (directionIsZero, other.directionIsZero) {
        case (true, true):
            return zeroPoint == other.zeroPoint ? zeroPoint : nil
        case (true, false):
            return distance(to: other.zeroPoint) == 0 ? other.zeroPoint : nil
        case (false, true):
            return other.distance(to: zeroPoint) == 0 ? zeroPoint : nil
        case (false, false):
            () // Perform the actual intersection test
        }

        let num1 = (other.zeroPoint - zeroPoint).cross(normalizedDirection)
        let num2 = (other.zeroPoint - zeroPoint).cross(other.normalizedDirection)
        let denom = normalizedDirection.cross(other.normalizedDirection)

        // Lines are collinear, check if points are contained in the other line
        if num1 == 0 && denom == 0 {
            return collinearIntersection(with: other)
        }

        // Lines are parallel, but not collinear
        if denom == 0 {
            return nil
        }

        // Lines may have one intersection – check if intersection is inside the bounds
        let u = num1 / denom
        let t = num2 / denom
        print(normalizedBounds, other.normalizedBounds, u, t)
        if normalizedBounds.contains(u) && other.normalizedBounds.contains(t) {
            print(zeroPoint + u * normalizedDirection)
            print(other.zeroPoint + t * other.normalizedDirection)
            return zeroPoint + u * normalizedDirection
        }

        return nil
    }

    /// The intersection implementation for two lines which are collinear.
    private func collinearIntersection(with other: LineType) -> CGPoint? {
        if zeroPoint == other.zeroPoint { return zeroPoint }

        // If required, negate other.bounds so that the effective direction is the same (namely self.normalizedDirection)
        var otherBounds = directionsAreInTheSameHemisphere(normalizedDirection, other.normalizedDirection) ? other.normalizedBounds : other.normalizedBounds.negated

        // Check which of the starting points is before the other, in respect to the shared direction
        let zeroPointDiff = other.zeroPoint - zeroPoint
        let selfComesFirst = directionsAreInTheSameHemisphere(zeroPointDiff.normalized, normalizedDirection)
        let shiftDistance = (selfComesFirst ? +1 : -1) * zeroPointDiff.length

        // Shift the range of the other line so that it starts from the zero-point of this line and check for intersection
        otherBounds = otherBounds.shifted(by: shiftDistance)
        let intersection = normalizedBounds.intersection(with: otherBounds)

        // If there is an intersection, the point lies on both lines
        if intersection.isEmpty {
            return nil
        } else {
            return zeroPoint + intersection.lower * normalizedDirection
        }
    }

    /// Check if the two directions are in the same hemisphere of the unit circle.
    /// Only call this method with directions which are normalized!
    private func directionsAreInTheSameHemisphere(_ dir1: CGPoint, _ dir2: CGPoint) -> Bool {
        return dir1.distance(to: dir2) <= sqrt(2)
    }

    /// Check if the two lines intersect or have a point in common.
    func intersects(with other: LineType) -> Bool {
        return intersection(with: other) != nil
    }
}
