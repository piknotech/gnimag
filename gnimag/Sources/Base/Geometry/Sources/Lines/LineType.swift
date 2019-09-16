//
//  Created by David Knothe on 08.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//  

import Common
import Foundation

public protocol LineType {
    /// The starting point of the line, or any point on the line if the line has no starting point.
    /// When the line has no starting point, that means that `normalizedBounds` are just the real numbers.
    var startPoint: CGPoint { get }

    /// True iff the direction is zero, which means that the line is actually just a single point, i.e. `startPoint`.
    var isTrivial: Bool { get }

    /// The direction of the line, normalized.
    /// When the `directionIsZero`, the result is unspecified.
    var normalizedDirection: CGPoint { get }

    /// The range of the line, in respect to startPoint and normalizedDirection.
    /// This means: for any `t` inside `normalizedBounds`: `startPoint + t * normalizedDirection` is on the line.
    var normalizedBounds: SimpleRange<CGFloat> { get }
}

// MARK: Distance and Intersection

public extension LineType {
    /// Calculate the unsigned distance to a point.
    func distance(to point: CGPoint) -> CGFloat {
        if isTrivial { return startPoint.distance(to: point) }

        let t = normalizedDirection.dot(point - startPoint)
        let clamped = normalizedBounds.clamp(t)
        let projection = startPoint + clamped * normalizedDirection
        return projection.distance(to: point)
    }

    /// Find the intersection point of two lines.
    /// If there are multiple (the lines are collinear), return one of them.
    func intersection(with other: LineType) -> CGPoint? {
        // Check for zero directions before starting the real intersection check
        switch (isTrivial, other.isTrivial) {
        case (true, true):
            return startPoint == other.startPoint ? startPoint : nil
        case (true, false):
            return distance(to: other.startPoint) == 0 ? other.startPoint : nil
        case (false, true):
            return other.distance(to: startPoint) == 0 ? startPoint : nil
        case (false, false):
            () // Perform the actual intersection test
        }

        if let t = tForIntersection(with: other) {
            return startPoint + t * normalizedDirection
        } else {
            return nil
        }
    }

    /// Find `t` such that `startPoint + t * normalizedDirection` lies on the other line.
    /// If the line is trivial, return nil.
    func tForIntersection(with other: LineType) -> CGFloat? {
        if isTrivial { return nil }

        let num1 = (other.startPoint - startPoint).cross(normalizedDirection)
        let num2 = (other.startPoint - startPoint).cross(other.normalizedDirection)
        let denom = normalizedDirection.cross(other.normalizedDirection)

        // Lines are collinear, check if points are contained in the other line
        if num1 == 0 && denom == 0 {
            return tForCollinearIntersection(with: other)
        }

        // Lines are parallel, but not collinear
        if denom == 0 {
            return nil
        }

        // Lines may have one intersection – check if intersection is inside the bounds
        let t = num2 / denom
        let u = num1 / denom

        if normalizedBounds.contains(t) && other.normalizedBounds.contains(u) {
            return t
        } else {
            return nil
        }
    }

    /// Check if the two lines intersect or have a point in common.
    func intersects(with other: LineType) -> Bool {
        return intersection(with: other) != nil
    }
}

extension LineType {
    /// The intersection implementation for two lines which are collinear.
    private func tForCollinearIntersection(with other: LineType) -> CGFloat? {
        if startPoint == other.startPoint { return 0 }

        // If required, negate other.bounds so that the effective direction is the same (namely self.normalizedDirection)
        var otherBounds = directionsAreInTheSameHemisphere(normalizedDirection, other.normalizedDirection) ? other.normalizedBounds : other.normalizedBounds.negated

        // Check which of the starting points is before the other, in respect to the shared direction
        let startPointDiff = other.startPoint - startPoint
        let selfComesFirst = directionsAreInTheSameHemisphere(startPointDiff.normalized, normalizedDirection)
        let shiftDistance = (selfComesFirst ? +1 : -1) * startPointDiff.length

        // Shift the range of the other line so that it starts from the zero-point of this line and check for intersection
        otherBounds = otherBounds.shifted(by: shiftDistance)
        let intersection = normalizedBounds.intersection(with: otherBounds)

        // If there is an intersection, the point lies on both lines
        if intersection.isEmpty {
            return nil
        } else {
            return intersection.lower // Anything inside the intersection range would be valid
        }
    }

    /// Check if the two directions are in the same hemisphere of the unit circle.
    /// Only call this method with directions which are normalized!
    private func directionsAreInTheSameHemisphere(_ dir1: CGPoint, _ dir2: CGPoint) -> Bool {
        return dir1.distance(to: dir2) <= sqrt(2)
    }
}
