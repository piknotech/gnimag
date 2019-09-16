//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//
// Taken from https://www.nayuki.io/res/smallest-enclosing-circle/SmallestEnclosingCircle.cs

import Foundation
import Geometry

public enum SmallestCircle {
    /// Calculate the smallest circle that contains a given (non-empty) set of points.
    /// This runs in expected O(n) time.
    public static func containing(_ points: [CGPoint]) -> Circle {
        // Shuffle the list of points
        var points = points
        points.shuffle()

        var circle = Circle(center: .zero, radius: -1)

        // Progressively add points to circle or recompute circle
        for (i, p) in points.enumerated() {
            if !circle.contains(p) {
                let firstI = Array(points[...i])
                circle = SmallestCircle.containing(firstI, onCircumference: p)
            }
        }

        return circle
    }

    // MARK: Actual Work

    /// Calculate the smallest circle that contains a set of points, having ONE given point on it's circumference.
    private static func containing(_ points: [CGPoint], onCircumference p: CGPoint) -> Circle {
        var circle = Circle(center: p, radius: 0)

        // Progressively add points to circle or recompute circle
        for (i, q) in points.enumerated() {
            if !circle.contains(q) {
                if circle.radius == 0 {
                    circle = makeDiameter(through: p, q)
                } else {
                    let firstI = Array(points[...i])
                    circle = SmallestCircle.containing(firstI, onCircumference: p, q)
                }
            }
        }

        return circle
    }

    /// Calculate the smallest circle that contains a set of points, having TWO given points on it's circumference.
    private static func containing(_ points: [CGPoint], onCircumference p: CGPoint, _ q: CGPoint) -> Circle {
        let circle = makeDiameter(through: p, q)
        var left = Circle(center: .zero, radius: -1)
        var right = Circle(center: .zero, radius: -1)

        // For each point not in the two-point circle
        let pq = q - p
        for r in points {
            if circle.contains(r) {
                continue
            }

            // Form a circumcircle and classify it on left or right side
            let cross = pq.cross(r - p)
            let c = makeCircumcircle(through: p, q, r)
            if c.radius < 0 {
                continue
            } else if cross > 0 && (left.radius < 0 || pq.cross(c.center - p) > pq.cross(left.center - p)) {
                left = c
            } else if cross < 0 && (right.radius < 0 || pq.cross(c.center - p) < pq.cross(right.center - p)) {
                right = c
            }
        }

        // Select which circle to return
        if left.radius < 0 && right.radius < 0 {
            return circle
        } else if left.radius < 0 {
            return right
        } else if right.radius < 0 {
            return left
        } else {
            return left.radius <= right.radius ? left : right
        }
    }

    // MARK: Trivial Cases

    /// Return the smallest circle that contains two given points.
    private static func makeDiameter(through a: CGPoint, _ b: CGPoint) -> Circle {
        let c = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        return Circle(center: c, radius: a.distance(to: b) / 2)
    }

    /// Return the smallest circle that contains three given points.
    private static func makeCircumcircle(through a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Circle {
        // Mathematical algorithm from Wikipedia: Circumscribed circle
        let ox = (min(a.x, b.x, c.x) + max(min(a.x, b.x), c.x)) / 2
        let oy = (min(a.y, b.y, c.y) + max(min(a.y, b.y), c.y)) / 2
        let ax = a.x - ox, ay = a.y - oy
        let bx = b.x - ox, by = b.y - oy
        let cx = c.x - ox, cy = c.y - oy

        let d = (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by)) * 2
        if d == 0 {
            return Circle(center: .zero, radius: -1)
        }

        let x = ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay - by)) / d
        let y = ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx - ax)) / d
        let p = CGPoint(x: ox + x, y: oy + y)
        let r = max(p.distance(to: a), p.distance(to: b), p.distance(to: c))

        return Circle(center: p, radius: r)
    }
}
